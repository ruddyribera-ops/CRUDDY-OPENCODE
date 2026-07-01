---
name: database-patterns
description: "SQL/SQLite migration patterns, seed data, and query utilities. Use when designing schemas, writing migrations, seeding test data, or optimizing queries. Triggers: migration, seed data, SQLite, PostgreSQL, schema, connection pool, index strategy, N+1, ORM."
---

# Database Patterns

## When to use this

Load this skill when designing database schemas, writing migration scripts, setting up seed data, reviewing ORM usage for query performance, or optimizing slow database access patterns.

---

## Core Principles

1. **Forward-only migrations with explicit versioning** — Never edit a migration that has been applied to any environment. Each migration is immutable. Use a `schema_migrations` table to track what has been applied.

2. **Idempotent seed data** — Seed data must be re-runnable without duplicates or errors. Use `ON CONFLICT DO NOTHING` or `INSERT OR IGNORE` so running seeds on an already-seeded database is safe.

3. **Never use SELECT *** in application code — Explicit column lists prevent breakage when schema changes and make query intent clear.

4. **Connection pooling is mandatory in production** — Without pooling, every request opens a new connection (slow, exhausts DB connections under load). Set max pool size based on your DB's connection limit.

5. **Every foreign key needs an index** — JOINs on unindexed FK columns cause full table scans. Add the index proactively.

6. **N+1 queries are the most common ORM performance bug** — Always eager-load relationships when iterating over collections. Measure query count in tests.

7. **Understand the query plan before adding an index** — Run `EXPLAIN QUERY PLAN` (SQLite) or `EXPLAIN ANALYZE` (PostgreSQL) to verify the index is actually used.

---

## Patterns

### Migration Framework (Forward-Only, Versioned)

```
migrations/
  000_initial_schema.sql
  001_add_users_table.sql
  002_add_posts_table.sql
  003_add_user_status.sql
  ...

schema_migrations (table — tracks applied migrations)
```

```sql
-- PostgreSQL: schema_migrations table
CREATE TABLE IF NOT EXISTS schema_migrations (
    version     INTEGER PRIMARY KEY,
    applied_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    description TEXT NOT NULL
);

-- SQLite: same pattern
CREATE TABLE IF NOT EXISTS schema_migrations (
    version     INTEGER PRIMARY KEY,
    applied_at  TEXT NOT NULL DEFAULT (datetime('now')),
    description TEXT NOT NULL
);
```

```sql
-- Migration 001: Initial schema
-- Mark as applied first (idempotent check)
INSERT INTO schema_migrations (version, description)
VALUES (1, 'Initial schema')
ON CONFLICT (version) DO NOTHING;

-- Only run if not already applied
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM schema_migrations WHERE version = 1) THEN
        CREATE TABLE IF NOT EXISTS users (
            id          SERIAL PRIMARY KEY,
            email       VARCHAR(255) NOT NULL UNIQUE,
            created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        INSERT INTO schema_migrations (version, description) VALUES (1, 'Initial schema');
    END IF;
END $$;
```

### Idempotent Seed Data (PostgreSQL)

```sql
-- seeds/001_seed_roles.sql

BEGIN;

-- Seed roles: Insert only if not exists
INSERT INTO roles (name, description, permissions)
VALUES
    ('admin', 'Full system access', ARRAY['read', 'write', 'delete', 'admin']),
    ('editor', 'Can create and edit content', ARRAY['read', 'write']),
    ('viewer', 'Read-only access', ARRAY['read'])
ON CONFLICT (name) DO UPDATE
    SET description = EXCLUDED.description,
        permissions = EXCLUDED.permissions;

-- Seed a default admin user (password: admin123 — CHANGE IN PRODUCTION)
INSERT INTO users (email, role, password_hash)
VALUES ('admin@example.com', 'admin', 'PLACEHOLDER_HASH')
ON CONFLICT (email) DO NOTHING;

COMMIT;
```

### Idempotent Seed Data (SQLite)

