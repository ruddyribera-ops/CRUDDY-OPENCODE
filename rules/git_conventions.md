---
name: git_conventions
description: Conventional commit format, branch naming, and safe git practices
type: rules
source: feedback_commit_convention.md + git-workflow/SKILL.md
---

# Git Conventions

## Commit Format (Conventional Commits)

**Mandatory shape:**
```
type(scope): subject in imperative mood

optional body explaining WHY (not WHAT — the diff shows what)
```

**Types (pick one):**

| Type | When to use |
|------|-------------|
| `feat` | New user-facing feature |
| `fix` | Bug fix |
| `refactor` | Code change that doesn't add/fix a feature |
| `test` | Adding or fixing tests only |
| `docs` | README, inline docs, comments |
| `ops` | Railway/Docker/infra/env config |
| `ci` | GitHub Actions / pipeline only |
| `chore` | Deps bump, lockfile, formatting — nothing else |

**Scope (optional but helpful):**
- Omit if change is cross-cutting
- Use short functional scope: `auth`, `ui`, `api`, `db`, `e2e`

**Examples:**
```
feat(auth): add session timeout for teacher dashboard
fix(db): cast must_change_password to int for PG
test(e2e): replace fixed timeouts with wait_for_selector
ops(railway): expose /version endpoint with RAILWAY_GIT_COMMIT_SHA
chore: bump bcrypt to 4.1.2
```

---

## Branch Naming

```
feature/short-description
fix/issue-number-description
chore/task-description
release/v1.2.0
```

**Rules:**
- Use kebab-case for descriptions
- Include issue number for bug fixes when available
- Never commit directly to `main` or `master`

---

## Safe Git Operations

**Always confirm before:**
- `git push` (especially to main/master)
- `git reset --hard`
- `git rebase`
- `git clean`

**Never use without asking:**
- `git push --force` — use `--force-with-lease` instead
- `git clean -fdx`

**Commit message rules:**
- Subject line ≤72 characters
- Use imperative mood: "add feature" not "added feature"
- Body explains WHY, not WHAT
- Reference issues: `Closes #123`

---

## Why

PRIA's git history stays scannable at a glance. `git log --oneline --grep='fix'` becomes useful. Release notes generate themselves.

---

## How to Apply

1. Before creating ANY commit, the coordinator or specialist must follow this format
2. If the commit doesn't fit one type, the change probably does more than one thing — split it first
3. The `feedback_commit_convention.md` hook is loaded at session start — this rules file formalizes it
4. Pre-commit hook (if configured) can enforce format — see `ci-cd-patterns/SKILL.md`
