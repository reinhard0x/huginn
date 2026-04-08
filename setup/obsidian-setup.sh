#!/usr/bin/env bash
# ============================================================
#  obsidian-setup.sh — Huginn Obsidian Setup
#  Maverick Security LLC — Reinhard Persona
#  Sets up two vaults:
#    1. huginn (training) — inside ~/huginn repo, syncs to GitHub
#    2. ops-private        — local only, never pushed
# ============================================================

set -euo pipefail

# ── Colors ───────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[*]${RESET} $*"; }
success() { echo -e "${GREEN}[+]${RESET} $*"; }
warn()    { echo -e "${YELLOW}[!]${RESET} $*"; }
error()   { echo -e "${RED}[-]${RESET} $*"; }
section() { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; \
            echo -e "${BOLD}${CYAN}  $*${RESET}"; \
            echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; }

# ── Config ────────────────────────────────────────────────────
HUGINN_REPO="$HOME/huginn"               # training vault (git repo)
OPS_VAULT="$HOME/vaults/ops-private"     # private client vault
OBSIDIAN_VER=""                          # leave blank to auto-detect latest

# ── Preflight ─────────────────────────────────────────────────
section "Preflight"

if [[ $EUID -eq 0 ]]; then
    error "Do not run as root. Run as your regular user."
    exit 1
fi

if [[ ! -d "$HUGINN_REPO" ]]; then
    error "Huginn repo not found at $HUGINN_REPO"
    warn  "Clone it first: git clone https://github.com/reinhard0x/huginn.git ~/huginn"
    exit 1
fi

info "Huginn repo: $HUGINN_REPO"
info "Ops vault:   $OPS_VAULT"

# ── Install Obsidian ──────────────────────────────────────────
section "Installing Obsidian"

if command -v obsidian &>/dev/null || flatpak list 2>/dev/null | grep -q obsidian; then
    success "Obsidian already installed — skipping"
else
    info "Fetching latest Obsidian release..."
    OBSIDIAN_VER=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest \
        | grep '"tag_name"' | cut -d'"' -f4 | tr -d 'v')

    if [[ -z "$OBSIDIAN_VER" ]]; then
        error "Could not determine latest Obsidian version. Check your internet connection."
        exit 1
    fi

    info "Downloading Obsidian v${OBSIDIAN_VER}..."
    DEB_URL="https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VER}/obsidian_${OBSIDIAN_VER}_amd64.deb"
    DEB_FILE="/tmp/obsidian_${OBSIDIAN_VER}_amd64.deb"

    curl -L -o "$DEB_FILE" "$DEB_URL"
    sudo dpkg -i "$DEB_FILE" || sudo apt-get install -f -y
    rm -f "$DEB_FILE"
    success "Obsidian v${OBSIDIAN_VER} installed"
fi

# ── Training Vault (.obsidian in huginn repo) ─────────────────
section "Training Vault — Huginn Repo"

info "Verifying .obsidian config in $HUGINN_REPO..."

if [[ ! -d "$HUGINN_REPO/.obsidian" ]]; then
    warn ".obsidian directory not found — repo may not be up to date"
    warn "Run: cd ~/huginn && git pull origin main"
else
    success ".obsidian config present"
fi

# Verify notes/ folder exists
if [[ ! -d "$HUGINN_REPO/notes" ]]; then
    warn "notes/ folder missing — pulling latest..."
    git -C "$HUGINN_REPO" pull origin main
fi

info "Training vault ready at: $HUGINN_REPO"
info "Open this folder in Obsidian to use the training vault."

# ── Ops Private Vault ─────────────────────────────────────────
section "Ops Private Vault"

if [[ -d "$OPS_VAULT" ]]; then
    warn "ops-private vault already exists — skipping creation"
