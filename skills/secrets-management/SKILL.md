---
name: secrets-management
description: All secrets in env vars or secret manager. .env.example for templates, never real values. Key rotation on exposure.
triggers: [secret, env, api-key, password, token, credential, dotenv, vault, key-rotation]
---

# Secrets Management

## What it does
Ensures all secrets (API keys, passwords, tokens) live in environment variables or a secret manager — never in code, config files, or git history. Defines rotation policy on suspected exposure.

## When to use
- Adding a new API integration
- Setting up environment configuration
- Reviewing code for hardcoded secrets
- Responding to a suspected credential leak
- Setting up a new project or service

## Rules

1. **All secrets in env vars or a secret manager.** Never in source code, config files committed to git, or container images.
2. **`.env.example` for templates.** Contains key NAMES only (e.g., `OPENAI_API_KEY=`), no real values. Committed to git.
3. **`.env` is gitignored.** Contains real values locally. Never committed. Add to `.gitignore` on day 1 of every project.
4. **Secret manager for production.** Railway, Vercel, AWS Secrets Manager, Doppler, or HashiCorp Vault. Never bake secrets into Docker images.
5. **Minimum key length: 256 bits (32 bytes).** Generate with `openssl rand -hex 32` or the provider's key generator.
6. **Rotate keys on suspected exposure.** Compromised key → rotate within 24h, audit access logs, invalidate downstream tokens.
7. **Different secrets per environment.** Dev, staging, and prod each have their own keys. A leaked dev key ≠ prod key.
8. **Never echo secrets in logs.** Strip from log output. Use structured logging with explicit allowlist of safe-to-log fields.

## Anti-patterns

- ❌ `API_KEY = "sk-abc123..."` in any file that touches git
- ❌ `.env` committed to git
- ❌ Secrets in Docker image layers (`ENV API_KEY=...` in Dockerfile)
- ❌ Secrets in CI logs (GitHub Actions step that prints `${{ secrets.X }}`)
- ❌ Frontend `.env` with `REACT_APP_API_KEY` — bundled into the JS sent to the browser
- ❌ One shared secret across dev/staging/prod
- ❌ Reusing a secret for multiple services (rotation breaks everything)
- ❌ Storing secrets in a database in plaintext

## Example (correct)

```python
# ✅ Load from env
import os
api_key = os.environ['OPENAI_API_KEY']  # raises KeyError if missing

# ✅ Validate presence at startup
required = ['OPENAI_API_KEY', 'DATABASE_URL', 'JWT_SECRET']
missing = [k for k in required if k not in os.environ]
if missing:
    raise RuntimeError(f"Missing required env vars: {missing}")
```

```bash
# ✅ .env.example (committed)
OPENAI_API_KEY=
DATABASE_URL=
JWT_SECRET=

# ✅ .env (gitignored)
OPENAI_API_KEY=sk-proj-abc123...
DATABASE_URL=postgresql://user:pass@host:5432/db
JWT_SECRET=a1b2c3d4e5f6...   # 64 hex chars = 256 bits
```

```dockerfile
# ❌ WRONG: secret baked into image
ENV API_KEY=sk-abc123

# ✅ CORRECT: pass at runtime
# (no ENV directive, set via `docker run -e API_KEY=...` or compose)
```

## References

- OWASP Secrets Management Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
- `env_security` rule — env-var-specific patterns
- `auth-patterns` skill — for JWT/cookie secrets specifically
