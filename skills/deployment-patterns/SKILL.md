---
name: deployment-patterns
description: Docker, docker-compose, Railway, containerization, and environment configuration. Use when containerizing apps, deploying to Railway, configuring production environments. Triggers: containerize, Docker, docker-compose, Railway, deploy, health check, Dockerfile, rolling deploy, blue green.
---

# Deployment Patterns

## When to use this

Load this skill when you are packaging an application into a container, deploying to Railway, configuring environment variables for production, or setting up deployment strategies like rolling or blue/green deployments.

---

## Core Principles

1. **Multi-stage builds reduce image size** — Separate the build environment from the runtime environment to exclude build tools from the final image.

2. **Layer caching is your friend** — Order Dockerfile instructions from least to most frequently changing so that rebuilds are fast.

3. **Railway has an ephemeral filesystem** — Any data written outside of persistent volumes (databases, uploaded files) is lost on redeploy.

4. **Health checks prevent premature traffic routing** — Both the Docker HEALTHCHECK directive and Railway readiness probes should validate that your app is actually ready to serve traffic.

5. **Environment variables for secrets, never baked into images** — Use Railway's environment variable system or a secrets manager. Never RUN npm install with credentials in the Dockerfile.

6. **Rolling deploys are safer than recreate** — When possible, update pods in batches so that traffic is never fully dropped during a deploy.

7. **Rollback plan before you deploy** — Know the exact command or procedure to roll back before you push. Post-deploy regret is not a strategy.

---

## Patterns

### Multi-Stage Dockerfile (Node.js example)

```dockerfile
# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Stage 2: Runtime
FROM node:20-alpine AS runtime
WORKDIR /app
# Do NOT copy node_modules from builder — use fresh prod deps
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force
COPY --from=builder /app/dist ./dist
EXPOSE 3000
ENV NODE_ENV=production
CMD ["node", "dist/server.js"]
```

### Multi-Stage Dockerfile (Python example)

```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
RUN pip install --user uv
COPY requirements.txt .
RUN pip install --user -r requirements.txt

FROM python:3.12-slim AS runtime
WORKDIR /app
COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH
COPY . .
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### docker-compose for Local Development

```yaml
version: "3.9"
services:
  app:
    build:
      context: .
      target: builder
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/mydb
      - NODE_ENV=development
    volumes:
      - .:/app
      - /app/node_modules  # preserve container node_modules
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: mydb
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d mydb"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  pgdata:
```

### Railway Deployment Checklist

```bash
# Environment variables (set in Railway dashboard or via CLI)
PORT=3000                    # Railway injects this; your app must respect it
NODE_ENV=production
DATABASE_URL=${DATABASE_URL} # reference a Railway Postgres instance
# DO NOT set: secret keys, API tokens — use Railway Secrets instead

# Health check endpoint (must return 200 for Railway to route traffic)
# In Express:
app.get("/health", (req, res) => {
  res.json({ status: "ok", uptime: process.uptime() });
});

# Railway start command override (in railway.json or Procfile)
# railway.json:
{
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "numInstances": 2,
    "sleepApplication": false
  }
}
```

### Rolling Deploy with Docker Compose

```yaml
# docker-compose.prod.yml
services:
  app:
    image: myapp:v2.0.0
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
        order: start-first  # start new before stopping old
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Blue/Green Deploy (manual Railway pattern)

```bash
# Deploy new version to a separate directory
git clone git@github.com:myorg/myapp.git myapp-blue

cd myapp-blue
railway login
railway init --project-id $PROJECT_ID
railway up --service app-blue

# Point traffic to new service (Railway uses your domain — swap via env)
# 1. In Railway dashboard, set environment variable SERVICE=blue
# 2. Or use nginx as a reverse proxy and swap upstream

# Verify blue is healthy, then decommission green
railway down --service app-green
```

### Rollback Procedure

```bash
# Docker rollback (if using docker-compose)
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d

# Railway rollback (deploy previous image)
railway log --deployment $PREVIOUS_DEPLOYMENT_ID
railway rollback --deployment $PREVIOUS_DEPLOYMENT_ID

# Image rollback (if using tags)
docker pull myapp:v1.9.0
docker tag myapp:v1.9.0 myapp:latest
docker-compose -f docker-compose.prod.yml up -d
```

---

## Anti-Patterns

- **Using :latest tag in production** — You cannot roll back to a known-good version because you do not know which version :latest pointed to when the bug was introduced. Always use explicit version tags (v1.2.3, git SHA).

- **Baking secrets into the Docker image** — Credentials in the Dockerfile survive in the image layers forever, even if you remove them from your repo. Use environment variables or Docker secrets.

- **Running containers as root** — The default container user is root. Create and switch to a non-root user: `RUN addgroup -S appgroup && adduser -S appuser -G appgroup`.

- **Not having a health check** — Without HEALTHCHECK, Docker and Railway assume the container is healthy as soon as the process starts. If your app needs 10 seconds to connect to the DB, Railway routes traffic to it immediately and returns 502s.

- **Single-stage builds for compiled languages** — A Go or Rust binary built in the same image as the runtime includes the entire build toolchain. Multi-stage drops image size from 1GB to 10MB.

- **Ignoring Railway's ephemeral filesystem** — Writing session data, caches, or temporary uploads to the container filesystem means they disappear on the next deploy. Use a persistent volume or an external cache (Redis).

---

## Quick Reference

| Concern | Correct Pattern | Anti-Pattern |
|---------|----------------|--------------|
| Image size | Multi-stage build | Single-stage with all deps |
| Secrets | Environment variables / Railway Secrets | Hardcoded in Dockerfile |
| Health checks | HEALTHCHECK + readiness probe | No health check |
| Deploy strategy | Rolling (start-first) or blue/green | Recreate (downtime) |
| Rollback | Explicit version tags, known SHA | :latest tag |
| User in container | Non-root (adduser -S) | Running as root |
| Railway storage | Persistent volumes for data | Container filesystem |
| Caching | Layer order: deps first, code last | Cache bust by reordering |

### One-Command Health Check (for Alpine-based images)

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget --spider -q http://localhost:${PORT:-3000}/health || exit 1
```

### Railway Service Configuration (railway.json)

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS",
    "buildCommand": "npm run build",
    "startCommand": "npm start"
  },
  "deploy": {
    "numInstances": 2,
    "sleepApplication": false,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```
