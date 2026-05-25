---
description: Security reviewer — checks for common vulnerabilities in every change
condition: fetch\(|await\s+\w+\(|\.execute\(|eval\(|exec\(|subprocess|os\.system|\.innerHTML|dangerouslySetInnerHTML
scope: "tool:edit(**/*.{py,ts,tsx,js,jsx,go,php})"
severity: error
triggered_by: potential security issue
---

# Security Review (Auto-Reviewer Persona)

Checks every change for common security issues. Triggered on every push.

## What it catches

| Pattern | Why |
|---------|-----|
| `fetch()` without timeout | Network calls that hang forever → DoS vector |
| `os.system()` / `subprocess.call()` with user input | Command injection |
| `eval()` / `exec()` | Code injection |
| `innerHTML` / `dangerouslySetInnerHTML` | XSS vector |
| `execute()` raw SQL without parameters | SQL injection |

## Fix

- Network calls: add timeout and retry
- Shell: use parameterized APIs (`subprocess.run(["cmd", arg])`)
- HTML: use `textContent` / safe rendering
- SQL: use parameterized queries or ORM
