---
name: no-silent-failure
description: "Never bare except:pass or catch{}. Always log + re-raise minimum. Structured logging with trace IDs. Use when writing error handling, designing logging, or debugging silent failures. Triggers: error handling, silent failure, exception, logging, trace ID, re-raise, alert fatigue, error categorization."
triggers:
  - "no-silent-failure"
  - "no silent failure"
  - "when to use no silent failure"
  - "how to no silent failure"
  - "no silent failure examples"
  - "no silent failure pattern"
applies_to:
  - "main-coordinator"
---


# No Silent Failure

## When to use this

Load this skill whenever you write error handling code, design logging infrastructure, configure alerting thresholds, or investigate a production incident where an error was swallowed and nobody noticed.

---

## Core Principles

1. **Never bare `except: pass` or `catch {}`** — Silent error absorption makes bugs invisible. At minimum, log the error with full context before continuing.

2. **Re-raise with context** — When catching an exception, always raise a new error that includes what you were trying to do: `raise NewError("Failed to do X") from originalError`.

3. **Structured logging with trace IDs** — Every log entry must include `trace_id`, `request_id`, or equivalent so you can correlate logs across services.

4. **Categorize errors: retryable vs non-retryable** — Network timeouts are retryable; invalid input is not. Alerting on retryable errors that are being handled by retry logic creates noise.

5. **Alert thresholds, not every error** — Alert on error rate (e.g., >1% of requests in 5 minutes), not on every individual error. Alert fatigue kills real alerts.

6. **Error handling must be explicit in code review** — A code reviewer should be able to see within 5 seconds that every `try` block has a corresponding `catch` with appropriate action.

7. **Test your error paths** — If you do not have tests that exercise the `catch` branch, you do not know if it works.

---

## Patterns

### Python: Proper Exception Handling

```python
import logging
import structlog
from typing import Optional

# Configure structured logging
structlog.configure(
    processors=[
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer(),
    ]
)
logger = structlog.get_logger()

def fetch_user(user_id: str, trace_id: Optional[str] = None) -> dict:
    """Fetch a user by ID with proper error handling."""
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            # This is not an error — return None, don't raise
            return None
        return {
            "id": user.id,
            "email": user.email,
            "trace_id": trace_id,
        }
    except db.OperationalError as e:
        # Retryable error — log, re-raise with context, do NOT swallow
        logger.error(
            "database.connection_failed",
            user_id=user_id,
            trace_id=trace_id,
            error=str(e),
            error_type=type(e).__name__,
        )
        raise UserFetchError(f"Failed to fetch user {user_id}") from e
    except Exception as e:
        # Non-retryable error — log, wrap, re-raise
        logger.exception(
            "user.fetch_failed",
            user_id=user_id,
            trace_id=trace_id,
        )
        raise UserFetchError(f"Unexpected error fetching user {user_id}") from e
```

### Python: Global Exception Handler (FastAPI example)

```python
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
import structlog

app = FastAPI()
logger = structlog.get_logger()

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Catches unhandled exceptions — log everything, hide details from client."""
    trace_id = request.headers.get("X-Trace-ID", "unknown")
    logger.error(
        "unhandled_exception",
        path=request.url.path,
        method=request.method,
        trace_id=trace_id,
        error=str(exc),
        error_type=type(exc).__name__,
        exc_info=True,  # includes stack trace
    )
    # Return generic error to client — never leak internal details
    return JSONResponse(
        status_code=500,
        content={
            "error": "internal_server_error",
            "message": "An unexpected error occurred. Please try again.",
            "trace_id": trace_id,
        },
    )
```

### Python: Structured Log with Trace ID (Production Pattern)

```python
import logging
from contextvars import ContextVar
from functools import wraps

trace_id_var: ContextVar[str] = ContextVar("trace_id", default="no-trace")

def with_trace_id(func):
    """Decorator that ensures every log entry has a trace_id."""
    @wraps(func)
    def wrapper(*args, **kwargs):
        trace_id = kwargs.pop("trace_id", None) or trace_id_var.get()
        # Attach trace_id to all subsequent log entries in this coroutine
        token = trace_id_var.set(trace_id)
        try:
            return func(*args, trace_id=trace_id, **kwargs)
        finally:
            trace_id_var.reset(token)
    return wrapper

# Usage in API handler:
@app.get("/users/{user_id}")
@with_trace_id
def get_user(user_id: str, trace_id: str = None):
    logger.info("get_user.start", user_id=user_id, trace_id=trace_id)
    try:
        user = fetch_user(user_id, trace_id=trace_id)
        logger.info("get_user.success", user_id=user_id, trace_id=trace_id)
        return user
    except UserFetchError as e:
        logger.warning("get_user.not_found", user_id=user_id, trace_id=trace_id)
        raise HTTPException(status_code=404, detail="User not found")
```

### TypeScript/Node.js: Proper Error Handling

