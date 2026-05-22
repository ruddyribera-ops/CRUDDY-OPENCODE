---
name: auth-patterns
description: Authentication and authorization patterns — OAuth 2.0, JWT, session management, password handling, MFA, RBAC. Expert-level coverage of auth flows, security boundaries, and common pitfalls.
triggers: [login, register, signup, signin, auth, oauth, jwt, session, token, password, mfa, 2fa, rbac, permission, role, sso, saml, openid, keycloak, auth0, clerk, next-auth, passport]
---

# Authentication & Authorization Patterns

## Core Principles

1. **Never build crypto yourself** — use well-audited libraries (bcrypt, argon2, passport, next-auth, OAuth2 libraries)
2. **Defense in depth** — multiple layers: transport (HTTPS), storage (hashed), validation (rate limit), session (short-lived)
3. **Least privilege** — tokens and sessions carry minimum scope needed
4. **Audit everything** — log auth events (login, logout, failed attempts, permission changes)

---

## 1. Password Handling

### Hashing (Non-Negotiable)

```python
# ✅ CORRECT: bcrypt with cost >= 12
import bcrypt
hashed = bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12))
```

```python
# ✅ CORRECT: argon2id (preferred for new projects)
from argon2 import PasswordHasher
ph = PasswordHasher(time_cost=2, memory_cost=19456, parallelism=1)
hashed = ph.hash(password)
```

```javascript
// ✅ CORRECT (Node.js):
import bcrypt from 'bcrypt';
const hashed = await bcrypt.hash(password, 12);
```

**❌ NEVER: MD5, SHA1, SHA256 (raw), custom "encryption", base64 encoding as "hashing"**

### Password Validation

```python
# Minimum requirements
MIN_LENGTH = 8  # NIST SP 800-63 recommends 8+ minimum
# DO NOT require: special chars, uppercase, numbers (NIST says this is counterproductive)
# DO: check against common passwords list (HaveIBeenPwned API)
```

### Password Reset Flow

1. User requests reset → generate single-use token (32+ random bytes, hex-encoded)
2. Store SHA256(token_hash) + expiry (1 hour) in DB — never store plain token
3. Send link via email only (never SMS unless verified phone)
4. On submission: validate hash match + expiry + mark used (prevent replay)
5. Invalidated ALL sessions after reset

---

## 2. JWT Best Practices

### Token Structure

```json
// Access Token (15-30 min expiry)
{
  "sub": "user_123",
  "role": "admin",
  "iat": 1700000000,
  "exp": 1700000900,
  "jti": "unique-token-id"
}

// Refresh Token (7-30 days, stored in DB, single-use)
// Store SHA256 hash of refresh token in DB
```

### Signing

```javascript
// ✅ CORRECT: HS256 with 256+ bit secret
jwt.sign(payload, process.env.JWT_SECRET, { algorithm: 'HS256', expiresIn: '15m' });

// ✅ BETTER: RS256 (asymmetric) — allows key rotation without redeploy
jwt.sign(payload, privateKey, { algorithm: 'RS256', expiresIn: '15m' });

// ❌ NEVER: algorithm: 'none', HS256 with short secret, hardcoded secret
```

### Cookie Transmission

```javascript
// ✅ CORRECT
res.cookie('session', token, {
  httpOnly: true,       // Not accessible via JS
  secure: true,         // HTTPS only
  sameSite: 'lax',      // CSRF protection
  maxAge: 15 * 60 * 1000 // 15 minutes
});

// ❌ NEVER: localStorage for auth tokens (XSS-vulnerable)
// ❌ NEVER: cookie without httpOnly + secure + sameSite
```

---

## 3. Session Management

### Stateful vs Stateless

| Approach | Best For | Gotcha |
|----------|----------|--------|
| JWT (stateless) | APIs, microservices | Can't revoke individual tokens without a blacklist |
| Server sessions (stateful) | Web apps, SSR | Requires Redis/DB, more infrastructure |
| Hybrid | Most apps | JWT for auth, server sessions for sensitive operations |

### Session Invalidation

```
On password change:   INVALIDATE ALL sessions (increment security_version in DB)
On password reset:    INVALIDATE ALL sessions
On logout:            Blacklist token jti until expiry
On role change:       INVALIDATE ALL sessions (enforce re-auth with new permissions)
```

### Database Schema

```sql
CREATE TABLE sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL,           -- SHA256 of refresh token
  device_info TEXT,
  ip_address INET,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,             -- NULL unless revoked
  created_at TIMESTAMPTZ DEFAULT NOW()
);
-- Index: idx_sessions_user_id ON sessions(user_id) WHERE revoked_at IS NULL
```

