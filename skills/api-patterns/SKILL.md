---
name: api-patterns
description: RESTful API design, HTTP semantics, error handling, input validation, pagination, versioning, and documentation patterns. FastAPI and Express focused.
triggers: [api, rest, endpoint, route, http, fastapi, express, nestjs, controller, handler, middleware, request, response, json, serializer, error-handler, validation, pagination, rate-limit, middleware, webhook, websocket]
---

# API Patterns

## Core Principles

1. **Consistent responses** — every endpoint returns the same shape for success and error
2. **HTTP semantics** — use the right status code, method, and headers for the operation
3. **Validate at the boundary** — all input is validated before reaching business logic
4. **Backward compatible** — never break existing clients without a version bump

---

## 1. Response Format

### Success Response

```json
{
  "data": { ... },
  "meta": {
    "request_id": "req_abc123",
    "timestamp": "2026-05-22T10:00:00Z"
  }
}
```

### List Response (Paginated)

```json
{
  "data": [ ... ],
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 142,
    "total_pages": 8,
    "has_next": true,
    "has_prev": false
  }
}
```

### Error Response

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email is required",
    "details": {
      "field": "email",
      "reason": "required"
    }
  },
  "meta": {
    "request_id": "req_abc123"
  }
}
```

---

## 2. HTTP Status Code Usage

| Code | When |
|------|------|
| **200 OK** | Successful GET, PUT, PATCH |
| **201 Created** | Successful POST (resource created) |
| **204 No Content** | Successful DELETE |
| **400 Bad Request** | Malformed input, validation failure |
| **401 Unauthorized** | Missing or invalid auth |
| **403 Forbidden** | Authenticated but lacks permission |
| **404 Not Found** | Resource doesn't exist |
| **409 Conflict** | Duplicate, state conflict (e.g., deleting non-empty resource) |
| **422 Unprocessable Entity** | Semantic validation failure |
| **429 Too Many Requests** | Rate limited |
| **500 Internal Server Error** | Unhandled server error (never leak details) |

---

## 3. RESTful URL Design

### Resource Naming

```
GET    /users                    # List users
POST   /users                    # Create user
GET    /users/:id                # Get user
PATCH  /users/:id                # Update user (partial)
DELETE /users/:id                # Delete user

GET    /users/:id/orders         # Nested resource (orders for user)
POST   /users/:id/orders         # Create order for user
GET    /orders/:id               # Get specific order

GET    /users/:id/orders/:order_id/items  # Deep nesting (avoid >2 levels)
```

### Action Verbs (use sparingly)

```
POST   /users/:id/archive        # Action that doesn't fit CRUD
POST   /orders/:id/cancel        # State transition
POST   /auth/login               # Authentication
POST   /auth/register            # Registration
POST   /auth/password-reset      # Non-CRUD operation
```

### Query Parameters

```
GET /users?role=admin&status=active    # Filtering
GET /users?sort=created_at&order=desc   # Sorting
GET /users?page=2&per_page=20          # Pagination
GET /users?q=search+term               # Search
GET /users?fields=id,name,email        # Sparse fields (optional)
```

---

## 4. Input Validation

### FastAPI

```python
from pydantic import BaseModel, EmailStr, Field
from fastapi import FastAPI, HTTPException

class CreateUserRequest(BaseModel):
    email: EmailStr
    name: str = Field(min_length=1, max_length=100)
    age: int = Field(ge=18, le=120)  # age must be 18-120
    role: str = Field(default="user", pattern="^(user|admin|manager)$")

@app.post("/users", status_code=201)
async def create_user(body: CreateUserRequest, db: Database):
    existing = await db.find_user_by_email(body.email)
    if existing:
        raise HTTPException(409, detail="Email already registered")
    user = await db.create_user(body.model_dump())
    return {"data": user}
```

### Express (Zod)

```typescript
import { z } from 'zod';

const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  age: z.number().int().min(18).max(120),
  role: z.enum(['user', 'admin', 'manager']).default('user'),
});

router.post('/users', async (req, res) => {
  const result = CreateUserSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid input',
        details: result.error.flatten(),
      },
    });
  }
  // result.data is fully typed and validated
  const user = await createUser(result.data);
  return res.status(201).json({ data: user });
});
```

---

## 5. Pagination

### Cursor-Based (Keyset) — Preferred for Large Datasets

```python
@app.get("/orders")
async def list_orders(cursor: str | None = None, limit: int = 20, db: Database):
    query = db.orders.order_by(desc(orders.created_at), desc(orders.id)).limit(limit + 1)

    if cursor:
        decoded = decode_cursor(cursor)  # base64 encode: {created_at, id}
        query = query.filter(
            or_(
                orders.created_at < decoded["created_at"],
                and_(orders.created_at == decoded["created_at"], orders.id < decoded["id"])
            )
        )

    items = await query.all()
    has_next = len(items) > limit
    items = items[:limit]

    return {
        "data": items,
        "meta": {
            "has_next": has_next,
            "next_cursor": encode_cursor({"created_at": items[-1].created_at, "id": items[-1].id}) if has_next else None,
            "limit": limit,
        }
    }
