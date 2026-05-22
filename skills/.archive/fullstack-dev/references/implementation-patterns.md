# Full-Stack Implementation Patterns — Complete Code Examples

## 1. Project Structure & Layering

### Feature-First Organization
```
✅ Feature-first                    ❌ Layer-first
src/                                src/
  orders/                             controllers/
    order.controller.ts                 order.controller.ts
    order.service.ts                    user.controller.ts
    order.repository.ts               services/
    order.dto.ts                        order.service.ts
    order.test.ts                       user.service.ts
  users/                              repositories/
    user.controller.ts                  ...
    user.service.ts
  shared/
    database/
    middleware/
```

### Three-Layer Architecture
```
Controller (HTTP) → Service (Business Logic) → Repository (Data Access)
```

| Layer | Responsibility | ❌ Never |
|-------|---------------|---------|
| Controller | Parse request, validate, call service, format response | Business logic, DB queries |
| Service | Business rules, orchestration, transaction mgmt | HTTP types (req/res), direct DB |
| Repository | Database queries, external API calls | Business logic, HTTP types |

### Dependency Injection (All Languages)

**TypeScript:**
```typescript
class OrderService {
  constructor(
    private readonly orderRepo: OrderRepository,
    private readonly emailService: EmailService,
  ) {}
}
```

**Python:**
```python
class OrderService:
    def __init__(self, order_repo: OrderRepository, email_service: EmailService):
        self.order_repo = order_repo
        self.email_service = email_service
```

**Go:**
```go
type OrderService struct {
    orderRepo    OrderRepository
    emailService EmailService
}
func NewOrderService(repo OrderRepository, email EmailService) *OrderService {
    return &OrderService{orderRepo: repo, emailService: email}
}
```

## 2. Configuration & Environment

**TypeScript:**
```typescript
const config = {
  port: parseInt(process.env.PORT || '3000', 10),
  database: { url: requiredEnv('DATABASE_URL'), poolSize: intEnv('DB_POOL_SIZE', 10) },
  auth: { jwtSecret: requiredEnv('JWT_SECRET'), expiresIn: process.env.JWT_EXPIRES_IN || '1h' },
} as const;

function requiredEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required env var: ${name}`);
  return value;
}
```

**Python:**
```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str        # required — fails fast if missing
    jwt_secret: str          # required
    port: int = 3000         # optional with default
    db_pool_size: int = 10
    class Config:
        env_file = ".env"

settings = Settings()
```

## 3. Typed Error Hierarchy

**TypeScript:**
```typescript
class AppError extends Error {
  constructor(message: string, public readonly code: string,
              public readonly statusCode: number,
              public readonly isOperational: boolean = true) { super(message); }
}
class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(`${resource} not found: ${id}`, 'NOT_FOUND', 404);
  }
}
class ValidationError extends AppError {
  constructor(public readonly errors: FieldError[]) {
    super('Validation failed', 'VALIDATION_ERROR', 422);
  }
}
```

**Python:**
```python
class AppError(Exception):
    def __init__(self, message: str, code: str, status_code: int):
        self.message, self.code, self.status_code = message, code, status_code

class NotFoundError(AppError):
    def __init__(self, resource: str, id: str):
        super().__init__(f"{resource} not found: {id}", "NOT_FOUND", 404)
```

### Global Error Handler (Express)
```typescript
app.use((err, req, res, next) => {
  if (err instanceof AppError && err.isOperational) {
    return res.status(err.statusCode).json({
      title: err.code, status: err.statusCode,
      detail: err.message, request_id: req.id,
    });
  }
  logger.error('Unexpected error', { error: err.message, stack: err.stack, request_id: req.id });
  res.status(500).json({ title: 'Internal Error', status: 500, request_id: req.id });
});
```

## 4. Database Access Patterns

### N+1 Prevention
```typescript
// ❌ N+1: 1 query + N queries
const orders = await db.order.findMany();
for (const o of orders) { o.items = await db.item.findMany({ where: { orderId: o.id } }); }
// ✅ Single JOIN query
const orders = await db.order.findMany({ include: { items: true } });
```

### Transactions for Multi-Step Writes
```typescript
await db.$transaction(async (tx) => {
  const order = await tx.order.create({ data: orderData });
  await tx.inventory.decrement({ productId, quantity });
  await tx.payment.create({ orderId: order.id, amount });
});
```

## 5. API Client: Typed Fetch Wrapper
```typescript
// lib/api-client.ts
const BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

