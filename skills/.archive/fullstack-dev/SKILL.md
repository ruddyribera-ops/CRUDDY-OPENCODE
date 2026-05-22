---
name: fullstack-dev
description: Full-stack backend architecture and frontend-backend integration guide. Covers REST API design, service layers, error handling, auth, file uploads, and real-time features (SSE/WebSocket).
tags: [fullstack, backend, frontend, api, web]
tags: [fullstack, rest-api, backend, frontend, architecture, nodejs, python, go]
---

## When to Use

- Building full-stack applications with backend + frontend integration
- Scaffolding REST APIs with Express, FastAPI, Flask, Go Fiber, or Laravel
- Implementing frontend-backend communication patterns
- Adding real-time features (SSE, WebSocket) to web apps
- Handling file uploads, auth flows, and error handling end-to-end
- Designing service layers and API client patterns

## Do Not Use

- Frontend-only UI work without backend integration (use frontend-dev)
- Backend-only API without frontend context (use api-patterns + framework docs)
- Database schema or migration design (use database-patterns)
- Mobile app development (use android-native-dev, ios-application-dev, or react-native-dev)
- DevOps or deployment infrastructure (use deployment-patterns)

# Full-Stack Development Practices

## MANDATORY WORKFLOW — Follow These Steps In Order

### Step 0: Gather Requirements
- **Stack**: Language/framework for backend and frontend
- **Service type**: API-only, full-stack monolith, or microservice?
- **Database**: SQL (PostgreSQL, SQLite, MySQL) or NoSQL (MongoDB, Redis)?
- **Integration**: REST, GraphQL, tRPC, or gRPC?
- **Real-time**: SSE, WebSocket, or polling?
- **Auth**: JWT, session, OAuth, or third-party?

### Step 1: Architectural Decisions
Choose from the table below and state each choice before coding:

