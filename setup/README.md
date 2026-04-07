# Setup

## Quick Start

```bash
# Full init (run once on a fresh Kali install)
chmod +x reinhard_setup.sh
./reinhard_setup.sh --init
```

## Flags

| Flag | Description |
|---|---|
| `--init` | Full setup: repos, packages, OMZ, P10k, fonts, venvs, tools, configs, hardening |
| `--update` | Update apt packages and all cloned tools |
| `--harden` | Hardening only (UFW, sysctl, Fail2Ban, AppArmor) |
| `--tools` | Clone / update pentest tools and pipx tools only |
| `--verify` | Verify installation status (30+ checks) |
| `--reset` | Remove ~/tools (with confirmation) |

## After --init

```bash
# Generate your P10k prompt layout
p10k configure

# Install VSCode extensions
bash ../vscode/install-extensions.sh
```
