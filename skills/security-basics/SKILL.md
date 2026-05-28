---
name: security-basics
description: Security best practices, vulnerability prevention, and secure development across web applications, APIs, networks, and embedded systems. Covers input validation, cryptography, OWASP Top 10, AppSec (SAST/DAST), malware analysis, CTF, fuzzing, incident response, IoT security.
tags: [security, web-security, best-practices, hardening]
---

# Security Best Practices and Vulnerability Prevention

## Skill Structure
```
security-basics/
├── SKILL.md                      # This file (core)
├── references/
│   ├── security-practices.md     # Input validation, auth, JWT, sessions, OWASP, logging
│   └── security-ecosystem.md     # SAST/DAST tools, scanning, monitoring, rate limiting
└── resources/                    # Detailed guides (read as needed)
    ├── web-security.md           # CSP, CORS, input/output encoding, SSRF
    ├── appsec.md                 # SAST/DAST, threat modeling (STRIDE), secure code review
    ├── malware.md                # Static/dynamic analysis, YARA, memory forensics
    ├── ctf.md                    # CTF categories, techniques, tools
    ├── fuzzing.md                # AFL++, LibFuzzer, HTTP fuzzing
    ├── incident-response.md      # IR lifecycle, containment, forensics
    └── iot-security.md           # Firmware, MQTT, Zigbee, BLE, secure boot
```

## When to Use
- Implementing authentication (password hashing, JWT, sessions)
- Preventing injection attacks (SQL, XSS, CSRF)
- Setting up security headers, CORS, CSP
- Performing security audits or vulnerability assessments
- Securing APIs with rate limiting, input validation, auth
- Reviewing code for security vulnerabilities

## Do Not Use
- General UI/UX design without security context
- Performance optimization or profiling
- Database schema design or migration
- Deployment or CI/CD configuration

## Quick Reference

### Core Rules
1. **Validate all input** — whitelist validation, server-side always
2. **Hash passwords** — bcrypt (cost 12+) or Argon2id
3. **Parameterized queries** — never concatenate SQL
4. **HTTPS everywhere** — HSTS, valid certs
5. **Security headers** — CSP, X-Frame-Options, X-Content-Type-Options
6. **Least privilege** — deny by default, RBAC/ABAC
7. **Never trust client data** — re-validate on server
8. **Log auth events** — not secrets/PII
9. **Rotate secrets** — env vars or vault, never in code
10. **Keep dependencies updated** — CVE scanning in CI

### Detailed Security Practices
→ See `references/security-practices.md` for:
- Input validation rules, SQL injection prevention
- Environment variables for secrets, HTTPS
- OWASP Top 10 detailed breakdown
- Password hashing (argon2, bcrypt with code)
- JWT security (RS256, short expiry, algorithm whitelist)
- Session management (HttpOnly, Secure, SameSite)
- Zero Trust authorization, secrets management
- Security headers complete reference
- Logging & monitoring (what to log, what not to, alert thresholds)
- Vulnerability assessment checklist

### Security Tools & Ecosystem
→ See `references/security-ecosystem.md` for:
- OWASP Top 10 mitigation tools
- Network scanning (Nmap, RustScan, Nuclei, ZAP)
- SAST tools (Semgrep, SonarQube, CodeQL, Bandit, gosec)
- DAST tools (OWASP ZAP, Burp Suite, Caido)
- Dependency & container scanning (Trivy, Grype, Dependabot)
- Secrets detection (Gitleaks, TruffleHog, git-secrets)
- Container & K8s security (docker-bench, Falco, Kube-bench)
- Auth & identity (bcrypt, Argon2, OAuth2, WebAuthn, TOTP)
- Security monitoring (CrowdSec, Fail2ban, Wazuh)
- API security (rate limiting, input validation, audit logging)

### Specialized Resources

| Resource | What It Covers |
|----------|---------------|
| `resources/web-security.md` | CSP, CORS, input/output encoding, SSRF, rate limiting |
| `resources/appsec.md` | SAST/DAST, threat modeling (STRIDE), secure code review |
| `resources/malware.md` | Static/dynamic analysis, YARA rules, memory forensics |
| `resources/ctf.md` | Jeopardy CTF categories, web/pwn/crypto techniques |
| `resources/fuzzing.md` | AFL++, LibFuzzer, HTTP fuzzing (ffuf), corpus minimization |
| `resources/incident-response.md` | IR lifecycle, triage, containment, forensics |
| `resources/iot-security.md` | Firmware analysis, MQTT/Zigbee/BLE security, secure boot |

## Verification

- [ ] Dependencies scanned for CVEs (Trivy, npm audit, pip audit)
- [ ] Security headers verified (securityheaders.com or curl)
- [ ] Auth endpoints have rate limiting
- [ ] Passwords hashed with bcrypt/argon2 (not SHA/MD5)
- [ ] No secrets in source code (gitleaks scan)
- [ ] CSP configured with appropriate directives
- [ ] CORS restricted to specific origins
- [ ] All reference links resolve to existing files
