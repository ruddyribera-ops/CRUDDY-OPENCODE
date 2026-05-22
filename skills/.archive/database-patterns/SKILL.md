---
name: database-patterns
description: SQL/SQLite/PostgreSQL migration patterns, seed data, query utilities, and modern databases (Supabase, PocketBase, Neon, InfluxDB, Neo4j, TypeDB)
tags: [database, sql, backend, storage]
---

# Database Patterns

## When to Use
- SQL/SQLite schema design, migrations, and seed data
- PostgreSQL/MySQL query optimization
- Modern databases: Supabase, PocketBase, Neon, InfluxDB, Neo4j, TypeDB
- Data migration workflows with backup/restore
- SQLite ↔ PostgreSQL type drift resolution

## Do Not Use
- Python async patterns (use python-patterns)
- Deployment/Docker setup (use deployment-patterns)
- Data analysis with pandas (use data-analysis)

## SQLite / sql.js (Browser-compatible)

**Core patterns:** table creation (CREATE IF NOT EXISTS), idempotent column migration, seed-only-if-empty, query utilities.

→ See `references/sql-patterns.md` for complete code examples.

## PostgreSQL / MySQL
- Use migration tools (knex, prisma, sequelize)
- Never ALTER TABLE in production without backup
- Connection pooling for high traffic

## SQLite ↔ PostgreSQL Type Drift
SQLite is permissive; PostgreSQL is strict. Common dev→prod bug: booleans and type mismatches.

→ See `references/sql-patterns.md` for the booleans trap, idempotent type migration, and dev-vs-prod parity checklist.

## PostgreSQL Bulk Operations
Bulk insert with `executemany`, skip duplicates with `ON CONFLICT DO NOTHING`, JSON backup & restore.

→ See `references/sql-patterns.md` for code examples.

## Data Migration Workflow (CRITICAL)
1. CREATE BACKUP first — never skip
2. Verify backup row count
3. Inform user → wait for confirmation
4. Execute → verify → spot-check

→ See `references/sql-patterns.md` for backup script template and verification queries.

## Modern Databases (Quick Nav)

| Database | Best For | Resource |
|----------|----------|----------|
| [Supabase](resources/supabase.md) | Auth + Postgres + Realtime | Firebase alternative |
| [PocketBase](resources/pocketbase.md) | Single-file Go backend | Embedded SQLite |
| [Neon](resources/neon.md) | Serverless Postgres | Scale-to-zero branching |
| [InfluxDB](resources/influxdb.md) | IoT, metrics, observability | Time-series |
| [Neo4j](resources/neo4j.md) | Social networks, fraud | Graph traversal |
| [TypeDB](resources/typedb.md) | Knowledge graphs, complex domains | Type system + inference |

## Ecosystem
- **ORMs:** sqlalchemy, sqlmodel, peewee, tortoise-orm, ponyorm, piccolo
- **Drivers:** asyncpg, psycopg2, aiosqlite, databases, records
- **NoSQL:** beanie (MongoDB), motor, redis-py, fakeredis
- **Search:** elasticsearch-dsl, meilisearch, typesense, whoosh
- **Caching:** aiocache, cachetools, diskcache, dogpile.cache
- **Migration:** alembic, yoyo-migrations, sqitch

## Verification
- [ ] Table creation is idempotent (CREATE IF NOT EXISTS)
- [ ] Seed data only inserts when table is empty
- [ ] Backup exists before destructive operations
- [ ] Row counts match expectations after migration
- [ ] PostgreSQL columns have correct types (no boolean→int drift)
- [ ] All reference links resolve to existing files
