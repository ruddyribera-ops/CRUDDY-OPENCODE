---
description: No empty except/catch handlers
condition: except\s*(Exception)?\s*:\s*\n\s*pass|catch\s*\([^)]*\)\s*\{\s*\}
multiline: true
scope: "tool:edit(**/*.{py,ts,js})"
severity: error
triggered_by: empty error handler
---

# No Empty Error Handlers

Never leave empty except or catch blocks. At minimum log the error.

## Fix
```python
except Exception as e:
    print(f"Warning: {e}")
```
If truly expected, add a comment explaining why.
