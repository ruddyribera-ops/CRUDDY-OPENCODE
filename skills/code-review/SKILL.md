---
name: code-review
description: Code review patterns and checklists — PR review workflow, common anti-patterns, security scanning, performance review, and style consistency checks.
triggers: review, code-review, pr, pull-request, audit, quality, cr
auto_load: code-builder, bug-fixer
---

# Code Review Patterns

## Review Checklist
- [ ] Changes trace to a single concern (no scope creep)
- [ ] No `any`, `ts-ignore`, `as any` type escapes
- [ ] No hardcoded secrets, URLs, or credentials
- [ ] Error paths handled (not just happy path)
- [ ] No empty catch blocks or silent failures
- [ ] Public API surface is intuitive (hard to misuse)
- [ ] No dead code, commented-out blocks, or debug artifacts
- [ ] All existing tests pass, new feature has tests

## Security Scan
- Input validation at API boundary
- SQL parameterization (no string concatenation)
- XSS prevention (escape output, CSP headers)
- Auth checks on every protected route

## Performance Review
- N+1 queries? → Use eager loading
- Bundle size impact? → Code split if >50KB added
- Unnecessary re-renders? → Memoize or restructure
- Sync I/O in async context? → Move to thread pool

## Style Consistency
- Match existing project patterns (don't introduce new style)
- Same import order, naming conventions, file structure
- Run formatter before marking done
