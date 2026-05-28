# Performance Optimization — Detailed Patterns

## React Performance
- `React.memo` — pure components, same props
- `useMemo` — expensive computations: `const sorted = useMemo(() => bigSort(items), [items])`
- `useCallback` — stable function refs: `const onClick = useCallback(() => doThing(id), [id])`
- Virtualization (1000+ items): `react-window`, `@tanstack/react-virtual`
- Lazy loading: `React.lazy(() => import('./HeavyPage'))`
- Context splitting — split by update frequency (not one large context)
- List optimization — stable keys, never index as key

## Bundle Optimization
| Tool | Command |
|------|---------|
| vite-bundle-visualizer | `npx vite-bundle-visualizer` |
| BundlePhobia | bundlephobia.com |
| size-limit CI gate | `npx size-limit` |

**Code-splitting patterns:**
```tsx
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Chart = lazy(() => import('./Chart'));
const handleExport = async () => { const { exportToPDF } = await import('./pdf-utils'); };
```

**Tree shaking checklist:** ES modules, `"sideEffects": false`, no barrel files, `lodash-es` instead of `lodash`, `date-fns` instead of `moment`.

## Image Optimization
| Technique | Benefit |
|-----------|---------|
| next/image | Auto format, sizing, lazy |
| Sharp (Node) | Server-side resize + format |
| AVIF format | 50% smaller than JPEG |
| WebP format | 30% smaller than PNG |
| Responsive srcset | Correct size per device |
| `loading="lazy"` | Defer offscreen images |

## Font Optimization
- Subsetting: `glyphhanger`, `fonttools`
- WOFF2 format: 30% over WOFF
- Preload: `<link rel="preload" href="/fonts/inter-var.woff2" as="font" crossorigin>`
- next/font: auto subsetting + self-hosting

## Database Performance
**Indexing rules:** Index WHERE/JOIN/ORDER BY columns. Composite: order by cardinality (high first). Partial indexes for filtered queries. `EXPLAIN ANALYZE` before and after.

```sql
CREATE INDEX idx_orders_status ON orders(status) WHERE status IN ('pending', 'processing');
```

**Connection pooling:**
```python
engine = create_async_engine("postgresql+asyncpg://user:pass@host/db", pool_size=20, max_overflow=10, pool_pre_ping=True)
```

**Read replicas:** read/write split with SQLAlchemy — separate engines for read (replica) and write (primary).

## API Caching
| Level | Tool | Latency |
|-------|------|---------|
| In-memory | `lru_cache`, Map | < 1 µs |
| Local | SQLite, Redis local | < 100 µs |
| Shared | Redis, Memcached | 1-5 ms |
| CDN | Cloudflare, Fastly | 10-50 ms |
| Browser | Cache-Control, SW | Disk |

```python
# In-memory
@lru_cache(maxsize=512)
def get_grade_summary(student_id: int): ...

# Redis
def get_cached(key, ttl=300):
    val = r.get(key); return json.loads(val) if val else None
def set_cached(key, value, ttl=300):
    r.setex(key, ttl, json.dumps(value))
```

## FastAPI/Express Performance
```python
# Python
from sqlalchemy.ext.asyncio import create_async_engine
from fastapi import BackgroundTasks
app.add_middleware(GZipMiddleware, minimum_size=500)

# Node.js
import compression from 'compression'; app.use(compression());
```

## API Performance Patterns
- Caching headers: `Cache-Control: public, max-age=3600`
- CDN: Cloudflare, Fastly, Vercel Edge
- Compression: GZip, Brotli (70-90% reduction)
- Connection pooling: pgBouncer, `http.Agent` keepAlive
- Pagination: Keyset (cursor) > offset
- Batching: GraphQL, JSON:API includes

## Profiling & Monitoring
| Category | Tool | Key Metric |
|----------|------|------------|
| Web vitals | Lighthouse | LCP < 2.5s, FID < 100ms, CLS < 0.1 |
| RUM | web-vitals, Sentry | P75 LCP, P75 FID |
| Server | py-spy, clinic.js | CPU flamegraphs |
| APM | Datadog, New Relic | p95 latency |
| DB | pg_stat_statements | Queries > 100ms |

## Performance Budget
| Metric | Good | Poor |
|--------|------|------|
| LCP | < 2.5s | > 4.0s |
| FID | < 100ms | > 300ms |
| CLS | < 0.1 | > 0.25 |
| Bundle (JS) | < 200KB | > 500KB |

**CI budget:**
```json
{ "size-limit": [{ "path": "dist/index.js", "limit": "200 KB" }] }
```

## Rules
- Profile before optimizing — don't guess, measure first
- Cache invalidation is harder than caching — design before adding
- YAGNI — don't add Redis for 10 req/sec
- CDN for static, not dynamic
