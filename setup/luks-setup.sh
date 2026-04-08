#!/usr/bin/env bash
# ============================================================
#  luks-setup.sh — Huginn Encrypted Drive Setup
#  Maverick Security LLC — Reinhard Persona
#
#  Sets up LUKS2 full-disk encryption on a secondary drive
#  for secure ops storage (client data, evidence, private vault)
#
#  Usage: ./luks-setup.sh [--setup|--header-backup|--add-keyfile|--status]
#
#    --setup          Format and encrypt /dev/sdb (interactive, destructive)
#    --header-backup  Back up the LUKS header to ~/huginn-luks-header.bin
#    --add-keyfile    Add a USB key file as second unlock factor
#    --status         Show current drive and mount status
# ============================================================

set -euo pipefail

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
DRIVE="/dev/sdb"
MAPPER_NAME="ops_secure"
MOUNT_POINT="/mnt/ops-secure"
HEADER_BACKUP="$HOME/huginn-luks-header.bin"

# ── Preflight ─────────────────────────────────────────────────
require_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This operation requires root. Run with sudo."
        exit 1
    fi
}

check_deps() {
    for cmd in cryptsetup lsblk mkfs.ext4; do
        if ! command -v "$cmd" &>/dev/null; then
            error "Required command not found: $cmd"
            error "Install with: sudo apt-get install -y cryptsetup e2fsprogs"
            exit 1
        fi
    done
}

# ── Status ────────────────────────────────────────────────────
cmd_status() {
    section "Drive & Mount Status"

    info "Block devices:"
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL 2>/dev/null

    echo ""
    info "LUKS mapper status ($MAPPER_NAME):"
    if cryptsetup status "$MAPPER_NAME" 2>/dev/null; then
        success "ops_secure is OPEN"
    else
        warn "ops_secure is CLOSED (not mounted)"
    fi

    echo ""
    info "Mount point ($MOUNT_POINT):"
    if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        df -h "$MOUNT_POINT"
        success "$MOUNT_POINT is mounted"
    else
        warn "$MOUNT_POINT is not mounted"
    fi
}

# ── Setup ─────────────────────────────────────────────────────
cmd_setup() {
    require_root
    check_deps
    section "LUKS2 Encrypted Drive Setup"

    # Confirm drive selection
    echo ""
    warn "Target drive: $DRIVE"
    warn "ALL DATA ON $DRIVE WILL BE PERMANENTLY DESTROYED."
    echo ""
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT "$DRIVE" 2>/dev/null || \
        { error "$DRIVE not found. Check with: lsblk"; exit 1; }

    echo ""
    read -rp "  Type 'DESTROY' to confirm you want to wipe $DRIVE: " confirm
    [[ "$confirm" != "DESTROY" ]] && { info "Aborted."; exit 0; }

    # Optional: overwrite with random data first
    echo ""
    read -rp "  Pre-fill drive with random data? (slow, ~30min per 500GB) [y/N]: " prewipe
    if [[ "${prewipe,,}" == "y" ]]; then
        info "Overwriting $DRIVE with random data (this will take a while)..."
        dd if=/dev/urandom of="$DRIVE" bs=4M status=progress 2>&1 || true
        success "Pre-wipe complete"
    fi

    # Format with LUKS2
    section "Formatting with LUKS2"
    info "Parameters: AES-256-XTS / SHA-512 / Argon2id PBKDF"
    cryptsetup luksFormat \
        --type luks2 \
        --cipher aes-xts-plain64 \
        --key-size 512 \
        --hash sha512 \
        --pbkdf argon2id \
        --verbose \
        "$DRIVE"
    success "LUKS2 format complete"

    # Open the encrypted drive
    section "Opening Encrypted Drive"
    cryptsetup open "$DRIVE" "$MAPPER_NAME"
    success "Drive opened at /dev/mapper/$MAPPER_NAME"

    # Create ext4 filesystem
    section "Creating Filesystem"
    mkfs.ext4 -L "ops-secure" /dev/mapper/"$MAPPER_NAME"
    success "ext4 filesystem created (label: ops-secure)"

    # Mount and set ownership
    section "Mounting"
    mkdir -p "$MOUNT_POINT"
    mount /dev/mapper/"$MAPPER_NAME" "$MOUNT_POINT"
    chown "$SUDO_USER":"$SUDO_USER" "$MOUNT_POINT"
    chmod 700 "$MOUNT_POINT"
    success "Mounted at $MOUNT_POINT"

    # Header backup
    section "LUKS Header Backup"
    warn "CRITICAL: If the LUKS header is damaged, all data is permanently unrecoverable."
    cryptsetup luksHeaderBackup "$DRIVE" --header-backup-file "$HEADER_BACKUP"
    chmod 400 "$HEADER_BACKUP"
    success "Header backed up to: $HEADER_BACKUP"
    warn "Copy this file to an offline location (USB, another machine) immediately."

    # Summary
    echo ""
    success "══════════════════════════════════════════"
    success "  ops-secure drive ready at $MOUNT_POINT"
    success "  LUKS header: $HEADER_BACKUP"
    success "  Mount:  sec-mount (alias in .zshrc)"
    success "  Lock:   sec-lock  (alias in .zshrc)"
    success "══════════════════════════════════════════"
    echo ""
    info "Suggested directory structure on the encrypted drive:"
    cat << 'STRUCT'
  /mnt/ops-secure/
  ├── ops/              ← symlink target for ~/ops
  ├── ops-private/      ← symlink target for ~/vaults/ops-private
  ├── evidence/         ← engagement screenshots and artifacts
  └── keys/             ← SSH keys, GPG keys, VPN configs
STRUCT

    echo ""
    info "Run after reboot to move ops directories:"
    echo "  mv ~/ops /mnt/ops-secure/ops && ln -s /mnt/ops-secure/ops ~/ops"
    echo "  mv ~/vaults/ops-private /mnt/ops-secure/ops-private && ln -s /mnt/ops-secure/ops-private ~/vaults/ops-private"
}

