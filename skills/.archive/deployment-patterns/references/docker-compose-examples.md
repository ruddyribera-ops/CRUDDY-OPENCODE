# Docker & Docker Compose Examples

## Dockerfile — Node.js (Multi-stage)
```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app; COPY package*.json ./; RUN npm ci; COPY . .; RUN npm run build

FROM node:20-alpine
WORKDIR /app; COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
EXPOSE 3000; CMD ["node", "dist/index.js"]
```

**Common mistakes:** Not copying source code, not building frontend before server start, wrong entry point path.

## Dockerfile — Simple Node.js (No build step)
```dockerfile
FROM node:20-alpine
WORKDIR /app; COPY . .
RUN npm install && npm run build
EXPOSE 8080; CMD ["node", "server/index.js"]
```

## Dockerfile — Python
```dockerfile
FROM python:3.12-slim
WORKDIR /app; COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .; EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## .dockerignore
```
node_modules, dist, .git, .env*, *.log, coverage, .pytest_cache, __pycache__, venv, .venv
```

## docker-compose.yml — Node.js + PostgreSQL
```yaml
services:
  app:
    build: .
    ports: ["${PORT:-3000}:3000"]
    environment: [NODE_ENV=production, DATABASE_URL=postgresql://postgres:postgres@db:5432/myapp]
    depends_on: { db: { condition: service_healthy } }
  db:
    image: postgres:16-alpine
    environment: { POSTGRES_DB: myapp, POSTGRES_USER: postgres, POSTGRES_PASSWORD: postgres }
    ports: ["5432:5432"]
    volumes: [pgdata:/var/lib/postgresql/data]
    healthcheck: { test: ["CMD-SHELL", "pg_isready -U postgres"], interval: 5s, timeout: 5s, retries: 5 }
volumes: { pgdata: }
```

## docker-compose.yml — Python + PostgreSQL
```yaml
services:
  app:
    build: .
    ports: ["${PORT:-8000}:8000"]
    environment: [DATABASE_URL=postgresql://postgres:postgres@db:5432/myapp]
    depends_on: { db: { condition: service_healthy } }
  db:
    image: postgres:16-alpine
    environment: { POSTGRES_DB: myapp, POSTGRES_USER: postgres, POSTGRES_PASSWORD: postgres }
    volumes: [pgdata:/var/lib/postgresql/data]
    healthcheck: { test: ["CMD-SHELL", "pg_isready -U postgres"], interval: 5s, timeout: 5s, retries: 5 }
volumes: { pgdata: }
```

## Patterns

**Health check on every container**
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
  interval: 30s; timeout: 10s; retries: 3
```

**Resource limits (prevent noisy neighbor)**
```yaml
deploy:
  resources:
    limits: { cpus: '0.5', memory: 256M }
    reservations: { cpus: '0.25', memory: 128M }
```

**Multi-stage build patterns:** Builder→runner (smallest), Dev→test→prod (reuse), FROM scratch for Go/Rust (~0MB base)

**Docker socket security** — never mount `/var/run/docker.sock` in production containers. Use Docker-in-Docker or socket proxy instead.

**Rootless Docker** — run daemon without root for additional isolation.
