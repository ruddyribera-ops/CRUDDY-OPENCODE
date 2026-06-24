---
name: api-patterns
description: REST API design patterns, error handling, and response format standards. Use when designing or reviewing REST APIs, error handling, pagination, versioning. Triggers: REST API, REST, HTTP, JSON, error response, pagination, versioning, idempotency, rate limit, status code.
---

# API Patterns

## When to use this

Load this skill when designing a new REST API, reviewing API code for correctness, implementing error handling, or adding pagination and versioning to existing endpoints.

---

## Core Principles

1. **REST is resource-oriented, not action-oriented** — URLs represent resources (nouns), not actions (verbs). Use HTTP methods to express operations: GET for read, POST for create, PUT/PATCH for update, DELETE for delete.

2. **Return the correct status codes** — HTTP status codes communicate the result of a request. Misusing them (returning 200 for errors) breaks client expectations and monitoring.

3. **RFC 7807 Problem Details for errors** — Standardize error responses across your entire API using a machine-readable format that clients can parse consistently.

4. **Version before breaking changes** — When an API contract must change in a breaking way, introduce a new version. Never break existing clients.

5. **Idempotency keys prevent duplicate operations** — For POST and PUT requests that create or modify data, accept an idempotency key so retries do not create duplicate records.

6. **Pagination prevents unbounded responses** — Never return all records for a collection endpoint. Use cursor or offset pagination with a sensible default limit.

7. **Rate limit headers are a contract** — Tell clients how many requests they have remaining and when to retry. This prevents accidental DoS of your own API.

---

## Patterns

### RESTful URL Design

```bash
# GOOD: Resource-oriented URLs (nouns)
GET    /users              # List users
GET    /users/123          # Get user 123
POST   /users              # Create user
PUT    /users/123          # Replace user 123
PATCH  /users/123           # Update user 123 (partial)
DELETE /users/123          # Delete user 123

GET    /users/123/orders   # Get orders for user 123
POST   /users/123/orders   # Create order for user 123

# GOOD: Actions as query parameters for filtering
GET    /users?status=active&role=admin
GET    /users?sort=created_at&order=desc

# BAD: Verbs in URLs
POST   /users/create       # Wrong — POST creates resources
POST   /users/123/delete   # Wrong — DELETE removes resources
GET    /getUser/123        # Wrong — GET retrieves resources
GET    /fetchOrdersByUser?user=123  # Wrong — use path resources
```

### Standard Response Format (Success)

```json
// Single resource response
{
  "data": {
    "id": "123",
    "type": "user",
    "attributes": {
      "email": "alice@example.com",
      "name": "Alice Smith",
      "createdAt": "2024-01-15T10:30:00Z"
    }
  },
  "meta": {
    "requestId": "req_abc123"
  }
}

// Collection response (paginated)
{
  "data": [
    { "id": "123", "type": "user", "attributes": { ... } },
    { "id": "456", "type": "user", "attributes": { ... } }
  ],
  "meta": {
    "total": 1523,
    "page": 1,
    "perPage": 20,
    "requestId": "req_abc123"
  },
  "links": {
    "self": "https://api.example.com/users?page=1",
    "next": "https://api.example.com/users?page=2",
    "prev": null,
    "first": "https://api.example.com/users?page=1",
    "last": "https://api.example.com/users?page=77"
  }
}
```

### RFC 7807 Problem Details (Error Response)

```json
// Error response following RFC 7807 Problem Details
// Content-Type: application/problem+json

{
  "type": "https://api.example.com/problems/validation-error",
  "title": "Validation Error",
  "status": 422,
  "detail": "The request body contains invalid fields.",
  "instance": "/users",
  "requestId": "req_abc123",
  "errors": [
    {
      "field": "email",
      "message": "Must be a valid email address",
      "code": "invalid_format",
      "value": "not-an-email"
    },
    {
      "field": "age",
      "message": "Must be a positive integer",
      "code": "invalid_type",
      "value": "-5"
    }
  ]
}
```

### HTTP Status Code Reference

