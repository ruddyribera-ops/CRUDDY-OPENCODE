---
name: auth-patterns
description: Password hashing, sessions, JWT, password change flows, and DB-type gotchas for auth flags
tags: [security, auth, backend, api]
tags: [authentication, jwt, password, oauth, sessions, security, authorization]
---

## When to Use
- Implementing user authentication with JWT or session-based tokens
- Setting up password hashing with bcrypt or Argon2
- Designing password change, reset, and recovery flows
- Securing API endpoints with auth middleware
- Handling OAuth2 or third-party login integration

## Do Not Use
- General API design (use api-patterns)
- Database schema design (use database-patterns)
- Encryption of non-auth data (use security-basics)

# Authentication Patterns

## TL;DR — Top 5 Rules (Always Apply)
1. **Passwords → bcrypt (cost ≥ 12) or argon2.** Never MD5, SHA, or plain text.
2. **Same error for "user not found" and "wrong password"** — always "invalid credentials" to prevent email enumeration.
3. **JWT secret in env, ≥ 256 bits, `exp` claim always set.** Access: 15-30 min. Refresh: 7-30 days.
4. **Session cookies: `HttpOnly`, `Secure`, `SameSite=Lax`.** Never store tokens in `localStorage`.
5. **Password change requires current password; password reset invalidates ALL sessions.**

## DB Gotcha
PostgreSQL rejects Python `True`/`False` in INTEGER column (SQLite doesn't). Use `BOOLEAN` consistently or `int(bool_value)`.

## Detailed Code & Flows
→ See `references/auth-flows.md` for complete code examples:

| Concern | Summary | Full Code |
|---------|---------|-----------|
| Password hashing | bcrypt cost 12+; never MD5/SHA/plain | Python + Node.js examples |
| JWT creation+verification | HS256, sub claim, exp required | PyJWT example + rules |
| Session persistence | HttpOnly cookie + DB-backed token | Session create/validate code |
| Password change | Requires current pw, invalidates other sessions | change_password() function |
| Password reset | 1-hour token, single-use, no email enumeration | reset flow with rate limiting |

## Key Rules Summary
- Same error for all auth failures (no email enumeration)
- bcrypt cost ≥ 12 (adjust as hardware improves)
- JWT: short expiry, include `sub` + `iat` + `exp`
- Cookies: `HttpOnly`, `Secure`, `SameSite=Lax` or `Strict`
- Password change: verify current password, invalidate other sessions
- Password reset: 1-hour single-use token, invalidate ALL sessions
- Rate-limit auth endpoints (max 3 password reset requests per 15 min)

## Verification
- [ ] Passwords hashed with bcrypt (cost ≥ 12) or argon2 — not MD5/SHA/plain
- [ ] JWT secret in environment variable, not in code
- [ ] Auth failure always returns "invalid credentials" (same message)
- [ ] Session cookies use `HttpOnly`, `Secure`, `SameSite=Lax`
- [ ] Password change requires current password
- [ ] Password reset invalidates all sessions
- [ ] Auth endpoints have rate limiting
- [ ] All reference links resolve
