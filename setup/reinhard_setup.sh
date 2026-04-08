#!/usr/bin/env bash
# ============================================================
# reinhard_setup.sh — v2.0.0
# Huginn (Kali Linux) — Maverick Security LLC
# Persona: Reinhard
#
# Usage: ./reinhard_setup.sh [--init|--update|--harden|--tools|--verify|--reset|--help]
#
#   --init      Full initial setup (recommended on fresh Kali install)
#   --update    Update packages and all cloned tools
#   --harden    Apply system hardening only (UFW, sysctl, Fail2Ban, AppArmor)
#   --tools     Clone / update pentest tools only
#   --verify    Check installation status
#   --reset     Remove tools directory (interactive confirmation)
#   --help      Show this help
# ============================================================

set -euo pipefail
IFS=$'\n\t'

# ============================================================
# CONSTANTS
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$HOME/.local/share/reinhard"
LOG_FILE="$LOG_DIR/setup-$(date +%Y%m%d).log"
TOOLS_DIR="$HOME/tools"
VENV_DIR="$HOME/.venvs"
OPS_DIR="$HOME/ops"
INSTALL_LIST="$SCRIPT_DIR/install_list.txt"
ZSHRC_SRC="$SCRIPT_DIR/dotfiles/reinhard.zshrc"
TERMINATOR_SRC="$SCRIPT_DIR/dotfiles/terminator_reinhard"
TERMINATOR_DEST="$HOME/.config/terminator/config"

# ============================================================
# COLORS
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GOLD='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================
# LOGGING
# ============================================================
mkdir -p "$LOG_DIR"

_log() {
    local level="$1"; shift
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${ts} [${level}] $*" | tee -a "$LOG_FILE"
}

info()    { _log "INFO " "${CYAN}[*]${NC} $*"; }
success() { _log "OK   " "${GREEN}[+]${NC} $*"; }
warn()    { _log "WARN " "${YELLOW}[!]${NC} $*"; }
error()   { _log "ERROR" "${RED}[-]${NC} $*"; }

header() {
    echo -e "\n${GOLD}${BOLD}══════════════════════════════════════════════════${NC}"
    echo -e "${GOLD}${BOLD}  $*${NC}"
    echo -e "${GOLD}${BOLD}══════════════════════════════════════════════════${NC}\n"
}

banner() {
    echo -e "${GOLD}${BOLD}"
    cat << 'EOF'
  ██████╗ ███████╗██╗███╗   ██╗██╗  ██╗ █████╗ ██████╗ ██████╗
  ██╔══██╗██╔════╝██║████╗  ██║██║  ██║██╔══██╗██╔══██╗██╔══██╗
  ██████╔╝█████╗  ██║██╔██╗ ██║███████║███████║██████╔╝██║  ██║
  ██╔══██╗██╔══╝  ██║██║╚██╗██║██╔══██║██╔══██║██╔══██╗██║  ██║
  ██║  ██║███████╗██║██║ ╚████║██║  ██║██║  ██║██║  ██║██████╔╝
  ╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝
EOF
    echo -e "${NC}"
    echo -e "${CYAN}  Huginn Setup Script v2.0.0${NC}"
    echo -e "${CYAN}  Maverick Security LLC — Kali Linux Deployment${NC}"
    echo -e "${CYAN}  Logging to: ${LOG_FILE}${NC}\n"
}

# ============================================================
# PRE-FLIGHT CHECKS
# ============================================================
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Do not run as root. Use a regular user with sudo."
        exit 1
    fi
}

check_kali() {
    if ! grep -qi kali /etc/os-release 2>/dev/null; then
        warn "This script targets Kali Linux. Proceeding on foreign OS."
    fi
}

check_internet() {
    info "Checking internet connectivity..."
    if ! curl -sf --max-time 8 https://1.1.1.1 > /dev/null; then
        error "No internet connection detected. Aborting."
        exit 1
    fi
    success "Internet OK."
}

