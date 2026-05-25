---
description: Check code against agent rules (empty handlers, debug artifacts, SQLite on Railway, etc.)
usage: /rules [path]
---

# /rules — Agent Rules Check

Scans the current directory (or specified path) against all active agent rules.

## Steps
1. Run `python $CONFIG/scripts/check-rules.py check <path>`
2. If violations found: fix errors first, then warnings
3. Re-run until 0 errors
4. Report result to user

## Available rules
- `no-empty-handlers` — catches empty except/catch blocks (error)
- `no-debug-artifacts` — catches console.log/print in production code (warning)
- `no-any-type` — catches TypeScript `any` type escapes (error)
- `no-timer-tests` — catches fixed timers in test code (warning)
- `railway-no-sqlite` — catches SQLite usage when Railway is deploy target (error)
