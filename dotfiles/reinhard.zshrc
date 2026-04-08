# ============================================================
# reinhard.zshrc — Huginn Shell Configuration
# Persona: Reinhard — Maverick Security LLC
# System: Huginn (Kali Linux — primary offensive workstation)
# Managed: ~/dotfiles/.zshrc → ~/.zshrc
# ============================================================

# === Powerlevel10k Instant Prompt ===
# MUST stay near the top. Everything above this must be non-interactive.
# Initialization code requiring console input (passwords, y/n prompts)
# must go ABOVE this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================================
# ENVIRONMENT & PATH
# ============================================================

# Core directories
export TOOLS_DIR="$HOME/tools"
export VENV_DIR="$HOME/.venvs"
export OPS_DIR="$HOME/ops"
export THM="$HOME/ops/tryhackme"
export ZSH="$HOME/.oh-my-zsh"
export PROJECT_HOME="$HOME/codeprojects/projects"
export VSCODE=code

# Gobuster file extension list
export FTYPES="php,sh,txt,cgi,html,js,css,py"

# Target variables — update per engagement
export IP=""       # Target machine IP
export PORT=80     # Target port
export TUN0=""     # VPN tunnel IP (fill after openvpn connects)

# PATH — order matters; personal bins take priority
export PATH="\
$HOME/bin:\
/usr/local/bin:\
$HOME/.local/bin:\
$TOOLS_DIR:\
$VENV_DIR/impacket/bin:\
/usr/local/go/bin:\
$PATH"

# RVM (append at end per rvm requirements)
[[ -d "$HOME/.rvm/bin" ]] && export PATH="$PATH:$HOME/.rvm/bin"

# ============================================================
# OH MY ZSH
# ============================================================

ZSH_THEME="powerlevel10k/powerlevel10k"

# Behavior
HYPHEN_INSENSITIVE="true"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="mm/dd/yyyy"