```sql
-- seeds/001_seed_roles.sql

-- Create roles table if not exists
CREATE TABLE IF NOT EXISTS roles (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT NOT NULL UNIQUE,
    description TEXT,
    permissions TEXT  -- JSON array as text
);

-- Seed data: INSERT OR IGNORE skips duplicates
INSERT OR IGNORE INTO roles (name, description, permissions)
VALUES
    ('admin', 'Full system access', '["read","write","delete"]'),
    ('editor', 'Can create and edit', '["read","write"]'),
    ('viewer', 'Read-only', '["read"]');

-- Seed admin user
INSERT OR IGNORE INTO users (email, role_id, password_hash)
VALUES ('admin@example.com', 1, 'PLACEHOLDER_HASH');
```

### Parameterized Query Utilities (Python)

```python
from typing import Any, Sequence
from sqlalchemy import text

class QueryHelper:
    """Safe parameterized query utilities."""

    def __init__(self, session):
        self.session = session

    def fetch_one(self, query: str, params: dict) -> dict | None:
        """Execute a parameterized SELECT and return one row as dict."""
        result = self.session.execute(text(query), params)
        row = result.fetchone()
        return dict(row._mapping) if row else None

    def fetch_all(self, query: str, params: dict | None = None) -> list[dict]:
        """Execute a parameterized SELECT and return all rows as dicts."""
        result = self.session.execute(text(query), params or {})
        return [dict(row._mapping) for row in result.fetchall()]

    def execute(self, query: str, params: dict | None = None) -> None:
        """Execute a parameterized INSERT/UPDATE/DELETE."""
        self.session.execute(text(query), params or {})
        self.session.commit()


# Usage:
helper = QueryHelper(session)

# Safe parameterized query
user = helper.fetch_one(
    "SELECT id, email, status FROM users WHERE email = :email AND status = :status",
    {"email": user_email, "status": "active"}
)

# Batch insert
helper.execute(
    "INSERT INTO audit_log (user_id, action, created_at) VALUES (:user_id, :action, NOW())",
    {"user_id": 123, "action": "login"}
)
```

### Connection Pooling (Python / SQLAlchemy)

```python
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

# Production engine with connection pooling
engine = create_engine(
    "postgresql://user:pass@localhost:5432/mydb",
    poolclass=QueuePool,
    pool_size=10,          # Connections to keep open
    max_overflow=20,       # Additional connections under load (10 + 20 = 30 max)
    pool_timeout=30,       # Seconds to wait for a connection from pool
    pool_recycle=3600,     # Recycle connections after 1 hour (prevents stale connections)
    pool_pre_ping=True,    # Verify connection is alive before using
    echo=False,            # Set True for SQL query logging
)

# Usage:
with engine.connect() as conn:
    result = conn.execute(text("SELECT 1"))
```

### Index Strategy

```sql
-- ALWAYS index foreign keys
CREATE INDEX idx_posts_user_id ON posts(user_id);          -- FK, almost always needed
CREATE INDEX idx_comments_post_id ON comments(post_id);    -- FK, almost always needed

-- Index columns used in WHERE, ORDER BY, and JOIN conditions
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);  -- Pagination
CREATE INDEX idx_users_email ON users(email);                  -- Login lookup

-- Composite index for common query patterns
CREATE INDEX idx_posts_user_created ON posts(user_id, created_at DESC);
-- Query: SELECT * FROM posts WHERE user_id = ? ORDER BY created_at DESC
-- Both conditions are served by this single composite index

-- Partial index for filtered queries (PostgreSQL)
CREATE INDEX idx_posts_published ON posts(id) WHERE status = 'published';
-- Only the subset of rows with status='published' are indexed
```

### Avoiding N+1 Queries

```python
# WRONG: N+1 query problem
users = session.query(User).limit(100).all()
for user in users:
    # This executes ONE query per user
    print(user.posts)  # Lazy load — 1 query per iteration = 101 total queries
    print(user.comments.count())  # Another query per user

# CORRECT: Eager loading with joinedload
from sqlalchemy.orm import joinedload

users = (
    session.query(User)
    .options(joinedload(User.posts))        # Single JOIN for all posts
    .options(joinedload(User.comments))     # Single JOIN for all comments
    .limit(100)
    .all()
)
# 1 query (with two LEFT OUTER JOINs)

# CORRECT: selectinload for large collections (avoids cartesian product)
from sqlalchemy.orm import selectinload

users = (
    session.query(User)
    .options(selectinload(User.posts))       # 2 queries: users + posts WHERE user_id IN (...)
    .options(selectinload(User.comments))    # 2 queries: users + comments WHERE user_id IN (...)
    .limit(100)
    .all()
)

# CORRECT: Explicit subquery for count
from sqlalchemy import func

user_post_counts = (
    session.query(
        User.id,
        User.email,
        func.count(Post.id).label('post_count')
    )
    .outerjoin(Post)
    .group_by(User.id)
    .limit(100)
    .all()
)
# Single query with GROUP BY — no N+1
```

