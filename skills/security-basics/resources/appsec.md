# Application Security (AppSec)

Systematic approach to securing applications throughout the software development lifecycle — from threat modeling to penetration testing.

## SDLC Security Integration

| Phase | Security Activity |
|-------|-------------------|
| Requirements | Threat modeling, security requirements definition |
| Design | Secure design review, attack surface analysis |
| Development | SAST, secure coding guidelines, dependency scanning |
| Testing | DAST, penetration testing, security regression tests |
| Deployment | Secrets scanning, hardening, CSP/headers verification |
| Maintenance | Vulnerability monitoring, patch management, incident response |

## Threat Modeling (STRIDE / Attack Trees)

Use STRIDE to classify threats:

| Threat | What It Violates | Mitigation |
|--------|-----------------|------------|
| **S**poofing | Authenticity | MFA, certificate pinning, secure sessions |
| **T**ampering | Integrity | Digital signatures, HMAC, integrity checks |
| **R**epudiation | Non-repudiation | Audit logs, digital signatures |
| **I**nformation Disclosure | Confidentiality | Encryption, access controls, data masking |
| **D**enial of Service | Availability | Rate limiting, load balancing, CDN |
| **E**levation of Privilege | Authorization | Least privilege, role-based access |

**Attack Tree Example (Password Reset):**
```
Password Reset Abuse
├── Guessable token
│   ├── Weak RNG (use crypto.randomUUID)
│   └── Token leakage in URL (use POST + token in body)
├── Email hijacking
│   ├── Phishing (user education)
│   └── SIM swap (MFA, recovery codes)
└── Race condition
    └── Token reuse (invalidate after single use)
```

## SAST (Static Application Security Testing)

Integrate SAST into CI/CD:

```yaml
# GitHub Actions — Example with Semgrep
- name: Semgrep Scan
  uses: returntocorp/semgrep-action@v1
  with:
    config: >
      p/owasp-top-ten
      p/nodejs
      p/npm
    ci: true
```

**SAST Rules by Language:**

| Language | SAST Tools |
|----------|------------|
| JavaScript/TypeScript | Semgrep, ESLint security plugin, CodeQL |
| Python | Bandit, Semgrep, Pylint |
| Go | golangci-lint (staticcheck), CodeQL |
| Java | SpotBugs, Semgrep, Sonarqube |
| Ruby | Brakeman |
| Go/Rust | Cargo-audit for dependencies |

## DAST (Dynamic Application Security Testing)

Run DAST against staging before production:

```yaml
# GitHub Actions — OWASP ZAP scan
- name: OWASP ZAP Scan
  uses: zaproxy/action-baseline@v0.9.0
  with:
    target: 'https://staging.yoursite.com'
    delta: '' # compare to baseline
```

**DAST tools:**
- OWASP ZAP (free, extensible)
- Burp Suite (commercial, full-featured)
- Nuclei (fast, YAML-based templates)
- sqlmap (automated SQL injection)
- ffuf (web fuzzer)

## Dependency Vulnerability Scanning

```bash
# Node.js — audit dependencies
npm audit --audit-level=high

# Python — safety check
pip install safety
safety check

# Go — vulnerability check
go install golang.org/x/vuln/cmd/govulncheck@latest
govulncheck ./...

# Cargo (Rust)
cargo audit
```

**Automated tools:**
- Dependabot (GitHub) — PRs for vulnerable dependencies
- Snyk — real-time dependency scanning
- Renovate — automated dependency updates with security flags
- npm audit + `--audit-level=high` in CI

## Secrets Scanning

```yaml
# GitHub Actions — detect secrets in commits
- name: Detect Secrets
  uses: trufflesec/truffleHog-action@0.10.18
  with:
    path: ./
    base64: true
    maxdepth: 5
```

**Best practices:**
- Never commit `.env`, credentials, API keys, tokens, private keys
- Use git-secrets (pre-commit hook) or detect-secrets (Atlassian)
- Store secrets in a vault (HashiCorp Vault, AWS Secrets Manager, 1Password Secrets Automation)
- Rotate secrets regularly; revoke immediately if compromised

## Secure Code Review Checklist

| Category | Check |
|----------|-------|
| Auth | Passwords hashed with bcrypt/argon2; session tokens are high-entropy and HttpOnly |
| Sessions | Invalidated on logout, timeout after inactivity, tied to user agent + IP |
| Access Control | Every endpoint enforces authorization; no client-side-only checks |
| Input | Whitelist validation; no `innerHTML` / `dangerouslySetInnerHTML` |
| Output | Context-aware encoding; CSP with nonce for scripts |
| SQL | Parameterized queries only; no string interpolation in queries |
| Crypto | Using proven libraries (Node: crypto, Python: cryptography); no custom crypto |
| Logging | No PII in logs; auth failures are logged with context; logs are tamper-evident |
| Error Handling | Generic error messages in production; stack traces only in dev |

## Penetration Testing Scope

When engaging a pentest, define scope explicitly:

**In scope:**
- Web application (all authenticated and unauthenticated endpoints)
- API (REST/GraphQL)
- Mobile app (if applicable)
- Authentication flows

**Out of scope:**
- Social engineering
- Physical security
- Client-side malware

**Common test cases:**
1. Authentication bypass (IDOR, horizontal/vertical privilege escalation)
2. Injection (SQL, NoSQL, OS, LDAP, XSS, SSRF, XXE)
3. Business logic abuse (race conditions, workflows bypassed)
4. Session management flaws (token reuse, fixation, long timeout)
5. Cryptographic failures (weak algorithms, hardcoded secrets)
6. Sensitive data exposure (unencrypted storage, insecure direct object references)

## Security Bug Bounty Severity (CVSS-like)

| Severity | Definition | Example |
|----------|------------|---------|
| Critical | Full system compromise, remote code execution | SQL injection with stacked queries, SSRF to metadata service |
| High | Significant data theft or service disruption | Authentication bypass, stored XSS with session cookie theft |
| Medium | Limited impact, requires user interaction | Self-XSS, weak password reset token |
| Low | Minimal impact, hard to exploit |Verbose server headers, information disclosure in robots.txt |
| Info | Documentation issues | Lack of security headers, missing CSP report URI |