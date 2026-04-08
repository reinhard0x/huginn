# VSCode Customization — Reinhard / Huginn
**Persona**: Reinhard — Maverick Security LLC  
**System**: Huginn (Kali Linux)  
**Purpose**: Unified development, documentation, and operational tooling environment

---

## Platform Recommendation: GitHub

Both GitHub and GitLab have wikis, CI/CD, and free private repos — but GitHub is the clear choice for this setup for three reasons:

1. **VSCode is built on it.** The GitHub Pull Requests & Issues extension, Copilot, Codespaces, and the built-in Source Control panel all talk directly to GitHub with zero configuration. GitLab requires a separate extension and token management.
2. **You're already there.** Your `dotfiles` and `linux-packages` repos live at `github.com/tyler-maverick-higgins` — keeping everything under one account means one SSH key, one profile, one notification stream.
3. **GitHub Actions** is more mature than GitLab CI for lightweight automation (running `reinhard_setup.sh` in a CI job, linting configs, auto-generating docs).

> GitLab's self-hosting is compelling for high-sensitivity OPSEC work — worth revisiting if Huginn ever graduates to running its own Gitea or self-hosted GitLab instance.

---

## Repo Structure

Recommended layout for the new `huginn` repo:

```
huginn/
├── README.md                    ← Persona brief, system overview, quick-start
├── .gitignore
├── dotfiles/
│   ├── .zshrc                   ← reinhard.zshrc
│   ├── terminator               ← Terminator config
│   ├── .p10k.zsh                ← P10k config (generate with p10k configure)
│   └── .vimrc
├── setup/
│   ├── reinhard_setup.sh
│   ├── install_list.txt
│   └── README.md                ← Setup instructions
├── vscode/
│   ├── settings.json            ← Editor settings (this doc's output)
│   ├── extensions.json          ← Recommended extensions list
│   └── keybindings.json
├── docs/
│   ├── deployment-hardening-guide.md
│   └── vscode-customization.md  ← This document
└── ops/
    └── .gitkeep                 ← Never commit real ops data here
```

---

## Theme

### Recommended: Catppuccin Mocha

**Extension**: `Catppuccin.catppuccin-vsc`  
**Variant**: `Catppuccin Mocha`

Catppuccin Mocha is the current standard for dark terminal-adjacent workflows — deep backgrounds, warm earthy pastels, and wide port coverage (Obsidian, Terminator, Firefox, etc. all have Catppuccin ports). The Reinhard color overrides below lock the background to `#0D0D0D` and apply brass/gold accents on top, so the base theme mainly contributes syntax highlighting and UI chrome.

**Alternative**: `Gruvbox` (`jdinhlife.gruvbox`) — the original Gruvbox palette for VSCode, still actively maintained. Use `Gruvbox Dark Hard` variant if you want to stay closer to the classic Gruvbox feel.

**Icon Theme**: `vscode-icons` (`vscode-icons-team.vscode-icons`) — more comprehensive file detection than Material Icon Theme; recognizes `.zshrc`, Terminator configs, shell scripts, etc.

### Color Token Overrides (settings.json)

These overrides pull the editor accent closer to the Reinhard brass/gold and match the Terminator background exactly:

```json
"editor.tokenColorCustomizations": {
    "[Catppuccin Mocha]": {
        "textMateRules": [
            {
                "scope": ["keyword", "keyword.control"],
                "settings": { "foreground": "#B08D57" }
            },
            {
                "scope": ["string", "string.quoted"],
                "settings": { "foreground": "#72BB78" }
            },
            {
                "scope": ["comment"],
                "settings": { "foreground": "#4A4A46", "fontStyle": "italic" }
            }
        ]
    }
},
"workbench.colorCustomizations": {
    "[Catppuccin Mocha]": {
        "editor.background":              "#0D0D0D",
        "terminal.background":            "#0D0D0D",
        "activityBar.background":         "#0D0D0D",
        "sideBar.background":             "#0F0F0F",
        "statusBar.background":           "#1A1A17",
        "statusBarItem.remoteBackground": "#B08D57",
        "statusBarItem.remoteForeground": "#0D0D0D",
        "tab.activeBackground":           "#1A1A17",
        "tab.inactiveBackground":         "#0D0D0D",
        "titleBar.activeBackground":      "#1A1A17",
        "titleBar.activeForeground":      "#CDCCCA",
        "editorCursor.foreground":        "#B08D57",
        "editorLineNumber.foreground":    "#3D3C38",
        "editorLineNumber.activeForeground": "#B08D57"
    }
}
```

