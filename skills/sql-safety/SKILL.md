---
name: sql-safety
description: "Parameterized queries only. PostgreSQL/SQLite type discipline. Idempotent migrations via ON CONFLICT. Use when writing database code, designing migrations, or reviewing SQL. Triggers: SQL injection, parameterized query, migration, ON CONFLICT, schema, Postgres, SQLite, DROP TABLE, idempotent."
---

# SQL Safety

## When to use this

Load this skill whenever you write SQL queries, design database migrations, review SQL-generating code, or work with any ORM's raw query interface. Every SQL safety violation is a potential data breach.

---

## Core Principles

1. **Parameterized queries always, no exceptions** — User input must never be interpolated into SQL strings. The only safe SQL is parameterized SQL.

2. **Type discipline: match the column type** — Do not pass integers as strings or strings as integers. PostgreSQL and SQLite have type affinity rules that can cause silent coercion or index mismatches.

3. **Idempotent migrations are mandatory** — A migration must be safe to run multiple times. Use `ON CONFLICT DO NOTHING` or `ON CONFLICT DO UPDATE` so re-runs do not fail.

4. **Forward-only migrations with version control** — Never modify a migration file that has been applied to production. Add a new migration file instead. Maintain a schema version table.

5. **No destructive operations without explicit backup** — `DROP TABLE`, `DROP COLUMN`, and `TRUNCATE` must be reviewed and tested. Always generate a backup migration or take a DB snapshot first.

6. **The ORM is not a security layer** — Using an ORM does not automatically prevent SQL injection. Raw queries, `extra()` calls, and `QuerySet.filter()` with `__raw` can all introduce SQL injection.

7. **Index every foreign key** — Missing indexes on foreign key columns cause table scans on every JOIN. Add them proactively, but understand the write cost.

---

## Patterns

### Parameterized Queries (Python / psycopg2)

```python
# CORRECT: Parameterized query — user_input is never interpolated as SQL
cursor.execute(
    "SELECT id, name FROM users WHERE email = %s AND status = %s",
    (user_input_email, "active")
)

# WRONG: String interpolation — SQL injection vulnerability
cursor.execute(
    f"SELECT id, name FROM users WHERE email = '{user_input_email}'"
)
```

### Parameterized Queries (Node.js / pg)

```javascript
// CORRECT: Parameterized query
const result = await pool.query(
  'SELECT id, name FROM users WHERE email = $1 AND status = $2',
  [userInputEmail, 'active']
)

// WRONG: Template literal interpolation — SQL injection
const result = await pool.query(
  `SELECT id, name FROM users WHERE email = '${userInputEmail}'`
)
```

### Parameterized Queries (SQLite / Python)

```python
# CORRECT: Parameterized query with ? placeholders
cursor.execute(
    "SELECT id, name FROM users WHERE email = ? AND status = ?",
    (user_input_email, "active")
)

# WRONG: f-string interpolation
cursor.execute(
    f"SELECT id, name FROM users WHERE email = '{user_input_email}'"
)
```

### Idempotent Migration Pattern (PostgreSQL)

```sql
-- Migration: 003_add_user_status.sql

-- Idempotent: Creates table only if it does not exist
CREATE TABLE IF NOT EXISTS users (
    id          SERIAL PRIMARY KEY,
    email       VARCHAR(255) NOT NULL UNIQUE,
    status      VARCHAR(50) NOT NULL DEFAULT 'inactive',
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Idempotent: Adds column only if it does not exist (PostgreSQL 9.1+)
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login TIMESTAMP;

-- Idempotent index creation
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Idempotent constraint addition
ALTER TABLE users ADD CONSTRAINT users_status_check
    CHECK (status IN ('active', 'inactive', 'suspended'))
    NOT VALID;  -- Do not re-check existing rows

-- Seed data: Insert only if not exists
INSERT INTO users (email, status)
VALUES ('admin@example.com', 'active')
ON CONFLICT (email) DO NOTHING;
```

### Idempotent Migration Pattern (SQLite)

```sql
-- Migration: 003_add_user_status.sql

-- SQLite does not support IF NOT EXISTS for ALTER TABLE
-- Use a migration tracking table approach:

CREATE TABLE IF NOT EXISTS schema_migrations (
    version INTEGER PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Check before applying
INSERT OR IGNORE INTO schema_migrations (version) VALUES (3);

-- Now apply the migration only if not already applied
-- (wrapping in a transaction is recommended)
BEGIN TRANSACTION;
-- Your migration DDL here
COMMIT;
```

### Safe ORM Usage (Django)

