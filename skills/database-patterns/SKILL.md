---
name: database-patterns
description: Database design, migrations, query optimization, ORM patterns, indexing, and data modeling. PostgreSQL-focused with SQLite patterns for development. Covers schema design, migrations, seeds, and production query tuning.
triggers: [database, sql, query, migration, schema, table, index, postgresql, sqlite, prisma, drizzle, sqlalchemy, sequelize, typeorm, knex, model, relation, join, n+1, slow query, optimize query]
---

# Database Patterns

## Core Principles

1. **Schema as source of truth** — migrations are version-controlled, reviewed, and tested
2. **Index for your queries** — index columns used in WHERE, JOIN, ORDER BY, not every column
3. **Never trust ORM defaults** — understand what SQL your ORM generates
4. **Idempotent migrations** — run up/down repeatedly without side effects

---

## 1. Schema Design Principles

### Naming Convention

```sql
-- Tables: plural snake_case
users, orders, order_items, product_categories

-- Columns: singular snake_case
user_id, created_at, email_address

-- Primary Key: id (auto-increment or UUID)
-- Foreign Key: <singular_table>_id
-- Timestamps: created_at, updated_at
-- Soft Delete: deleted_at (nullable, NULL = not deleted)

-- Indexes: idx_<table>_<columns>
CREATE INDEX idx_users_email ON users(email);
CREATE UNIQUE INDEX idx_users_email_unique ON users(email) WHERE deleted_at IS NULL;
```

### Data Types (PostgreSQL)

```sql
-- IDs: UUID (not SERIAL for any public-facing system)
id UUID PRIMARY KEY DEFAULT gen_random_uuid()

-- Strings: TEXT (not VARCHAR with arbitrary limits)
email TEXT NOT NULL

-- Money: NUMERIC(10,2) — never FLOAT for currency
price NUMERIC(10, 2) NOT NULL

-- Status: TEXT with CHECK constraint (not ENUM for simple cases)
status TEXT NOT NULL CHECK (status IN ('active', 'inactive', 'suspended'))

-- Better: custom ENUM for values used across multiple tables
CREATE TYPE user_status AS ENUM ('active', 'inactive', 'suspended');

-- JSON: JSONB (not JSON — JSONB is indexable, supports GIN indexes)
metadata JSONB DEFAULT '{}'::jsonb

-- Timestamps: TIMESTAMPTZ (always, never TIMESTAMP without TZ)
created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
```

---

## 2. Migration Patterns

### Migration File Format

```sql
-- V001__create_users.sql (Flyway-style) or timestamp-based
-- 20260522_create_users.sql

-- UP
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX idx_users_email ON users(email);

-- DOWN
DROP TABLE IF EXISTS users;
```

### Migration Rules

```
1. NEVER modify an existing migration that has been merged/reviewed
2. NEW migration for every change (up + down always)
3. Down migration must exactly reverse the up migration
4. Test both up and down before committing
5. One logical change per migration (not 20 unrelated schema changes)
```

### Seed Data Pattern

```sql
-- Always ON CONFLICT DO NOTHING (idempotent)
INSERT INTO users (id, email, password_hash, role)
VALUES ('00000000-0000-0000-0000-000000000001', 'admin@example.com', '$2b$12$...', 'admin')
ON CONFLICT (id) DO NOTHING;
```

---

## 3. Query Optimization

### The N+1 Problem

```python
# ❌ BAD: N+1 queries
users = User.query.all()
for user in users:
    print(user.profile.name)  # 1 query per user

# ✅ CORRECT: Eager loading
users = User.query.options(joinedload(User.profile)).all()
for user in users:
    print(user.profile.name)  # 2 queries total (1 for users, 1 joined)
```

```javascript
// ❌ BAD (Prisma):
const users = await prisma.user.findMany();
for (const user of users) {
  await prisma.profile.findUnique({ where: { userId: user.id } });  // N+1
}

// ✅ CORRECT (Prisma):
const users = await prisma.user.findMany({
  include: { profile: true }
});  // 1 query with JOIN
```

### Index Strategy

```sql
-- Use EXPLAIN ANALYZE before optimizing
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test@example.com';

-- Composite index order matters: most selective first
-- Good for: WHERE status = 'active' AND created_at > '2024-01-01'
CREATE INDEX idx_orders_status_created ON orders(status, created_at);

-- Partial indexes: index only the rows you query
CREATE INDEX idx_orders_pending ON orders(status) WHERE status = 'pending';

-- Covering indexes: include all columns the query needs
CREATE INDEX idx_users_email_cover ON users(email) INCLUDE (name, role);
```