---

## settings.json

Full workspace settings file. Lives at `.vscode/settings.json` in the `huginn` repo, and can be copied to `~/.config/Code/User/settings.json` as the global config.

```json
{
    // ── Appearance ────────────────────────────────────────────
    "workbench.colorTheme": "Catppuccin Mocha",
    "workbench.iconTheme": "vscode-icons",
    "workbench.tree.indent": 16,
    "workbench.startupEditor": "none",
    "workbench.editor.showTabs": "multiple",
    "workbench.editor.wrapTabs": true,

    // ── Font (matches Terminator — MesloLGS NF must be installed) ──
    "editor.fontFamily": "'MesloLGS NF', 'Fira Code', 'Cascadia Code', monospace",
    "editor.fontSize": 13,
    "editor.lineHeight": 1.6,
    "editor.fontLigatures": true,
    "terminal.integrated.fontFamily": "'MesloLGS NF'",
    "terminal.integrated.fontSize": 13,

    // ── Editor Behavior ───────────────────────────────────────
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "editor.detectIndentation": true,
    "editor.wordWrap": "off",
    "editor.rulers": [100],
    "editor.renderWhitespace": "boundary",
    "editor.formatOnSave": true,
    "editor.formatOnPaste": false,
    "editor.bracketPairColorization.enabled": true,
    "editor.guides.bracketPairs": "active",
    "editor.suggestSelection": "first",
    "editor.minimap.enabled": false,
    "editor.scrollBeyondLastLine": false,
    "editor.cursorBlinking": "smooth",
    "editor.cursorStyle": "block",
    "editor.smoothScrolling": true,
    "editor.linkedEditing": true,

    // ── Files ──────────────────────────────────────────────────
    "files.autoSave": "onFocusChange",
    "files.trimTrailingWhitespace": true,
    "files.insertFinalNewline": true,
    "files.trimFinalNewlines": true,
    "files.exclude": {
        "**/.git": true,
        "**/__pycache__": true,
        "**/*.pyc": true,
        "**/.DS_Store": true
    },

    // ── Terminal (uses your Reinhard zsh config) ───────────────
    "terminal.integrated.shell.linux": "/bin/zsh",
    "terminal.integrated.defaultProfile.linux": "zsh",
    "terminal.integrated.profiles.linux": {
        "zsh": {
            "path": "/bin/zsh",
            "args": ["-l"],
            "icon": "terminal-linux"
        }
    },
    "terminal.integrated.scrollback": 10000,
    "terminal.integrated.copyOnSelection": true,
    "terminal.integrated.rightClickBehavior": "paste",

    // ── Git ────────────────────────────────────────────────────
    "git.enableSmartCommit": true,
    "git.autofetch": true,
    "git.confirmSync": false,
    "git.decorations.enabled": true,
    "gitlens.hovers.currentLine.over": "line",
    "gitlens.codeLens.enabled": false,

    // ── Python ────────────────────────────────────────────────
    "python.defaultInterpreterPath": "/usr/bin/python3",
    "python.formatting.provider": "black",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": false,
    "python.linting.flake8Enabled": true,
    "[python]": {
        "editor.defaultFormatter": "ms-python.black-formatter",
        "editor.tabSize": 4
    },

    // ── Go ────────────────────────────────────────────────────
    "go.useLanguageServer": true,
    "go.formatTool": "goimports",
    "[go]": {
        "editor.formatOnSave": true,
        "editor.tabSize": 4,
        "editor.insertSpaces": false
    },

    // ── Shell ─────────────────────────────────────────────────
    "[shellscript]": {
        "editor.defaultFormatter": "foxundermoon.shell-format",
        "editor.tabSize": 4
    },

    // ── Markdown ──────────────────────────────────────────────
    "markdown.preview.breaks": true,
    "[markdown]": {
        "editor.wordWrap": "on",
        "editor.quickSuggestions": { "other": true, "comments": true, "strings": true },
        "editor.defaultFormatter": "yzhang.markdown-all-in-one"
    },

    // ── YAML ──────────────────────────────────────────────────
    "[yaml]": {
        "editor.tabSize": 2,
        "editor.insertSpaces": true
    },

    // ── Extensions: Error Lens ────────────────────────────────
    "errorLens.enabled": true,
    "errorLens.followCursor": "allLines",

    // ── Extensions: Better Comments ───────────────────────────
    "better-comments.tags": [
        { "tag": "!",  "color": "#C0504A", "strikethrough": false, "underline": false, "backgroundColor": "transparent", "bold": true,   "italic": false },
        { "tag": "?",  "color": "#3D8C8C", "strikethrough": false, "underline": false, "backgroundColor": "transparent", "bold": false,  "italic": false },
        { "tag": "//", "color": "#4A4A46", "strikethrough": true,  "underline": false, "backgroundColor": "transparent", "bold": false,  "italic": false },
        { "tag": "TODO", "color": "#B08D57", "strikethrough": false, "underline": false, "backgroundColor": "transparent", "bold": true, "italic": false },
        { "tag": "*",  "color": "#72BB78", "strikethrough": false, "underline": false, "backgroundColor": "transparent", "bold": true,   "italic": false }
    ],

    // ── Extensions: Todo Tree ─────────────────────────────────
    "todo-tree.general.tags": ["BUG", "HACK", "FIXME", "TODO", "XXX", "NOTE", "OPSEC"],
    "todo-tree.highlights.defaultHighlight": {
        "icon": "alert",
        "type": "text",
        "foreground": "#0D0D0D",
        "background": "#B08D57",
        "opacity": 50,
        "iconColour": "#B08D57"
    },

    // ── Telemetry ──────────────────────────────────────────────
    "telemetry.telemetryLevel": "off",
    "redhat.telemetry.enabled": false
}
```

