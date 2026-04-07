# Huginn

> *Huginn and Muninn fly each day over the spacious earth. I fear for Huginn, that he come not back, yet more anxious am I for Muninn.*  
> — Grímnismál, Stanza 20

**System**: Huginn — Primary offensive workstation (Kali Linux)  
**Companion**: Muninn — Mobile / field system  
**Persona**: Reinhard — Maverick Security LLC  
**Location**: Eirdom Office, Austin, Minnesota

---

## What This Repo Contains

| Directory | Contents |
|---|---|
| `dotfiles/` | Shell config (`.zshrc`), Terminator profile, P10k config |
| `setup/` | `reinhard_setup.sh` and `install_list.txt` — full system bootstrap |
| `docs/` | Deployment & hardening guide, VSCode customization reference |
| `vscode/` | `settings.json`, `extensions.json`, `keybindings.json`, install script |
| `.vscode/` | Workspace-level VSCode settings for this repo |
| `ops/` | Placeholder — never commit real operational data here |

---

## Quick Start — Fresh Kali Install

```bash
# 1. Clone this repo
git clone git@github.com:tyler-maverick-higgins/huginn.git ~/huginn
cd ~/huginn

# 2. Run full setup (installs packages, OMZ, P10k, tools, configs, hardens system)
chmod +x setup/reinhard_setup.sh
./setup/reinhard_setup.sh --init

# 3. Configure Powerlevel10k prompt
p10k configure

# 4. Install VSCode extensions
bash vscode/install-extensions.sh
```

---

## Handles

| Context | Handle |
|---|---|
| Professional | Reinhard |
| CTF / Bug Bounty | r3inhard |
| GitHub | tyler-maverick-higgins |

---

## Tools Philosophy

- Tools that are archived, stale (3yr+), or superseded are removed — see `setup/reinhard_setup.sh` for the current active list
- Python tools run in isolated venvs under `~/.venvs/`
- pipx manages CLI tools (NetExec, Certipy) to avoid dependency conflicts
- neo4j is installed from its own apt repository — not from Kali's default packages

---

*Maverick Security LLC — Maritime Cybersecurity*
