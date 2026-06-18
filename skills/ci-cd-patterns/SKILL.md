---
name: ci-cd-patterns
description: CI/CD pipeline patterns — GitHub Actions, Railway auto-deploy, Docker build caching, environment promotion, and verification gates.
triggers: ci, cd, github-actions, pipeline, deploy, github actions, ci/cd, workflow
auto_load: code-builder
---

# CI/CD Patterns

## GitHub Actions
- **Test job**: lint → type-check → test → build (fail fast)
- **Cache**: `actions/cache` for `node_modules`, pip, Docker layers
- **Secrets**: never echo env vars in logs, use `${{ secrets.X }}`

## Railway Deploy
- Auto-deploy from `master`/`main` branch
- Run `Verify-Deploy.ps1` after every push with SHA verification
- Stale build cache is a known issue — use commit hash verification

## Docker Pipeline
- Multi-stage builds: `build` stage → `production` stage
- Never bake secrets into images — use runtime env vars
- `docker build --cache-from` for layer caching

## Verification Gates
- Tier 1: tests pass → deploy
- Tier 2: smoke test (curl health endpoint) → promote
- Tier 3: E2E tests → mark complete