---

## 4. OAuth 2.0 / OpenID Connect

### Authorization Code Flow (PKCE) — RECOMMENDED

```
1. Client generates code_verifier (random 43-128 chars) + code_challenge (SHA256)
2. Client redirects to auth server with code_challenge
3. Auth server returns authorization code
4. Client exchanges code + verifier for tokens
5. Auth server verifies challenge matches -> returns access_token + id_token + refresh_token
```

### State Parameter (Mandatory)

```javascript
// Generate random state, store in session before redirect
const state = crypto.randomBytes(32).toString('hex');
session.oauth_state = state;
// Verify state matches on callback — prevents CSRF on auth callback
```

### Provider Checklist

- [ ] All providers use PKCE flow
- [ ] State parameter validated on callback
- [ ] Email verified before creating/merging accounts
- [ ] Provider ID stored, not just email (email can change)
- [ ] Rate limit per provider per IP

---

## 5. Authorization (RBAC / ABAC)

### Role-Based Access Control

```python
class Role(str, Enum):
    ADMIN = "admin"
    MANAGER = "manager"
    USER = "user"
    READONLY = "readonly"

PERMISSIONS = {
    Role.ADMIN: {"*": "*"},                    # Full access
    Role.MANAGER: {"users": "crud", "reports": "crud", "settings": "read"},
    Role.USER: {"profile": "crud", "projects": "crud"},
    Role.READONLY: {"*": "read"},
}

def check_permission(user: User, resource: str, action: str) -> bool:
    if user.role not in PERMISSIONS:
        return False
    rules = PERMISSIONS[user.role]
    if "*" in rules and (rules["*"] == "*" or action in rules["*"]):
        return True
    if resource not in rules:
        return False
    return action in rules[resource]
```

### Middleware Pattern

```javascript
// Route-level permission guard
router.delete('/api/users/:id',
  authenticate,                    // Verify JWT/session
  authorize('users', 'delete'),    // Check permission
  userController.delete            // Execute
);

// ❌ NEVER: role check inline inside route handler
// ❌ NEVER: x-user-role header (spoofable)
```

---

## 6. Rate Limiting & Bruteforce Protection

```python
# Login: 5 attempts per IP per 15min (sliding window)
# Password reset: 3 per email per 15min
# Registration: 3 per IP per hour
# API (unauthenticated): 100 per IP per minute
# API (authenticated): 1000 per user per minute

# Response: 429 Too Many Requests
# Headers: Retry-After: 900
```

---

## 7. MFA / 2FA

1. TOTP (Time-based One-Time Password) — preferred for most apps
   - Use `pyotp` or `otplib`
   - Store secret encrypted in DB, never expose after setup
   - Provide backup codes (10 codes, single-use, store SHA256 hash)
2. WebAuthn (Passkeys) — growing standard, hardware-backed
   - Platform authenticator (TouchID, FaceID, Windows Hello)
   - Cross-platform authenticator (YubiKey)
3. SMS/Email codes — least secure, use only as fallback

---

## 8. Common Anti-Patterns

| Anti-Pattern | Why | Fix |
|-------------|-----|-----|
| "Skip auth for now, add later" | Security hole ships to production | 20 lines for bcrypt + session cookie |
| Storing tokens in localStorage | XSS exposes all tokens | httpOnly cookies |
| Returning "user not found" vs "wrong password" | Allows user enumeration | Always return "invalid credentials" |
| No rate limiting on login | Brute force attack | Sliding window rate limiter |
| Infinite session lifetime | Stolen token = permanent access | 15min access, 7d refresh, rotate on use |
| Role/ID in JWT without verification | Token was valid when issued but user may have changed | Verify against DB on sensitive operations |

---

## 9. Verification Checklist

- [ ] Passwords hashed with bcrypt(12+) or argon2id
- [ ] No MD5, SHA1, or custom hash used anywhere in auth flow
- [ ] JWT signed with strong secret (256+ bits) or RS256
- [ ] Tokens set as httpOnly + secure + sameSite cookies
- [ ] Refresh tokens are single-use, stored as SHA256 hash
- [ ] Rate limiting on ALL auth endpoints
- [ ] Login returns same error for "user not found" and "wrong password"
- [ ] Password reset tokens expire in 1 hour, single-use
- [ ] Password change invalidates ALL existing sessions
- [ ] OAuth state parameter validated on every callback
- [ ] Backend validates every permission check — never trust client-side role
- [ ] Auth events logged to audit trail
