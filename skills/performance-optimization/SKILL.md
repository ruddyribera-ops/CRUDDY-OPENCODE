---
name: performance-optimization
description: "Performance Optimization Patterns and Best Practices across React, API, DB, and bundle optimization. Use when optimizing app performance, query speed, or bundle size. Triggers: performance, optimize, React memo, bundle size, code splitting, lazy loading, N+1, query optimization, caching, profiling."
---

# Performance Optimization

## When to use this

Load this skill when investigating slow performance, optimizing bundle size, eliminating N+1 queries, implementing caching, or profiling an application to find bottlenecks.

---

## Core Principles

1. **Profile before optimizing** — You cannot guess where performance problems are. Use a profiler to find the actual hot spots. Optimizing the wrong thing is the most common mistake.

2. **The 80/20 rule applies to performance** — 80% of the time is spent in 20% of the code. Find that 20% and optimize it. Do not optimize cold paths.

3. **Premature optimization is real** — Micro-optimizations that hurt readability without measurable impact are harmful. Only optimize when you have evidence.

4. **Caching is the highest-leverage optimization** — Returning cached data instead of recomputing or re-fetching can be 100x faster. Always check if caching applies before algorithmic changes.

5. **Database queries are the most common bottleneck** — Network I/O and database queries are orders of magnitude slower than in-memory operations. Optimize queries before algorithm complexity.

6. **Bundle size affects time-to-interactive** — Large JavaScript bundles block the initial render. Code splitting and lazy loading improve perceived performance.

7. **Measure, change, measure again** — Every optimization must be verified with before/after measurements. Without measurement, you are guessing.

---

## Patterns

### React Performance: Memoization

```tsx
// 1. React.memo — prevent unnecessary re-renders of child components
const ExpensiveChild = React.memo(function ExpensiveChild({ data, onProcess }) {
  // Only re-renders when data or onProcess changes
  return <div>{/* expensive rendering */}</div>;
});

// Without React.memo, parent re-render would always re-render this child
// With React.memo, shallow comparison of props determines re-render

// 2. useMemo — memoize expensive computations
function DataTable({ items, filter }) {
  const filteredItems = useMemo(() => {
    // This computation only runs when items or filter changes
    return items.filter(item => item.name.includes(filter));
  }, [items, filter]);

  const sortedItems = useMemo(() => {
    return [...filteredItems].sort((a, b) => a.name.localeCompare(b.name));
  }, [filteredItems]);

  return <Table data={sortedItems} />;
}

// 3. useCallback — memoize callback functions passed to children
function ParentComponent() {
  const [count, setCount] = useState(0);

  // Without useCallback: new function created on every render
  // Child component receiving this as prop will re-render every time

  const handleClick = useCallback((id) => {
    console.log('Clicked:', id);
  }, []);  // Empty deps: function never changes

  const handleUpdate = useCallback((id, value) => {
    setItems(prev => prev.map(item =>
      item.id === id ? { ...item, value } : item
    ));
  }, []);  // setItems is stable (from useState)

  return (
    <>
      <button onClick={() => setCount(c => c + 1)}>Count: {count}</button>
      <ChildComponent onClick={handleClick} onUpdate={handleUpdate} />
    </>
  );
}
```

### React Performance: Virtualization

```tsx
// Virtualization: render only visible rows in large lists
// Without virtualization: 10,000 rows = 10,000 DOM nodes = slow
// With virtualization: 20 rows in DOM = fast

import { FixedSizeList } from 'react-window';

function VirtualizedList({ items }) {
  const Row = ({ index, style }) => (
    <div style={style}>
      {/* Render only this row — only ~20 rows in DOM at any time */}
      <ListItem item={items[index]} />
    </div>
  );

  return (
    <FixedSizeList
      height={600}
      itemCount={items.length}
      itemSize={50}  // Height of each row
      width="100%"
    >
      {Row}
    </FixedSizeList>
  );
}

// Alternative: react-virtual or @tanstack/virtual for more flexibility
```

### React Performance: Code Splitting and Lazy Loading

```tsx
// 1. Route-based code splitting (most common)
import { lazy, Suspense } from 'react';

const Dashboard = lazy(() => import('./pages/Dashboard'));
const Settings = lazy(() => import('./pages/Settings'));
const Reports = lazy(() => import('./pages/Reports'));

function App() {
  return (
    <Routes>
      <Route path="/" element={<HomePage />} />
      {/* These routes load their code only when navigated to */}
      <Route path="/dashboard" element={
        <Suspense fallback={<LoadingSpinner />}>
          <Dashboard />
        </Suspense>
      } />
      <Route path="/settings" element={
        <Suspense fallback={<LoadingSpinner />}>
          <Settings />
        </Suspense>
      } />
    </Routes>
  );
}

// 2. Component-level lazy loading (for large, rarely-used components)
const Chart = lazy(() => import('./components/HeavyChart'));

// 3. Dynamic import for feature detection
const GeolocationAPI = lazy(() => import('./utils/geolocation'));
```

