# Incident Response

Structured methodology for detecting, containing, eradicating, and recovering from security incidents.

## Incident Response Lifecycle (NIST 800-61)

| Phase | What It Involves |
|-------|------------------|
| **Preparation** | Tools, runbooks, training, communication channels |
| **Detection & Analysis** | Triage alerts, determine scope, assess severity |
| **Containment** | Isolate affected systems, stop spread |
| **Eradication** | Remove threat, patch vulnerability, close attacker access |
| **Recovery** | Restore systems, validate integrity, resume operations |
| **Post-Incident** | Document, blameless retro, improve controls |

## Severity Classification

| Severity | Definition | Response Time |
|----------|------------|---------------|
| **P1 (Critical)** | Active breach, data exfiltration, ransomware, complete service compromise | Immediate (< 15 min) |
| **P2 (High)** | Confirmed intrusion, lateral movement detected, significant unauthorized access | < 1 hour |
| **P3 (Medium)** | Suspicious activity, potential vulnerability, phishing credential capture | < 4 hours |
| **P4 (Low)** | Failed attack attempts, policy violations, non-critical anomalies | < 24 hours |

## First Response Checklist

When an alert fires or an incident is suspected:

**Step 1: Verify the alert**
- Is it a true positive? (systematic noise vs. real attack)
- Can you reproduce it?
- What systems/users are affected?

**Step 2: Preserve evidence**
```bash
# Stop any ongoing processes that might overwrite evidence
# Do NOT power down (volatile memory contains critical forensic data)

# Capture memory if system is live
# Linux: crashdump = /proc/kcore
# Windows: winpmem (AV-fee kernel-mode driver)

# Screenshot any anomalous UI or tool output
# Log timestamps: when did it start? what changed?

# For endpoints:
# - Full disk image (dd or DCFLDD)
# - Memory acquisition (LiME for Linux, winpmem for Windows)
# - Network captures (tcpdump before it's gone)
```

**Step 3: Notify the team**
- Open incident ticket with: title, severity, affected systems, observed IOCs
- Page on-call if P1/P2
- Establish a bridge (Slack/Teams dedicated channel)
- Assign roles: lead investigator, documentation, communications

**Step 4: Contain**
- Isolate affected host(s) from network (not power off)
- Block malicious IPs/domains at firewall
- Revoke compromised credentials immediately
- For ransomware: disconnect backups from network

## Common Attack Signatures

### Confirmed Intrusion Indicators (IOCs)

```bash
# Unusual processes
ps aux | grep -E 'nc|ncat|bash -i|/dev/tcp|wget|curl.*exec'
# Check for: cron jobs you didn't create, SSH keys in unexpected places
crontab -l
cat /etc/crontab
ls -la /etc/cron.d/

# Unusual network
# Linux:
ss -tulpn | grep ESTABLISHED
netstat -antp

# Persistence mechanisms
# Linux: systemd services, cron, SSH keys, init scripts
# Windows: registry run keys, scheduled tasks, services
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Run
reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Run
schtasks /query /fo LIST /v

# Privilege escalation artifacts
# Check: sudoers modifications, new sudo access, suid binaries
find / -perm -4000 -type f 2>/dev/null
ls -la /etc/sudoers.d/
```

### Ransomware Signatures

```
Early indicators:
- High CPU/disk activity on file servers
- Cryptographic operations observed ( Ransom note files: README.txt, DECRYPT_INSTRUCTIONS.html)
- Unusual SMB connections between workstations
- Shadow copy deletion (vssadmin delete shadows /all /quiet)
- Backup deletion (wbadmin delete catalog -quiet)

Files that signal ransomware:
- .encrypted, .locked, .crypto, .crypt
- README.TXT, DECRYPT_INSTRUCTIONS.html
- ransom note filenames ending in .html
```

### Web Shell Detection

```bash
# Web shells often hide in upload directories
find /var/www -name "*.php" -exec grep -l "eval|base64_decode|system(" {} \;

# Check for suspicious patterns in access logs
# Common web shell URIs:
grep -E "(\?cmd=|\?shell=|\?exec=|wp-content/uploads.*\.php)" /var/log/apache2/access.log

# IOC pattern:
# POST to a file that was never linked from the application
# Large response bodies from small POST requests
```

## Forensics Collection Order

**Order of volatility (capture most volatile first):**
1. CPU registers, cache
2. RAM (live system)
3. Network connections, open ports
4. Running processes
5. Disk (can be captured later)
6. Logs (remote syslog is best, local logs second)
7. Backups, archives