| Decision | Options | Reference |
|----------|---------|-----------|
| Project structure | Feature-first (recommended) vs layer-first | [§1 patterns](references/implementation-patterns.md#1-project-structure--layering) |
| API client | Typed fetch / React Query / tRPC / OpenAPI codegen | [§5 patterns](references/implementation-patterns.md#5-api-client-typed-fetch-wrapper) |
| Auth strategy | JWT + refresh / session / third-party | [references/auth-flow.md](references/auth-flow.md) |
| Real-time method | Polling / SSE / WebSocket | [§11 patterns](references/implementation-patterns.md#11-real-time-patterns) |
| Error handling | Typed error hierarchy + global handler | [§3 patterns](references/implementation-patterns.md#3-typed-error-hierarchy) |

### Step 2: Scaffold with Checklist

**Backend:** ensure ALL checked:
- [ ] Feature-first project structure
- [ ] Configuration centralized, env vars validated at startup (fail fast)
- [ ] Typed error hierarchy + global error handler
- [ ] Structured JSON logging with request ID propagation
- [ ] Database migrations + connection pooling
- [ ] Input validation on all endpoints (Zod / Pydantic)
- [ ] Authentication middleware in place
- [ ] Health check endpoints (`/health`, `/ready`)
- [ ] Graceful shutdown (SIGTERM)
- [ ] CORS configured (explicit origins, not `*`)
- [ ] Security headers (helmet or equivalent)
- [ ] `.env.example` committed (no real secrets)

**Frontend-Backend Integration:**
- [ ] API client configured (typed fetch, React Query, tRPC, or OpenAPI generated)
- [ ] Base URL from environment variable (not hardcoded)
- [ ] Auth token attached to requests automatically
- [ ] API errors mapped to user-facing messages
- [ ] Loading states handled (skeleton/spinner)
- [ ] Type safety across boundary (shared types, OpenAPI, or tRPC)
- [ ] Refresh token flow (httpOnly cookie + transparent retry on 401)

### Step 3: Implement Following Patterns

Implement using the detailed code patterns below. Each section has a reference file with complete code examples.

| Need to… | L1 Summary | Full Code |
|----------|-----------|-----------|
| Project structure | Feature-first, 3-layer: Controller→Service→Repository | [references/implementation-patterns.md#1](references/implementation-patterns.md#1-project-structure--layering) |
| Config & env | Centralized, typed, fail-fast at startup | [references/implementation-patterns.md#2](references/implementation-patterns.md#2-configuration--environment) |
| Error handling | Typed hierarchy + global handler + operational vs programming errors | [references/implementation-patterns.md#3](references/implementation-patterns.md#3-typed-error-hierarchy) |
| Database access | Migrations, N+1 prevention, transactions, pooling | [references/implementation-patterns.md#4](references/implementation-patterns.md#4-database-access-patterns) |
| API client | Typed fetch wrapper / React Query / tRPC / OpenAPI | [references/implementation-patterns.md#5](references/implementation-patterns.md#5-api-client-typed-fetch-wrapper) |
| Auth & middleware | JWT rules, RBAC, token refresh, middleware order | [references/auth-flow.md](references/auth-flow.md) |
| Logging | Structured JSON, request ID, log levels | [references/implementation-patterns.md#7](references/implementation-patterns.md#7-logging--observability) |
| Background jobs | Idempotent, retry→dead letter, separate process | [references/implementation-patterns.md#8](references/implementation-patterns.md#8-background-jobs-idempotent-pattern) |
| Caching | Cache-aside, TTL always, invalidate on write | [references/implementation-patterns.md#9](references/implementation-patterns.md#9-caching-patterns-cache-aside) |
| File uploads | Presigned URL for large, multipart for small | [references/implementation-patterns.md#10](references/implementation-patterns.md#10-file-upload-presigned-url-pattern) |
| Real-time | Polling / SSE / WebSocket decision | [references/implementation-patterns.md#11](references/implementation-patterns.md#11-real-time-patterns) |
| Cross-boundary errors | Human-readable messages, auto-retry 5xx | [references/implementation-patterns.md#12](references/implementation-patterns.md#12-cross-boundary-error-handling) |
| Production hardening | Health checks, graceful shutdown, security checklist | [references/implementation-patterns.md#13](references/implementation-patterns.md#13-production-hardening) |

## Core Principles (7 Iron Rules)

```
1. ✅ Organize by FEATURE, not by technical layer
2. ✅ Controllers never contain business logic
3. ✅ Services never import HTTP request/response types
4. ✅ All config from env vars, validated at startup, fail fast
5. ✅ Every error is typed, logged, and returns consistent format
6. ✅ All input validated at the boundary — trust nothing from client
7. ✅ Structured JSON logging with request ID — not console.log
```

## Common Issues

- **"Where does this business rule go?"** — HTTP → controller. Business decisions → service. Database → repository.
- **"Service is getting too big"** — Split by sub-domain: `OrderService` → `OrderCreationService` + `OrderFulfillmentService`.
- **"Tests are slow because they hit the database"** — Unit tests mock repository layer. Integration tests use transactions rollback.

## Specialized Resources

| Need to… | Reference |
|----------|-----------|
| Go / Fiber high-performance patterns | [resources/go-fiber.md](resources/go-fiber.md) |
| Python backend (FastAPI, Flask, Dash) | [resources/python-backend.md](resources/python-backend.md) |
| PHP backend (Laravel, Symfony) | [resources/php-backend.md](resources/php-backend.md) |
| Backend testing strategies | [references/testing-strategy.md](references/testing-strategy.md) |
| Release validation checklist | [references/release-checklist.md](references/release-checklist.md) |
| Tech stack selection | [references/technology-selection.md](references/technology-selection.md) |
| Django / DRF best practices | [references/django-best-practices.md](references/django-best-practices.md) |
| API design (REST/GraphQL/gRPC) | [references/api-design.md](references/api-design.md) |
| Database schema & indexes | [references/db-schema.md](references/db-schema.md) |
| CORS & environment management | [references/environment-management.md](references/environment-management.md) |
| Ecosystem & library catalog | [references/ecosystem.md](references/ecosystem.md) |
| API client decision guide | [references/implementation-patterns.md#decision-which-api-client](references/implementation-patterns.md) |
| Real-time method decision guide | [references/implementation-patterns.md#decision-real-time](references/implementation-patterns.md) |
| Anti-patterns table (18 items) | [references/implementation-patterns.md#anti-patterns](references/implementation-patterns.md#anti-patterns) |

## Verification

- [ ] Backend and frontend compile without errors (`npm run build` / `go build`)
- [ ] Smoke test: `curl http://localhost:3000/health` returns 200
- [ ] API client can connect to backend (CORS, base URL, auth flow)
- [ ] Real-time works (if applicable): two browser tabs sync
- [ ] All reference links in this file resolve to existing files
