# Git Workflow — Detailed Patterns

## Branching Strategies
| Strategy | Use Case | Key Rule |
|----------|----------|----------|
| Trunk-based | CI/CD, small teams, fast deploy | Short branches (<1 day), merge to `main` multiple times/day |
| GitHub Flow | Web apps, continuous deploy | Feature branch → PR → merge to `main` → deploy |
| GitLab Flow | Environments + releases | Feature → `main` → `staging` → `production` |
| Git-flow | Versioned releases, large teams | `develop` + `feature` + `release` + `hotfix` branches |

## Common Git Workflows

### Feature branch
```bash
git checkout -b feature/my-feature
# work...
git add .; git commit -m "feat(scope): description"
git push -u origin feature/my-feature
gh pr create --title "feat: description" --body "summary"
```

### Quick fix
```bash
git checkout -b fix/issue-description
# fix...
git add .; git commit -m "fix(scope): description"
git push -u origin fix/issue-description
```

### Stash workflow
```bash
git stash; git stash list; git stash pop; git stash drop
```

## Commit Lint Setup
```bash
npm install -D @commitlint/cli @commitlint/config-conventional
echo "module.exports = {extends: ['@commitlint/config-conventional']}" > commitlint.config.js
npx husky add .husky/commit-msg 'npx --no -- commitlint --edit $1'
```

## Conventional Commits — Full Type Reference
| Type | Scope | Release Bump |
|------|-------|-------------|
| `feat` | New feature | MINOR |
| `fix` | Bug fix | PATCH |
| `chore` | Maintenance, deps | — |
| `docs` | Documentation | — |
| `style` | Code formatting | — |
| `refactor` | Code change (no bugfix/feature) | — |
| `perf` | Performance improvement | PATCH |
| `test` | Adding/fixing tests | — |
| `ci` | CI/CD config changes | — |

Breaking changes: append `!` or add `BREAKING CHANGE:` footer. Example: `feat(api)!: remove deprecated endpoint`

## Hook Frameworks
| Tool | Language | Pros |
|------|----------|------|
| husky | JS/TS | Prevalent, v9 dropped config file |
| lefthook | Any (Go binary) | Fast, parallel hooks, no Node dep |
| pre-commit | Python | Rich ecosystem of plugins |

## Pre-Commit Checklist
1. Run tests: `npm test` / `pytest` / `go test ./...`
2. Run lint: `npm run lint` / `flake8` / `golint`
3. Review diff: `git diff --staged`
4. Write meaningful commit message

## Safe Git Operations
Always confirm before: `git push` (to main), `git reset --hard`, `git rebase`, `git clean`
Never without asking: `git push --force` (use `--force-with-lease` instead), `git clean -fdx`
