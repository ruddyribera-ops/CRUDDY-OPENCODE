---
name: performance-optimization
description: Performance Optimization Patterns and Best Practices across React, API, DB, and bundle optimization
tags: [performance, optimization, react, backend]
---

# Performance Optimization Skill


## When to Use
- Debug slow page load or laggy UI
- Fix N+1 queries or database bottlenecks
- Optimize React re-render performance
- Reduce bundle size or API latency
- Memory leak investigation and fixing

## Do Not Use
- Security hardening (use security-basics)
- Code style or formatting improvements
- Database schema design (use database-patterns)
- Deployment optimization (use deployment-patterns)

Cross-cutting skill wired into: `code-builder`, `bug-fixer`, `code-analyzer`, `architecture-advisor`.

## Bundle Size (JS/TS/Vite)


## When to Use
- Debug slow page load or laggy UI
- Fix N+1 queries or database bottlenecks
- Optimize React re-render performance
- Reduce bundle size or API latency
- Memory leak investigation and fixing

## Do Not Use
- Security hardening (use security-basics)
- Code style or formatting improvements
- Database schema design (use database-patterns)
- Deployment optimization (use deployment-patterns)

- **Analyze:** `npx vite-bundle-visualizer` or browser devtools → Network → coverage
- **Tree shaking:** ES module imports, `"sideEffects": false`, no barrel files
- **Code splitting:** `const Dashboard = lazy(() => import('./pages/Dashboard'))`
- **Dynamic import:** `const lib = await import('@heavy/lib')` (on interaction)
- **Lazy images:** `<img loading="lazy" />`

## React Performance


## When to Use
- Debug slow page load or laggy UI
- Fix N+1 queries or database bottlenecks
- Optimize React re-render performance
- Reduce bundle size or API latency
- Memory leak investigation and fixing

## Do Not Use
- Security hardening (use security-basics)
- Code style or formatting improvements
- Database schema design (use database-patterns)
- Deployment optimization (use deployment-patterns)

| Technique | When | API |
|-----------|------|-----|
| `React.memo` | Pure component, same props | `const Comp = React.memo(...)` |
| `useMemo` | Expensive computation | `const sorted = useMemo(() => bigSort(items), [items])` |
| `useCallback` | Stable function reference | `const onClick = useCallback(() => doThing(id), [id])` |
| Virtualization | 1000+ items list | `@tanstack/react-virtual` |
| Context splitting | Split by update frequency | Separate ThemeContext / UserContext / CartContext |
| Stable keys | Never index as key | `key={item.id}` |

→ See `references/code-examples.md` for detailed patterns with code.

## Database Optimization


## When to Use
- Debug slow page load or laggy UI
- Fix N+1 queries or database bottlenecks
- Optimize React re-render performance
- Reduce bundle size or API latency
- Memory leak investigation and fixing

## Do Not Use
- Security hardening (use security-basics)
- Code style or formatting improvements
- Database schema design (use database-patterns)
- Deployment optimization (use deployment-patterns)

- **Index** columns used in `WHERE`, `JOIN`, `ORDER BY`
- **Composite index:** order by cardinality (high first)
- **Avoid N+1** — use JOIN or eager loading
- **Pagination:** always paginate large result sets
- **`EXPLAIN ANALYZE`** before and after changes
- **Connection pooling:** `pool_size=20, max_overflow=10`

→ See `references/code-examples.md` for SQL examples, read replicas, comprehensive indexing.

## API Caching


## When to Use
- Debug slow page load or laggy UI
- Fix N+1 queries or database bottlenecks
- Optimize React re-render performance
- Reduce bundle size or API latency
- Memory leak investigation and fixing

## Do Not Use
- Security hardening (use security-basics)
- Code style or formatting improvements
- Database schema design (use database-patterns)
- Deployment optimization (use deployment-patterns)

| Level | Tool | TTL |
|-------|------|-----|
| In-memory | `lru_cache` | Per-process |
| Shared | Redis | 5-15 min |
| CDN | Cloudflare, Fastly | 1 year (hashed) |
| Browser | Cache-Control | 1 year (immutable) |

**Never cache:** Auth tokens, real-time WS data.

→ See `references/code-examples.md` for Redis patterns, CDN setup, full caching hierarchy.

## FastAPI/Express Performance
- Async DB driver (`asyncpg`, `create_async_engine`)
- Compression middleware (GZip/Brotli)
- Background tasks for heavy work
- Fail fast on missing env vars at startup

## Image & Font Optimization
- WebP/AVIF formats, responsive srcset, lazy loading
- Font subsetting, WOFF2, preload critical fonts

## Verification


## When to Use
- Debug slow page load or laggy UI
- Fix N+1 queries or database bottlenecks
- Optimize React re-render performance
- Reduce bundle size or API latency
- Memory leak investigation and fixing

## Do Not Use
- Security hardening (use security-basics)
- Code style or formatting improvements
- Database schema design (use database-patterns)
- Deployment optimization (use deployment-patterns)

| Check | Command/Tool |
|-------|-------------|
| Bundle size | `npm run build` → check `dist/assets/*.js` sizes |
| DB query analysis | `EXPLAIN ANALYZE <sql>` |
| Redis cache hit | `redis-cli info stats | grep hit_rate` |
| API response time | `curl -w "@curl-format.txt" -o /dev/null -s` |
| React render count | React DevTools Profiler |

## Rules
- Profile before optimizing — don't guess, measure first
- Cache invalidation is harder than caching — design before adding
- YAGNI — don't add Redis for 10 req/sec

## Performance Budget Targets
| Metric | Good | Poor |
|--------|------|------|
| LCP | < 2.5s | > 4.0s |
| FID | < 100ms | > 300ms |
| CLS | < 0.1 | > 0.25 |
| Bundle (JS) | < 200KB | > 500KB |

## References
→ `references/code-examples.md` — Full code examples for all patterns above
