---
name: git-workflow
description: Conventional commits, branch naming, git hooks, and safe git practices
tags: [git, version-control, workflow]
tags: [git, conventional-commits, branching, hooks, version-control, workflow]
---

## When to Use
- Writing commit messages following Conventional Commits format
- Setting up branch naming conventions and git hooks
- Establishing safe git practices (rebasing, merging, reverting)
- Configuring CI/CD triggers based on commit types

## Do Not Use
- CI/CD pipeline configuration (use ci-cd-patterns)
- Deployment automation (use deployment-patterns)
- Code review checklists (use code-review)

# Git Workflow Standards

## Commit Format (Conventional Commits)
```
type(scope): short description

Body (optional): explain WHY not WHAT
Closes #issue
```

**Types:** feat | fix | docs | style | refactor | test | chore | perf | ci

**Examples:**
- `feat(auth): add OAuth2 login with Google`
- `fix(api): handle null response from /users endpoint`
- `refactor(db): extract connection pool to separate module`
- `chore(deps): update express to v5`

## Branch Naming
- `feature/short-description` — new features
- `fix/issue-number-description` — bug fixes
- `chore/task-description` — maintenance
- `release/v1.2.0` — releases

## Git Hooks Setup
**Node.js (Husky + lint-staged):**
```bash
npm install -D husky lint-staged && npx husky init
echo "npx lint-staged" > .husky/pre-commit
```

**Python (pre-commit):**
```bash
pip install pre-commit && pre-commit install
```

→ See `references/detailed-workflows.md` for commitlint setup, lefthook config, and hook framework comparison.

## Detailed Workflows
→ `references/detailed-workflows.md` contains:
- Branching strategies (trunk-based, GitHub Flow, GitLab Flow, git-flow)
- Feature branch, quick fix, and stash workflows
- Conventional Commits full type reference with release bumps
- Hook framework comparison (husky, lefthook, pre-commit)
- Pre-commit checklist and safe git operations

## Verification
- [ ] Commit message follows Conventional Commits format
- [ ] Branch name follows convention (`feature/`, `fix/`, `chore/`)
- [ ] Pre-commit hooks run successfully
- [ ] `git diff --staged` reviewed before commit
- [ ] No force-push without `--force-with-lease`
