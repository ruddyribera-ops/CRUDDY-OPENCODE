---
name: api-patterns
description: REST API design patterns, error handling, and response format standards
tags: [api, backend, rest, design]
tags: [rest-api, http, api-design, error-handling, json, backend]
---

## When to Use

- Designing REST API endpoints and resource hierarchies
- Implementing consistent JSON response formats and error codes
- Choosing appropriate HTTP status codes for API responses
- Setting up API versioning, pagination, and filtering
- Building middleware for request validation and error handling

## Do Not Use

- Frontend-only development without API endpoints
- GraphQL API design (use specialized GraphQL patterns)
- Real-time communication protocols (use realtime-patterns)
- Authentication-specific patterns (use auth-patterns)
- Database schema or query design (use database-patterns)

# API Patterns

## Response Format (Consistent JSON)
Success:
```json
{ "data": { ... }, "meta": { "timestamp": "..." } }
```
Error:
```json
{ "error": { "code": "NOT_FOUND", "message": "User not found", "field": "userId" } }
```

## HTTP Status Codes
- 200 OK — successful GET, PUT
- 201 Created — successful POST
- 204 No Content — successful DELETE
- 400 Bad Request — invalid input (include error.field)
- 401 Unauthorized — not authenticated
- 403 Forbidden — authenticated but not permitted
- 404 Not Found — resource does not exist
- 409 Conflict — resource already exists
- 422 Unprocessable Entity — validation failed
- 500 Internal Server Error — unexpected server failure

## Input Validation
- Validate at the route/controller level before business logic
- Return 400 with specific field errors
- Never trust client input

## Authentication
- Use Authorization header: `Bearer <token>`
- Validate token on every protected route via middleware
- Never put tokens in URLs

## Error Handling
- Catch all async errors with try/catch or error middleware
- Log errors server-side with context (user, endpoint, timestamp)
- Never expose stack traces to clients in production

## Anti-Patterns (What NOT to Do)

### ❌ Changing API Response Format Without Versioning
```json
// v1.0 — deployed in production
{ "user": { "id": 1, "name": "Alice" } }

// v1.1 — oops, breaks all clients
{ "data": { "user": { "id": 1, "name": "Alice" } } }
```

**FIX:** Use API versioning (`/api/v1/users` vs `/api/v2/users`) or add `Accept-Version` header.

### ❌ Storing Sensitive Data in Error Messages
```python
# BAD — leaks internal details
if not user:
    raise HTTPException(404, detail=f"User {user_id} not found in table users_prod")

# GOOD — generic error, internal log separate
logger.info(f"User lookup failed: user_id={user_id}, table=users_prod")
raise HTTPException(404, detail="User not found")
```

### ❌ No Rate Limiting
```python
# BAD — exposed to brute force, DoS
@app.post("/auth/login")
async def login(email: str, password: str):
    ...

# GOOD — rate limit by IP or user
@limiter.limit("5/minute")  # 5 attempts per minute
@app.post("/auth/login")
async def login(email: str, password: str):
    ...
```

### ❌ Ignoring Async/Await in Error Handlers
```python
# BAD — error handler blocks, API freezes
try:
    result = await fetch_data()
except Exception:
    write_to_file(error_log)  # BLOCKING!

# GOOD — non-blocking error handling
try:
    result = await fetch_data()
except Exception:
    asyncio.create_task(log_error_async(error_log))
```

## API Versioning Tradeoffs

| Strategy | Pros | Cons |
|---|---|---|
| **URL path** (`/v1/users` vs `/v2/users`) | Clear, easy to test | Code duplication |
| **Query param** (`GET /users?api_version=2`) | One endpoint | Easy to miss version param |
| **Header** (`Accept-Version: 2`) | Clean, hidden | Client must know to set it |
| **No versioning, only add fields** | Minimal code | Breaking changes hard to avoid |

**Recommendation:** Use URL versioning for major breaks. Deprecate old endpoints gradually (6+ months notice).

---

## Ecosystem (awesome-nodejs)