---

## Recommended Extensions

Install all at once with the block in `vscode/extensions.json` (see below) or individually via the command palette.

### Version Control & Collaboration
| Extension | ID | Purpose |
|---|---|---|
| **GitLens** | `eamodio.gitlens` | Inline git blame, history, diff, commit explorer — essential |
| **GitHub Pull Requests** | `github.vscode-pull-request-github` | PR review, issue tracking, and GitHub Actions status directly in VSCode |

### Language Support
| Extension | ID | Purpose |
|---|---|---|
| **Python** | `ms-python.python` | IntelliSense, debugging, venv management |
| **Pylance** | `ms-python.vscode-pylance` | Fast Python type checking and auto-import |
| **Black Formatter** | `ms-python.black-formatter` | Opinionated Python formatting |
| **Go** | `golang.go` | Full Go toolchain integration |
| **PowerShell** | `ms-vscode.powershell` | Syntax, debugging, and ISE for Windows pen test scripts |
| **Bash IDE** | `mads-hartmann.bash-ide-vscode` | Completion and hover for shell scripts |
| **ShellCheck** | `timonwong.shellcheck` | Lints shell scripts; catches bugs in setup scripts |
| **shell-format** | `foxundermoon.shell-format` | Auto-format `.sh` and `.zsh` files |

### Documentation & Writing
| Extension | ID | Purpose |
|---|---|---|
| **Markdown All in One** | `yzhang.markdown-all-in-one` | TOC generation, keyboard shortcuts, auto-preview |
| **Markdown PDF** | `yzane.markdown-pdf` | Export writeups directly to PDF from VSCode |
| **YAML** | `redhat.vscode-yaml` | Schema validation and completion for CI configs |

### Security & Pentest Workflow
| Extension | ID | Purpose |
|---|---|---|
| **Hex Editor** | `ms-vscode.hexeditor` | Binary inspection, payload analysis |
| **REST Client** | `humao.rest-client` | Send HTTP requests from `.http` files — useful for API pentesting |
| **Remote - SSH** | `ms-vscode-remote.remote-ssh` | Connect directly to Huginn (or a target) over SSH |
| **Remote Explorer** | `ms-vscode-remote.remote-explorer` | Manage SSH remotes visually |
| **Docker** | `ms-azuretools.vscode-docker` | Manage BloodHound CE and other tool containers |

### UI & Productivity
| Extension | ID | Purpose |
|---|---|---|
| **Catppuccin** | `Catppuccin.catppuccin-vsc` | Primary theme (Mocha variant) |
| **vscode-icons** | `vscode-icons-team.vscode-icons` | Comprehensive icon set |
| **Error Lens** | `usernamehw.errorlens` | Inline error/warning display — no more hunting the Problems panel |
| **Better Comments** | `aaron-bond.better-comments` | Color-coded comment tags (TODO, !, ?, OPSEC) |
| **Todo Tree** | `gruntfuggly.todo-tree` | Sidebar view of all TODO/FIXME/OPSEC notes across the repo |
| **Indent Rainbow** | `oderwat.indent-rainbow` | Colored indent guides — useful in Python and YAML |
| **Rainbow CSV** | `mechatroner.rainbow-csv` | Highlight and query CSV files (loot, scan output) |
| **Path Intellisense** | `christian-kohler.path-intellisense` | Autocomplete file paths |
| **Trailing Spaces** | `shardulm94.trailing-spaces` | Highlight and trim trailing whitespace |

