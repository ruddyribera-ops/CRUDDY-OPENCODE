---
name: security-basics
description: Security best practices, vulnerability prevention, and secure development across web applications, APIs, networks, and embedded systems. Triggers: security, OWASP, vulnerability, SAST, DAST, input validation, XSS, SQL injection, CSRF, auth, bcrypt, JWT, SAST, DAST, incident response.
---

# Security Basics

## When to use this

Load this skill whenever you are writing authentication code, handling user input, processing file uploads, reviewing code for vulnerabilities, configuring security tooling, or responding to a security incident.

---

## Core Principles

1. **Allowlist input validation, never blocklist** — It is impossible to enumerate all malicious inputs. Instead, define what is valid and reject everything else.

2. **Use established cryptography libraries, never roll your own** — Encryption, hashing, and signing are subtle. Use well-audited libraries (Python: cryptography, PyNaCl; JS: Web Crypto API, libsodium).

3. **Authenticate on the server, never trust the client** — All authorization checks must happen server-side. Client-side checks are for UX only.

4. **Defense in depth: multiple layers** — A single security control can fail. Layer authentication, authorization, input validation, output encoding, and logging.

5. **Principle of least privilege** — Request only the permissions you need. Run services with only the access they require.

6. **Log security events, not sensitive data** — Log authentication failures, authorization denials, and input validation failures. Never log passwords, tokens, or PII.

7. **SAST in development, DAST in testing, RASP in production** — Security testing at every stage: static analysis during coding, dynamic scanning during testing, runtime protection in production.

---

## Patterns

### Input Validation (Allowlist)

```python
import re
from dataclasses import dataclass

@dataclass
class ValidationResult:
    valid: bool
    value: str | None = None
    error: str | None = None

def validate_email(email: str) -> ValidationResult:
    """Allowlist: only valid email format is accepted."""
    if not email:
        return ValidationResult(False, error="Email is required")
    # Strict allowlist pattern — only matches RFC-compliant emails
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    if not re.match(pattern, email):
        return ValidationResult(False, error="Invalid email format")
    return ValidationResult(True, value=email)

def validate_integer(value: str, min_val: int = None, max_val: int = None) -> ValidationResult:
    """Validate and bound an integer input."""
    try:
        num = int(value)
    except (ValueError, TypeError):
        return ValidationResult(False, error="Must be an integer")
    if min_val is not None and num < min_val:
        return ValidationResult(False, error=f"Must be >= {min_val}")
    if max_val is not None and num > max_val:
        return ValidationResult(False, error=f"Must be <= {max_val}")
    return ValidationResult(True, value=num)

# WRONG: Blocklist approach (insecure — you will miss cases)
def validate_email_blocklist(email: str) -> bool:
    blocked = ["'", '"', ";", "--", "union", "select"]
    # This will miss: encoded characters, case variations, etc.
    return not any(b in email.lower() for b in blocked)
```

### Password Hashing (bcrypt / Argon2)

```python
import bcrypt

def hash_password(password: str) -> str:
    """Hash a password with bcrypt. Always use a unique salt."""
    salt = bcrypt.gensalt(rounds=12)  # 12 rounds — balance security vs speed
    hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
    return hashed.decode('utf-8')

def verify_password(password: str, stored_hash: str) -> bool:
    """Verify a password against its stored hash."""
    return bcrypt.checkpw(password.encode('utf-8'), stored_hash.encode('utf-8'))

# WRONG: MD5 or SHA1 for passwords (fast hashes — crackable in seconds)
import hashlib
def hash_password_md5(password: str) -> str:
    return hashlib.md5(password.encode()).hexdigest()  # DO NOT USE

# WRONG: SHA256 (no salt, fast — GPU cracks billions per second)
def hash_password_sha256(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()  # DO NOT USE
```

### JWT Security

