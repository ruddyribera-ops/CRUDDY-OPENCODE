# Railway Deployment

## CLI Commands
```bash
# Deploy
railway up --detach        # Deploy without watching logs
railway up                 # Deploy with live logs

# Monitor
railway status             # Current project/service status
railway logs --tail 50     # Debug startup issues

# Run scripts in Railway context
railway run python script.py; railway run node script.js

# Project management
railway project link -p <project-id>; railway project list
```

## Deployment Checklist
- [ ] Verify DATABASE_URL in Railway dashboard matches production DB
- [ ] Check `railway status` before deploying
- [ ] Run `railway logs --tail 30` after deploy to verify startup
- [ ] Confirm app responds at the production URL
- [ ] If deploy fails: check logs first, verify all env vars set

## Port Configuration
```javascript
const PORT = process.env.PORT || 3001;
server.listen(PORT, () => console.log(`Running on port ${PORT}`));
```
Container platforms (Railway, Render, Fly.io) set `PORT` automatically.

## API URLs in Frontend
```javascript
// ✅ Good: Relative URLs work in dev AND production
fetch('/api/users')
// ❌ Bad: Hardcoded localhost breaks in production
fetch('http://localhost:3001/api/users')
```

## Web Proxy (Vite Dev Server)
```javascript
// vite.config.js
export default { server: { proxy: {
  '/api': { target: 'http://localhost:3001', changeOrigin: true },
  '/ws': { target: 'ws://localhost:3001', ws: true }
}}}
```

## Environment Variables
```bash
# .env.example (commit this — documents required vars)
PORT=3000; DATABASE_URL=postgresql://user:pass@localhost:5432/dbname
NODE_ENV=development; JWT_SECRET=change-me-in-production
```
- `.env` → `.gitignore` (never commit)
- `.env.example` → commit (documents requirements)
- Production → set in platform dashboard

## Post-Push Verification Protocol

```bash
# Your local commit
git rev-parse HEAD

# What's actually deployed (if app exposes /version)
curl -s https://your-app.up.railway.app/version
```

**Expose commit hash in app:**
```python
import os; APP_COMMIT = os.environ.get("RAILWAY_GIT_COMMIT_SHA", "unknown")[:7]
```
```javascript
const APP_COMMIT = process.env.RAILWAY_GIT_COMMIT_SHA?.slice(0, 7) || "unknown";
```

**Protocol:**
1. `git push` → wait for CI
2. Wait ~30s for platform to roll build
3. `curl /version` → confirm commit matches local HEAD
4. Only then smoke test prod
5. If never matches: `railway logs --tail 50`

**Never declare a deploy "done" until live commit hash matches what you pushed.**

## First-Production-Deploy Checklist
- [ ] Default admin user seeded (idempotent seed-on-startup)
- [ ] Default non-admin users seeded if needed
- [ ] Test login with real credentials against prod URL
- [ ] Verify live DB schema matches code: `SELECT ... FROM information_schema.columns WHERE table_name='users'`
- [ ] All secrets set in platform dashboard
- [ ] Smoke test critical path (login→main action→logout)
- [ ] Logs show no startup errors
- [ ] Health endpoint returns 200

## Platform Quick Reference
| Platform | Config File | Notes |
|----------|-------------|-------|
| Railway | `railway.toml` | Auto-detects Dockerfile |
| Vercel | `vercel.json` | Serverless functions |
| Netlify | `netlify.toml` | Static + functions |
| Render | `render.yaml` | Auto-suspends free tier |
| Fly.io | `fly.toml` | Edge deployments |