---

## extensions.json

Place at `.vscode/extensions.json` in the repo. VSCode will prompt any cloner to install these automatically.

```json
{
    "recommendations": [
        "eamodio.gitlens",
        "github.vscode-pull-request-github",
        "ms-python.python",
        "ms-python.vscode-pylance",
        "ms-python.black-formatter",
        "golang.go",
        "ms-vscode.powershell",
        "mads-hartmann.bash-ide-vscode",
        "timonwong.shellcheck",
        "foxundermoon.shell-format",
        "yzhang.markdown-all-in-one",
        "yzane.markdown-pdf",
        "redhat.vscode-yaml",
        "ms-vscode.hexeditor",
        "humao.rest-client",
        "ms-vscode-remote.remote-ssh",
        "ms-vscode-remote.remote-explorer",
        "ms-azuretools.vscode-docker",
        "Catppuccin.catppuccin-vsc",
        "vscode-icons-team.vscode-icons",
        "usernamehw.errorlens",
        "aaron-bond.better-comments",
        "gruntfuggly.todo-tree",
        "oderwat.indent-rainbow",
        "mechatroner.rainbow-csv",
        "christian-kohler.path-intellisense",
        "shardulm94.trailing-spaces"
    ]
}
```

---

## keybindings.json

Security-workflow focused keybindings. Place at `~/.config/Code/User/keybindings.json`.

```json
[
    // Terminal shortcuts
    { "key": "ctrl+`",       "command": "workbench.action.terminal.toggleTerminal" },
    { "key": "ctrl+shift+`", "command": "workbench.action.terminal.new" },
    { "key": "ctrl+alt+t",   "command": "workbench.action.terminal.newWithCwd" },

    // Quick file operations
    { "key": "ctrl+shift+e", "command": "workbench.view.explorer" },
    { "key": "ctrl+shift+g", "command": "workbench.view.scm" },
    { "key": "ctrl+shift+x", "command": "workbench.view.extensions" },

    // Panel management
    { "key": "ctrl+b",       "command": "workbench.action.toggleSidebarVisibility" },
    { "key": "ctrl+j",       "command": "workbench.action.togglePanel" },

    // Markdown preview
    { "key": "ctrl+shift+v", "command": "markdown.showPreviewToSide", "when": "editorLangId == markdown" },

    // TODO Tree
    { "key": "ctrl+shift+t", "command": "todo-tree.showFlatView" }
]
```

---

## Quick Install Script

Run this once on Huginn to install all extensions from the command line (no GUI required):

```bash
#!/usr/bin/env bash
# Install Reinhard VSCode extensions
extensions=(
    eamodio.gitlens
    github.vscode-pull-request-github
    ms-python.python
    ms-python.vscode-pylance
    ms-python.black-formatter
    golang.go
    ms-vscode.powershell
    mads-hartmann.bash-ide-vscode
    timonwong.shellcheck
    foxundermoon.shell-format
    yzhang.markdown-all-in-one
    yzane.markdown-pdf
    redhat.vscode-yaml
    ms-vscode.hexeditor
    humao.rest-client
    ms-vscode-remote.remote-ssh
    ms-vscode-remote.remote-explorer
    ms-azuretools.vscode-docker
    Catppuccin.catppuccin-vsc
    vscode-icons-team.vscode-icons
    usernamehw.errorlens
    aaron-bond.better-comments
    gruntfuggly.todo-tree
    oderwat.indent-rainbow
    mechatroner.rainbow-csv
    christian-kohler.path-intellisense
    shardulm94.trailing-spaces
)

for ext in "${extensions[@]}"; do
    echo "[*] Installing $ext..."
    code --install-extension "$ext" --force
done

echo "[+] Done. Restart VSCode to apply."
```

---

## GitHub Copilot (Optional)

If you add GitHub Copilot (`github.copilot`), set these overrides to keep it useful without being intrusive in shell scripts where hallucinated paths are dangerous:

```json
"github.copilot.enable": {
    "*": true,
    "shellscript": false,
    "markdown": true,
    "python": true,
    "go": true
}
```

Disabling for `shellscript` prevents Copilot from suggesting paths like `~/pentest/` or old tool names that would silently break on Huginn.

---

*Document version: 1.0 — Maverick Security LLC / Huginn*