### Common Query Patterns

```sql
-- Upsert (PostgreSQL):
INSERT INTO users (email, name)
VALUES ('test@example.com', 'Test')
ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name, updated_at = NOW();

-- Pagination (keyset/cursor — faster than OFFSET):
SELECT * FROM users WHERE created_at < $cursor ORDER BY created_at DESC LIMIT 20;

-- ℹ️ OFFSET pagination gets slow on large datasets because the database must read and skip all rows.
-- Keyset pagination uses the index directly and stays fast regardless of page depth.

-- Soft-delete filter (use on EVERY query):
SELECT * FROM users WHERE deleted_at IS NULL;

-- Window function (row number per group):
SELECT * FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC) AS rn
  FROM orders
) sub WHERE rn = 1;  -- latest order per user
```

---

## 4. ORM Patterns (Prisma, SQLAlchemy, Drizzle)

### Prisma

```prisma
model User {
  id        String   @id @default(uuid()) @db.Uuid
  email     String   @unique
  name      String?
  role      Role     @default(USER)
  posts     Post[]
  profile   Profile?
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")
  @@map("users")
}

enum Role {
  ADMIN
  USER
}

model Post {
  id        String   @id @default(uuid()) @db.Uuid
  title     String
  content   String?
  published Boolean  @default(false)
  authorId  String   @map("author_id") @db.Uuid
  author    User     @relation(fields: [authorId], references: [id])
  createdAt DateTime @default(now()) @map("created_at")
  @@map("posts")
  @@index([authorId, published])
}
```

### SQLAlchemy

```python
class User(Base):
    __tablename__ = "users"

    id: Mapped[UUID] = mapped_column(UUID, primary_key=True, default=uuid4)
    email: Mapped[str] = mapped_column(String, unique=True, nullable=False)
    posts: Mapped[list["Post"]] = relationship(back_populates="author", lazy="selectin")

class Post(Base):
    __tablename__ = "posts"

    id: Mapped[UUID] = mapped_column(UUID, primary_key=True, default=uuid4)
    author_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
    author: Mapped["User"] = relationship(back_populates="posts")
```

---

## 5. Anti-Patterns

| Anti-Pattern | Why | Fix |
|-------------|-----|-----|
| String concatenation in SQL | SQL injection | Parameterized queries always |
| SELECT * in production | Returns unused columns, breaks on schema changes | Name columns explicitly |
| No migration on schema change | Inconsistent environments | Every schema change = new migration file |
| Float for currency | Floating point rounding errors | NUMERIC(10,2) or integer cents |
| Offsetting large datasets | Gets slower the deeper you paginate | Keyset/cursor pagination |
| Missing unique constraint | Duplicate data over time | Always add UNIQUE where business logic requires uniqueness |
| No foreign key constraint | Orphaned rows | Always define FK constraints at DB level |
| ENUM modification in production | ENUM values are hard to change | Consider TEXT + CHECK or create migration to add/drop values |
| Storing JSON without JSONB (PostgreSQL) | JSONB is faster and indexable | Always use JSONB for PostgreSQL |

---

## 6. Migration Workflow

```
Local dev:   migration up → test → migration down → modify → migration up
PR review:   migration file reviewed alongside code
Staging:     migration up → seed → run tests
Production:  migration up (with backup) → verify → (down only for rollback)
```

---

## 7. Verification Checklist

- [ ] All user-facing IDs are UUIDs, not sequential integers
- [ ] Every migration has both up and down
- [ ] All queries use parameterized inputs (no string concatenation)
- [ ] N+1 queries checked and eager-loaded where needed
- [ ] EXPLAIN ANALYZE run on production-critical queries
- [ ] Indexes exist for all WHERE/JOIN/ORDER BY columns
- [ ] Currency stored as NUMERIC or integer cents
- [ ] Foreign keys defined at database level
- [ ] Unique constraints on fields that require uniqueness
- [ ] JSON stored as JSONB (PostgreSQL)
- [ ] Seed data is idempotent (ON CONFLICT DO NOTHING)
- [ ] Timestamps use TIMESTAMPTZ (not TIMESTAMP)
- [ ] Soft-delete queries filtered with WHERE deleted_at IS NULL
