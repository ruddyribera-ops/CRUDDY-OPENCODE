# GitHub Actions Setup Instructions

## One-Time Setup (Do This First)

### 1. Create GitHub Secrets
For each repo, add these secrets in **Settings → Secrets and Variables → Actions:**

```
RAILWAY_TOKEN          → Your Railway API token
DATABASE_URL           → PostgreSQL connection string (if needed)
RAILWAY_SERVICE_ID     → Service ID from Railway dashboard
GITHUB_TOKEN           → (auto-provided by GitHub)
```

**How to get RAILWAY_TOKEN:**
1. Go to Railway.app → Account → API Tokens
2. Create new token, copy it
3. Add to GitHub repo Secrets

**How to get RAILWAY_SERVICE_ID:**
1. Go to Railway project → copy from URL or dashboard
2. For PRIA: find PRIAv5 service ID

### 2. Enable Actions in Repo
- Go to repo → Settings → Actions
- Ensure "Allow all actions and reusable workflows" is selected

### 3. Done
Workflows will run on next commit to `main` branch.

---

## Workflows Included

| Project | Workflow | Trigger | Tests | Deploy |
|---------|----------|---------|-------|--------|
| PRIA | `pria-deploy.yml` | Push to main | pytest | Railway API |
| Palma Coin | `palma-deploy.yml` | Push to main | npm test | Railway API |
| Math Platform | `math-platform-deploy.yml` | Push to main | pytest + npm test | Railway API |

---

## What Each Workflow Does

### On every `git push` to `main`:

1. **Checkout code**
2. **Run tests**
   - PRIA: `pytest`
   - Palma Coin: `npm test`
   - Math Platform: `pytest` + `npm test`
3. **If tests pass:** Deploy to Railway
4. **If tests fail:** Stop (don't deploy broken code)
5. **Notify** result via GitHub (PR comment or commit status)

---

## For PRIA Specifically

### Test Command
```bash
pytest tests/ -v --tb=short
```

### Deploy Command
```bash
railway up --service <SERVICE_ID>
```

### Rollback (if needed)
```bash
railway rollback --to <DEPLOYMENT_ID>
```

---

## Manual Triggers

If you need to deploy without a commit:
```bash
gh workflow run pria-deploy.yml --ref main
```

Or via GitHub UI:
- Repo → Actions → PRIA Deploy → "Run workflow" button

---

## Monitoring

### Success
- GitHub shows ✅ on commit
- PR shows "All checks passed"
- Railway logs show deployment

### Failure
- GitHub shows ❌ on commit
- Workflow log shows error (click the X to see details)
- Code is NOT deployed (safe fail)

---

## Rollback Strategy

If a deployment breaks production:

### Automatic Rollback
```bash
# If health check fails (optional, needs setup)
railway rollback --to <last-good-deployment>
```

### Manual Rollback
1. Go to Railway dashboard
2. Find service → Deployments tab
3. Click "Rollback" on previous build

### Prevention
- Always test locally first
- Let CI run tests before deploy
- Keep previous 2 builds (Railway default)

---

## Customization

Edit `.github/workflows/pria-deploy.yml` to:
- Change test command: edit `run: pytest...` line
- Change deploy command: edit `railway up...` line
- Add environment variables: add to `env:` section
- Change trigger: edit `on: [push]` section

---

## If Tests Are Flaky (Cold Start Issue)

PRIA's cold start breaks e2e tests. Workaround:

```yaml
# In pria-deploy.yml, increase test timeout:
- name: Run tests
  run: pytest tests/ -v --timeout=30
```

Or skip e2e on deploy:
```yaml
- name: Run tests
  run: pytest tests/ -v --ignore=tests/e2e
```

---

## Next: Copy Workflows to Repo

Once you're ready, copy the `.yml` files from this setup to your repo's `.github/workflows/` directory and commit them.