class ApiError extends Error {
  constructor(public status: number, public body: any) {
    super(body?.detail || body?.message || `API error ${status}`);
  }
}

async function api<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = getAuthToken();
  const res = await fetch(`${BASE_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });
  if (!res.ok) { const body = await res.json().catch(() => null); throw new ApiError(res.status, body); }
  if (res.status === 204) return undefined as T;
  return res.json();
}

export const apiClient = {
  get: <T>(path: string) => api<T>(path),
  post: <T>(path: string, data: unknown) => api<T>(path, { method: 'POST', body: JSON.stringify(data) }),
  put: <T>(path: string, data: unknown) => api<T>(path, { method: 'PUT', body: JSON.stringify(data) }),
  patch: <T>(path: string, data: unknown) => api<T>(path, { method: 'PATCH', body: JSON.stringify(data) }),
  delete: <T>(path: string) => api<T>(path, { method: 'DELETE' }),
};
```

## 6. Auth: JWT + HTTP-Only Cookie Refresh

**Backend refresh flow:**
```typescript
// lib/api-client.ts — transparent refresh on 401
async function apiWithRefresh<T>(path: string, options: RequestInit = {}): Promise<T> {
  try { return await api<T>(path, options); }
  catch (err) {
    if (err instanceof ApiError && err.status === 401) {
      const refreshed = await api<{ accessToken: string }>('/api/auth/refresh', {
        method: 'POST', credentials: 'include',
      });
      setAuthToken(refreshed.accessToken);
      return api<T>(path, options);  // retry
    }
    throw err;
  }
}
```

**RBAC Middleware:**
```typescript
function authorize(...roles: Role[]) {
  return (req, res, next) => {
    if (!req.user) throw new UnauthorizedError();
    if (!roles.some(r => req.user.roles.includes(r))) throw new ForbiddenError();
    next();
  };
}
router.delete('/users/:id', authenticate, authorize('admin'), deleteUser);
```

## 7. Logging & Observability

```typescript
// ✅ Structured — parseable, filterable, alertable
logger.info('Order created', {
  orderId: order.id, userId: user.id, total: order.total,
  items: order.items.length, duration_ms: Date.now() - startTime,
});
// ❌ Unstructured — useless at scale
console.log(`Order created for user ${user.id} with total ${order.total}`);
```

## 8. Background Jobs (Idempotent Pattern)

```typescript
async function processPayment(data: { orderId: string }) {
  const order = await orderRepo.findById(data.orderId);
  if (order.paymentStatus === 'completed') return;  // already processed
  await paymentGateway.charge(order);
  await orderRepo.updatePaymentStatus(order.id, 'completed');
}
```

## 9. Caching Patterns (Cache-Aside)
```typescript
async function getUser(id: string): Promise<User> {
  const cached = await redis.get(`user:${id}`);
  if (cached) return JSON.parse(cached);
  const user = await userRepo.findById(id);
  if (!user) throw new NotFoundError('User', id);
  await redis.set(`user:${id}`, JSON.stringify(user), 'EX', 900);  // 15min TTL
  return user;
}
```

## 10. File Upload: Presigned URL Pattern

**Backend:**
```typescript
app.get('/api/uploads/presign', authenticate, async (req, res) => {
  const { filename, type } = req.query;
  const key = `uploads/${crypto.randomUUID()}-${filename}`;
  const url = await s3.getSignedUrl('putObject', {
    Bucket: process.env.S3_BUCKET, Key: key,
    ContentType: type, Expires: 300,
  });
  res.json({ uploadUrl: url, fileKey: key });
});
```

**Frontend:**
```typescript
async function uploadFile(file: File) {
  const { uploadUrl, fileKey } = await apiClient.get<PresignResponse>(
    `/api/uploads/presign?filename=${file.name}&type=${file.type}`);
  await fetch(uploadUrl, { method: 'PUT', body: file, headers: { 'Content-Type': file.type } });
  return apiClient.post('/api/photos', { fileKey });
}
```

## 11. Real-Time Patterns

### SSE (Server → Client)
**Backend (Express):**
```typescript
app.get('/api/events', authenticate, (req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-cache', Connection: 'keep-alive' });
  const send = (event: string, data: unknown) => { res.write(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`); };
  const unsubscribe = eventBus.subscribe(req.user.id, (event) => { send(event.type, event.payload); });
  req.on('close', () => unsubscribe());
});
```

**Frontend:**
```typescript
function useServerEvents(userId: string) {
  useEffect(() => {
    const source = new EventSource(`/api/events?userId=${userId}`);
    source.addEventListener('notification', (e) => { showToast(JSON.parse(e.data).message); });
    source.onerror = () => { source.close(); setTimeout(() => reconnect, 3000); };
    return () => source.close();
  }, [userId]);
}
```

### WebSocket (Bidirectional)
**Backend:**
```typescript
import { WebSocketServer } from 'ws';
const wss = new WebSocketServer({ server: httpServer, path: '/ws' });
wss.on('connection', (ws, req) => {
  const userId = authenticateWs(req);
  if (!userId) { ws.close(4001, 'Unauthorized'); return; }
  ws.on('message', (raw) => handleMessage(userId, JSON.parse(raw.toString())));
  ws.on('close', () => cleanupUser(userId));
  const interval = setInterval(() => ws.ping(), 30000);
  ws.on('close', () => clearInterval(interval));
});
```

### Polling (React Query)
```typescript
function useOrderStatus(orderId: string) {
  return useQuery({
    queryKey: ['order-status', orderId],
    queryFn: () => apiClient.get<Order>(`/api/orders/${orderId}`),
    refetchInterval: (query) => {
      if (query.state.data?.status === 'completed') return false;
      return 5000;
    },
  });
}
```

## 12. Cross-Boundary Error Handling

```typescript
// lib/error-handler.ts
export function getErrorMessage(error: unknown): string {
  if (error instanceof ApiError) {
    switch (error.status) {
      case 401: return 'Please log in to continue.';
      case 403: return 'You don\'t have permission to do this.';
      case 404: return 'The item you\'re looking for doesn\'t exist.';
      case 409: return 'This conflicts with an existing item.';
      case 422:
        const fields = error.body?.errors;
        if (fields?.length) return fields.map((f: any) => f.message).join('. ');
        return 'Please check your input.';
      case 429: return 'Too many requests. Please wait a moment.';
      default: return 'Something went wrong. Please try again.';
    }
  }
  return 'An unexpected error occurred.';
}
```

## 13. Production Hardening

**Health Checks:**
```typescript
app.get('/health', (req, res) => res.json({ status: 'ok' }));
app.get('/ready', async (req, res) => {
  const checks = { database: await checkDb(), redis: await checkRedis() };
  const ok = Object.values(checks).every(c => c.status === 'ok');
  res.status(ok ? 200 : 503).json({ status: ok ? 'ok' : 'degraded', checks });
});
```

**Graceful Shutdown:**
```typescript
process.on('SIGTERM', async () => {
  logger.info('SIGTERM received');
  server.close();
  await drainConnections();
  await closeDatabase();
  process.exit(0);
});
```

## Anti-Patterns

| # | ❌ Don't | ✅ Do Instead |
|---|---------|--------------|
| 1 | Business logic in routes/controllers | Move to service layer |
| 2 | `process.env` scattered everywhere | Centralized typed config |
| 3 | `console.log` for logging | Structured JSON logger |
| 4 | Generic `Error('oops')` | Typed error hierarchy |
| 5 | Direct DB calls in controllers | Repository pattern |
| 6 | No input validation | Validate at boundary (Zod/Pydantic) |
| 7 | Catching errors silently | Log + rethrow or return error |
| 8 | No health check endpoints | `/health` + `/ready` |
| 9 | Hardcoded config/secrets | Environment variables |
| 10 | No graceful shutdown | Handle SIGTERM properly |
| 11 | Hardcode API URL in frontend | Environment variable |
| 12 | Store JWT in localStorage | Memory + httpOnly refresh cookie |
| 13 | Show raw API errors to users | Map to human-readable messages |
| 14 | Retry 4xx errors | Only retry 5xx |
| 15 | Skip loading states | Skeleton/spinner while fetching |
| 16 | Upload large files through API server | Presigned URL → direct to S3 |
| 17 | Poll for real-time data | SSE or WebSocket |
| 18 | Duplicate types frontend + backend | Shared types, tRPC, or OpenAPI codegen |
