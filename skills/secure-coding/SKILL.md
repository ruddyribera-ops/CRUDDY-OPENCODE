---
name: secure-coding
description: Secure coding practices — OWASP Top 10, input validation, parameterized queries, security-focused code review. Use when writing or reviewing code that handles user input, authentication, database queries, or external API calls. Triggers: security check, secure this, vulnerability, OWASP, sql injection, auth bypass, xss, csrf, parameterized query.
---

# Secure Coding

## When to Use This

Load this skill when:
- Writing code that handles user input, authentication, or database queries
- Reviewing a PR for security implications
- Auditing code before production deploy
- Investigating a potential security vulnerability
- Adding a new external API integration

This skill composes **3 focused skills**: `security-basics`, `sql-safety`, and `differential-review`.

---

## The 3 Lenses

### 1. Foundations Lens (`security-basics/`)

Covers: Input validation, cryptography fundamentals, OWASP Top 10, SAST/DAST, CTF patterns.

**Key questions:**
- Is all user input validated before use?
- Is sensitive data encrypted at rest and in transit?
- Does the code follow OWASP Top 10 guidance?
- Are security tools (SAST/DAST) integrated into CI?

### 2. Data Layer Lens (`sql-safety/`)

Covers: Parameterized queries only, PostgreSQL/SQLite type discipline, idempotent migrations.

**Key questions:**
- Are all SQL queries parameterized? (No string interpolation!)
- Are database types strictly enforced?
- Are migrations versioned and idempotent?
- Is the principle of least privilege applied to DB users?

### 3. Review Lens (`differential-review/`)

Covers: Security-focused PR review, blast radius assessment, supply chain security, OWASP ASI 2026.

**Key questions:**
- Does the diff weaken auth or authorization?
- Are there new SQL injection vectors?
- Does the change introduce new attack surface?
- Are new dependencies audited for supply chain risks?

---

## Composite Checklist

### Input Validation
- [ ] All user input validated for type, length, format, and range
- [ ] No `eval()`, `exec()`, or similar on user-controlled data
- [ ] File uploads validated for type, size, and content
- [ ] URLs validated before following redirects
- [ ] User input sanitized before HTML/JSON output (XSS prevention)

### Authentication & Authorization
- [ ] No hardcoded credentials or API keys
- [ ] Passwords hashed with bcrypt/Argon2 (not MD5, SHA-1, or plain)
- [ ] Session tokens expire appropriately
- [ ] Auth checks on every protected endpoint (not just UI)
- [ ] Role checks are explicit, not implicit

### Database
- [ ] All queries use parameterized statements
- [ ] No string interpolation in SQL (no `f"SELECT ... {var}"`)
- [ ] Database user has least privilege (not root/admin)
- [ ] Sensitive fields encrypted at rest
- [ ] Connection strings not logged

### API & Network
- [ ] External API calls have timeouts
- [ ] Secrets not in URL query parameters (they get logged)
- [ ] HTTPS enforced for all external calls
- [ ] Rate limiting on public endpoints
- [ ] CORS policy is explicit and restrictive

### Dependencies & Supply Chain
- [ ] New dependencies audited (`npm audit`, `safety check`)
- [ ] No `:latest` tags in production Docker images
- [ ] Build scripts reviewed for unexpected network calls
- [ ] Transitive dependencies understood (or minimized)

---

## Cross-References

| Skill | What it adds |
|-------|-------------|
| `security-basics/` | Input validation, cryptography, OWASP Top 10, SAST/DAST, CTF patterns |
| `sql-safety/` | Parameterized queries, type discipline, idempotent migrations, least DB privilege |
| `differential-review/` | PR blast radius, supply chain review, OWASP ASI 2026, adversarial analysis |

---

## Anti-Patterns: Top 5 "Looks Secure But Isn't"

### 1. "We use HTTPS so it's secure"
**Reality:** HTTPS only encrypts the pipe. Doesn't protect against XSS, SQL injection, broken auth, or any application-level attack.

### 2. "We validate input on the client side"
**Reality:** Client-side validation is UX only. Always re-validate on the server. Attackers can bypass the browser.

### 3. "We use a ORM so we're safe from SQL injection"
**Reality:** ORMs are safe by default, but `.raw()` queries, dynamic column names, or unsafe interpolation can still inject.

### 4. "We have auth middleware so all endpoints are protected"
**Reality:** Auth middleware protects most endpoints. But new endpoints can be accidentally left unprotected. Explicit `[Authorize]` on every endpoint.

### 5. "We don't log sensitive data"
**Reality:** Logs often contain sensitive data anyway (user IDs, email addresses, query parameters). Ensure structured logs exclude sensitive fields explicitly.

---

## Quick Reference: OWASP Top 10 (2021) + LLM Top 10

| OWASP Top 10 (2021) | What to check | LLM Top 10 (OWASP ASI 2026) |
|---------------------|---------------|------------------------------|
| A01: Broken Access Control | AuthZ checks on every endpoint | LLM01: Prompt Injection |
| A02: Cryptographic Failures | No hardcoded secrets, proper crypto | LLM02: Sensitive Disclosure |
| A03: Injection | Parameterized queries, input validation | LLM03: Supply Chain |
| A04: Insecure Design | Threat modeling, secure defaults | LLM04: Data Poisoning |
| A05: Security Misconfiguration | Hardened configs, minimal surface | LLM05: Excessive Agency |
| A06: Vulnerable Components | Dependency audits, version pins | LLM06: System Prompt Leakage |
| A07: Auth Failures | Session management, password policy | LLM07: Vector/Embedding Weaknesses |
| A08: Data Integrity Failures | CI/CD integrity, no unsigned code | LLM08: Misinformation |
| A09: Logging Failures | Structured logs with trace IDs | LLM09: Model Theft |
| A10: SSRF | URL validation, block internal access | LLM10: Unbounded Consumption |

### Parameterized Query Template

```python
# ✅ SAFE: Parameterized
cursor.execute("SELECT * FROM users WHERE email = %s", (email,))

# ❌ DANGEROUS: String interpolation
cursor.execute(f"SELECT * FROM users WHERE email = '{email}'")
```

### Security Review Two-Question Test

For every diff, ask:
1. If this change is exploited, what is the maximum damage?
2. Is that damage acceptable?
