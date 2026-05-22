# Neon — Serverless Postgres

Fully managed PostgreSQL with branching, autoscaling, and scale-to-zero.

## Quick Reference

| Feature | Description |
|---------|-------------|
| **Serverless** | Automatic scaling, scale-to-zero |
| **Branching** | Create dev branches like Git |
| **Full Postgres** | All PostgreSQL features |
| **Prisma support** | Native integration |

## Connection

```python
import psycopg2

# Standard connection (use connection string from Neon console)
conn = psycopg2.connect(
    connection_string="postgresql://user:password@xxx.neon.tech/dbname"
)

# Or with Prisma (schema.prisma)
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

# Prisma migrate
DATABASE_URL="postgresql://..." npx prisma migrate dev
```

## Branching Pattern

```bash
# Create a dev branch (like git branch)
neon branches create --name feature-x

# Connection string for branch
postgresql://user:password@xxx.feature-x.neon.tech/dbname

# Promote branch to main (after testing)
neon branches promote --name feature-x
```

## Serverless Driver (Python)

```python
import psycopg2.pool

# Use connection pool for serverless (avoids cold start latency)
pool = psycopg2.pool.ThreadedConnectionPool(
    minconn=1,
    maxconn=10,
    connection_string=os.environ['DATABASE_URL']
)

def handler(event, context):
    conn = pool.getconn()
    try:
        cur = conn.cursor()
        cur.execute("SELECT * FROM users WHERE id = %s", (user_id,))
        return cur.fetchone()
    finally:
        pool.putconn(conn)
```

## Autoscaling

```yaml
# neon.yaml (project config)
production:
  branch: main
  compute:
    min: 0.5  # Scale to zero
    max: 4
    scaling_step: 0.5

development:
  branch: dev
  compute:
    min: 0.25
    max: 1
```

## Edge Functions (Neon Serverless)

```typescript
// Deno edge function with Neon
import { neon } from '@neondatabase/serverless'

const sql = neon(process.env.DATABASE_URL!)

Deno.serve(async (req) => {
  const { user_id } = await req.json()
  const users = await sql`SELECT * FROM users WHERE id = ${user_id}`
  return new Response(JSON.stringify(users))
})
```

## Comparison

| Feature | Neon | Supabase | Traditional RDS |
|---------|------|----------|-----------------|
| Serverless | ✅ | Partial | ❌ |
| Branching | ✅ | ❌ | ❌ |
| Scale to zero | ✅ | ❌ | ❌ |
| Full Postgres | ✅ | ✅ | ✅ |
| Free tier | 0.5 GB | 500 MB | ❌ |

## Best Practices

- **Use Prisma** for type-safe queries and migrations
- **Connection pooling** via PgBouncer or built-in pooling
- **Idle timeout:** Set `connection_timeout=10` to handle cold starts
- **Migration:** Neon supports all standard PostgreSQL migration tools

## Resources

- [awesome-neon](https://github.com/tyaga001/awesome-neon)
- [neon.tech/docs](https://neon.tech/docs)