# ============================================================
# PHASE 1 — APT REPOSITORIES
# ============================================================
setup_neo4j_repo() {
    header "neo4j Repository"

    # Check if already configured
    if apt-cache policy neo4j 2>/dev/null | grep -q "neo4j.com"; then
        info "neo4j repo already configured. Skipping."
        return 0
    fi

    info "Adding neo4j apt repository..."

    # Prefer gpg keyring method (modern); fall back to apt-key (deprecated)
    if command -v gpg &>/dev/null; then
        curl -fsSL https://debian.neo4j.com/neotechnology.gpg.key \
            | sudo gpg --dearmor -o /usr/share/keyrings/neo4j.gpg
        echo "deb [signed-by=/usr/share/keyrings/neo4j.gpg] https://debian.neo4j.com stable latest" \
            | sudo tee /etc/apt/sources.list.d/neo4j.list > /dev/null
    else
        wget -qO - https://debian.neo4j.com/neotechnology.gpg.key \
            | sudo apt-key add -
        echo "deb https://debian.neo4j.com stable latest" \
            | sudo tee /etc/apt/sources.list.d/neo4j.list > /dev/null
    fi

    sudo apt-get update -qq
    success "neo4j repository configured."
}

# ============================================================
# PHASE 2 — CORE PACKAGE INSTALLATION
# ============================================================
install_core_packages() {
    header "Core Package Installation"

    if [[ ! -f "$INSTALL_LIST" ]]; then
        error "install_list.txt not found at: $INSTALL_LIST"
        exit 1
    fi

    # Parse install_list.txt — strip comment lines and blank lines
    local pkgs=()
    while IFS= read -r line; do
        # Strip inline comments, then leading/trailing whitespace
        line="${line%%#*}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -n "$line" ]] && pkgs+=("$line")
    done < "$INSTALL_LIST"

    if [[ ${#pkgs[@]} -eq 0 ]]; then
        error "No packages found in install_list.txt after parsing."
        exit 1
    fi

    info "Preparing to install ${#pkgs[@]} packages..."
    sudo apt-get update -qq

    # Attempt batch install first; fall back to individual if batch fails
    DEBIAN_FRONTEND=noninteractive sudo apt-get install -y "${pkgs[@]}" || {
        warn "Batch install encountered errors. Retrying individually..."
        local failed=()
        for pkg in "${pkgs[@]}"; do
            if ! DEBIAN_FRONTEND=noninteractive sudo apt-get install -y "$pkg" 2>/dev/null; then
                warn "Failed: $pkg"
                failed+=("$pkg")
            fi
        done
        if [[ ${#failed[@]} -gt 0 ]]; then
            warn "Packages that could not be installed: ${failed[*]}"
        fi
    }

    # Install neo4j from its dedicated repo
    info "Installing neo4j..."
    DEBIAN_FRONTEND=noninteractive sudo apt-get install -y neo4j || \
        warn "neo4j install failed — ensure the repo was added first (run --init)."

    # Wireshark non-root capture
    if getent group wireshark &>/dev/null; then
        sudo usermod -aG wireshark "$USER"
        success "Added $USER to wireshark group — non-root capture enabled (re-login required)"
    fi

    success "Package installation complete."
}

# ============================================================
# PHASE 3 — OH MY ZSH + POWERLEVEL10K + FONTS
# ============================================================
install_ohmyzsh_and_p10k() {
    header "Oh My Zsh + Powerlevel10k + MesloLGS NF"

    # --- Oh My Zsh ---
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        info "Oh My Zsh already installed. Updating..."
        git -C "$HOME/.oh-my-zsh" pull --ff-only 2>/dev/null || \
            warn "OMZ update skipped (local changes)."
    else
        info "Installing Oh My Zsh (non-interactive)..."
        RUNZSH=no CHSH=no \
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        success "Oh My Zsh installed."
    fi

    local OMZ_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # --- Powerlevel10k ---
    local P10K_DIR="$OMZ_CUSTOM/themes/powerlevel10k"
    if [[ -d "$P10K_DIR" ]]; then
        info "Powerlevel10k present. Pulling updates..."
        git -C "$P10K_DIR" pull --ff-only 2>/dev/null || warn "p10k update skipped."
    else
        info "Cloning Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
        success "Powerlevel10k installed."
    fi

    # --- zsh-autosuggestions ---
    local ZAS="$OMZ_CUSTOM/plugins/zsh-autosuggestions"
    if [[ ! -d "$ZAS" ]]; then
        info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZAS"
    fi

    # --- zsh-syntax-highlighting ---
    local ZSH_HL="$OMZ_CUSTOM/plugins/zsh-syntax-highlighting"
    if [[ ! -d "$ZSH_HL" ]]; then
        info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_HL"
    fi

    # --- zsh-completions ---
    local ZCO="$OMZ_CUSTOM/plugins/zsh-completions"
    if [[ ! -d "$ZCO" ]]; then
        info "Installing zsh-completions..."
        git clone https://github.com/zsh-users/zsh-completions "$ZCO"
    fi

    # --- zsh-history-substring-search ---
    local HSS="$OMZ_CUSTOM/plugins/zsh-history-substring-search"
    if [[ ! -d "$HSS" ]]; then
        info "Installing zsh-history-substring-search..."
        git clone https://github.com/zsh-users/zsh-history-substring-search "$HSS"
    fi

    # --- MesloLGS NF Fonts ---
    local FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"

    local base_url="https://github.com/romkatv/powerlevel10k-media/raw/master"
    local -a fonts=(
        "MesloLGS NF Regular.ttf"
        "MesloLGS NF Bold.ttf"
        "MesloLGS NF Italic.ttf"
        "MesloLGS NF Bold Italic.ttf"
    )

    info "Downloading MesloLGS NF fonts..."
    for font in "${fonts[@]}"; do
        local dest="$FONT_DIR/$font"
        if [[ ! -f "$dest" ]]; then
            # URL-encode spaces as %20
            local enc="${font// /%20}"
            curl -fsSL "${base_url}/${enc}" -o "$dest" || \
                warn "Font download failed: $font"
        else
            info "Font already present: $font"
        fi
    done

    fc-cache -fv "$FONT_DIR" > /dev/null 2>&1
    success "MesloLGS NF installed. Restart Terminator and set font to 'MesloLGS NF 12'."
}

# ============================================================
# PHASE 4 — PYTHON VIRTUAL ENVIRONMENTS
# ============================================================
setup_python_venvs() {
    header "Python Virtual Environments"
    mkdir -p "$VENV_DIR"

    # Impacket venv — entry points (impacket-secretsdump, etc.) land on PATH via .zshrc
    if [[ ! -d "$VENV_DIR/impacket" ]]; then
        info "Creating impacket venv..."
        python3 -m venv "$VENV_DIR/impacket"
        "$VENV_DIR/impacket/bin/pip" install --quiet --upgrade pip
        "$VENV_DIR/impacket/bin/pip" install --quiet impacket
        success "Impacket venv created."
    else
        info "Impacket venv exists. Upgrading..."
        "$VENV_DIR/impacket/bin/pip" install --quiet --upgrade impacket
        success "Impacket updated."
    fi
}

# ============================================================
# PHASE 5 — PIPX TOOLS
# ============================================================
install_pipx_tools() {
    header "pipx Tools"

    # Ensure pipx is bootstrapped
    if command -v pipx &>/dev/null; then
        pipx ensurepath 2>/dev/null || true
    else
        warn "pipx not found — was it installed via apt? Trying via pip..."
        python3 -m pip install --user pipx
        python3 -m pipx ensurepath
    fi

    local -a pipx_tools=(
        "netexec"          # Replaces CrackMapExec (cmx/nxc)
        "certipy-ad"       # AD Certificate Services exploitation
    )

    for tool in "${pipx_tools[@]}"; do
        # Package name may differ from installed binary; check by package
        if pipx list 2>/dev/null | grep -q "^  - ${tool}"; then
            info "$tool already installed. Upgrading..."
            pipx upgrade "$tool" 2>/dev/null || warn "Upgrade failed for: $tool"
        else
            info "Installing $tool via pipx..."
            pipx install "$tool" || warn "Install failed for: $tool"
        fi
    done

    success "pipx tools ready."
}

# ============================================================
# PHASE 6 — TOOL CLONING
# ============================================================
clone_tools() {
    header "Pentest Tool Cloning"
    mkdir -p "$TOOLS_DIR"

    # Associative array: [directory-name]="git-url"
    # Only actively maintained repos as of 2026 audit.
    declare -A repos=(
        # ── Exploitation / Post-Exploitation ──────────────────────
        ["impacket"]="https://github.com/fortra/impacket"
        ["tplmap"]="https://github.com/epinna/tplmap"
        # ── Privilege Escalation ──────────────────────────────────
        ["PEASS-ng"]="https://github.com/peass-ng/PEASS-ng"
        ["wesng"]="https://github.com/bitsadmin/wesng"
        ["pspy"]="https://github.com/DominicBreuker/pspy"
        ["PrintSpoofer"]="https://github.com/itm4n/PrintSpoofer"
        # ── Active Directory ──────────────────────────────────────
        ["BloodHound"]="https://github.com/SpecterOps/BloodHound"
        ["Certipy"]="https://github.com/ly4k/Certipy"
        # ── Enumeration ───────────────────────────────────────────
        ["enum4linux-ng"]="https://github.com/cddmp/enum4linux-ng"
        ["NetExec"]="https://github.com/Pennyw0rth/NetExec"
        # ── Tunneling & Pivoting ──────────────────────────────────
        ["ligolo-ng"]="https://github.com/nicocha30/ligolo-ng"
        # ── Resources & References ────────────────────────────────
        ["PEH-Resources"]="https://github.com/TCM-Course-Resources/Practical-Ethical-Hacking-Resources"
    )

    for name in "${!repos[@]}"; do
        local url="${repos[$name]}"
        local dest="$TOOLS_DIR/$name"

        if [[ -d "$dest/.git" ]]; then
            info "Updating $name..."
            git -C "$dest" pull --ff-only 2>/dev/null || \
                warn "$name: fast-forward failed (local changes or diverged)."
        else
            info "Cloning $name..."
            git clone --depth=1 "$url" "$dest" || warn "Clone failed: $name"
        fi
    done

    # pspy binary release (64-bit)
    local pspy_bin="$TOOLS_DIR/pspy/pspy64"
    if [[ ! -f "$pspy_bin" ]]; then
        info "Downloading pspy64 binary..."
        mkdir -p "$TOOLS_DIR/pspy"
        curl -fsSL \
            "https://github.com/DominicBreuker/pspy/releases/latest/download/pspy64" \
            -o "$pspy_bin" && chmod +x "$pspy_bin"
        success "pspy64 downloaded."
    fi

    # Make enum4linux-ng executable
    local e4l="$TOOLS_DIR/enum4linux-ng/enum4linux-ng.py"
    [[ -f "$e4l" ]] && chmod +x "$e4l"

    success "Tool cloning complete."
}

# ============================================================
# PHASE 6.5 — ADDITIONAL TOOLS (Burp Suite, Docker)
# ============================================================
install_burpsuite() {
    header "Burp Suite Community Edition"
    if command -v burpsuite &>/dev/null; then
        success "Burp Suite already installed — skipping"
        return 0
    fi

    info "Fetching latest Burp Suite Community installer..."
    local BURP_URL BURP_INSTALLER
    BURP_URL="https://portswigger.net/burp/releases/download?product=community&type=Linux"
    BURP_INSTALLER="/tmp/burpsuite_community_linux.sh"

    if ! curl -sL --max-time 120 "$BURP_URL" -o "$BURP_INSTALLER"; then
        warn "Burp Suite download failed — skipping. Install manually from https://portswigger.net/burp"
        return 1
    fi

    chmod +x "$BURP_INSTALLER"
    # Silent install to /opt/BurpSuiteCommunity
    if "$BURP_INSTALLER" -q -dir /opt/BurpSuiteCommunity 2>/dev/null; then
        sudo ln -sf /opt/BurpSuiteCommunity/BurpSuiteCommunity /usr/local/bin/burpsuite
        rm -f "$BURP_INSTALLER"
        success "Burp Suite Community installed — launch with: burpsuite"
    else
        warn "Burp Suite installer failed. Download manually: https://portswigger.net/burp"
        rm -f "$BURP_INSTALLER"
    fi
}

install_docker() {
    header "Docker"
    if command -v docker &>/dev/null; then
        success "Docker already installed — skipping"
        return 0
    fi

    info "Installing Docker..."
    # Remove legacy packages if present
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    sudo apt-get install -y docker.io docker-compose-plugin
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker "$USER"
    success "Docker installed — re-login required for group membership"
}

init_metasploit() {
    header "Metasploit Database"
    if msfdb status 2>/dev/null | grep -q "connected"; then
        success "Metasploit DB already initialized"
        return 0
    fi

    info "Starting PostgreSQL and initializing Metasploit database..."
    sudo systemctl enable postgresql
    sudo systemctl start postgresql
    msfdb init
    success "Metasploit DB initialized"
}

setup_screen_lock() {
    header "Screen Auto-Lock"
    info "Installing xautolock + i3lock..."
    DEBIAN_FRONTEND=noninteractive sudo apt-get install -y xautolock i3lock 2>/dev/null || \
        warn "xautolock/i3lock install failed — screen lock not configured"

    # Add xautolock to XFCE autostart (10-minute idle lock)
    local AUTOSTART_DIR="$HOME/.config/autostart"
    mkdir -p "$AUTOSTART_DIR"
    cat > "$AUTOSTART_DIR/xautolock.desktop" <<'AUTOSTART'
[Desktop Entry]
Type=Application
Name=xautolock
Exec=xautolock -time 10 -locker 'i3lock -c 0D0D0D' -detectsleep
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
AUTOSTART
    success "Screen auto-lock configured (10 min idle → i3lock black screen)"
}

# ============================================================
# PHASE 7 — DIRECTORY STRUCTURE
# ============================================================
setup_directories() {
    header "Workspace Directories"

    local -a dirs=(
        "$OPS_DIR"
        "$OPS_DIR/vpn"
        "$OPS_DIR/writeups"
        "$OPS_DIR/tryhackme"
        "$TOOLS_DIR"
        "$VENV_DIR"
        "$HOME/.config/terminator"
        "$HOME/.local/share/fonts"
        "$HOME/dotfiles"
    )

    for d in "${dirs[@]}"; do
        mkdir -p "$d"
        info "Directory: $d"
    done

    # .blank file for xclip alias
    [[ -f "$HOME/.blank" ]] || touch "$HOME/.blank"

    success "Directory structure ready."
}

# ============================================================
# PHASE 8 — DEFAULT SHELL
# ============================================================
set_default_shell() {
    local zsh_path
    zsh_path="$(command -v zsh)"

    if [[ "$SHELL" == "$zsh_path" ]]; then
        info "zsh is already the default shell."
        return 0
    fi

    info "Setting zsh as default shell..."
    sudo chsh -s "$zsh_path" "$USER"
    success "Default shell → zsh. Log out and back in (or reboot) to apply."
}

# ============================================================
# PHASE 9 — CONFIG DEPLOYMENT
# ============================================================
deploy_configs() {
    header "Config Deployment"

    # --- reinhard.zshrc → ~/.zshrc ---
    if [[ -f "$ZSHRC_SRC" ]]; then
        if [[ -f "$HOME/.zshrc" ]]; then
            local bak="$HOME/.zshrc.bak.$(date +%Y%m%d%H%M%S)"
            cp "$HOME/.zshrc" "$bak"
            info "Existing .zshrc backed up to: $bak"
        fi
        cp "$ZSHRC_SRC" "$HOME/.zshrc"
        success "reinhard.zshrc → ~/.zshrc"
    else
        warn "reinhard.zshrc not found at $ZSHRC_SRC — skipping."
    fi

    # --- terminator_reinhard → ~/.config/terminator/config ---
    if [[ -f "$TERMINATOR_SRC" ]]; then
        mkdir -p "$(dirname "$TERMINATOR_DEST")"
        if [[ -f "$TERMINATOR_DEST" ]]; then
            local bak="${TERMINATOR_DEST}.bak.$(date +%Y%m%d%H%M%S)"
            cp "$TERMINATOR_DEST" "$bak"
            info "Existing Terminator config backed up to: $bak"
        fi
        cp "$TERMINATOR_SRC" "$TERMINATOR_DEST"
        success "terminator_reinhard → $TERMINATOR_DEST"
    else
        warn "terminator_reinhard not found at $TERMINATOR_SRC — skipping."
    fi

    # --- Git hooks ---
    local REPO_ROOT
    REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || true)"
    if [[ -n "$REPO_ROOT" && -d "$REPO_ROOT/.githooks" ]]; then
        git -C "$REPO_ROOT" config core.hooksPath .githooks
        chmod +x "$REPO_ROOT/.githooks/pre-commit" 2>/dev/null || true
        success "Git hooks configured: $REPO_ROOT/.githooks"
    fi
}

# ============================================================
# PHASE 10 — SYSTEM HARDENING
# ============================================================

harden_ufw() {
    info "Configuring UFW..."
    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw --force enable
    sudo systemctl enable ufw
    success "UFW: deny incoming, allow outgoing, SSH allowed."
}

harden_sysctl() {
    info "Applying kernel hardening (sysctl)..."
    sudo tee /etc/sysctl.d/99-reinhard.conf > /dev/null << 'SYSCTL'
# Reinhard — Kernel Hardening
# rp_filter — IP spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
# Ignore ICMP broadcasts
net.ipv4.icmp_echo_ignore_broadcasts = 1
# Block source-routed packets
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
# Don't send redirects
net.ipv4.conf.all.send_redirects = 0
# SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5
# Log martian packets
net.ipv4.conf.all.log_martians = 1
# Disable magic SysRq key
kernel.sysrq = 0
# Restrict /dev/kmsg / dmesg to root
kernel.dmesg_restrict = 1
# ASLR — full randomization
kernel.randomize_va_space = 2
# Restrict ptrace scope (Yama LSM)
kernel.yama.ptrace_scope = 1
SYSCTL
    sudo sysctl -p /etc/sysctl.d/99-reinhard.conf > /dev/null
    success "Kernel hardening applied."
}

harden_fail2ban() {
    info "Configuring Fail2Ban..."
    if ! command -v fail2ban-server &>/dev/null; then
        sudo apt-get install -y fail2ban > /dev/null
    fi
    sudo tee /etc/fail2ban/jail.local > /dev/null << 'FAIL2BAN'
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
backend  = systemd

[sshd]
enabled  = true
port     = ssh
logpath  = %(sshd_log)s
maxretry = 3
FAIL2BAN
    sudo systemctl enable --now fail2ban
    success "Fail2Ban: SSH max 3 retries, 1h ban."
}

harden_apparmor() {
    info "Enabling AppArmor..."
    if ! command -v aa-status &>/dev/null; then
        sudo apt-get install -y apparmor apparmor-utils > /dev/null
    fi
    sudo systemctl enable --now apparmor
    sudo aa-enforce /etc/apparmor.d/* 2>/dev/null || \
        warn "Some AppArmor profiles could not be enforced."
    success "AppArmor enabled and enforcing."
}

harden_auditing() {
    info "Initializing security audit tools..."

    if command -v rkhunter &>/dev/null; then
        sudo rkhunter --update --quiet 2>/dev/null || warn "rkhunter db update failed."
        sudo rkhunter --propupd --quiet
        success "rkhunter baseline updated."
    fi

    if command -v aide &>/dev/null; then
        if [[ ! -f /var/lib/aide/aide.db.gz ]]; then
            info "Initializing AIDE database (may take a few minutes)..."
            sudo aideinit -y > /dev/null 2>&1 || warn "AIDE init failed."
            success "AIDE database initialized."
        else
            info "AIDE database already exists."
        fi
    fi
}

run_hardening() {
    header "System Hardening"
    harden_ufw
    harden_sysctl
    harden_fail2ban
    harden_apparmor
    harden_auditing
    success "System hardening complete."
}

# ============================================================
# PHASE 11 — VERIFICATION
# ============================================================
verify_install() {
    header "Installation Verification"

    local pass=0 fail=0

    _check_cmd() {
        if command -v "$1" &>/dev/null; then
            success "  CMD  $1"
            ((pass++))
        else
            warn    "  CMD  $1  ✗ not found"
            ((fail++))
        fi
    }

    _check_file() {
        if [[ -f "$2" ]]; then
            success "  FILE $1"
            ((pass++))
        else
            warn    "  FILE $1  ✗ missing: $2"
            ((fail++))
        fi
    }

    _check_dir() {
        if [[ -d "$2" ]]; then
            success "  DIR  $1"
            ((pass++))
        else
            warn    "  DIR  $1  ✗ missing: $2"
            ((fail++))
        fi
    }

    echo ""
    info "── Commands ─────────────────────────────────"
    for cmd in zsh git vim curl tmux nmap gobuster ffuf ncat socat \
               python3 pip3 pipx go ruby neo4j btop pandoc \
               burpsuite docker wireshark msfdb xautolock; do
        _check_cmd "$cmd"
    done

    info "── Groups ──────────────────────────────────────"
    for grp in wireshark docker; do
        if id -nG "$USER" 2>/dev/null | grep -qw "$grp"; then
            success "  GROUP $grp"
            ((pass++))
        else
            warn    "  GROUP $grp  ✗ $USER not in group (re-login required?)"
            ((fail++))
        fi
    done

    info "── Oh My Zsh & Powerlevel10k ─────────────────"
    _check_dir "Oh My Zsh"      "$HOME/.oh-my-zsh"
    _check_dir "Powerlevel10k"  "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"

    info "── OMZ Plugins ───────────────────────────────"
    _check_dir "zsh-autosuggestions"       "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    _check_dir "zsh-syntax-highlighting"   "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    _check_dir "zsh-completions"           "$HOME/.oh-my-zsh/custom/plugins/zsh-completions"

    info "── Virtual Environments ──────────────────────"
    _check_dir  "Impacket venv"            "$VENV_DIR/impacket"
    _check_file "impacket-secretsdump"     "$VENV_DIR/impacket/bin/impacket-secretsdump"

    info "── Config Files ──────────────────────────────"
    _check_file "~/.zshrc"                 "$HOME/.zshrc"
    _check_file "Terminator config"        "$TERMINATOR_DEST"
    _check_file "~/.p10k.zsh"             "$HOME/.p10k.zsh"

    info "── Fonts ─────────────────────────────────────"
    _check_file "MesloLGS NF Regular"    "$HOME/.local/share/fonts/MesloLGS NF Regular.ttf"
    _check_file "MesloLGS NF Bold"       "$HOME/.local/share/fonts/MesloLGS NF Bold.ttf"

    info "── Tools Directory ───────────────────────────"
    for tool in PEASS-ng wesng BloodHound enum4linux-ng ligolo-ng PrintSpoofer; do
        _check_dir "$tool" "$TOOLS_DIR/$tool"
    done
    _check_file "pspy64" "$TOOLS_DIR/pspy/pspy64"

    echo ""
    echo -e "  ${BOLD}Results: ${GREEN}${pass} passed${NC}  ${YELLOW}${fail} failed${NC}"
    echo -e "  Log: $LOG_FILE\n"

    if [[ $fail -gt 0 ]]; then
        warn "Some checks failed. Review the log for details."
        return 1
    fi
    success "All checks passed."
}

# ============================================================
# RESET
# ============================================================
reset_tools() {
    header "Reset Tools Directory"
    warn "This will permanently remove: $TOOLS_DIR"
    echo -n "  Type 'yes' to confirm: "
    read -r confirm
    if [[ "$confirm" == "yes" ]]; then
        rm -rf "$TOOLS_DIR"
        success "Tools directory removed. Re-run --tools to restore."
    else
        info "Reset cancelled."
    fi
}

# ============================================================
# USAGE
# ============================================================
usage() {
    echo -e "\n${BOLD}Usage:${NC} $0 [OPTION]\n"
    echo -e "  ${GOLD}--init${NC}      Full setup: repos, packages, OMZ, P10k, fonts, venvs, tools, configs, harden"
    echo -e "  ${GOLD}--update${NC}    Update apt packages and all cloned tools"
    echo -e "  ${GOLD}--harden${NC}    Apply system hardening only (UFW / sysctl / Fail2Ban / AppArmor)"
    echo -e "  ${GOLD}--tools${NC}     Clone / update pentest tools and pipx tools"
    echo -e "  ${GOLD}--verify${NC}    Verify installation status"
    echo -e "  ${GOLD}--reset${NC}     Remove the tools directory (requires confirmation)"
    echo -e "  ${GOLD}--help${NC}      Show this help\n"
}

# ============================================================
# MAIN
# ============================================================
main() {
    banner
    check_root
    check_kali

    case "${1:-}" in
        --init)
            header "Full Initial Setup — Huginn"
            check_internet
            setup_directories
            setup_neo4j_repo
            install_core_packages
            install_ohmyzsh_and_p10k
            set_default_shell
            setup_python_venvs
            install_pipx_tools
            clone_tools
            install_burpsuite
            install_docker
            init_metasploit
            setup_screen_lock
            deploy_configs
            run_hardening
            verify_install
            echo ""
            success "═══════════════════════════════════════════════════"
            success "  Huginn initial setup complete."
            success "  Next: restart terminal, then run: p10k configure"
            success "  Note: re-login required for wireshark/docker groups"
            success "═══════════════════════════════════════════════════"
            ;;

        --update)
            header "Update Mode"
            check_internet
            sudo apt-get update && sudo apt-get upgrade -y
            install_ohmyzsh_and_p10k
            setup_python_venvs
            install_pipx_tools
            clone_tools
            success "Update complete."
            ;;

        --harden)
            run_hardening
            ;;

        --tools)
            check_internet
            clone_tools
            install_pipx_tools
            setup_python_venvs
            ;;

        --verify)
            verify_install
            ;;

        --reset)
            reset_tools
            ;;

        --help|-h|"")
            usage
            ;;

        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
}

main "$@"
