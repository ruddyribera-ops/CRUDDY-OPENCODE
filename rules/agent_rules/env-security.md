---
description: No API keys, tokens, or secrets in memory files — use .env or env vars only
condition: sk-[a-zA-Z0-9_-]{10,}|api_key\s*[=:]|SECRET\s*[=:]|token\s*[=:]\s*[a-zA-Z0-9_-]{20,}
scope: "tool:edit(**/memory/*.md), tool:write(**/memory/*.md)"
severity: error
triggered_by: API key in memory file
---

# No Secrets in Memory Files

**Never write API keys, tokens, passwords, or secrets in ANY memory file.**

## Why
- Memory files get indexed and loaded during sessions — secrets leak into agent context
- Template repos can accidentally expose keys to GitHub
- `.md` files are plaintext — no encryption

## Fix
- Replace the key with `(key in .env)` or `(key stored in Windows env var)`
- Never paste the actual value
- Example: `MiniMax API key (stored in .env)` not `MiniMax API key (sk-abc123...)`

## What this catches
- `sk-...` (OpenAI/MiniMax API key prefix)
- `api_key: abc123...`
- `SECRET: ...`
- Any token-like string over 20 characters

This rule is non-negotiable. Violation = immediate fix required.
