---
name: code-review
description: Code review checklist for security, performance, and maintainability
tags: [code-quality, security, review, best-practices]
tags: [code-review, quality, security, best-practices, checklist, peer-review]
---

## When to Use

- Reviewing pull requests for security vulnerabilities
- Checking code for performance issues and anti-patterns
- Validating maintainability and code style consistency
- Performing pre-merge quality checks
- Establishing team code review standards

## Do Not Use

- Automated linting or formatting (use CI/CD pipeline tools)
- Git workflow or commit conventions (use git-workflow)
- Architecture-level design decisions (use architecture-advisor)
- Deployment or infrastructure review (use deployment-patterns)
- Writing tests or test coverage (use testing-standards)

# Code Review Checklist

## Security (check first)
- [ ] No hardcoded secrets, API keys, or passwords
- [ ] All user inputs validated and sanitized
- [ ] SQL queries use parameterized statements (no string concatenation)
- [ ] Authentication checked on all protected routes
- [ ] Sensitive data not logged or exposed in responses

## Logic & Correctness
- [ ] Edge cases handled (null, empty, zero, overflow)
- [ ] Error paths handled (not just happy path)
- [ ] No silent failures (errors caught but not handled)
- [ ] Async operations properly awaited

## Performance
- [ ] No N+1 database queries (use joins or batch queries)
- [ ] No expensive operations inside loops
- [ ] Large data sets paginated
- [ ] Caches used where appropriate

## Maintainability
- [ ] Functions do one thing (single responsibility)
- [ ] Variable/function names are descriptive
- [ ] Complex logic has a comment explaining WHY
- [ ] No dead code or commented-out blocks
- [ ] No magic numbers (use named constants)

## Tests
- [ ] New functionality has corresponding tests
- [ ] Edge cases tested
- [ ] Tests have clear names that describe behavior

## Review Tone
- Be specific: "This query runs on every render" not "This is slow"
- Explain why: "This could cause a race condition because..."
- Offer solutions: "Consider using useCallback here to memoize this"
- Distinguish: must-fix vs nice-to-have

## Anti-Patterns (Common Code Smells)

### ❌ Exception Silencing
```python
# BAD — silently swallows errors, makes debugging impossible
try:
    result = risky_operation()
except:
    pass  # Quietly fails, hard to diagnose

# GOOD — log or re-raise with context
try:
    result = risky_operation()
except SpecificError as e:
    logger.error(f"Failed to do X: {e}", exc_info=True)
    raise
```

### ❌ Type Checking at Runtime Instead of Development
```python
# BAD — catches bugs in production, not development
def process(data):
    if not isinstance(data, dict):
        raise TypeError("Expected dict")
    return data['key']

# GOOD — types caught during development/CI
def process(data: dict) -> str:
    return data['key']
    # mypy/pyright will catch type errors at lint time
```

### ❌ Magic Numbers / Strings
```python
# BAD — what is 1000? What is 'ACTIVE'?
if user.status == 'ACTIVE' and user.age > 65:
    MAX_AMOUNT = 1000

# GOOD — named constants
STATUS_ACTIVE = 'ACTIVE'
MIN_RETIREMENT_AGE = 65
MAX_WITHDRAWAL_FOR_SENIORS = 1000

if user.status == STATUS_ACTIVE and user.age > MIN_RETIREMENT_AGE:
    max_amount = MAX_WITHDRAWAL_FOR_SENIORS
```

### ❌ Premature Optimization
```python
# BAD — complex code that doesn't solve the actual bottleneck
def process_users(users):
    cache = {}
    return [cache.get(u.id) or compute_complex_value(u) for u in users]

# GOOD — profile first, optimize proven bottlenecks
def process_users(users):
    return [compute_complex_value(u) for u in users]
    # If this is slow, measure WHICH part. Cache only what matters.
```

### ❌ Incomplete Error Messages
```python
# BAD — what failed?
raise Exception("Error")

# GOOD — specific, actionable error
raise ValueError(f"Expected user.age to be int, got {type(age).__name__}")
```

## Common Mistakes by Domain

### Database
- **Missing indexes** on frequently queried columns
- **N+1 queries** — fetching users then their orders in a loop (use JOIN)
- **String concatenation in SQL** — exposes to injection (use parameterized statements)

### API
- **Inconsistent error codes** — 404 for missing user, 400 for missing email (pick one per error type)
- **No rate limiting** — exposes to DoS
- **Secrets in responses** — returning full password hash or API key in JSON

### Frontend (JS/React)
- **Missing key prop in lists** — causes re-renders, lost state
- **Creating objects in render** — new object every render, breaks memoization
- **Direct DOM manipulation** — mixing React and vanilla JS causes sync bugs

