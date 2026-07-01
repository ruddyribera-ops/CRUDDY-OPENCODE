---
name: CI/CD Deployment Automation
description: GitHub Actions auto-deploy on push to main. Tests first, deploy if pass, rollback if break.
type: feedback
---

# CI/CD Deployment Automation

**Rule:** Every commit to `main` triggers: tests → (if pass) deploy to Railway → (if fail) stop + notify

**Why:** Never deploy broken code. Teachers can't wait for manual deploys. Auto-rollback on failure.

**How to apply:** 
1. Copy workflows from `.github/workflows/` to each repo
2. Set GitHub Secrets (RAILWAY_TOKEN, SERVICE_IDs)
3. Push to main → auto-tests + auto-deploys

---

## Safe Deployment Flow

```
git push main
    ↓
GitHub Actions triggered
    ↓
Run tests (pytest for Python, npm test for Node)
    ↓
Tests fail? → Stop, notify, no deploy ✓
Tests pass? → Deploy to Railway
    ↓
Railway builds + starts service
    ↓
Notify success on GitHub
    ↓
Done (rollback available via Railway dashboard if needed)
```

---

## Workflows Available

| Project | File | Trigger | Tests | Deploy |
|---------|------|---------|-------|--------|
| PRIA | `pria-deploy.yml` | push main | pytest | Railway FastAPI |
| Palma Coin | `palma-coin-deploy.yml` | push main | npm test | Railway Express |
| Math Platform | `math-platform-deploy.yml` | push main | pytest + npm test | Railway (both) |

---

## One-Time Setup Per Repo

1. **Create `.github/workflows/` directory** in repo root
2. **Copy workflow file** (pria-deploy.yml, etc.) to `.github/workflows/`
3. **Add GitHub Secrets:**
   - `RAILWAY_TOKEN` — from Railway.app account settings
   - `RAILWAY_SERVICE_ID` — service ID for this project
   - For Math Platform: `MATH_PLATFORM_BACKEND_SERVICE_ID` + `MATH_PLATFORM_FRONTEND_SERVICE_ID`
4. **Enable Actions** in repo settings
5. **Commit + push** to main

---

## PRIA-Specific Notes

- Cold start breaks e2e tests → use `--timeout=30` in pytest
- Can skip e2e: `pytest tests/ --ignore=tests/e2e`
- Streamlit doesn't need build step (runs directly)
- If deploy fails, manually rollback via Railway dashboard

---

## Palma Coin-Specific Notes

- WebSocket `/ws` will NOT work on Railway (documented in skill_websocket_railway.md)
- Use SSE (Server-Sent Events) as fallback for live updates
- Workflow notes this in PR comment as reminder

---

## Math Platform-Specific Notes

- Backend + frontend deployed separately
- Backend runs migrations automatically on startup (alembic upgrade head)
- If schema changed, backend will apply migrations + restart
- Frontend needs `NEXT_PUBLIC_API_URL` set in Railway env vars

---

## Rollback Strategy

### If Deploy Breaks Production

1. **Revert commit** locally + push new commit
2. **Or manually rollback** via Railway dashboard:
   - Service → Deployments → find previous build → click "Rollback"
3. **Or manual CLI:**
   ```bash
   railway rollback --to <deployment-id>
   ```

### Prevention

- Always test locally first (`pytest`, `npm test`)
- Let CI catch errors before deploy
- Keep previous 2 builds (Railway default)

---

## Notifications

- ✅ Deploy succeeds → GitHub PR comment says "✅ Deployed"
- ❌ Tests fail → GitHub PR comment says "❌ Tests failed, no deploy"
- ⚠️ Warnings (e.g., WebSocket on Palma) → included in success comment

---

## Manual Trigger

If you need to deploy without a new commit:

```bash
# From repo directory
gh workflow run pria-deploy.yml --ref main
gh workflow run palma-coin-deploy.yml --ref main
gh workflow run math-platform-deploy.yml --ref main
```

Or via GitHub UI: Actions → workflow name → "Run workflow" button

---

## Customization

Edit `.github/workflows/pria-deploy.yml` to:
- Change test command: edit `run: pytest...`
- Add environment variables: add to Railway service env vars
- Change deploy branch: edit `branches: [main]`
- Skip e2e tests: add `--ignore=tests/e2e` to pytest

---

## Status for PRIA Beta

✅ Workflows created and ready to copy  
⏳ Needs: GitHub Secrets setup (5 min per repo)  
⏳ Then: First commit to main auto-deploys