# ── Header Backup ─────────────────────────────────────────────
cmd_header_backup() {
    require_root
    section "LUKS Header Backup"

    if [[ ! -b "$DRIVE" ]]; then
        error "$DRIVE not found."
        exit 1
    fi

    cryptsetup luksHeaderBackup "$DRIVE" --header-backup-file "$HEADER_BACKUP"
    chmod 400 "$HEADER_BACKUP"
    success "Header backed up: $HEADER_BACKUP"
    warn "Store this file offline (USB, separate machine). Without it, data is unrecoverable."
}

# ── Add Key File ───────────────────────────────────────────────
cmd_add_keyfile() {
    require_root
    section "Add USB Key File (Two-Factor Unlock)"

    read -rp "  Path to USB key file (e.g. /media/usb/reinhard.key): " KEYFILE_PATH

    if [[ -z "$KEYFILE_PATH" ]]; then
        error "No path provided. Aborted."
        exit 1
    fi

    if [[ ! -f "$KEYFILE_PATH" ]]; then
        read -rp "  Key file not found. Generate a new 4KB key file at that path? [y/N]: " gen
        if [[ "${gen,,}" == "y" ]]; then
            mkdir -p "$(dirname "$KEYFILE_PATH")"
            dd if=/dev/urandom of="$KEYFILE_PATH" bs=4096 count=1
            chmod 400 "$KEYFILE_PATH"
            success "Key file generated: $KEYFILE_PATH"
        else
            info "Aborted."
            exit 0
        fi
    fi

    info "Adding key file to LUKS keyslot on $DRIVE..."
    info "You will be prompted for your existing passphrase to authorize the change."
    cryptsetup luksAddKey "$DRIVE" "$KEYFILE_PATH"
    success "Key file added. Drive can now be unlocked with passphrase OR key file."
    warn "Keep the USB key file safe — losing it doesn't lock you out (passphrase still works)."
}

# ── Usage ─────────────────────────────────────────────────────
usage() {
    echo ""
    echo -e "${BOLD}Usage:${RESET} sudo ./luks-setup.sh [OPTION]"
    echo ""
    echo "  --setup           Format and encrypt $DRIVE (destructive)"
    echo "  --header-backup   Back up LUKS header to $HEADER_BACKUP"
    echo "  --add-keyfile     Add USB key file as second unlock factor"
    echo "  --status          Show drive and mount status"
    echo ""
}

# ── Main ──────────────────────────────────────────────────────
case "${1:-}" in
    --setup)         cmd_setup ;;
    --header-backup) cmd_header_backup ;;
    --add-keyfile)   cmd_add_keyfile ;;
    --status)        cmd_status ;;
    --help|-h|"")    usage ;;
    *) error "Unknown option: $1"; usage; exit 1 ;;
esac