```python
import jwt
from datetime import datetime, timedelta
import os

SECRET_KEY = os.environ["JWT_SECRET"]  # min 256 bits, randomly generated
ALGORITHM = "HS256"

def create_token(user_id: str, expires_in_hours: int = 24) -> str:
    """Create a signed JWT. Always set expiration."""
    payload = {
        "sub": user_id,
        "iat": datetime.utcnow(),
        "exp": datetime.utcnow() + timedelta(hours=expires_in_hours),
        "jti": os.urandom(16).hex(),  # Unique token ID for revocation
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

def verify_token(token: str) -> dict | None:
    """Verify and decode a JWT. Returns None if invalid or expired."""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        return None  # Token expired
    except jwt.InvalidTokenError:
        return None  # Invalid signature or malformed

# JWT Security Rules:
# 1. Always verify the algorithm (prevent algorithm confusion attacks)
# 2. Always check expiration (exp claim)
# 3. Use a strong secret (256+ bits of entropy)
# 4. Store tokens securely (HttpOnly cookies, not localStorage)
# 5. Implement token revocation (blacklist expired tokens)
```

### SQL Injection Prevention

```python
# Parameterized queries — the ONLY safe way to query SQL
# (See sql-safety skill for full patterns)

# WRONG: String interpolation (SQL injection)
query = f"SELECT * FROM users WHERE email = '{email}'"
# Attacker input: "'; DROP TABLE users; --"
# Executes: SELECT * FROM users WHERE email = ''; DROP TABLE users; --'

# CORRECT: Parameterized query
cursor.execute(
    "SELECT * FROM users WHERE email = %s",
    (email,)
)
# The database driver handles escaping — input is always a literal value
```

### XSS Prevention (Output Encoding)

```python
import html

# In web frameworks, use template auto-escaping (Jinja2, React, etc.)

# When you must manually encode:
def escape_for_html(untrusted: str) -> str:
    """Escape HTML special characters to prevent XSS in rendered content."""
    return html.escape(untrusted, quote=True)

# React: automatically escapes in JSX — never use dangerouslySetInnerHTML
# <div>{userContent}</div>  # Safe
# <div dangerouslySetInnerHTML={{__html: userContent}} />  # DANGEROUS

# HTTP headers to prevent XSS:
# Content-Security-Policy: default-src 'self'; script-src 'self'
# X-Content-Type-Options: nosniff
# X-XSS-Protection: 1; mode=block
```

### CSRF Protection

```python
# CSRF: Cross-Site Request Forgery — attacker tricks user into making authenticated requests

# Solution 1: CSRF Token (synchronous)
# In your form template:
# <input type="hidden" name="csrf_token" value="{{ csrf_token }}" />

# In your form handler (Flask example):
from flask_wtf.csrf import generate_csrf

@app.route("/transfer", methods=["POST"])
def transfer():
    token = request.form.get("csrf_token")
    if not token or token != session.get("csrf_token"):
        abort(403)  # CSRF validation failed

    # Process the request
    ...

# Solution 2: SameSite Cookie
# Set-Cookie: session_id=abc; SameSite=Lax; Secure; HttpOnly
# SameSite=Lax: browser doesn't send cookie on cross-site POST
# SameSite=Strict: browser doesn't send cookie on any cross-site request
```

### File Upload Security

```python
import os
import magic
from pathlib import Path

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".gif", ".webp"}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB
UPLOAD_DIR = Path("/var/uploads")

def secure_filename(filename: str) -> str:
    """Remove path traversal and dangerous characters from filename."""
    # Remove any path components
    filename = os.path.basename(filename)
    # Remove null bytes
    filename = filename.replace("\x00", "")
    # Use a safe filename (UUID) + original extension
    import uuid
    safe_name = f"{uuid.uuid4().hex}{Path(filename).suffix.lower()}"
    return safe_name

def validate_upload(file_stream, filename: str) -> tuple[bool, str]:
    """Validate file upload security."""
    # 1. Check extension
    ext = Path(filename).suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        return False, f"Extension {ext} not allowed"

    # 2. Check size
    file_stream.seek(0, os.SEEK_END)
    size = file_stream.tell()
    file_stream.seek(0)
    if size > MAX_FILE_SIZE:
        return False, f"File too large (max {MAX_FILE_SIZE} bytes)"

    # 3. Verify MIME type (don't trust extension)
    mime = magic.from_buffer(file_stream.read(2048), mime=True)
    file_stream.seek(0)
    allowed_mimes = {"image/jpeg", "image/png", "image/gif", "image/webp"}
    if mime not in allowed_mimes:
        return False, f"Invalid file type: {mime}"

    return True, "OK"

def save_upload(file_stream, filename: str, upload_dir: Path) -> Path:
    """Save uploaded file with validation."""
    safe_name = secure_filename(filename)
    file_path = upload_dir / safe_name

    # Store outside web root — serve via application code
    # This prevents executable file uploads

    file_stream.save(file_path)
    return file_path
```

