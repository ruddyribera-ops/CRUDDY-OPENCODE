---
name: Docker Compose local dev patterns
description: Docker Compose workflows for Math Platform and EduFlow — schema migrations, volumes, debugging, hot-reload
type: feedback
---

# Docker Compose Local Dev Patterns

Applies to: **Math Platform** (FastAPI + Next.js + Postgres + Redis) and **EduFlow** (Laravel + Next.js + Postgres + Redis)

## Critical Rules

**Why:** Docker Desktop's named pipe drops mid-session on Windows. Daemon restarts silently break compose.
**How to apply:** Before any `docker compose` command, verify daemon is up:
```powershell
docker info 2>&1 | Select-String "Server Version"
# If error → restart Docker Desktop before proceeding
```

---

## Startup Sequence (Math Platform)

```powershell
# 1. Verify daemon
docker info | Select-String "Server Version"

# 2. Start services
docker compose up -d

# 3. Wait for postgres to be ready (don't run migrations immediately)
docker compose logs postgres --follow
# Wait for: "database system is ready to accept connections"

# 4. Run migrations (only after postgres is ready)
docker compose exec backend alembic upgrade head

# 5. Verify
docker compose ps
# All services should show "running"
```

---

## Schema Migrations

### Safe migration (no data loss risk)
```powershell
# Generate migration
docker compose exec backend alembic revision --autogenerate -m "describe_change"

# Review the generated file in alembic/versions/ BEFORE applying
# Then apply
docker compose exec backend alembic upgrade head
```

### Breaking migration (column rename, type change)
```powershell
# ALWAYS backup first
docker compose exec postgres pg_dump -U $user $dbname > backup_$(Get-Date -Format yyyyMMdd).sql

# Then migrate
docker compose exec backend alembic upgrade head
```

### Schema changed but migration is wrong → full reset
```powershell
# WARNING: destroys all local data
docker compose down -v           # -v wipes volumes (Postgres data)
docker compose up -d
docker compose exec backend alembic upgrade head
```
**Rule:** Only use `down -v` on schema changes. Never on normal restarts.

---

## Volume Management

| Command | When | What it does |
|---------|------|-------------|
| `docker compose down` | Normal stop | Stops containers, keeps volumes |
| `docker compose down -v` | Schema change | Stops + wipes Postgres volume |
| `docker compose restart backend` | Code change (no hot-reload) | Restarts single service |
| `docker compose logs -f backend` | Debugging | Follow logs in real-time |

---

## Hot-Reload Setup

### FastAPI (backend)
```yaml
# docker-compose.yml
volumes:
  - ./backend:/app
command: uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
Code changes reload automatically. Migration changes still need `alembic upgrade head`.

### Next.js (frontend)
```yaml
volumes:
  - ./frontend:/app
  - /app/node_modules   # keep container node_modules separate
```
`npm run dev` inside container handles hot-reload.

---

## Debugging Inside Containers

```powershell
# Open shell in backend
docker compose exec backend bash

# Run one-off Python script
docker compose exec backend python -c "from app.db import engine; print(engine.url)"

# Check Postgres directly
docker compose exec postgres psql -U $user -d $dbname

# Check Redis
docker compose exec redis redis-cli ping
```

---

## Known Issues (Math Platform)

| Issue | Cause | Fix |
|-------|-------|-----|
| `pydantic._internal._signature` missing locally | Python env vs Docker Python differ | Always use Docker — never run FastAPI directly |
| Playwright EACCES on Windows | Windows Defender blocks browser spawn | Add `D:\Temp\playwright-browsers` to Defender exclusions |
| Postgres volume has stale schema | Forgot `-v` on schema change | `docker compose down -v` then `up -d` |
| Backend port conflict | Old container still running | `docker compose down` then `up -d` |
| Docker daemon pipe drop | Windows Docker Desktop mid-session crash | Restart Docker Desktop, then `docker compose up -d` |

---

## EduFlow Notes

Same patterns apply. Additional:
- Laravel uses `php artisan migrate` instead of alembic
- `APP_KEY` must be generated once: `docker compose exec backend php artisan key:generate`
- Frontend `NEXT_PUBLIC_API_URL` must match backend Railway URL on deploy
- FERPA compliance: verify PostgreSQL RLS policies before any production deploy

---

## How to Apply

Before running any `docker compose` command:
1. Check daemon is alive (`docker info`)
2. Know which command destroys volumes (`down -v`) and which doesn't (`down`)
3. Never run backend/frontend directly on Windows — Docker is the only safe path
4. For schema changes: backup first, then migrate, then verify