| Code | Meaning | When to Use |
|------|---------|------------|
| 200 | OK | Successful GET, PATCH, PUT |
| 201 | Created | Successful POST that creates a resource |
| 202 | Accepted | Request accepted but processing is async |
| 204 | No Content | Successful DELETE or PUT with no body |
| 400 | Bad Request | Malformed request syntax |
| 401 | Unauthorized | Missing or invalid authentication |
| 403 | Forbidden | Authenticated but not authorized |
| 404 | Not Found | Resource does not exist |
| 409 | Conflict | Resource state conflict (duplicate, version mismatch) |
| 422 | Unprocessable Entity | Validation errors (semantic) |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Unexpected server error |
| 502 | Bad Gateway | Upstream service error |
| 503 | Service Unavailable | Server temporarily unavailable |

### Cursor Pagination

```json
// Cursor pagination (better for large/dynamic datasets)
// Use when: dataset is large, data changes frequently, consistent ordering is important

// Request
GET /users?limit=20&cursor=eyJpZCI6MTIzfQ

// Response
{
  "data": [...],
  "meta": {
    "hasMore": true,
    "nextCursor": "eyJpZCI6MTQzfQ",
    "prevCursor": "eyJpZCI6MTAzfQ",
    "total": null
  }
}
```

```python
# Cursor pagination implementation (Python/Flask)
from base64 import b64encode, b64decode
import json

def encode_cursor(record):
    """Encode a record's cursor from its ID and timestamp."""
    return b64encode(json.dumps({
        "id": record.id,
        "ts": record.created_at.isoformat()
    }).encode()).decode()

def decode_cursor(cursor):
    """Decode a cursor back to filter values."""
    return json.loads(b64decode(cursor.encode()).decode())

@app.get("/users")
def list_users():
    limit = min(int(request.args.get("limit", 20)), 100)
    cursor = request.args.get("cursor")

    query = User.query.order_by(User.id.asc())

    if cursor:
        decoded = decode_cursor(cursor)
        query = query.filter(User.id > decoded["id"])

    users = query.limit(limit + 1).all()  # Fetch one extra to check hasMore
    has_more = len(users) > limit
    users = users[:limit]

    next_cursor = encode_cursor(users[-1]) if has_more else None

    return {
        "data": [user.to_dict() for user in users],
        "meta": {
            "hasMore": has_more,
            "nextCursor": next_cursor
        }
    }
```

### Idempotency Key Pattern

```json
// Client sends an idempotency key with POST requests
// Server stores results keyed by idempotency key
// If the same key is seen again, return the cached result

// Request
POST /payments
Idempotency-Key: idk_7a9b3c2d
Content-Type: application/json

{
  "amount": 99.99,
  "currency": "USD",
  "source": "card_abc123"
}

// Response
HTTP/1.1 201 Created
Idempotency-Key: idk_7a9b3c2d

{
  "data": {
    "id": "ch_xyz789",
    "amount": 99.99,
    "status": "succeeded"
  }
}

// If client retries with the same key, response is:
// HTTP/1.1 201 Created (or 200 OK) with the original response body
```

```python
# Idempotency implementation
from functools import wraps
import redis
import hashlib

r = redis.Redis()

def idempotent(ttl_seconds=86400):
    """Decorator that deduplicates requests by idempotency key."""
    def decorator(f):
        @wraps(f)
        def wrapper(request, *args, **kwargs):
            key = request.headers.get("Idempotency-Key")
            if not key:
                return f(request, *args, **kwargs)

            # Hash the key to avoid storing sensitive values
            cache_key = f"idempotent:{hashlib.sha256(key.encode()).hexdigest()}"

            # Check cache
            cached = r.get(cache_key)
            if cached:
                return json.loads(cached)

            # Execute and cache
            response = f(request, *args, **kwargs)
            r.setex(cache_key, ttl_seconds, json.dumps(response))

            return response
        return wrapper
    return decorator
```

### API Versioning

```bash
# URL path versioning (most common, most explicit)
GET /v1/users/123
GET /v2/users/123

# Header versioning (cleaner URLs, requires custom header)
GET /users/123
API-Version: 2024-01-01

# Deprecation header (tell clients when to migrate)
GET /v1/users
Response Headers:
  Deprecation: true
  Sunset: Sat, 01 Mar 2025 00:00:00 GMT
  Link: <https://api.example.com/v2/users>; rel="successor-version"
```

