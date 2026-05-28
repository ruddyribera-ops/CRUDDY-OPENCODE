# Security Practices — Detailed Guide

## 1. Input Validation Rules
- **Validate all input** — treat external data as untrusted
- **Whitelist validation** — define what IS allowed (not what isn't)
- **Server-side validation** — always, even if client-side exists
- **Check** type, length, format (e.g., email regex)

### Never Trust Client Data
Any data from client can be tampered with. Always re-validate on server.

### SQL Injection Prevention
- **Parameterized queries** — never concatenate user input into SQL
```python
cursor.execute("SELECT * FROM users WHERE username = %s", (username,))
```
- ORMs (SQLAlchemy, Hibernate, Eloquent) handle parameterization automatically

## 2. Environment Variables for Secrets
- Never hardcode secrets in code
- Use env vars: `process.env` (Node), `os.environ` (Python)
- `.env` files for dev only — ensure in `.gitignore`

## 3. HTTPS Basics
- Always use HTTPS — encrypt all communication
- Valid SSL/TLS certificates from trusted authority
- HSTS: force browsers to use HTTPS

## 4. Common OWASP Mistakes
1. Injection (SQL, NoSQL, OS Command) — prevent with parameterized queries
2. Broken Authentication — weak passwords, insecure sessions
3. Sensitive Data Exposure — unencrypted storage, HTTP
4. XXE — XML parser vulnerabilities
5. Broken Access Control — unauthorized resource access
6. Security Misconfiguration — default configs, unnecessary features
7. XSS — malicious scripts; prevent with output encoding + CSP
8. Insecure Deserialization — untrusted data deserialization
9. Known Vulnerabilities — outdated libraries/frameworks
10. Insufficient Logging & Monitoring — lack of detection

## 5. Authentication Patterns

### Password Hashing
- **Always bcrypt or argon2** — never MD5, SHA1, SHA256 alone
- bcrypt cost: 12+
- Argon2id recommended (GPU/ASIC resistant)

```python
from argon2 import PasswordHasher
ph = PasswordHasher(time_cost=3, memory_cost=65536, parallelism=4, hash_len=32, salt_len=16)
hash = ph.hash("user_password")
ph.verify(hash, "user_password")
```

```javascript
const bcrypt = require('bcrypt');
const hash = await bcrypt.hash(password, 12);
const match = await bcrypt.compare(password, hash);
```

### JWT Security
- Verify signature with server's public key — never `algorithm: "none"`
- Check `exp` claim — reject expired tokens
- Use `iat` and `nbf` for token timeline
- Don't store sensitive data in payload (visible to client)
- Use asymmetric keys (RS256/ES256) — never share secret across services
- Short expiry: 15 min access + 7 day refresh
- Algorithm whitelist: explicitly set `algorithms: ['RS256']`

### Session Management
- Session tokens: high-entropy random (min 128 bits), CSPRNG-generated
- Cookie flags: `HttpOnly`, `Secure`, `SameSite=Strict` or `Lax`
- Session timeout: 30 min inactivity for sensitive apps
- Invalidate sessions on password change and logout

## 6. Authorization — Zero Trust
- Deny by default — every endpoint requires explicit auth check
- Least privilege — request only needed permissions
- Check on every API call — not just at login
- RBAC or ABAC for complex permissions

## 7. Secrets Management
- HashiCorp Vault for production
- AWS Secrets Manager / GCP Secret Manager for cloud-native
- Never in source control (.env files, config files, comments)
- Rotate secrets automatically

## 8. Security Headers
```http
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Content-Security-Policy: default-src 'self'; script-src 'self' 'nonce-{RANDOM}'
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

## 9. Logging & Monitoring

### What to Log
- Auth events (success + failure with reason)
- Authorization failures (access denied)
- Sensitive operations (password change, privilege escalation)
- Admin actions (config changes, user management)

### What NOT to Log
- Passwords, session tokens, API keys, secrets
- Full request bodies with PII
- User data beyond audit necessity

### Alert Thresholds
| Level | Trigger |
|-------|---------|
| Critical | Auth bypass, privilege escalation, data exfiltration |
| High | 10+ failed logins in 5 min, unusual admin activity |
| Medium | Failed auth spike, suspicious API requests |
| Low | Single failed auth, input validation failure |

## 10. Vulnerability Assessment Checklist

| Category | Check |
|----------|-------|
| Auth | Passwords hashed with bcrypt/argon2; HttpOnly session tokens |
| Sessions | Invalidated on logout; timeout after inactivity |
| Access Control | Every endpoint enforces authorization |
| Input | Whitelist validation; no `innerHTML`/`dangerouslySetInnerHTML` |
| Output | Context-aware encoding; CSP with nonce |
| SQL | Parameterized queries only |
| Crypto | Proven libraries only; no custom crypto |
| Logging | No PII; auth failures logged with context |
| Error Handling | Generic messages in production; no stack traces |
| Dependencies | CVE scanning in CI; regular updates |
| Secrets | All in env vars/vault; none in source control |
| Security Headers | HSTS, CSP, X-Frame-Options, X-Content-Type-Options |
| Rate Limiting | On auth endpoints and expensive operations |