else
    info "Creating ops-private vault at $OPS_VAULT..."
    mkdir -p \
        "$OPS_VAULT/.obsidian/plugins/obsidian-git" \
        "$OPS_VAULT/.obsidian/snippets" \
        "$OPS_VAULT/templates" \
        "$OPS_VAULT/engagements" \
        "$OPS_VAULT/findings" \
        "$OPS_VAULT/reports" \
        "$OPS_VAULT/evidence"

    # ── Obsidian config ──
    cat > "$OPS_VAULT/.obsidian/app.json" <<'EOF'
{
  "accentColor": "#B08D57",
  "theme": "obsidian"
}
EOF

    cat > "$OPS_VAULT/.obsidian/appearance.json" <<'EOF'
{
  "accentColor": "#B08D57",
  "cssTheme": "",
  "enabledCssSnippets": ["reinhard"],
  "theme": "obsidian"
}
EOF

    cat > "$OPS_VAULT/.obsidian/core-plugins.json" <<'EOF'
[
  "file-explorer",
  "global-search",
  "switcher",
  "graph",
  "backlink",
  "outgoing-link",
  "tag-pane",
  "page-preview",
  "daily-notes",
  "templates",
  "command-palette",
  "note-composer",
  "editor-status",
  "starred",
  "outline",
  "word-count",
  "file-recovery"
]
EOF

    cat > "$OPS_VAULT/.obsidian/community-plugins.json" <<'EOF'
[]
EOF

    cat > "$OPS_VAULT/.obsidian/templates.json" <<'EOF'
{
  "folder": "templates",
  "dateFormat": "YYYY-MM-DD",
  "timeFormat": "HH:mm"
}
EOF

    # ── Reinhard CSS snippet ──
    cp "$HUGINN_REPO/.obsidian/snippets/reinhard.css" \
       "$OPS_VAULT/.obsidian/snippets/reinhard.css" 2>/dev/null || \
    warn "Could not copy CSS snippet — apply manually from huginn repo"

    # ── Safety .gitignore ──
    cat > "$OPS_VAULT/.gitignore" <<'EOF'
# ops-private vault — DO NOT PUSH TO ANY REMOTE
*
!.gitignore
EOF

    # ── Copy templates from training vault ──
    cp "$HUGINN_REPO/notes/templates/"*.md "$OPS_VAULT/templates/" 2>/dev/null || \
        warn "Could not copy templates — copy manually from $HUGINN_REPO/notes/templates/"

    # ── Gitkeeps ──
    touch "$OPS_VAULT/engagements/.gitkeep" \
          "$OPS_VAULT/findings/.gitkeep" \
          "$OPS_VAULT/reports/.gitkeep" \
          "$OPS_VAULT/evidence/.gitkeep"

    success "ops-private vault created at $OPS_VAULT"
fi

# ── Hotkey reference ──────────────────────────────────────────
section "Hotkey Reference"

cat <<'EOF'
  Ctrl+T             Insert template
  Ctrl+P             Command palette
  Ctrl+O             Quick switcher
  Ctrl+Shift+F       Search all notes
  Ctrl+G             Open graph view
  Ctrl+P → Git       Commit / push / pull (training vault only)

EOF

# ── Manual Steps ─────────────────────────────────────────────
section "One-Time Manual Steps"

cat <<EOF
${YELLOW}After running this script, do the following in Obsidian:${RESET}

  1. Open Obsidian → "Open folder as vault" → select: ${BOLD}$HUGINN_REPO${RESET}
     (this is your TRAINING vault — syncs to GitHub)

  2. Enable community plugins:
     Settings → Community Plugins → Turn off Restricted Mode → Browse
     Search for and install: ${BOLD}Obsidian Git${RESET}
     Enable it after installation.

  3. Add a second vault (ops-private):
     Vault switcher (bottom-left) → Open another vault → Open folder as vault
     Select: ${BOLD}$OPS_VAULT${RESET}
     ${RED}NOTE: ops-private stays local. Never install Obsidian Git in this vault.${RESET}

  4. (Optional) Install a dark theme:
     Settings → Appearance → Themes → Browse → search "Gruvbox" or "Minimal"
     The reinhard.css snippet handles accent colors regardless of theme chosen.

${GREEN}Setup complete.${RESET}
EOF