```typescript
import { AsyncLocalStorage } from "async_hooks";

interface TraceContext {
  traceId: string;
  requestId: string;
  userId?: string;
}

const traceStorage = new AsyncLocalStorage<TraceContext>();

// Structured logger
function log(level: "info" | "warn" | "error", msg: string, data: Record<string, unknown>) {
  const ctx = traceStorage.getStore();
  console.log(JSON.stringify({
    level,
    msg,
    timestamp: new Date().toISOString(),
    ...(ctx ?? {}),
    ...data,
  }));
}

// Safe async handler wrapper
function withErrorHandler<T>(
  fn: (ctx: TraceContext) => Promise<T>
): (ctx: TraceContext) => Promise<T> {
  return async (ctx: TraceContext) => {
    try {
      return await fn(ctx);
    } catch (error) {
      const err = error as Error;
      log("error", "unhandled_exception", {
        message: err.message,
        stack: err.stack,
        name: err.name,
      });
      // Re-throw with context — DO NOT swallow
      throw new AppError(`Operation failed: ${err.message}`, { cause: error });
    }
  };
}

// Usage in route handler:
app.get("/users/:id", async (req, res) => {
  const ctx = { traceId: req.headers["x-trace-id"] as string, requestId: req.id };
  const handler = withErrorHandler(async (ctx) => {
    const user = await fetchUser(req.params.id, ctx.traceId);
    if (!user) throw new NotFoundError(`User ${req.params.id} not found`);
    return user;
  });
  const result = await handler(ctx);
  res.json(result);
});
```

### Error Categorization and Alerting (Python)

```python
from enum import Enum
from dataclasses import dataclass

class ErrorCategory(Enum):
    RETRYABLE = "retryable"      # Network issues, timeouts — retry will fix
    CLIENT_ERROR = "client"      # Bad input — retry won't fix, alert only if rate high
    SYSTEM_ERROR = "system"      # Bugs, bad logic — always alert
    SECURITY = "security"        # Auth failures, injection attempts — always alert

@dataclass
class AlertPolicy:
    category: ErrorCategory
    alert_threshold: float  # e.g., 0.01 = alert if >1% of requests
    alert_window_seconds: int = 300

# Prometheus alerting rule (Prometheus alert format):
# - name: HighErrorRate
#   expr: |
#     sum(rate(http_requests_total{status=~"5.."}[5m]))
#     / sum(rate(http_requests_total[5m])) > 0.01
#   annotations:
#     summary: "Error rate > 1% for 5 minutes"
```

### Retry with Exponential Backoff (Retryable Errors Only)

```python
import time
import functools

def retry(
    max_attempts: int = 3,
    base_delay: float = 1.0,
    max_delay: float = 10.0,
    exceptions=(ConnectionError, TimeoutError)
):
    """Retry decorator for retryable errors with exponential backoff."""
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(max_attempts):
                try:
                    return func(*args, **kwargs)
                except exceptions as e:
                    if attempt == max_attempts - 1:
                        raise  # Let it propagate — do not swallow
                    delay = min(base_delay * (2 ** attempt), max_delay)
                    logger.warning(
                        "retry.attempt",
                        func=func.__name__,
                        attempt=attempt + 1,
                        max_attempts=max_attempts,
                        delay=delay,
                        error=str(e),
                    )
                    time.sleep(delay)
        return wrapper
    return decorator

# Usage — only on retryable errors:
@retry(max_attempts=3, exceptions=(ConnectionError, TimeoutError))
def call_external_api(url: str) -> dict:
    response = requests.get(url, timeout=5)
    return response.json()
```

---

## Anti-Patterns

- **`except: pass`** — The most dangerous pattern. Errors are silently discarded, bugs are invisible, and users get wrong results with no indication something failed.

- **Catching exceptions without logging** — Even without `pass`, if you catch an exception and only re-raise a generic error, you have lost the original stack trace and context.

- **Logging errors without trace IDs** — Logs that cannot be correlated to a specific request are nearly useless in production debugging. Every log must have `trace_id` or equivalent.

- **Alerting on every error** — If your alerting system fires on every 404 or every network timeout, the on-call engineer will disable alerts. Only alert on rates or thresholds.

- **Swallowing errors "to make tests pass"** — A test that catches an exception and asserts it was the right exception is not the same as letting the exception propagate. If the error is "unexpected", the test should fail.

- **`raise Exception("error")` without chaining** — When you re-raise, always chain with `from originalError` so the full stack trace is preserved.

- **No distinction between retryable and non-retryable errors** — If you retry invalid input, you waste resources and delay the error response to the user.

---

## Quick Reference

| Anti-Pattern | Fix |
|-------------|-----|
| `except: pass` | Log + re-raise (or handle explicitly) |
| `catch {}` (empty) | Log at minimum, ideally re-throw |
| `raise Error("msg")` without chaining | `raise NewError("msg") from original` |
| Logs without trace_id | Add trace_id to every log entry |
| Alert on every error | Alert on error rate, not per-error |
| No error categorization | Distinguish retryable vs non-retryable |
| Tests that swallow errors | Let unexpected errors propagate; test the catch branch explicitly |

### Python Error Handler Checklist

```python
# Every try block needs:
# 1. Specific exception types (not bare except:)
# 2. Logging with full context (trace_id, user_id, what failed)
# 3. Re-raise with chained exception (raise NewError() from e)
# 4. OR explicit handling with clear recovery action

try:
    result = risky_operation()
except ValidationError as e:
    logger.warning("validation.failed", input=user_input, error=str(e))
    raise  # Re-raise to let caller handle
except ConnectionError as e:
    logger.error("connection.failed", operation="risky_operation", error=str(e))
    raise NewServiceError("Service unavailable") from e  # Chain, add context
except Exception as e:
    logger.exception("unexpected.error")  # logs full traceback
    raise  # or raise with context
```

### Trace ID Injection in HTTP Headers

```python
# Middleware to inject trace_id in every request
@app.middleware("http")
async def trace_middleware(request: Request, call_next):
    trace_id = request.headers.get("X-Trace-ID", generate_uuid())
    request.state.trace_id = trace_id

    # Make trace_id available in logging
    with bind(trace_id=trace_id, request_id=request.id):
        response = await call_next(request)

    response.headers["X-Trace-ID"] = trace_id
    return response
```
