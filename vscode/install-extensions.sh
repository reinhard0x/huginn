#!/usr/bin/env bash
# Install Reinhard VSCode extensions
# Run once on Huginn: bash vscode/install-extensions.sh

set -euo pipefail

if ! command -v code &>/dev/null; then
    echo "[-] VSCode (code) not found in PATH. Is it installed?"
    exit 1
fi

extensions=(
    # Version Control
    eamodio.gitlens
    github.vscode-pull-request-github
    # Python
    ms-python.python
    ms-python.vscode-pylance
    ms-python.black-formatter
    # Go
    golang.go
    # PowerShell
    ms-vscode.powershell
    # Shell
    mads-hartmann.bash-ide-vscode
    timonwong.shellcheck
    foxundermoon.shell-format
    # Documentation
    yzhang.markdown-all-in-one
    yzane.markdown-pdf
    redhat.vscode-yaml
    # Security / Pentest
    ms-vscode.hexeditor
    humao.rest-client
    # Remote
    ms-vscode-remote.remote-ssh
    ms-vscode-remote.remote-explorer
    ms-azuretools.vscode-docker
    # Theme & UI
    sainnhe.gruvbox-material
    vscode-icons-team.vscode-icons
    usernamehw.errorlens
    aaron-bond.better-comments
    gruntfuggly.todo-tree
    oderwat.indent-rainbow
    mechatroner.rainbow-csv
    christian-kohler.path-intellisense
    shardulm94.trailing-spaces
)

echo "[*] Installing ${#extensions[@]} VSCode extensions..."
for ext in "${extensions[@]}"; do
    echo "  -> $ext"
    code --install-extension "$ext" --force 2>/dev/null || \
        echo "  [!] Failed: $ext"
done

echo "[+] Done. Restart VSCode to apply all extensions."
