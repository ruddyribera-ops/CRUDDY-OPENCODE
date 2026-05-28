---
description: Reliability reviewer â€” checks network calls, error handling, observability
condition: fetch\(|await\s+fetch|\.get\(|\.post\(|try\s*{|except\s*\w+:|catch\s*\(|axios\.|requests\.
scope: "tool:edit(**/*.{py,ts,tsx,js,jsx,go})"
severity: error
triggered_by: reliability concern
---

# Reliability Review (Auto-Reviewer Persona)

Checks every change for reliability patterns. Triggered on every push.

## What it catches

| Pattern | Why |
|---------|-----|
| Network calls without timeout | Hanging connections = cascading failures |
| Network calls without retry | Transient failures become permanent |
| try/catch that doesn't re-raise or log | Silent failures in production |
| Missing observability | No way to debug in production |
| Hardcoded timeouts | Inflexible, can't tune per environment |

## Fix

- Every network call: `timeout=5000` and wrap in retry logic
- Every catch: log the error with context before handling
- Every feature: add at least one structured log line
- Timeouts: use env vars or config, not hardcoded values
