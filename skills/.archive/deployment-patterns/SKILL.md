---
name: deployment-patterns
description: Docker, docker-compose, Railway, containerization, and environment configuration
tags: [devops, deployment, docker, railway]
tags: [deployment, docker, railway, container, ci-cd, cloud, devops]
---

## When to Use

- Containerizing applications with Docker and docker-compose
- Deploying to Railway or similar PaaS platforms
- Configuring environment variables and secrets management
- Setting up multi-stage Docker builds for optimization
- Managing production, staging, and development environments

## Do Not Use

- CI/CD pipeline configuration (use ci-cd-patterns)
- Kubernetes or orchestrator-specific deployment (use platform docs)
- Application code testing (use testing-standards)
- Git workflow or branching strategies (use git-workflow)
- Monitoring or logging infrastructure setup

# Deployment Patterns

## Quick Reference

### Port Configuration
```javascript
const PORT = process.env.PORT || 3001;
```
Container platforms (Railway, Render, Fly.io) set `PORT` automatically.

### API URLs in Frontend
```javascript
// ✅ Relative URLs work in dev AND production
fetch('/api/users')
// ❌ Hardcoded localhost breaks in production
fetch('http://localhost:3001/api/users')
```

### Web Proxy (Vite)
```javascript
export default { server: { proxy: {
  '/api': { target: 'http://localhost:3001', changeOrigin: true },
  '/ws': { target: 'ws://localhost:3001', ws: true }
}}}
```

## Docker Images & Compose
→ See `references/docker-compose-examples.md` for complete code:
- Dockerfile: Node.js multi-stage, Node.js simple, Python
- `.dockerignore` patterns
- docker-compose.yml: Node.js+PostgreSQL, Python+PostgreSQL
- Health checks, resource limits, multi-stage patterns
- Docker socket security, rootless Docker

## Railway Deployment
→ See `references/railway-deployment.md` for complete guide:
- CLI commands (deploy, monitor, run scripts)
- Deployment checklist
- Environment variables (.env.example rules)
- Post-push verification protocol (match commit hashes)
- First-production-deploy checklist
- Platform quick reference (Railway, Vercel, Netlify, Render, Fly.io)

## Environment Variables
```bash
# .env.example (commit this — documents required vars)
PORT=3000
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname
NODE_ENV=development
JWT_SECRET=change-me-in-production
```
- `.env` → `.gitignore` (never commit)
- `.env.example` → commit (documents what's needed)
- Production → set in platform dashboard (Railway, Render, etc.)

## Pre-Deployment Checklist
- [ ] All API URLs use relative paths (`/api` not `localhost:3001`)
- [ ] WebSocket URL uses `window.location` for host
- [ ] `PORT` env var used, not hardcoded
- [ ] Dockerfile copies all source files
- [ ] Frontend builds successfully before server starts
- [ ] CORS configured for production domain
- [ ] Environment variables documented in `.env.example`
- [ ] Default admin user seeded (idempotent: check count, insert only if empty)

## Ecosystem & Tools
→ See `references/deployment-ecosystem.md` for:
- Container orchestration, monitoring (Prometheus+Grafana, cAdvisor)
- Security scanning (docker-bench, Trivy, Falco, Checkov)
- Reverse proxy (Traefik, nginx-proxy, Caddy)
- Self-hosted PaaS (Dokku, CapRover, Coolify)
- Base images (distroless, alpine, slim, wolfi)
- Desktop UIs (Portainer, Lazydocker, Dockge)

## Verification
- [ ] `docker build .` succeeds
- [ ] `docker-compose up` starts all services without errors
- [ ] Health endpoint returns 200: `curl localhost:3000/health`
- [ ] Commit hash verification: `git rev-parse HEAD` matches live deploy
- [ ] Railway: `railway status` shows healthy, `railway logs --tail 30` shows no errors
- [ ] All reference links resolve to existing files
