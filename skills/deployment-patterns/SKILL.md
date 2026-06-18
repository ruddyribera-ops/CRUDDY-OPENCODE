---
name: deployment-patterns
description: Deployment, CI/CD, environment management, Docker, Railway, and infrastructure patterns. Production-hardened deployment practices for full-stack apps.
triggers: [deploy, deployment, railway, docker, dockerfile, docker-compose, ci, cd, github-actions, pipeline, environment, env, staging, production, vercel, netlify, cloudflare, aws, release, build, npm-build, docker-build, push, container]
---

# Deployment Patterns

## Core Principles

1. **Build once, deploy many** — same artifact goes through staging → production
2. **Immutable infrastructure** — never SSH into production to "fix things"
3. **Environment parity** — dev/staging/prod are as identical as possible
4. **Rollback is a feature** — every deploy must be reversible in < 5 minutes

---

## 1. Project Configuration

### Environment Variables

```bash
# .env.example — committed to git, template with placeholder values
DATABASE_URL=postgresql://user:pass@host:5432/db
NEXT_PUBLIC_API_URL=http://localhost:3000
JWT_SECRET=change-me-in-production
```

```bash
# .env — NEVER committed to git
DATABASE_URL=postgresql://user:realpassword@localhost:5432/dev_db
```

```python
# ✅ CORRECT: Access pattern
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str
    jwt_secret: str
    environment: str = "development"

    class Config:
        env_file = ".env"
```

```javascript
// ✅ CORRECT (Node.js):
import 'dotenv/config';
const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) throw new Error('DATABASE_URL is required');
```

### Environment-Specific Config

```
.env.example           ← template (committed)
.env.development       ← local dev defaults
.env.staging           ← staging overrides
.env.production         ← production overrides (CI injects these, never in repo)
```

---

## 2. Docker

### Dockerfile Best Practices

```dockerfile
# 1. Multi-stage build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
USER nextjs  # ← NEVER run as root
EXPOSE 3000
ENV NODE_ENV=production
CMD ["node", "server.js"]
```

```dockerfile
# ✅ Python multi-stage
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

FROM python:3.12-slim
WORKDIR /app
RUN adduser --system --uid 1001 appuser
COPY --from=builder /root/.local /root/.local
COPY . .
ENV PATH=/root/.local/bin:$PATH
USER appuser
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Dockerignore

```dockerfile
# .dockerignore — prevents sending unnecessary context to docker daemon
node_modules/
.git/
.env
*.md
.DS_Store
```

### docker-compose.yml (Development)

```yaml
version: '3.8'
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD: devpassword
      POSTGRES_DB: app_dev
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://app:devpassword@db:5432/app_dev
    depends_on:
      - db

volumes:
  pgdata:
```

---

## 3. Railway Deployment

### Critical Config

```toml
# railway.toml
[build]
  builder = "nixpacks"
  buildCommand = "npm run build"

[deploy]
  startCommand = "node server.js"
  numReplicas = 1

[service]
  port = 3000
```

### Railway Reminders

```
⚠️  Railway filesystem is EPHEMERAL
    → Use Postgres plugin for databases (never SQLite on disk)
    → Use volume mounts for uploads/temp files
    → Don't rely on local file persistence between restarts

⚠️  Railway rebuilds on every deploy
    → Build cache stays between deploys
    → Env vars set in Railway dashboard override .env files

✅  Stale-build caching has burned us before
    → Verify commit hash matches between build and deploy
    → Use commit-hash-verify step (see Verify-Deploy.ps1)
```

---

## 4. CI/CD Pipeline

### GitHub Actions Template

```yaml
name: CI/CD
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npm run lint

  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_PASSWORD: test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npm test

  deploy:
    if: github.ref == 'refs/heads/main'
    needs: [lint, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to Railway
        run: npx railway up --service ${{ vars.RAILWAY_SERVICE }}
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
```

---

## 5. Environment Management

| Env | Purpose | Database | Deploy Trigger |
|-----|---------|----------|----------------|
| local | Development | Local Docker Postgres | Manual |
| staging | QA/Testing | Railway Postgres (restore from prod backup) | Push to develop |
| production | Live | Railway Postgres (production) | Push to main |

### Deployment Workflow

```bash
# 1. Check CI passes (lint + test)
# 2. Create migration
# 3. Run migration against staging first
# 4. Deploy to staging, verify
# 5. Run migration against production (if needed)
# 6. Deploy to production
# 7. Run Verify-Deploy.ps1
# 8. Monitor logs for 10 minutes
```

---

## 6. Secrets Management

```
DO NOT:
  - Commit .env files to git
  - Hardcode API keys in source code
  - Share secrets via chat/email

DO:
  - Railway dashboard → Variables → Add
  - GitHub → Settings → Secrets → Actions
  - For local dev: .env (in .gitignore)
  - Rotate immediately on suspected exposure
```

---

## 7. Anti-Patterns

| Anti-Pattern | Why | Fix |
|-------------|-----|-----|
| "It works on my machine" | Environment differences | Dockerize or use nixpacks |
| SSH-ing into production to debug | State drift, unreproducible fixes | Read logs, fix locally, redeploy |
| Deploying on Friday afternoon | Weekend incidents | Deploy early week, give 24h monitoring window |
| No health check endpoint | Don't know if app is alive | Add GET /health endpoint |
| Running as root in container | Security vulnerability | Add USER directive to Dockerfile |
| Different config per environment | The "works on staging but not prod" classic | Environment parity |

---

## 8. Verification Checklist

- [ ] Build once, same artifact promoted through environments
- [ ] .env.example committed with all required vars (no real values)
- [ ] Secrets injected via environment, never in code
- [ ] Dockerfile uses multi-stage build, non-root user
- [ ] docker-compose.yml for local development
- [ ] CI runs lint + test before deploy
- [ ] Railway: Postgres plugin used, not SQLite on disk
- [ ] Verify-Deploy.ps1 runs and exits 0 after push
- [ ] Rollback plan documented and tested
- [ ] Health check endpoint returns 200
- [ ] Migration run before or after code deploy (tested both ways on staging)