### Query Plan Analysis

```sql
-- PostgreSQL: EXPLAIN ANALYZE shows actual execution plan with timing
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT u.id, u.email, COUNT(p.id) as post_count
FROM users u
LEFT JOIN posts p ON p.user_id = u.id
WHERE u.created_at > '2024-01-01'
GROUP BY u.id, u.email;

-- SQLite: EXPLAIN QUERY PLAN
EXPLAIN QUERY PLAN
SELECT u.id, u.email, COUNT(p.id)
FROM users u
LEFT JOIN posts p ON p.user_id = u.id
WHERE u.created_at > '2024-01-01'
GROUP BY u.id, u.email;

-- Key things to look for:
-- - "Seq Scan" on large tables = full table scan, needs index
-- - "Index Scan" = good, index is being used
-- - "Hash Join" vs "Nested Loop" — hash join is usually better for large sets
-- - "Using index" in SQLite EXPLAIN = good
```

---

## Anti-Patterns

- **SELECT *** in application code — Fragile when columns are added, renamed, or reordered. Always specify the columns you need.

- **N+1 queries** — The single most common database performance bug. Use eager loading (`joinedload`, `selectinload`) whenever iterating over a collection.

- **Missing indexes on foreign keys** — JOINs on unindexed FK columns cause table scans. Index every FK column.

- **SELECT without WHERE on large tables** — A `SELECT * FROM huge_table` without a LIMIT can exhaust memory and lock the table.

- **ORM usage without understanding the generated SQL** — ORMs generate SQL. If you do not understand what SQL your ORM is producing, you will write N+1 queries and missing index problems.

- **Migrations that lock tables** — Some DDL operations in PostgreSQL (e.g., adding a NOT NULL column without a default) lock the table. Use `CREATE INDEX CONCURRENTLY` for production indexes.

- **No connection pool or pool too small** — Without pooling, every request opens a new connection. Under load, this exhausts the DB connection limit and causes "too many connections" errors.

- **Backfilling data without batching** — Updating millions of rows in a single UPDATE statement can lock the table and fill the transaction log. Use batched updates with `LIMIT`.

---

## Quick Reference

| Concern | Correct | Anti-Pattern |
|---------|---------|--------------|
| Query columns | `SELECT id, email FROM` | `SELECT * FROM` |
| N+1 | `joinedload(User.posts)` | `for user in users: user.posts` |
| FK columns | Always indexed | No index on FK |
| Migrations | Forward-only, versioned | Edit applied migrations |
| Seed data | `ON CONFLICT DO NOTHING` | `INSERT` (duplicate key) |
| Connection | Pool with size 10+ | No pooling |
| Large UPDATE | Batched with LIMIT | Single UPDATE millions of rows |
| Schema change | Add new migration | Modify old migration file |

### Batch Update Pattern (PostgreSQL)

```sql
-- Backfill in batches of 1000 to avoid locking
DO $$
DECLARE
    batch_size INT := 1000;
    offset_val INT := 0;
    rows_updated INT;
BEGIN
    LOOP
        UPDATE users
        SET status = 'active'
        FROM (
            SELECT id FROM users
            WHERE status = 'pending'
            LIMIT batch_size
        ) AS batch
        WHERE users.id = batch.id;

        GET DIAGNOSTICS rows_updated = ROW_COUNT;
        EXIT WHEN rows_updated = 0;

        -- Commit this batch and start next
        COMMIT;
        offset_val := offset_val + batch_size;
    END LOOP;
END $$;
```

### Seed Data Checklist

```sql
-- Before running seeds in production:
-- 1. Verify schema_migrations is at the correct version
-- 2. Check that seed data doesn't conflict with existing data
-- 3. Use ON CONFLICT DO NOTHING for all INSERT statements
-- 4. Verify seed data with a SELECT after running

SELECT COUNT(*) FROM roles;  -- Should return 3 (admin, editor, viewer)
SELECT email FROM users WHERE role = 'admin';  -- Should return admin@example.com
```
