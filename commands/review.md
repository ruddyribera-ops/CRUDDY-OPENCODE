---
description: Run a code quality review loop on changed files
usage: /review [path] [--max-cycles 3]
---

# /review — Auto Review Loop

Runs the review-loop script on specified files or directory. Iterates until clean or max cycles reached.

## Steps
1. Run `python $CONFIG/scripts/review-loop.py run <path> --max-cycles 3`
2. If issues found, fix them
3. If clean, report pass
4. Max 3 cycles — don't let it loop forever

## What it checks
- console.log / print() left in code
- Empty except/catch handlers
- TODO/FIXME placeholders
- Overly long functions (>60 lines)
