# Authentication Patterns — Detailed Code & Flows

## Password Hashing (bcrypt)

### Python
```python
import bcrypt
def hash_password(password: str) -> str:
    if not password: raise ValueError("password cannot be empty")
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12)).decode()

def verify_password(password: str, hashed: str) -> bool:
    if not password or not hashed: return False
    try: return bcrypt.checkpw(password.encode(), hashed.encode())
    except (ValueError, TypeError): return False
```

### Node.js
```javascript
import bcrypt from 'bcrypt';
export async function hashPassword(password) {
  if (!password) throw new Error('password cannot be empty');
  return bcrypt.hash(password, 12);
}
export async function verifyPassword(password, hashed) {
  if (!password || !hashed) return false;
  try { return await bcrypt.compare(password, hashed); }
  catch { return false; }
}
```

### ❌ Never do this
- `hashlib.md5(password.encode()).hexdigest()` — crackable in minutes
- SHA256 alone — fast hashes = attackers love this
- Plain text storage — game over
- "Custom" obfuscation (base64, reversing) — this is not hashing

## JWT (Python — PyJWT)
```python
import jwt
from datetime import datetime, timedelta, timezone

SECRET = os.environ["JWT_SECRET"]  # Load from env — never hardcode
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE = timedelta(minutes=30)

def create_access_token(user_id: int) -> str:
    payload = {"sub": str(user_id), "iat": datetime.now(timezone.utc),
               "exp": datetime.now(timezone.utc) + ACCESS_TOKEN_EXPIRE}
    return jwt.encode(payload, SECRET, algorithm=ALGORITHM)

def decode_token(token: str) -> dict | None:
    try: return jwt.decode(token, SECRET, algorithms=[ALGORITHM])
    except jwt.ExpiredSignatureError: return None
    except jwt.InvalidTokenError: return None
```

### JWT Rules
- Access tokens: 15-30 min. Refresh tokens: 7-30 days
- Secret ≥ 256 bits from env, never committed
- `exp` claim always set; include `sub` (not PII)
- Rotate secret if leak suspected

## Session Persistence
```python
def create_session(user_id: int, remember_me: bool) -> str:
    token = secrets.token_urlsafe(32)  # 256 bits entropy
    expires_at = datetime.now(timezone.utc) + (timedelta(days=30) if remember_me else timedelta(hours=8))
    db.execute("INSERT INTO sessions (token, user_id, expires_at) VALUES (%s, %s, %s)", (token, user_id, expires_at))
    return token

def validate_session(token: str) -> int | None:
    row = db.fetchone("SELECT user_id FROM sessions WHERE token = %s AND expires_at > NOW()", (token,))
    return row[0] if row else None
```

### Cookie Flags That Matter
- `HttpOnly` — blocks JS access (prevents XSS stealing the cookie)
- `Secure` — HTTPS only (prevents MITM)
- `SameSite=Lax` (default) or `Strict` — CSRF protection
- Never store tokens in `localStorage`

## Password Change Flow
```python
def change_password(user_id: int, current_pw: str, new_pw: str) -> bool:
    user = db.get_user(user_id)
    if not verify_password(current_pw, user.password_hash):
        raise PermissionError("current password is wrong")
    if len(new_pw) < 12: raise ValueError("new password must be at least 12 chars")
    if new_pw == current_pw: raise ValueError("new password must differ from current")
    new_hash = hash_password(new_pw)
    db.execute("UPDATE users SET password_hash = %s WHERE id = %s", (new_hash, user_id))
    db.execute("DELETE FROM sessions WHERE user_id = %s AND token != %s", (user_id, current_session_token))
    return True
```

### After Password Reset
- Invalidate ALL sessions (force re-login)
- Send notification email: "your password was changed at HH:MM from IP X"

## Password Reset Flow
```python
def request_password_reset(email: str) -> None:
    user = db.get_user_by_email(email)
    # Same response whether user exists or not (prevents email enumeration)
    if user:
        token = secrets.token_urlsafe(32)
        expires_at = datetime.now(timezone.utc) + timedelta(hours=1)
        db.execute("INSERT INTO password_resets (token, user_id, expires_at) VALUES (%s, %s, %s)", (token, user.id, expires_at))
        send_email(user.email, reset_link=f"https://app.example.com/reset?token={token}")
    # No else — don't reveal whether email exists
```

### Security rules
- Token expires in 1 hour (single-use)
- Token is single-use — delete after first access
- Reset invalidates ALL existing sessions
- Rate-limit requests: max 3 per email per 15 min
- Log all reset requests (IP, timestamp) in audit log

## DB Gotcha
PostgreSQL rejects Python `True`/`False` in INTEGER column (SQLite doesn't). Use `BOOLEAN` consistently or cast with `int(bool_value)`.