### API Performance: Connection Pooling

```python
# Connection pooling: reuse DB connections instead of creating new ones
# See database-patterns skill for full details

# PostgreSQL with SQLAlchemy (recommended settings)
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

engine = create_engine(
    "postgresql://user:pass@localhost:5432/mydb",
    poolclass=QueuePool,
    pool_size=10,       # Persistent connections to keep
    max_overflow=20,     # Additional connections under load
    pool_timeout=30,      # Wait time for available connection
    pool_recycle=3600,    # Recycle after 1 hour
    pool_pre_ping=True,   # Verify connection before using
)
```

### API Performance: Response Caching

```python
# HTTP caching headers — let browsers and CDNs cache responses

# Cache-Control: most powerful header
# Response can be cached for 1 hour
# Cache-Control: public, max-age=3600

# For user-specific data: private (only browser cache, not CDN)
# Cache-Control: private, max-age=3600

# For immutable assets (versioned JS/CSS): long cache + cache busting
# Cache-Control: public, max-age=31536000, immutable

# In Flask:
from flask import make_response

@app.get("/api/users")
def get_users():
    response = make_response(jsonify(users))
    response.headers["Cache-Control"] = "public, max-age=60"
    return response

# Application-level caching (Redis)
import redis
import json

r = redis.Redis()
CACHE_TTL = 300  # 5 minutes

def get_users_cached():
    cache_key = "users:all"
    cached = r.get(cache_key)
    if cached:
        return json.loads(cached)

    users = fetch_users_from_db()  # Slow
    r.setex(cache_key, CACHE_TTL, json.dumps(users))
    return users
```

### API Performance: Pagination (Avoid Unbounded Responses)

```python
# Large responses cause timeouts and memory issues
# Always paginate collection endpoints

@app.get("/api/orders")
def get_orders():
    page = int(request.args.get("page", 1))
    per_page = min(int(request.args.get("per_page", 50)), 100)

    # Database-level pagination (efficient — let DB do it)
    orders = (
        db.query(Order)
        .order_by(Order.created_at.desc())
        .offset((page - 1) * per_page)
        .limit(per_page)
        .all()
    )

    total = db.query(func.count(Order.id)).scalar()

    return {
        "data": [order.to_dict() for order in orders],
        "meta": {
            "page": page,
            "per_page": per_page,
            "total": total,
            "pages": (total + per_page - 1) // per_page
        }
    }
```

### Database: Index Strategy

```sql
-- See database-patterns skill for full details

-- Index every foreign key
CREATE INDEX idx_orders_user_id ON orders(user_id);

-- Composite index for common query patterns
-- Query: SELECT * FROM posts WHERE user_id = ? ORDER BY created_at DESC
CREATE INDEX idx_posts_user_created ON posts(user_id, created_at DESC);

-- Partial index for filtered queries (PostgreSQL)
CREATE INDEX idx_posts_published ON posts(id) WHERE status = 'published';

-- Check if index is used — run EXPLAIN before and after
EXPLAIN QUERY PLAN SELECT * FROM posts WHERE user_id = 123 ORDER BY created_at DESC;
```

### Database: N+1 Query Elimination

```python
# See database-patterns skill for full details

# Wrong: N+1 queries
users = db.query(User).limit(100).all()
for user in users:
    print(user.posts)  # One query per user = 101 queries

# Correct: Eager loading
from sqlalchemy.orm import joinedload, selectinload

users = (
    db.query(User)
    .options(joinedload(User.posts))  # Single JOIN loads all posts
    .limit(100)
    .all()
)
# 1 or 2 queries total instead of 101
```

### Bundle Optimization

```javascript
// 1. Analyze bundle size
// webpack-bundle-analyzer or source-map-explorer
npx webpack --profile --json > stats.json
npx source-map-explorer dist/main.*.js

// 2. Tree-shaking (remove unused code)
// Ensure ES modules (import/export) not CommonJS
// Webpack/ Rollup automatically tree-shakes ES modules

// 3. Code splitting (split large modules)
const HeavyLibrary = async () => {
  // Dynamic import — only loads when called
  const module = await import('heavy-library');
  return module.default;
};

// 4. Treat dependencies as implementation details
// If you use 5 functions from lodash, import only those
// import { debounce, throttle } from 'lodash-es'  // Tree-shakeable
// Instead of: import _ from 'lodash'; _.debounce()

// 5. Compression (gzip/brotli)
// Server config for brotli (better than gzip):
// BrotliCompressionQuality: 11 (maximum)
// Works on all modern CDNs and browsers

// 6. Preload critical resources
// <link rel="preload" href="/fonts/important.woff2" as="font" crossorigin>
// <link rel="modulepreload" href="/main.js">
```

