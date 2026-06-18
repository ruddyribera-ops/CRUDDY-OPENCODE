---
name: git-workflow
description: Git workflow patterns — branching strategy, commit conventions, merge/rebase rules, Railway auto-deploy, and safety protocols for solo development.
triggers: git, commit, branch, merge, rebase, push, pull, stash
auto_load: code-builder, bug-fixer
---

# Git Workflow

## Branch Strategy (Solo Dev)
- `master` → production (auto-deploys to Railway)
- Feature branches → `feat/<name>` or `fix/<name>`
- No long-lived branches — merge daily

## Commit Convention
```
type(scope): subject

Types: feat, fix, refactor, docs, test, chore, perf
Scope: module/area (optional)
Subject: imperative, lowercase, no period
```

## Safety Rules
- **Never** `--force` or `--no-verify` without explicit user confirmation
- **Never** commit unless user asks
- Always `git fetch` before touching code (avoid divergence)
- Before commit: `git status` + `git diff` + `git log --oneline -10`

## Railway Auto-Deploy
- Push to `master` → Railway auto-deploys
- Run `Verify-Deploy.ps1` after push
- If deploy fails: check `railway logs` (pink 404 = container not serving)