```python
# CORRECT: Django ORM — safe from injection
User.objects.filter(email=user_email, status="active")

# CAUTION: .extra() can introduce SQL injection if values are not safely quoted
User.objects.extra(
    where=["email = '%s'" % user_email]  # WRONG — vulnerable
)

# CORRECT: Use .extra() with params if needed
User.objects.extra(
    where=["email = %s"],
    params=[user_email]  # properly parameterized
)
```

### Safe ORM Usage (SQLAlchemy)

```python
from sqlalchemy import text

# CORRECT: SQLAlchemy Core parameterized query
result = session.execute(
    text("SELECT id, name FROM users WHERE email = :email AND status = :status"),
    {"email": user_email, "status": "active"}
)

# CORRECT: SQLAlchemy ORM query
user = session.query(User).filter(
    User.email == user_email,
    User.status == "active"
).first()

# WRONG: String interpolation in raw SQL
result = session.execute(
    text(f"SELECT id, name FROM users WHERE email = '{user_email}'")
)
```

### Schema Version Tracking

```sql
-- PostgreSQL schema version table
CREATE TABLE IF NOT EXISTS schema_version (
    version     INTEGER PRIMARY KEY,
    applied_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);

-- Mark migration as applied
INSERT INTO schema_version (version, description)
VALUES (3, 'Add user status column')
ON CONFLICT (version) DO NOTHING;

-- Verify version before running migration script
-- Migration 003_add_user_status.sql:
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM schema_version WHERE version = 3) THEN
        -- Apply DDL
        ALTER TABLE users ADD COLUMN IF NOT EXISTS status VARCHAR(50);
        -- Mark done
        INSERT INTO schema_version (version, description) VALUES (3, 'Add user status column');
    END IF;
END $$;
```

### Preventing N+1 Queries (the most common ORM anti-pattern)

```python
# WRONG: N+1 query problem
users = session.query(User).limit(100).all()
for user in users:
    print(user.orders.all())  # One query per user = 101 queries

# CORRECT: Eager loading with join
users = (
    session.query(User)
    .options(joinedload(User.orders))
    .limit(100)
    .all()
)
# 1 query (or 2 with selectinload for large collections)
```

---

## Anti-Patterns

- **String concatenation in SQL queries** — Even a single occurrence can lead to data exfiltration or deletion. Use parameterized queries exclusively.

- **DROP TABLE or DROP COLUMN in production migrations** — These are destructive and irreversible without a backup. Always create a backup migration or take a DB snapshot before applying.

- **No migration rollback plan** — Forward-only migrations mean you must be able to re-apply forward from any state. Without version tracking, you cannot safely re-run migrations on a fresh database.

- **Using SELECT * in application code** — This breaks when columns are added, renamed, or reordered. Always specify the columns you need.

- **Trusting ORM raw query methods** — Methods like Django's `.extra()`, Rails' `.find_by_sql()`, and SQLAlchemy's `text()` with f-strings bypass ORM safety.

- **Missing indexes on foreign keys** — Every foreign key column needs an index for JOIN performance. Adding indexes after the table has millions of rows causes table locks on some databases.

- **No transaction around migrations** — Each migration should be atomic. If a migration fails halfway through, the DB should roll back to its previous state.

---

## Quick Reference

| Pattern | Correct | Wrong |
|---------|---------|-------|
| User input in SQL | `cursor.execute("...WHERE x = %s", (val,))` | `f"WHERE x = '{val}'"` |
| Create table | `CREATE TABLE IF NOT EXISTS` | `CREATE TABLE` (fails on re-run) |
| Add column | `ALTER TABLE ADD COLUMN IF NOT EXISTS` | `ALTER TABLE ADD COLUMN` (Postgres) |
| Seed data | `INSERT ... ON CONFLICT DO NOTHING` | `INSERT` (duplicate key error) |
| Drop object | Backup first, then DROP with IF EXISTS | `DROP TABLE mytable` (no backup) |
| Foreign key | Always index the FK column | Skip index "to keep it simple" |
| ORM raw SQL | Use parameterized helpers | `text(f"...{x}...")` interpolation |

### SQL Injection Attack Vectors to Block

```sql
-- Classic injection: ' OR '1'='1
-- Input: "'; DROP TABLE users; --"
-- Dangerous query: SELECT * FROM users WHERE name = '${input}'
-- Becomes: SELECT * FROM users WHERE name = ''; DROP TABLE users; --'

-- Parameterized blocks all of these because the entire
-- string is treated as a literal value, not executable SQL.
```

### Index Strategy Checklist

```sql
-- Add index when: FK column, frequently filtered column, ORDER BY column
CREATE INDEX idx_orders_user_id ON orders(user_id);  -- FK, almost always needed
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);  -- pagination

-- Do NOT add index when: low-cardinality columns (gender, boolean flags),
-- unless they are used in composite indexes with high-cardinality columns
```
