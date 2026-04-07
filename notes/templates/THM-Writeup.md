---
date: {{date}}
type: thm-writeup
room: 
room_url: 
difficulty: 
category: 
completed: false
tags: [thm, writeup]
---

# THM — {{title}}

## Room Info
| Field | Value |
|---|---|
| **URL** | [Room Name](https://tryhackme.com/room/) |
| **Difficulty** | Easy / Medium / Hard / Insane |
| **Category** | CTF / Learning / Red Team / Blue Team / Other |
| **Est. Time** | |
| **Completed** | |

---

## Task Breakdown
| Task | Points | Notes |
|---|---|---|
| | | |

---

## Recon

### Nmap
```bash
nmap -sV -sC -p- --min-rate 5000 -oA nmap/<roomname> <IP>
```

**Open Ports:**
| Port | Service | Version | Notes |
|---|---|---|---|
| | | | |

---

## Enumeration

### Web
```bash
gobuster dir -u http://<IP>/ -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -x php,html,txt
```

**Findings:**
- 

### Other Services
(SMB, FTP, SSH, etc.)

```bash

```

**Findings:**
- 

---

## Foothold / Exploitation

**Vulnerability / Path:**  

```bash
# Command(s) used

```

**Result:**
- [ ] Shell obtained
- [ ] Shell type: 

---

## Privilege Escalation

### Enumeration
```bash
# linpeas / winpeas
curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | sh

# manual checks
id && whoami
sudo -l
find / -perm -4000 2>/dev/null
```

**Findings:**
- 

### PrivEsc Path
```bash

```

**Result:**
- [ ] Root / SYSTEM obtained

---

## Flags
| Flag | Value |
|---|---|
| **User** | |
| **Root** | |
| **Other** | |

---

## Rabbit Holes
(What looked promising but didn't pan out — useful for future reference)
- 

---

## Lessons Learned
- 
- 

---

## Tools Used
| Tool | Purpose |
|---|---|
| nmap | Port scan |
| | |

---

## Related Resources
- 
