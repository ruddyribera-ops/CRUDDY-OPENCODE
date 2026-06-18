---
name: code_review_checklist
description: Runtime-enforceable code review checklist for security, performance, and maintainability
type: rules
source: code-review/SKILL.md (elevated to runtime rule)
---

# Code Review Checklist

Every code change must pass this checklist before Stage 7 (Archive). The Reviewer has final authority.

## Security (check FIRST)

- [ ] No hardcoded secrets, API keys, or passwords in code or responses
- [ ] All user inputs validated and sanitized server-side
- [ ] SQL queries use parameterized statements (no string concatenation)
- [ ] Authentication checked on all protected routes
- [ ] Sensitive data not logged or exposed in responses
- [ ] Environment variables used for secrets (not hardcoded)
- [ ] HTTPS used for all external communication

## Logic & Correctness

- [ ] Edge cases handled: null, empty, zero, maximum values
- [ ] Error paths handled (not just happy path)
- [ ] No silent failures (errors caught must be logged or re-raised)
- [ ] Async operations properly awaited
- [ ] No race conditions in concurrent code

## Performance

- [ ] No N+1 database queries (use joins or batch queries)
- [ ] No expensive operations inside loops
- [ ] Large data sets paginated
- [ ] Caches used where appropriate
- [ ] No blocking I/O in async code paths

## Maintainability

- [ ] Functions do one thing (single responsibility)
- [ ] Variable/function names are descriptive (no `temp`, `data`, `x`)
- [ ] Complex logic has a comment explaining WHY (not WHAT)
- [ ] No dead code or commented-out blocks
- [ ] No magic numbers (use named constants)
- [ ] No `ts-ignore`, `any`, `# type: ignore`, or `noqa` shortcuts

## Tests

- [ ] New functionality has corresponding tests
- [ ] Edge cases tested
- [ ] Tests have clear names that describe behavior
- [ ] Test coverage: business logic ≥90%, utilities ≥80%

## Anti-Patterns (Automatic Rejection)

**These patterns fail review automatically:**

| Anti-Pattern | Why Rejected | Fix |
|--------------|--------------|-----|
| `except: pass` | Silences errors | Log + re-raise |
| `catch {}` | Silences errors | Log + re-raise |
| Hardcoded secrets | Security hole | Use env vars |
| String-concatenated SQL | SQL injection risk | Parameterized query |
| `ts-ignore` / `any` | Type safety escaped | Fix underlying type |
| Empty catch blocks | Bug hiding | Specific exception + context |

## Review Tone Guidelines

- Be specific: "This query runs on every render" not "This is slow"
- Explain why: "This could cause a race condition because..."
- Offer solutions: "Consider using useCallback here to memoize this"
- Distinguish: **must-fix** vs **nice-to-have**
- **Must-fix items:** block Stage 7 (Archive) until resolved
- **Nice-to-have items:** note in `REVIEW.md`, don't block

## How to Apply

1. Reviewer runs through checklist for every change in Stage 6 (Review)
2. Any unchecked Security or Logic item → return to Stage 4 (Implement)
3. Nice-to-have items → document in `REVIEW.md`, don't block
4. After review passes, Reviewer signs off in `REVIEW.md` artifact
5. Reviewer has final authority — if Reviewer fails the output, follow Failure Routing Rules:
   - Logic/spec error → return to **Architect**
   - Test gap → return to **Test-Writer** (or @code-builder for implementation)
   - Style/rule violation → return to **Implement** (fix code, not design)
