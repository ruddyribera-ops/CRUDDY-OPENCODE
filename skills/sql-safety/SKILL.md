---
name: sql-safety
description: Parameterized queries only. PostgreSQL/SQLite type discipline. Idempotent migrations via ON CONFLICT.
triggers: [sql, query, database, migration, select, insert, update, delete, postgresql, sqlite, orm, sqlalchemy, prisma]
---

# SQL Safety

## What it does
Enforces parameterized queries (no string concatenation) and database-engine-aware type discipline. Prevents SQL injection, type coercion bugs, and broken migration re-runs.

## When to use
- Writing any database query (raw SQL or ORM)
- Creating migrations
- Reviewing query code for injection risk
- Switching between PostgreSQL and SQLite

## Rules

1. **Never concatenate strings into SQL.** Always use parameterized queries. The only exception is dynamic table/column names from a hardcoded allowlist.
2. **PostgreSQL `ON CONFLICT` requires a unique CONSTRAINT, not just an INDEX.** If you only have an index, `ON CONFLICT (col) DO NOTHING` fails. Use `CREATE UNIQUE INDEX` or define a constraint first.
3. **SQLite: TEXT for strings.** No VARCHAR/LIMIT clauses (they're ignored). Use `INTEGER PRIMARY KEY` for auto-increment IDs.
4. **PostgreSQL: native UUID type for IDs.** Not TEXT. The `uuid` type is indexable, smaller, and validates format.
5. **PostgreSQL inserts: use `RETURNING *`.** Not `last_insert_rowid()` (that's SQLite). `RETURNING` is atomic and works in a single round-trip.
6. **Migrations must be idempotent.** Use `CREATE TABLE IF NOT EXISTS`, `ON CONFLICT DO NOTHING` for seeds. Otherwise re-running a failed migration breaks the DB.
7. **Always specify the schema or search_path explicitly** in multi-tenant PostgreSQL setups. Otherwise queries hit `public` by default.

## Anti-patterns

- ❌ `f"SELECT * FROM users WHERE id = {user_id}"` — SQL injection
- ❌ `cursor.execute("SELECT * FROM users WHERE name = '" + name + "'")` — same
- ❌ `last_insert_rowid()` on PostgreSQL — doesn't exist, use `RETURNING id`
- ❌ `VARCHAR(255)` in SQLite — silently ignored, but misleading
- ❌ Storing UUIDs as TEXT in PostgreSQL — wastes space, no format validation
- ❌ Migration that fails halfway and can't be re-run — always use `IF NOT EXISTS` and `ON CONFLICT`
- ❌ `SELECT *` in production code — schema changes break callers

## Example (correct)

```python
# ✅ Parameterized
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))

# ✅ PostgreSQL RETURNING
cursor.execute(
    "INSERT INTO users (email, name) VALUES (%s, %s) RETURNING id",
    (email, name)
)
user_id = cursor.fetchone()[0]

# ✅ Idempotent seed
cursor.execute(
    "INSERT INTO roles (name) VALUES (%s) ON CONFLICT (name) DO NOTHING",
    ('admin',)
)
```

```sql
-- ✅ Migration with proper unique constraint
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,  -- UNIQUE creates a constraint
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ❌ This would FAIL with ON CONFLICT (email) DO NOTHING
-- CREATE INDEX idx_users_email ON users(email);
```

## References

- PostgreSQL INSERT: https://www.postgresql.org/docs/current/sql-insert.html
- SQLite Type Affinity: https://www.sqlite.org/datatype3.html
- `database-patterns` skill — broader DB design and migration patterns
