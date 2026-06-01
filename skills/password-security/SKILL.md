---
name: password-security
description: Bcrypt/Argon2 password hashing. Rejects MD5, SHA, plain, or custom hashes. Unified error messages for auth failures.
triggers: [password, hash, bcrypt, argon2, encrypt, credential, login, signup, register]
---

# Password Security

## What it does
Enforces strong password hashing and uniform authentication error responses. Prevents the most common auth vulnerabilities: weak hashing (MD5/SHA/plain), timing-based user enumeration, and PostgreSQL type coercion bugs.

## When to use
- Implementing or reviewing any authentication endpoint
- Storing user credentials in a database
- Migrating from an old auth system
- Auditing existing password handling code

## Rules

1. **Always use bcrypt (cost >= 12) or argon2id.** MD5, SHA-1, SHA-256, and custom hashes are cryptographically broken for passwords.
2. **PostgreSQL boolean columns only.** Python `True`/`False` sent as `INTEGER` will be silently rejected. Always use the `BOOLEAN` type.
3. **Unified auth error message.** Return `"invalid credentials"` for BOTH "user not found" AND "wrong password". This prevents user enumeration via timing or message differences.
4. **Never log passwords or password hashes.** Hashes in logs = offline brute force. Passwords in logs = credential leaks.
5. **Rate-limit login attempts.** 5 attempts per IP per 15 minutes, sliding window. Return 429 with `Retry-After` header.

## Anti-patterns

- ❌ `md5(password)` or `sha1(password)` — broken, instant brute force on rainbow tables
- ❌ `hashlib.md5(password.encode()).hexdigest()` — same problem in Python
- ❌ Custom hash functions (e.g., `hash(password + salt + secret)`) — never invent crypto
- ❌ Returning "user not found" vs "wrong password" as different errors — user enumeration
- ❌ `WHERE password = '...'` in SQL — see also `sql-safety` skill
- ❌ Storing passwords in `INTEGER` columns or as floats
- ❌ Logging failed login attempts with the attempted password

## Example (correct)

```python
import bcrypt

# Hash
hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt(rounds=12))

# Verify
if bcrypt.checkpw(password.encode('utf-8'), stored_hash):
    # success
    pass
else:
    # Same error as "user not found"
    return {"error": "invalid credentials"}, 401
```

## References

- OWASP Password Storage Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html
- `auth-patterns` skill — broader auth coverage (OAuth, JWT, sessions)