### Profiling Tools

```python
# Python profiling with cProfile
import cProfile
import pstats
import io

def profile_function(func, *args, **kwargs):
    profiler = cProfile.Profile()
    profiler.enable()

    result = func(*args, **kwargs)

    profiler.disable()

    # Print top 20 functions by cumulative time
    stream = io.StringIO()
    stats = pstats.Stats(profiler, stream=stream)
    stats.sort_stats(pstats.SortKey.CUMULATIVE)
    stats.print_stats(20)
    print(stream.getvalue())

    return result

# Python profiling with line_profiler (per-line timing)
# pip install line_profiler
# @profile decorator above the function to profile
# kernprof -l -v script.py

# Memory profiling
# pip install memory_profiler
from memory_profiler import profile

@profile
def memory_intensive_function():
    data = [x ** 2 for x in range(1000000)]
    return data
```

```javascript
// Node.js / JavaScript profiling
// Chrome DevTools Performance tab: record a profile
// Or use the V8 profiler programmatically:

const { Session } = require('inspector');
const fs = require('fs');

const session = new Session();
session.connect();

session.post('Profiler.enable', () => {
  session.post('Profiler.start', () => {
    // Run the code you want to profile
    myExpensiveFunction();

    session.post('Profiler.stop', (err, { profile }) => {
      fs.writeFileSync('profile.cpuprofile', JSON.stringify(profile));
      console.log('Profile saved to profile.cpuprofile');
    });
  });
});

// React DevTools Profiler
// <Profiler id="ComponentName" onRender={onRenderCallback}>
//   <ComponentToProfile />
// </Profiler>
```

---

## Anti-Patterns

- **Premature micro-optimization** — Changing `dict.get()` to `dict[key]` to save a function call is not worth it. The readability loss is greater than the performance gain.

- **Optimizing cold paths** — Spending a day optimizing code that runs once per month is wasted effort. Optimize the code that runs on every request.

- **Ignoring algorithmic complexity** — O(n^2) code that could be O(n log n). Always check the algorithm before micro-optimizing.

- **Memoizing everything** — React.memo, useMemo, and useCallback have costs (comparison overhead, memory). Only use them when you have evidence they help.

- **Large bundle without code splitting** — A 2MB JavaScript bundle blocks the initial render. Users on slow connections see a blank screen.

- **No caching on expensive operations** — Fetching the same data from a database or API repeatedly when it rarely changes. Cache with appropriate TTL.

- **Ignoring the network** — Network latency is often the biggest bottleneck. Minimize round trips, compress data, use HTTP/2 multiplexing.

---

## Quick Reference

| Concern | Optimization | Tool |
|---------|-------------|------|
| Slow React renders | React.memo, useMemo | React DevTools Profiler |
| Large bundle | Code splitting, lazy loading | webpack-bundle-analyzer |
| Slow DB queries | Add indexes, eager loading | EXPLAIN QUERY PLAN |
| Repeated API calls | HTTP caching, Redis | Cache-Control, Redis |
| N+1 queries | joinedload/selectinload | SQLAlchemy profiler |
| Slow initial load | Lazy routes, preload | React.lazy, link preload |
| Memory bloat | Profiling, streaming | memory_profiler, Chrome heap |
| Cold starts | Keep warm, smaller images | AWS Lambda, Railway |

### Performance Checklist

```
BEFORE OPTIMIZING:
[ ] Profile the application to find hot spots
[ ] Measure current performance (baseline)
[ ] Identify the 20% of code causing 80% of time

OPTIMIZING:
[ ] Cache expensive operations (Redis, HTTP cache)
[ ] Add database indexes for slow queries
[ ] Eliminate N+1 queries with eager loading
[ ] Code-split large JavaScript bundles
[ ] Lazy-load non-critical components
[ ] Optimize images (WebP, lazy loading)
[ ] Use CDN for static assets
[ ] Reduce network round trips (batching, pagination)

AFTER OPTIMIZING:
[ ] Measure again — verify improvement
[ ] Check for regressions in other areas
[ ] Document what was changed and why
```
