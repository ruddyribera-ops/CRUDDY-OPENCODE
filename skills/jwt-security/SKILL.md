---
name: jwt-security
description: Secure JWT configuration — claims, TTL, cookie flags, session invalidation on password change.
triggers: [jwt, token, login, auth, session-cookie, refresh-token, access-token, bearer]
---

# JWT Security

## What it does
Defines secure defaults for JWT issuance, storage, and lifecycle. Prevents common JWT pitfalls: long-lived tokens, missing claims, insecure cookies, and orphaned sessions after password change.

## When to use
- Issuing access or refresh tokens
- Setting up session cookies
- Implementing logout or password change
- Reviewing token-based auth code

## Rules

1. **Algorithm: HS256 minimum, RS256/ES256 preferred.** Never `none`. Never user-supplied algorithm (`alg: 'HS256'` vs `alg: 'RS256'` confusion attacks).
2. **Required claims: `sub` and `exp`.** `sub` = user ID, `exp` = expiration. Missing either is a vulnerability.
3. **Secret length: >= 256 bits.** Generate with `openssl rand -hex 32` or equivalent. Never hardcode.
4. **Access token TTL: 15-30 minutes.** Refresh token TTL: 7-30 days. Both with sliding expiration.
5. **Cookie flags (if storing in cookie):** `HttpOnly` (no JS access), `Secure` (HTTPS only), `SameSite=Lax` (CSRF protection).
6. **Never store tokens in localStorage.** XSS-readable. Use HttpOnly cookies or in-memory.
7. **Blacklist on logout.** Maintain a server-side blacklist (or use short TTL + refresh rotation). Stolen tokens must expire.
8. **Password change invalidates ALL sessions.** Require current password. Issue a "session-invalidation" event that blacklists all of the user's tokens.
9. **Password reset: 1-hour single-use token.** Invalidate all existing sessions on successful reset.

## Anti-patterns

- ❌ `alg: 'none'` in JWT header — anyone can forge tokens
- ❌ `localStorage.setItem('token', jwt)` — XSS exfiltration
- ❌ 30-day access token TTL — long blast radius if stolen
- ❌ Same secret across dev/staging/prod
- ❌ No `exp` claim — tokens never expire
- ❌ Forgetting to invalidate old tokens on password change
- ❌ Returning the JWT in the response body AND a cookie (double exposure)
- ❌ Verifying JWT signature but not `exp` or `nbf` claims

## Example (correct)

```python
import jwt
import os
from datetime import datetime, timedelta

SECRET = os.environ['JWT_SECRET']  # 256+ bits
ALGO = 'HS256'

def issue_token(user_id: str) -> str:
    payload = {
        'sub': user_id,
        'iat': datetime.utcnow(),
        'exp': datetime.utcnow() + timedelta(minutes=15),
        'jti': os.urandom(16).hex(),  # for blacklist
    }
    return jwt.encode(payload, SECRET, algorithm=ALGO)

# Cookie
response.set_cookie(
    'session',
    token,
    httponly=True,
    secure=True,
    samesite='Lax',
    max_age=15 * 60,
)
```

## References

- RFC 7519 (JWT): https://datatracker.ietf.org/doc/html/rfc7519
- OWASP JWT Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html
- `auth-patterns` skill — broader auth coverage
