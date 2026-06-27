---
description: No console.log or print() left in production code
condition: console\.log|print\(
scope: "tool:edit(**/*.{ts,tsx,js,jsx,py})"
severity: warning
triggered_by: debug output in code
---

# No Debug Artifacts

Remove console.log, print(), and debug output before committing.

## Fix
- Remove the line or gate behind a verbose flag
- For logging, use the project's logger
- CLI tools with intentional print output are exempt
