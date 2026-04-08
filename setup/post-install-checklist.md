# Post-Install Checklist — Huginn

Run through this after `./reinhard_setup.sh --init` completes and you've rebooted/re-logged in.

---

## 1 — Shell & Prompt

- [ ] Terminal opens with Powerlevel10k prompt (run `p10k configure` if it didn't auto-run)
- [ ] `echo $SHELL` returns `/usr/bin/zsh`
- [ ] `source ~/.zshrc` runs without errors
- [ ] MesloLGS NF font rendering correctly in Terminator (icons, arrows, separators)
- [ ] `sz` alias works (reloads shell config)

---

## 2 — Core Tools

```bash
# Run verify script first
./reinhard_setup.sh --verify
```

Manual spot-checks:

- [ ] `nmap --version`
- [ ] `gobuster version`
- [ ] `netexec --version` (or `nxc --version`)
- [ ] `impacket-secretsdump --help` *(should resolve from venv PATH)*
- [ ] `python3 -c "import impacket; print(impacket.__version__)"`
- [ ] `bloodhound-python --help`
- [ ] `certipy --help`
- [ ] `evil-winrm --version`
- [ ] `rustscan --version`

---

## 3 — Metasploit

```bash
msfdb status      # should show: connected
msfconsole        # should launch without DB errors
# Inside msfconsole:
# db_status        → should show postgresql connected
# workspace        → should show default workspace
```

- [ ] `msfdb status` shows connected
- [ ] `msfconsole` launches cleanly
- [ ] No "database not connected" warnings on launch

---

## 4 — Burp Suite

```bash
burpsuite &       # should launch GUI
```

- [ ] Burp Suite Community launches
- [ ] CA certificate exported and installed in browser:
  - Burp → Proxy → Options → Import/Export CA Certificate → Export DER
  - Firefox: Settings → Privacy & Security → Certificates → Import
- [ ] Proxy listener active on `127.0.0.1:8080`
- [ ] FoxyProxy or browser proxy set to `127.0.0.1:8080`

---

## 5 — Docker

```bash
docker --version
docker run hello-world     # confirms daemon running and group membership
docker compose version
```

- [ ] `docker --version` returns version
- [ ] `docker run hello-world` succeeds (no sudo required)
- [ ] Docker daemon enabled: `sudo systemctl is-enabled docker`

---

## 6 — Wireshark

```bash
wireshark &       # should open without permission errors
```

- [ ] Wireshark opens without "permission denied" on capture interfaces
- [ ] `groups` output includes `wireshark`
- [ ] Can start a capture on eth0/wlan0 without sudo

---

## 7 — BloodHound CE

```bash
hound_ce          # starts via Docker Compose
# Then: http://localhost:8080
```

- [ ] `hound_ce` alias starts containers without errors
- [ ] BloodHound CE accessible at `http://localhost:8080`
- [ ] Default credentials set on first login (admin / *set on first run*)

---

## 8 — Obsidian

```bash
./setup/obsidian-setup.sh     # if not already run
```

- [ ] Obsidian opens with `~/huginn` as the training vault
- [ ] Obsidian Git plugin installed and enabled
- [ ] `Ctrl+T` inserts a template (Engagement-Kickoff, Recon-Enumeration, etc.)
- [ ] `Ctrl+P` → "Obsidian Git: Pull" succeeds
- [ ] ops-private vault accessible at `~/vaults/ops-private`

---

## 9 — Encrypted Drive

```bash
sudo ./setup/luks-setup.sh --status
sec-mount          # after running luks-setup.sh --setup
```

- [ ] `luks-setup.sh --setup` completed (or drive already configured)
- [ ] `sec-mount` mounts `/mnt/ops-secure` successfully
- [ ] `sec-lock` cleanly unmounts and closes
- [ ] LUKS header backup exists: `~/huginn-luks-header.bin`
- [ ] Header backup copied to offline storage (USB / second machine)
- [ ] `~/ops` and `~/vaults/ops-private` symlinked to `/mnt/ops-secure/`

---

## 10 — Screen Lock

```bash
lock              # should immediately lock screen
# Then log back in and verify:
xautolock -disable   # temporarily disable for testing
xautolock -enable
```

- [ ] `lock` alias locks the screen
- [ ] Auto-lock fires after 10 minutes of inactivity
- [ ] `~/.config/autostart/xautolock.desktop` exists

---

## 11 — VPN

```bash
thm_vpn           # connect to TryHackMe VPN
ip                # verify tun0 interface exists
vpn_killswitch    # test kill switch (run before connecting VPN)
vpn_killswitch_off
```

- [ ] `thm_vpn` connects and `tun0` interface appears
- [ ] `vpn_killswitch` / `vpn_killswitch_off` run without errors
- [ ] OpenVPN configs stored under `~/ops/vpn/`

---

## 12 — Security Hardening

```bash
sudo ufw status verbose       # should show active with rules
sudo fail2ban-client status   # should show active jails
sudo apparmor_status          # should show profiles loaded
```

- [ ] UFW active: `sudo ufw status verbose`
- [ ] Fail2Ban running: `sudo fail2ban-client status`
- [ ] AppArmor loaded: `sudo apparmor_status`
- [ ] sysctl hardening applied: `sysctl kernel.randomize_va_space` → `2`

---

## 13 — Git & Repo

```bash
cd ~/huginn
git status        # should be clean, up to date
git log --oneline -3
```

- [ ] `git config user.email` returns `tylermaverickhiggins@gmail.com`
- [ ] `git config user.name` returns `reinhard0x`
- [ ] `gh auth status` shows authenticated
- [ ] Pre-commit hook installed: `ls .git/hooks/pre-commit`
- [ ] Test hook: `echo "THM{test_flag}" > /tmp/test.txt && git add /tmp/test.txt` should be blocked

---

## 14 — Ops Workflow Smoke Test

```bash
newop test-engagement
ls ~/ops/test-engagement/
```

- [ ] `newop` creates directory structure: `recon/ enum/ exploit/ loot/ notes/ evidence/`
- [ ] `cd ~/ops` alias works
- [ ] `serve 8000` starts HTTP server on port 8000
- [ ] `listen 4444` starts netcat listener on port 4444 (`Ctrl+C` to exit)

---

## Sign-Off

| Check | Passed | Notes |
|---|---|---|
| Shell & Prompt | | |
| Core Tools | | |
| Metasploit | | |
| Burp Suite | | |
| Docker | | |
| Wireshark | | |
| BloodHound CE | | |
| Obsidian | | |
| Encrypted Drive | | |
| Screen Lock | | |
| VPN | | |
| Hardening | | |
| Git & Repo | | |
| Ops Workflow | | |

**Date completed**: ________________  
**Huginn build version**: `./reinhard_setup.sh --version` *(or last git tag)*