### Security Headers

```python
# Recommended HTTP security headers
SECURITY_HEADERS = {
    "Content-Security-Policy": "default-src 'self'; script-src 'self'",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "X-XSS-Protection": "1; mode=block",
    "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
    "Referrer-Policy": "strict-origin-when-cross-origin",
    "Permissions-Policy": "geolocation=(), microphone=(), camera=()",
}

@app.after_request
def add_security_headers(response):
    for header, value in SECURITY_HEADERS.items():
        response.headers[header] = value
    return response
```

---

## OWASP Top 10 Quick Reference (2021)

| A01 | Broken Access Control | Users act outside intended permissions. Enforce authorization on every request. |
| A02 | Cryptographic Failures | Sensitive data exposure. Encrypt at rest and in transit. |
| A03 | Injection | SQL, NoSQL, OS command injection. Use parameterized queries. |
| A04 | Insecure Design | Missing rate limiting, missing brute-force protection. |
| A05 | Security Misconfiguration | Default credentials, unnecessary features, verbose errors. |
| A06 | Vulnerable Components | Outdated libraries, unpatched dependencies. |
| A07 | Auth Failures | Weak passwords, credential stuffing, session fixation. |
| A08 | Data Integrity Failures | Unverified software updates, CI/CD without integrity checks. |
| A09 | Logging Failures | Insufficient logging of security events, no alerting. |
| A10 | SSRF | Server makes requests to user-controlled URLs without validation. |

---

## Anti-Patterns

- **MD5 or SHA1 for passwords** — These are fast hashes designed for checksums. GPU clusters can crack billions per second. Use bcrypt, Argon2, or scrypt.

- **Rolling your own cryptography** — The details of crypto are subtle. Use established libraries. The NIST competition winners and widely-used libraries have been audited by experts.

- **Trusting client-side validation** — Client-side validation is for UX only. Attackers can bypass it with curl, Postman, or browser dev tools. Always validate server-side.

- **Blocklist input validation** — You cannot enumerate all malicious inputs. An allowlist of valid inputs is always correct.

- **Storing passwords in plaintext** — If your database is breached, all passwords are exposed. Always hash passwords with a slow algorithm (bcrypt, Argon2).

- **Using localhost for security** — In containerized environments, localhost is shared. Use proper authentication even for internal services.

- **Logging sensitive data** — Never log passwords, tokens, credit card numbers, or PII. Log authentication failures without logging credentials.

---

## Quick Reference

| Vulnerability | Prevention |
|-------------|------------|
| SQL Injection | Parameterized queries only |
| XSS | Output encoding, CSP header |
| CSRF | CSRF token + SameSite cookie |
| Password breach | bcrypt/Argon2 (slow hash, salt) |
| JWT forgery | Verify signature, check exp claim |
| File upload RCE | Validate MIME, store outside web root |
| SSRF | URL validation, block private IPs |
| Credential stuffing | Rate limiting, MFA |

### SAST/DAST Tooling

```bash
# SAST — Static Application Security Testing (run in CI)
# Python
pip install bandit
bandit -r ./src

# JavaScript/TypeScript
npm install --save-dev eslint-plugin-security
npx eslint --plugin security .

# DAST — Dynamic Application Security Testing (run against running app)
# OWASP ZAP (Zed Attack Proxy)
docker run -t owasp/zap2docker-stable zap-baseline.py -t https://staging.example.com

# Dependency scanning
# Python
pip install safety
safety check

# Node.js
npm audit
```