# Plugins
# NOTE: zsh-syntax-highlighting MUST be last or near-last
plugins=(
    git
    colored-man-pages
    zsh-autosuggestions
    zsh-completions
    history-substring-search
    sudo
    command-not-found
    vscode
    docker
    golang
    python
    zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# Docker completion stacking
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes

# ============================================================
# POWERLEVEL10K
# ============================================================
# Prompt is fully managed by p10k — do NOT set PS1/PROMPT/RPROMPT here.
# Run `p10k configure` to generate/regenerate ~/.p10k.zsh.
# POWERLEVEL10K_MODE belongs in .p10k.zsh, not here.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ============================================================
# FUNCTIONS — System
# ============================================================

# Reload shell config
function reload {
    source ~/.zshrc
}

# Full system upgrade and reboot
function update {
    sudo apt update &&
    sudo apt dist-upgrade -Vy &&
    sudo apt autoremove -y &&
    sudo apt autoclean &&
    sudo apt clean &&
    sudo reboot
}

# ============================================================
# FUNCTIONS — Operations
# ============================================================

# Create a new operation workspace
# Usage: newop <operation-name>
function newop {
    local name="${1:?Usage: newop <operation-name>}"
    local dir="$OPS_DIR/$name"
    mkdir -p "$dir"/{recon,loot,exploits,notes,screenshots,deliverables}
    echo "# Operation: $name\n\n## Target\n\n## Scope\n\n## Notes" > "$dir/notes/README.md"
    echo "[*] Operation workspace created: $dir"
    cd "$dir"
}

# Quick HTTP server (default: 8000)
# Usage: serve [port]
function serve {
    local port="${1:-8000}"
    echo "[*] Serving on http://0.0.0.0:$port"
    sudo python3 -m http.server "$port"
}

# Listen for reverse shell connection
# Usage: listen <port>
function listen {
    local port="${1:?Usage: listen <port>}"
    echo "[*] Listening on 0.0.0.0:$port..."
    sudo ncat -lvnp "$port"
}

# Print shell stabilization steps for dumb shells
function stabilize {
    echo "[*] Shell stabilization — run in order:"
    echo "    1.  python3 -c 'import pty; pty.spawn(\"/bin/bash\")'"
    echo "    2.  Ctrl+Z"
    echo "    3.  stty raw -echo; fg"
    echo "    4.  export TERM=xterm"
    echo "    5.  stty rows 50 cols 200   # match your terminal"
}

# Borg backup — excludes caches, venvs, and tool repos
function borg_backup {
    local repo="${BORG_REPO:-$HOME/backups/borg}"
    local name="huginn-$(date +%Y%m%d-%H%M)"
    echo "[*] Creating Borg archive: $repo::$name"
    borg create --stats --progress --compression lz4 \
        "$repo::$name" \
        "$HOME" \
        --exclude "$HOME/.cache" \
        --exclude "$HOME/.venvs" \
        --exclude "$HOME/tools" \
        --exclude "$HOME/.oh-my-zsh" \
        --exclude "$HOME/.local/share/Trash"
}

# ============================================================
# FUNCTIONS — Offensive Tools
# ============================================================

# Start BloodHound CE via Docker Compose
function hound_ce {
    echo "[*] Starting BloodHound CE..."
    sudo docker compose -f "$TOOLS_DIR/BloodHound/docker-compose.yml" up -d
    echo "[*] Interface: http://localhost:8080"
    echo "[*] Default user: admin  (set password on first run)"
}

# Legacy BloodHound (neo4j + binary) — kept for compatibility
function hound {
    sudo neo4j start
    sleep 10s
    bloodhound
    sudo neo4j stop
}

# Start Metasploit with database
function msf {
    msfdb start
    sleep 5s
    msfconsole
}

# Start Nessus scanner service
function nessus {
    sudo /bin/systemctl start nessusd.service
    echo "[*] Nessus started — https://localhost:8834"
}

# Connect to TryHackMe VPN
function thm_vpn {
    echo "[*] Connecting to TryHackMe..."
    sudo openvpn "$HOME/ops/vpn/tryhackme.ovpn"
}

# Start PowerShell Empire REST server
function empire {
    sudo powershell-empire --rest &
}

# Launch Starkiller (Empire GUI)
function starkiller {
    sudo starkiller --no-sandbox
}

# ============================================================
# FUNCTIONS — Reporting
# ============================================================

# Render a THM/HTB room README.md to PDF via pandoc
# Usage: writeup [path/to/README.md] [output.pdf]
function writeup {
    local src="${1:-$PWD/README.md}"
    local out="${2:-$HOME/ops/writeups/$(basename $(dirname $src)).pdf}"
    pandoc -V geometry:'top=2cm, bottom=1.5cm, left=2cm, right=2cm' \
        --highlight-style zenburn \
        "$src" -s -o "$out"
    echo "[+] Written to: $out"
}

# Backup home directory to tarball
function backup {
    cd ~/
    tar -cvzf "huginn-backup-$(date +%Y%m%d).tar.gz" \
        Desktop Documents Downloads Music Pictures Public Templates Videos ops
}

# ============================================================
# FUNCTIONS — Security
# ============================================================

# VPN kill switch — locks all traffic through tun0 before connecting
# Usage: vpn_killswitch [interface]  (default: tun0)
function vpn_killswitch {
    local VPN_IFACE="${1:-tun0}"
    sudo iptables -F
    sudo iptables -P INPUT   DROP
    sudo iptables -P FORWARD DROP
    sudo iptables -P OUTPUT  DROP
    # Loopback
    sudo iptables -A INPUT  -i lo -j ACCEPT
    sudo iptables -A OUTPUT -o lo -j ACCEPT
    # Established/related
    sudo iptables -A INPUT  -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    sudo iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    # VPN tunnel traffic
    sudo iptables -A INPUT  -i "$VPN_IFACE" -j ACCEPT
    sudo iptables -A OUTPUT -o "$VPN_IFACE" -j ACCEPT
    # Allow outbound VPN connection (UDP 1194, TCP 443/1194)
    sudo iptables -A OUTPUT -p udp --dport 1194 -j ACCEPT
    sudo iptables -A OUTPUT -p tcp --dport  443 -j ACCEPT
    sudo iptables -A OUTPUT -p tcp --dport 1194 -j ACCEPT
    echo "[+] Kill switch active — all non-VPN traffic dropped"
    echo "[*] Connect VPN now. Run: vpn_killswitch_off to restore."
}

# Restore normal routing after VPN session
function vpn_killswitch_off {
    sudo iptables -F
    sudo iptables -P INPUT   ACCEPT
    sudo iptables -P FORWARD ACCEPT
    sudo iptables -P OUTPUT  ACCEPT
    echo "[+] Kill switch removed — normal routing restored"
}

# ============================================================
# ALIASES — Navigation
# ============================================================
alias ..="cd .."
alias ...="cd ../.."
alias cd..="cd .."
alias ls='ls -lah --color=auto'
alias grep='grep --color=auto'
alias ip="ip -br -c a"
alias netstat="netstat -tulpn"
alias sz='source ~/.zshrc'

# ============================================================
# ALIASES — System & Python
# ============================================================
alias python='python3'
alias pip='pip3'
alias create='python3 -m venv venv'
alias activate='source venv/bin/activate'
alias sysmon='sudo btop'
alias blank="xclip -sel clip $HOME/.blank"
alias vscode='code'

# ============================================================
# ALIASES — Offensive: Impacket
# (entry points installed via $VENV_DIR/impacket/bin — on PATH)
# ============================================================
alias secretsdump='impacket-secretsdump'
alias smbserver='impacket-smbserver kali .'
alias smbhere='impacket-smbserver kali . -smb2support'
alias psexec='impacket-psexec'
alias wmiexec='impacket-wmiexec'
alias atexec='impacket-atexec'
alias dcomexec='impacket-dcomexec'
alias lookupsid='impacket-lookupsid'
alias getnpusers='impacket-GetNPUsers'
alias getuserspns='impacket-GetUserSPNs'

# ============================================================
# ALIASES — Offensive: NetExec (replaces CrackMapExec)
# ============================================================
alias nxc='netexec'
alias cmx='netexec'

# ============================================================
# ALIASES — Offensive: Enumeration & Recon
# ============================================================
alias enum4linux="$TOOLS_DIR/enum4linux-ng/enum4linux-ng.py"
alias kerbrute="$TOOLS_DIR/kerbrute"
alias ssh2john="python3 /usr/share/john/ssh2john.py"
alias tplmap="python3 $TOOLS_DIR/tplmap/tplmap.py"
alias wesng="python3 $TOOLS_DIR/wesng/wes.py"
alias pspy="$TOOLS_DIR/pspy/pspy64"

# ============================================================
# ALIASES — Offensive: Active Directory
# ============================================================
alias cert='certipy'

# ============================================================
# ALIASES — Offensive: Scanning
# ============================================================
alias nmap='sudo nmap'
alias rustscan="rustscan -n -b 100 -t 5000 --ulimit 5000 -a \$IP"

# ============================================================
# ALIASES — Gobuster Shortcuts
# ============================================================
alias godir="gobuster dir -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -u"
alias govhost="gobuster vhost -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -u"
alias godns="gobuster dns -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -d"

# ============================================================
# ALIASES — tmux
# ============================================================
alias tmux="TERM=screen-256color-bce tmux"
alias tm="tmux new-session"
alias tl="tmux list-sessions"
alias ta="tmux attach -t"

# ============================================================
# ALIASES — HTTP Servers (wrappers around serve())
# ============================================================
alias simple80='serve 80'
alias simple443='serve 443'
alias simple8080='serve 8080'
alias simple8000='serve 8000'

# ============================================================
# ALIASES — Git
# ============================================================
alias gs='git status'
alias gp='git push'
alias gl='git pull'
alias gco='git checkout'
alias startover='git status | grep "modified" | awk "{print \$2}" | xargs -I{} git checkout -- {}'

# ============================================================
# ALIASES — Directories
# ============================================================
alias ops="cd $OPS_DIR"
alias tools="cd $TOOLS_DIR"
alias thm="cd $THM"
alias project="cd $PROJECT_HOME"

# ============================================================
# ALIASES — Secure Drive (LUKS)
# ============================================================
alias sec-mount='sudo cryptsetup open /dev/sdb ops_secure \
    && sudo mount /dev/mapper/ops_secure /mnt/ops-secure \
    && sudo chown $USER:$USER /mnt/ops-secure \
    && echo "[+] ops-secure mounted at /mnt/ops-secure"'
alias sec-lock='sudo umount /mnt/ops-secure 2>/dev/null; \
    sudo cryptsetup close ops_secure \
    && echo "[+] ops-secure locked"'
alias sec-status='sudo cryptsetup status ops_secure 2>/dev/null \
    || echo "[-] ops-secure is not open"'

# ============================================================
# ALIASES — Session Security
# ============================================================
# Lock screen — tries XFCE → i3lock → xscreensaver in order
alias lock='xflock4 2>/dev/null || i3lock -c 0D0D0D 2>/dev/null || xscreensaver-command -lock'

# ============================================================
# ALIASES — Dotfiles & Config Editing
# ============================================================
alias dotfiles="cd ~/dotfiles && git status"
alias editzshrc="code ~/dotfiles/.zshrc"
alias editvimrc="code ~/dotfiles/.vimrc"
alias edittmux="code ~/dotfiles/tmux.config"
alias ohmyzsh="code ~/.oh-my-zsh"