```

### Offset-Based — Acceptable for Small Datasets (< 10k rows)

```python
@app.get("/products")
async def list_products(page: int = 1, per_page: int = 20, db: Database):
    offset = (page - 1) * per_page
    items = await db.products.order_by(products.name).offset(offset).limit(per_page).all()
    total = await db.products.count()

    return {
        "data": items,
        "meta": {
            "page": page,
            "per_page": per_page,
            "total": total,
            "total_pages": ceil(total / per_page),
            "has_next": offset + per_page < total,
            "has_prev": page > 1,
        }
    }
```

---

## 6. Error Handling

### Global Error Handler Pattern

```python
@app.exception_handler(Exception)
async def global_error_handler(request: Request, exc: Exception):
    request_id = request.state.request_id

    if isinstance(exc, HTTPException):
        return JSONResponse(
            status_code=exc.status_code,
            content={"error": {"code": "HTTP_ERROR", "message": exc.detail}, "meta": {"request_id": request_id}}
        )

    if isinstance(exc, ValidationError):
        return JSONResponse(
            status_code=422,
            content={"error": {"code": "VALIDATION_ERROR", "message": str(exc)}, "meta": {"request_id": request_id}}
        )

    # Log unexpected errors (never expose details to client)
    logger.exception("Unhandled error", exc_info=exc)
    return JSONResponse(
        status_code=500,
        content={"error": {"code": "INTERNAL_ERROR", "message": "An unexpected error occurred"}, "meta": {"request_id": request_id}}
    )
```

---

## 7. API Versioning

### URL Path Versioning

```
/api/v1/users
/api/v2/users
```

### When to Version

```
MAJOR: Breaking change (rename field, remove endpoint, change response type)
MINOR: Non-breaking addition (new field, new endpoint)
PATCH: Bug fix (same response shape, different values)
```

### Backward Compatibility Checklist

- [ ] Adding a field to a response → safe (old clients ignore it)
- [ ] Renaming a field → BREAKING (old clients expect old name)
- [ ] Removing a field → BREAKING
- [ ] Changing field type → BREAKING
- [ ] Making required field optional → safe
- [ ] Adding new endpoint → safe

---

## 8. Rate Limiting

```python
from fastapi import Request, HTTPException
import time

# Simple in-memory rate limiter (use Redis for production)
rate_limits = {}

@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    client_ip = request.client.host
    now = time.time()
    window = 60  # 1 minute

    # Clean old entries
    rate_limits[client_ip] = [t for t in rate_limits.get(client_ip, []) if t > now - window]

    if len(rate_limits.get(client_ip, [])) >= 100:
        raise HTTPException(429, detail="Too many requests")

    rate_limits.setdefault(client_ip, []).append(now)
    return await call_next(request)
```

---

## 9. Common Anti-Patterns

| Anti-Pattern | Why | Fix |
|-------------|-----|-----|
| Returning 200 for everything | Client can't distinguish success from error | Use correct HTTP status codes |
| Stack traces in error responses | Information leak | Log detailed errors, return generic messages |
| No request ID | Can't correlate errors across services | Generate UUID per request, return in response |
| Deeply nested resources (3+ levels) | Fragile URLs, hard to maintain | Flatten or use query parameters |
| Breaking changes without version bump | Silent client breakage | Version API or use backward-compatible changes |
| Returning all fields including internal ones | Data leak (password_hash, internal IDs) | Use serializers/DTOs to shape response |
| No pagination on list endpoints | Client must load everything | Always paginate list endpoints |
| PUT for partial updates | PUT should replace the entire resource | Use PATCH for partial updates |

---

## 10. Verification Checklist

- [ ] All responses follow consistent format (success + error)
- [ ] HTTP status codes used correctly per operation
- [ ] Input validated at API boundary before business logic
- [ ] Pagination implemented on all list endpoints
- [ ] Error handler catches all unhandled exceptions
- [ ] No stack traces or internal details in error responses
- [ ] Request ID logged and returned in response
- [ ] Rate limiting on auth and public endpoints
- [ ] Versioning strategy in place (URL path or header)
- [ ] All endpoints have documented request/response examples
- [ ] Auth middleware applied to protected routes (not forgotten)
- [ ] CORS configured correctly for production origin
