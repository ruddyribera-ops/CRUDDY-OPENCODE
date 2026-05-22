---
name: env_security
description: Environment variable security, secret management, and safe deployment practices
type: rules
source: security-basics/SKILL.md (environment section)
---

# Environment Security

## Core Rules

### 1. Never Hardcode Secrets

❌ **Forbidden:**
```python
API_KEY = "sk-abc123..."  # in source code
DATABASE_URL = "postgres://user:pass@host/db"  # in source code
```

✅ **Required:**
```python
import os
API_KEY = os.environ.get("API_KEY")  # runtime only
DATABASE_URL = os.environ.get("DATABASE_URL")
```

### 2. Use `.env` for Local Development Only

- Create `.env.example` with all variable names, but NO real values
- `.env` must be in `.gitignore` (verify this before committing)
- Real values come from: CI/CD secrets, Railway dashboard, cloud provider secrets manager

### 3. Validate Environment Variables at Startup

```python
# Python example — fail fast if required env vars missing
import os

required = ["DATABASE_URL", "API_KEY", "SECRET_KEY"]
missing = [v for v in required if not os.environ.get(v)]
if missing:
    raise ValueError(f"Missing required env vars: {', '.join(missing)}")
```

### 4. Environment-Specific Defaults

| Environment | Rule |
|-------------|------|
| Development | Can have defaults for convenience, but `.env` overrides |
| Staging | Same as production — no defaults, real values only |
| Production | No defaults. Missing vars = startup failure (fail fast) |

---

## Secret Scanning (Pre-Commit)

**Before any commit**, check for leaked secrets:

```bash
# Detect potential secrets in diff
git diff --staged | grep -E "(sk-|password|secret|api_key|token)="

# Or use a tool:
npx secretlint "**/*"
```

If a secret is detected:
1. Rotate the secret immediately
2. Remove from git history if already committed (see `feedback_git_divergent_remote.md`)
3. Add the pattern to `.gitignore`

---

## Railway-Specific Rules

| Variable | Where to Set |
|----------|-------------|
| `DATABASE_URL` | Railway PostgreSQL panel |
| `API_KEY` | Railway Variables panel (not in code) |
| `SECRET_KEY` | Railway Variables panel |
| `RAILWAY_GIT_COMMIT_SHA` | Automatic (read-only) |

**Never** set secrets in:
- Code comments
- Git history
- Public repositories
- Docker image layers (for multi-stage builds, use build-time args)

---

## Logging & Error Messages

❌ **Never log:**
- Passwords or partial passwords
- API keys or tokens
- Full database URLs (contains credentials)
- Session IDs in plain logs

✅ **Safe to log:**
- User ID (not email unless user is informed)
- Request IDs (for tracing)
- Error types (not full stack traces in production)

---

## Deployment Checklist

Before any deploy:

- [ ] All secrets in environment variables (not in code)
- [ ] `.env.example` exists with all variable names, no real values
- [ ] `.gitignore` includes `.env`
- [ ] Secrets rotated if ever exposed
- [ ] Startup validation: missing required vars → fail immediately
- [ ] No `console.log` or print statements in production output

---

## Why

Exposed secrets lead to unauthorized access, data breaches, and financial loss. The fix is trivial (env vars) — the cost of not using them is catastrophic.

---

## How to Apply

1. For any new code, check that secrets come from `os.environ.get()` or `process.env`
2. Before committing, run secret scan on staged diff
3. On Railway, verify secrets are in the Variables panel, not in code
4. If a secret is accidentally exposed: rotate immediately, document in `feedback_*.md`, and treat as a security incident
