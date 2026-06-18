---
name: no-silent-failure
description: Never bare except:pass or catch{}. Always log + re-raise minimum. Structured logging with trace IDs.
triggers: [error, exception, catch, try-except, error-handling, logging, observability, trace-id]
---

# No Silent Failures

## What it does
Forbids bare `except: pass` / `catch {}` / `try { ... } catch {}` patterns. Requires that every caught error is logged (with context) and either handled meaningfully or re-raised. Silent failures hide the bugs that compound into outages.

## When to use
- Writing any `try/catch` or `try/except` block
- Reviewing code for swallowed errors
- Designing error-handling for a service boundary
- Debugging "why didn't this work" — silent failures are the most common cause

## Rules

1. **Never `except: pass`.** Always at minimum log the error with context. Re-raise if you can't handle it.
2. **Never `catch (e) {}` (empty catch).** Same: log + re-raise or handle with intent.
3. **Catch specific exceptions, not `Exception` / `Throwable`.** Bare `except Exception` catches `KeyboardInterrupt`, `SystemExit`, `MemoryError` — usually not what you want.
4. **Always include a trace ID in the log.** Enables correlation across services. Use `contextvars` or middleware to propagate.
5. **Re-raise with `raise from`.** Preserves the original traceback. `except Foo as e: raise Bar() from e` — not `raise Bar()` alone.
6. **If you handle, handle meaningfully.** "Meaningful" = retry with backoff, fall back to a known-good default, or convert to a user-visible error. Not "swallow and continue."
7. **Log at the boundary, not deep in the call stack.** Internal helpers should `raise`; the API boundary logs and converts to HTTP status.

## Anti-patterns

- ❌ `try: ... except: pass` — bug never surfaces
- ❌ `try: ... except Exception: continue` — same
- ❌ `catch (err) { /* TODO: handle later */ }` — TODO never gets done
- ❌ `except Exception as e: print(e)` — print goes to stdout, not logs, no context
- ❌ `except Exception: raise ValueError("failed")` — loses original traceback, should be `from e`
- ❌ Catching `Exception` to log and continue in a loop — masks the failure of N items
- ❌ Logging the error then returning `None` — caller has no way to know it failed

## Example (correct)

```python
import logging
import uuid
from contextvars import ContextVar

trace_id_var: ContextVar[str] = ContextVar('trace_id', default='-')
log = logging.getLogger(__name__)

# ✅ Specific exception, log with context, re-raise
try:
    result = risky_operation()
except TimeoutError as e:
    log.error("operation timed out", extra={
        "trace_id": trace_id_var.get(),
        "operation": "risky_operation",
        "timeout_s": 30,
    })
    raise  # or: raise ServiceUnavailable() from e

# ✅ Meaningful handling: retry with backoff
import time
for attempt in range(3):
    try:
        return call_external_api()
except RetryableError as e:
    if attempt == 2:
        log.error("api call failed after 3 attempts", extra={"trace_id": trace_id_var.get()})
        raise
    time.sleep(2 ** attempt)

# ✅ At the API boundary (FastAPI example)
from fastapi import HTTPException
@app.get("/items/{id}")
def get_item(id: int):
    try:
        return db.query(Item).filter(Item.id == id).one()
except NoResultFound:
    raise HTTPException(status_code=404, detail="item not found")
except DatabaseError as e:
    log.exception("db error fetching item", extra={"trace_id": trace_id_var.get(), "item_id": id})
    raise HTTPException(status_code=500, detail="internal error")
```

```javascript
// ✅ JavaScript / TypeScript
try {
  const result = await riskyOperation();
} catch (err) {
  logger.error('operation failed', {
    traceId: getTraceId(),
    operation: 'riskyOperation',
    err: err.message,
    stack: err.stack,
  });
  throw err;  // or convert to user-visible error
}

// ❌ NEVER
try {
  await riskyOperation();
} catch (err) {
  // silent
}
```

## References

- Python exceptions: https://docs.python.org/3/tutorial/errors.html
- Structured logging: https://www.structlog.org/
- `verification_depth` rule — runtime evidence over file-existence
- `feedback_errors` memory — documented error-handling patterns