```python
# Version routing (Flask)
from functools import wraps

def version(required):
    def decorator(f):
        @wraps(f)
        def wrapper(request, *args, **kwargs):
            # Check API-Version header or URL
            version = request.headers.get("API-Version") or "v1"

            if version != required:
                return {
                    "error": "unsupported_version",
                    "message": f"Version {required} is not supported. Use {version}."
                }, 400

            return f(request, *args, **kwargs)
        return wrapper
    return decorator

@app.get("/v1/users/<int:user_id>")
@version("v1")
def get_user_v1(user_id):
    return User.query.get_or_404(user_id).to_dict()

@app.get("/v2/users/<int:user_id>")
@version("v2")
def get_user_v2(user_id):
    # v2 includes additional fields (e.g., preferences)
    return User.query.get_or_404(user_id).to_dict_v2()
```

### Rate Limiting Headers

```python
# Rate limiting implementation
from flask import request, jsonify

RATE_LIMIT = 100  # requests per window
RATE_WINDOW = 60  # seconds

def rate_limit_key():
    """Identify the client by API key or IP."""
    return request.headers.get("X-API-Key") or request.remote_addr

@app.before_request
def check_rate_limit():
    key = f"rate:{rate_limit_key()}"
    current = r.get(key)

    if current and int(current) >= RATE_LIMIT:
        return jsonify({
            "error": "rate_limit_exceeded",
            "message": f"Rate limit of {RATE_LIMIT} requests per {RATE_WINDOW}s exceeded",
            "retryAfter": r.ttl(key)
        }), 429

    pipe = r.pipeline()
    pipe.incr(key)
    pipe.expire(key, RATE_WINDOW)
    pipe.execute()

@app.after_request
def add_rate_limit_headers(response):
    key = f"rate:{rate_limit_key()}"
    remaining = RATE_LIMIT - int(r.get(key) or 0)
    response.headers["X-RateLimit-Limit"] = str(RATE_LIMIT)
    response.headers["X-RateLimit-Remaining"] = str(max(0, remaining))
    response.headers["X-RateLimit-Reset"] = str(int(time.time()) + RATE_WINDOW)
    return response
```

---

## Anti-Patterns

- **Using verbs in URLs** — `POST /createUser` violates REST principles and mixes HTTP methods with URL design. Use nouns and HTTP methods.

- **Returning 200 for errors** — A 200 status code means "success". Returning it for errors breaks client error handling, monitoring, and alerting.

- **Exposing internal error details** — Stack traces, SQL errors, and internal paths should never be in API responses. They leak security information.

- **Breaking changes without versioning** — Removing a field, changing a field type, or changing behavior without a new version breaks existing clients.

- **No pagination on collection endpoints** — Returning all records from a large table can cause timeouts, memory exhaustion, and broken clients.

- **Not handling concurrent updates** — Without optimistic locking (ETags) or last-write-wins semantics, concurrent updates can silently overwrite each other.

- **Returning overly verbose error messages** — Error messages should be actionable for the API consumer. "Something went wrong" is not actionable.

---

## Quick Reference

| Pattern | Correct | Wrong |
|---------|---------|-------|
| URLs | `/users/123` | `/getUser?id=123` |
| Error status | 404 Not Found | 200 with `error: "not found"` |
| Error body | RFC 7807 Problem Details | `"error": "something went wrong"` |
| Collection pagination | Cursor or offset with limit | No pagination (all records) |
| Versioning | URL path (`/v1/`) or header | No versioning (breaks clients) |
| POST retry safety | Idempotency key | No idempotency (duplicates) |
| Rate limit | Headers (X-RateLimit-*) | No rate limit info |

### Error Response Template

```json
{
  "type": "https://api.example.com/problems/[error-type]",
  "title": "[Short human-readable title]",
  "status": [HTTP status code],
  "detail": "[Specific description of what went wrong]",
  "instance": "[The request path]",
  "requestId": "[Unique request identifier for tracing]"
}
```

### Required Response Headers

```
Content-Type: application/json
X-Request-ID: [UUID — for log correlation]
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 99
X-RateLimit-Reset: 1700000000
```