**What to collect per system:**
- Memory image
- Disk image (full or forensic copy)
- All logs (auth, system, application)
- Network captures (if available)
- List of running processes + parent/child tree
- User sessions (logged in users, SSH sessions)
- Registry hives (Windows)
- Bash history, command history
- Mounted devices, network shares

## Containment Playbook

**Network-level:**
```bash
# Block IPs at firewall (iptables)
iptables -A INPUT -s <malicious-ip> -j DROP
iptables -A OUTPUT -d <malicious-ip> -j DROP

# Block domains in /etc/hosts
echo "0.0.0.0 malicious-domain.com" >> /etc/hosts

# For cloud environments: update security groups/NACLs
# AWS: revoke security group ingress from attacker IP
```

**Credential-level:**
```bash
# Force password reset for compromised accounts
# Azure AD:
# Get-AzureADUser -SearchString "john" | Set-AzureADUserPassword -ForceChangePasswordNextSignIn $true

# Invalidate all sessions for a user
# Auth0: mgmt.api.create_domainwide_blacklist_session_token()
# Okta: via Admin console → Session timeout

# Revoke API keys/tokens
# GitHub: Settings → Developer settings → Personal access tokens (revoke all suspicious)
# AWS: aws iam delete-access-key --access-key-id <AKID>
```

**System-level:**
```bash
# Linux: isolate without shutdown
ip link set eth0 down  # physical
# or:
iptables -A INPUT -s <attacker-ip> -j DROP

# Windows: disable network on affected host via vSphere/Hyper-V console
# Or: netsh interface set interface "Ethernet0" disable

# For malware that spreads via SMB:
# Disconnect shares: net use * /delete /y
# Block ports 139, 445 at perimeter firewall
```

## Eradication

After containment, remove the threat:

1. **Identify patient zero** — which system/user was the entry point
2. **Remove attacker footholds**:
   - Kill malicious processes
   - Remove scheduled tasks / cron jobs created by attacker
   - Delete persistence mechanisms (services, registry keys)
   - Remove web shells and attacker uploaded files
3. **Patch the exploited vulnerability** — the initial access vector
4. **Reset all potentially compromised credentials** (users who had active sessions at time of breach)
5. **Scan for backdoors** — check for SSH keys attacker added, new users, rootkits

## Recovery

**Validate system integrity before bringing back online:**

```bash
# Linux: check for rootkits
rkhunter --check
lynis audit system

# Windows:
# Run Malwarebytes Antimalware in addition to existing AV
# Check for unauthorized admin accounts
net localgroup administrators

# Verify file integrity (hash known-good files)
sha256sum /bin/ls /bin/bash | diff <(cat known_good_hashes.txt)

# Validate configurations (not modified by attacker)
# Compare current iptables rules against baseline
iptables-save > current_rules.txt
diff baseline_rules.txt current_rules.txt
```

**Phased restoration:**
1. Rebuild critical systems from known-good backups (do not restore from compromised state)
2. Patch the initial vulnerability before reconnecting
3. Bring back one system at a time; monitor for reinfection
4. Validate with internal scans before declaring clean

## Post-Incident Review

After the incident is closed, conduct a blameless post-mortem:

**Document:**
- Timeline (initial access → detection → containment → eradication → recovery)
- What worked, what didn't
- Gaps in monitoring/controls
- Root cause (how did they get in?)
- IOCs (what artifacts remain?)

**Questions to answer:**
1. How did the attacker gain initial access?
2. What was the dwell time (time from initial access to detection)?
3. What systems/data were affected?
4. Did existing controls detect/prevent it? If not, why?
5. What would prevent this from happening again?

**Update runbooks and detection rules based on findings.**

## Tools Used During IR

| Tool | Purpose |
|------|---------|
| Volatility (memory forensics) | Analyze RAM dumps |
| Autopsy / Sleuth Kit | Disk image analysis, file carvin |
| FTK Imager | Forensic disk imaging |
| Wireshark / tshark | Network packet analysis |
| YARA | Malware signature identification |
| GRR Rapid Response | Remote incident response |
| Velociraptor | Endpoint visibility and collection |
| MISP | Threat intel sharing |

## IR Contact Template

```
INCIDENT REPORT

ID: INC-2025-XXXX
Title: [Brief description]
Severity: P1/P2/P3/P4
Status: [Open/Investigating/Contained/Eradicated/Resolved]
Reported By: [Name]
Detected: [datetime]
Affected Systems: [list]
Initial Access Vector: [if known]

Timeline:
- YYYY-MM-DD HH:MM — [event]
- YYYY-MM-DD HH:MM — [event]

IOCs:
- IP: [list]
- Domains: [list]
- File hashes: [list]

Actions Taken:
1. [action]
2. [action]

Pending:
- [action item]
- [action item]
```