### Web Frameworks
| Library | Description |
|---------|-------------|
| [fastify](https://fastify.dev) | Fast & low overhead, schema-based validation, Swagger plugin |
| [express](https://expressjs.com) | Minimal, widely adopted ecosystem |
| [hono](https://hono.dev) | Ultralight, multi-runtime (Node, Deno, Bun, Cloudflare) |
| [koa](https://koajs.com) | Express successor, async middleware |
| [nest](https://nestjs.com) | Opinionated framework (decorators, DI, OpenAPI integration) |

### Validation
| Library | Description |
|---------|-------------|
| [zod](https://zod.dev) | TypeScript-first schema validation (recommended) |
| [joi](https://joi.dev) | Rich validation language (Hapi ecosystem) |
| [ajv](https://ajv.js.org) | JSON Schema validator (fastest, OpenAPI-compatible) |
| [json-schema](https://json-schema.org) | Standard for describing JSON data structures |

### Authentication & Authorization
| Library | Description |
|---------|-------------|
| [passport](https://www.passportjs.org) | Strategy-based auth (500+ strategies) |
| [jsonwebtoken](https://github.com/auth0/node-jsonwebtoken) | JWT signing & verification |
| [jose](https://github.com/panva/jose) | JWT, JWE, JWS, JWK (full JOSE standard) |
| [iron-session](https://github.com/vvo/iron-session) | Encrypted cookie sessions |
| [next-auth / auth.js](https://authjs.dev) | Universal auth for any framework |

### API Documentation
| Tool | Description |
|------|-------------|
| [swagger-ui](https://swagger.io/tools/swagger-ui) | Interactive API documentation browser |
| [scalar](https://scalar.com) | Modern API reference UI (clean, fast) |
| [redoc](https://redocly.com/redoc) | Beautiful OpenAPI documentation |
| [typedoc](https://typedoc.org) | TypeScript API documentation generator |

### Rate Limiting
| Library | Description |
|---------|-------------|
| [express-rate-limit](https://github.com/express-rate-limit/express-rate-limit) | Rate limiting for Express |
| [bottleneck](https://github.com/SGrondin/bottleneck) | Rate limiter (promises, async, clustering) |
| [p-ratelimit](https://github.com/sindresorhus/p-ratelimit) | Promise-based rate limiter |

### API Client Libraries
| Library | Description |
|---------|-------------|
| [axios](https://axios-http.com) | Promise-based HTTP client (browser + Node) |
| [got](https://github.com/sindresorhus/got) | Human-friendly HTTP client (retry, hooks, streams) |
| [undici](https://undici.nodejs.org) | Node.js built-in HTTP/1.1 client |
| [openapi-generator](https://openapi-generator.tech) | Generate SDKs from OpenAPI specs |

### API Testing
| Tool | Description |
|------|-------------|
| [supertest](https://github.com/ladjs/supertest) | HTTP integration testing (works with any framework) |
| [stepci](https://stepci.com) | API workflow testing (OpenAPI-compatible) |
| [insomnia](https://insomnia.rest) | Desktop API client (design, debug, test) |
| [bruno](https://www.usebruno.com) | Offline-first API client (git-friendly) |
| [postman-cli](https://learning.postman.com/docs/postman-cli/postman-cli-overview) | CLI for Postman collections |

### GraphQL
| Library | Description |
|---------|-------------|
| [graphql-yoga](https://the-guild.dev/graphql/yoga-server) | GraphQL server (The Guild, cross-platform) |
| [apollo-server](https://www.apollographql.com/docs/apollo-server) | Production GraphQL server |
| [pothos](https://pothos-graphql.dev) | TypeScript-first schema builder |
| [typegraphql](https://typegraphql.com) | Decorator-based GraphQL schema (Nest-like) |

---

## See Also

- [awesome-nodejs](https://github.com/sindresorhus/awesome-nodejs) — Curated Node.js resources (65K+ stars)
- [OpenAPI Specification](https://swagger.io/specification) — API description standard
- [JSON:API](https://jsonapi.org) — Standard API response format
- [REST API Tutorial](https://restapitutorial.com) — RESTful API design guide
- [Postman / Bruno](https://www.usebruno.com) — API client alternatives
