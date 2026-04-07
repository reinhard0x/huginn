---
date: {{date}}
type: recon
engagement: 
target: 
tags: [recon, enumeration]
---

# Recon — {{title}}

## Target Summary
| Field | Value |
|---|---|
| **Target** | |
| **IP Range** | |
| **Domain** | |
| **OS / Platform** | |
| **Engagement** | |

---

## OSINT

### Domains & Subdomains
```
# amass
amass enum -passive -d <domain>

# subfinder
subfinder -d <domain>

# crt.sh
curl -s "https://crt.sh/?q=%.<domain>&output=json" | jq '.[].name_value' | sort -u
```

**Results:**
- 

### DNS Records
```
dig <domain> ANY
dig <domain> MX
dig <domain> TXT
nslookup -type=ns <domain>
```

**Results:**
- 

### WHOIS / Org Info
```
whois <domain>
whois <IP>
```

**Results:**
- 

### Technologies
```
whatweb <url>
wafw00f <url>
```

**Results:**
- 

### Breach / Email Recon
- theHarvester: `theHarvester -d <domain> -b all`
- Hunter.io / Dehashed / HaveIBeenPwned manual check

**Results:**
- 

---

## Host Discovery

### Ping Sweep
```bash
nmap -sn <CIDR> -oG - | awk '/Up$/{print $2}'
```

**Live Hosts:**
| IP | Hostname | Notes |
|---|---|---|
| | | |

---

## Port Scanning

### Quick TCP (Top 1000)
```bash
nmap -sV -sC -oA recon/quick <IP>
```

### Full Port Scan
```bash
nmap -p- --min-rate 5000 -oA recon/allports <IP>
```

### Targeted Service Scan
```bash
nmap -p <ports> -sV -sC -O --script=vuln -oA recon/targeted <IP>
```

### UDP (Top 100)
```bash
nmap -sU --top-ports 100 -oA recon/udp <IP>
```

**Port Summary:**
| IP | Port | Proto | Service | Version | Notes |
|---|---|---|---|---|---|
| | | | | | |

---

## Web Enumeration

### Directory Brute Force
```bash
# Gobuster
gobuster dir -u <url> -w /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-directories.txt -x php,html,txt -o recon/gobuster.txt

# Feroxbuster
feroxbuster -u <url> -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt
```

**Results:**
| URL | Status | Notes |
|---|---|---|
| | | |

### Vhost Discovery
```bash
gobuster vhost -u <url> -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt --append-domain
```

**Results:**
- 

### Tech Stack & Headers
```bash
curl -I <url>
whatweb -a 3 <url>
```

**Results:**
- 

### Interesting Files
- robots.txt: 
- sitemap.xml: 
- .git exposed: 
- Other: 

---

## SMB Enumeration
```bash
nxc smb <IP> -u '' -p '' --shares
nxc smb <IP> -u <user> -p <pass> --shares
enum4linux-ng -A <IP>
```

**Shares:**
| Share | Access | Notes |
|---|---|---|
| | | |

---

## AD Enumeration

### Initial Recon (Unauthenticated)
```bash
nxc smb <IP> --users
nxc smb <IP> --pass-pol
enum4linux-ng -A <DC_IP>
```

### Authenticated Enumeration
```bash
# BloodHound
bloodhound-python -u <user> -p <pass> -d <domain> -dc <DC_IP> -c All --zip

# PowerView (from Windows / Evil-WinRM)
# Get-NetUser | select samaccountname,description
# Get-NetGroup -GroupName "Domain Admins"
# Find-LocalAdminAccess
```

**Users:**
| Username | Groups | Notes |
|---|---|---|
| | | |

**Interesting ACLs / Paths:**
- 

---

## Findings Summary
| Host | Port | Service | Potential Finding | Priority |
|---|---|---|---|---|
| | | | | |

---

## Next Steps
- [ ] 
- [ ] 
- [ ] 

---

## Notes
