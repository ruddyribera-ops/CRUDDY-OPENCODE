---
description: No fixed timers in tests — use polling instead
condition: time\.sleep|setTimeout\(|wait_for_timeout
scope: "tool:edit(**/*.test.{py,ts,js}), tool:edit(**/*_test.{py,ts,js})"
severity: warning
triggered_by: fixed timer in test
---

# No Timer-Based Waiting in Tests

Don't use time.sleep or setTimeout for waiting in tests. Poll for the expected condition instead.

## Fix
```python
page.wait_for_selector(".loaded", timeout=10000)
```
