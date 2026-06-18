---
name: review-loop
description: Auto-review changed files until they pass quality gates. Inspired by Greptile + GrepLoop. Triggers: review my code, check for issues, run quality checks, find bugs, gate check.
When: Run after any feature is built, before declaring done. Runs checks for debug artifacts, empty handlers, placeholders, long functions, duplicates.
Do not: Use as replacement for actual test suites. Ignore review results — fix each issue it finds.
Commands:
  python scripts/review-loop.py run <path> [--max-cycles 3]
  python scripts/review-loop.py list
---