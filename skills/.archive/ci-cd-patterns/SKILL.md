---
name: ci-cd-patterns
description: GitHub Actions CI/CD pipeline patterns, git hooks, and automated quality checks
tags: [devops, ci-cd, github-actions, automation]
tags: [ci-cd, github-actions, automation, pipeline, devops, testing]
---

## When to Use
- Setting up GitHub Actions workflows for CI/CD
- Configuring automated lint, test, and build pipelines
- Implementing deployment automation and release workflows
- Adding pre-commit hooks and quality gates

## Do Not Use
- Containerization or Docker setup (use deployment-patterns)
- Git workflow conventions (use git-workflow)
- Manual deployment or server provisioning

# CI/CD Patterns

## GitHub Actions — Quick Reference

### Node.js CI
```yaml
name: CI
on: { push: { branches: [main, develop] }, pull_request: { branches: [main] } }
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: 'npm' }
      - run: npm ci
      - run: npm run lint --if-present
      - run: npx tsc --noEmit --if-present
      - run: npm run build --if-present
      - run: npm test --if-present
```

### Python CI
```yaml
name: CI
on: { push: { branches: [main, develop] }, pull_request: { branches: [main] } }
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.12', cache: 'pip' }
      - run: pip install -r requirements.txt
      - run: pip install pytest flake8
      - run: flake8 . --max-line-length=120 --exclude=venv,__pycache__
      - run: pytest --tb=short -q
```

### Deploy to Railway (after CI passes)
```yaml
  deploy:
    needs: ci
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: railwayapp/deploy-action@v1
        with: { railway_token: ${{ secrets.RAILWAY_TOKEN }} }
```

### Deploy to Vercel
```yaml
  deploy:
    needs: ci
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'
```

## Adapt to Project (IMPORTANT)
1. Read `package.json` scripts → use what exists (`lint`, `test`, `build`)
2. Check for existing `.github/workflows/` → don't create duplicates
3. Match the project stack → don't add Node steps to a Python project
4. Only add deploy step if deployment platform is configured
5. Use `--if-present` for optional scripts

## Git Hooks

### Node.js (Husky + lint-staged)
```bash
npm install -D husky lint-staged && npx husky init
echo "npx lint-staged" > .husky/pre-commit
```

### Python (pre-commit)
```bash
pip install pre-commit && pre-commit install
```

## When to Add What
| Project state | Add this |
|---------------|----------|
| No CI at all | Basic CI (lint + test + build) |
| CI exists, no deploy | Add deploy job |
| No git hooks | Husky/lint-staged or pre-commit |
| Has hooks, no CI | GitHub Actions workflow |
| Everything exists | Skip |

## Verification
- [ ] GitHub Actions workflow file is valid YAML
- [ ] CI runs and passes (lint + type-check + test + build)
- [ ] Deploy step only triggers on main branch push
- [ ] Secrets configured in GitHub repo settings (not hardcoded)
- [ ] Pre-commit hooks run lint and tests before commit
- [ ] `--if-present` used for optional scripts to avoid CI failures