### Python
- **Blocking I/O in async code** — `requests.get()` instead of `httpx` in async function
- **Shared mutable defaults** → `def func(items=[])` then appending modifies the default
- **Missing `__all__`** in modules → unclear public API

---

## Ecosystem

### Linting & Formatting
| Tool | Language | Description |
|------|----------|-------------|
| [eslint](https://eslint.org) | JS/TS | Pluggable linting (recommended: flat config + typescript-eslint) |
| [prettier](https://prettier.io) | JS/TS/CSS | Opinionated code formatter (run after eslint) |
| [ruff](https://docs.astral.sh/ruff) | Python | Fast Python linter + formatter (10-100x faster than flake8) |
| [flake8](https://flake8.pycqa.org) | Python | Classic Python linting |
| [biome](https://biomejs.dev) | JS/TS/CSS | Linter + formatter in one tool (Rust-based, fast) |
| [oxlint](https://oxc.rs) | JS/TS | Rust-based linter (Oxidation compiler) |

### Type Checking
| Tool | Language | Description |
|------|----------|-------------|
| [typescript](https://www.typescriptlang.org) | JS | TypeScript compiler (`tsc --noEmit` in CI) |
| [mypy](https://mypy-lang.org) | Python | Static type checker for Python |
| [pyright](https://github.com/microsoft/pyright) | Python | Fast Python type checker (Microsoft) |
| [flow](https://flow.org) | JS | Static type checker (Meta) |

### Security Auditing
| Tool | Description |
|------|-------------|
| [npm audit](https://docs.npmjs.com/cli/v10/commands/npm-audit) | Built-in npm dependency vulnerability scan |
| [snyk](https://snyk.io) | Developer security platform (SAST, SCA, container) |
| [trivy](https://github.com/aquasecurity/trivy) | Open-source vulnerability scanner (containers, deps, IaC) |
| [sonarqube](https://www.sonarsource.com/products/sonarqube) | Code quality & security (SAST, coverage, complexity) |
| [codeql](https://codeql.github.com) | GitHub semantic code analysis (free for public repos) |
| [semgrep](https://semgrep.dev) | Lightweight static analysis (rule-based, multi-language) |
| [bandit](https://bandit.readthedocs.io) | Python security linter |

### Test Coverage
| Tool | Language | Description |
|------|----------|-------------|
| [istanbul](https://istanbul.js.org) | JS/TS | Code coverage tool (nyc) |
| [c8](https://github.com/bcoe/c8) | JS/TS | Native V8 coverage (no instrumentation) |
| [pytest-cov](https://pytest-cov.readthedocs.io) | Python | Coverage plugin for pytest |
| [codecov](https://about.codecov.io) | All | Coverage reporting & CI integration |
| [coveralls](https://coveralls.io) | All | Coverage history & badge |

### Complexity Analysis
| Tool | Language | Description |
|------|----------|-------------|
| [plato](https://github.com/es-analysis/plato) | JS | Code complexity visualization |
| [lizard](https://github.com/terryyin/lizard) | All | Cyclomatic complexity (C, JS, Python, Java, etc.) |
| [radon](https://github.com/rubik/radon) | Python | Code complexity (McCabe, Halstead, Maintainability Index) |

### Dependency Management
| Tool | Description |
|------|-------------|
| [npm-check](https://github.com/dylang/npm-check) | Check for outdated, incorrect, unused npm deps |
| [renovate](https://docs.renovatebot.com) | Auto-update dependencies via PR (preferred) |
| [dependabot](https://github.com/dependabot) | GitHub-native dependency updates |
| [pyup](https://pyup.io) | Python dependency updates + safety checks |
| [trufflehog](https://github.com/trufflesecurity/trufflehog) | Find leaked secrets in git history |

### Diff & Review Tools
| Tool | Description |
|------|-------------|
| [diff2html](https://diff2html.xyz) | Pretty HTML diff rendering |
| [reviewdog](https://github.com/reviewdog/reviewdog) | Automated code review tool (works with any linter) |
| [gitlint](https://github.com/jorisroovers/gitlint) | Git commit message linter |
| [commitlint](https://commitlint.js.org) | Conventional commit validation (husky integration) |
| [danger](https://danger.systems) | Automate PR review rules (Swift, JS, Ruby, Kotlin) |

---

## See Also

- [awesome-nodejs](https://github.com/sindresorhus/awesome-nodejs) — Curated Node.js resources
- [awesome-python](https://github.com/vinta/awesome-python) — Curated Python resources
- [OWASP Top 10](https://owasp.org/www-project-top-ten) — Web application security risks
- [Google Code Review Guide](https://google.github.io/eng-practices/review) — Google's review best practices
- [Conventional Commits](https://www.conventionalcommits.org) — Commit message standard
