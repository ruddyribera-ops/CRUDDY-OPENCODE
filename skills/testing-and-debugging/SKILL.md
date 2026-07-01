---
name: testing-and-debugging
description: "End-to-end testing and debugging methodology — bug investigation, property-based testing, performance, end-to-end webapp testing. Use when chasing a bug, designing tests, investigating failures, or auditing performance. Triggers: debug this, fix this bug, test this feature, find what's broken, performance issue, race condition, flapping test, repro, root cause, investigate, slow query."
triggers:
  - "testing-and-debugging"
  - "testing and debugging"
  - "when to use testing and debugging"
  - "how to testing and debugging"
  - "testing and debugging examples"
  - "testing and debugging pattern"
applies_to:
  - "main-coordinator"
---


# Testing and Debugging

## When to Use This

Load this skill when:
- Chasing a bug that needs root cause investigation
- Writing tests for a new feature
- Investigating test failures or flaky tests
- Auditing performance of a system
- Debugging intermittent issues (race conditions, timing bugs)

This skill composes **4 focused skills**: `systematic-debugging`, `investigate`, `webapp-testing`, and `performance-optimization`.

---

## The 4 Lenses

### 1. Debugging Lens (`systematic-debugging/`)

Covers: Root cause investigation, hypothesis-driven exploration, minimal reproduction, eliminating causes one by one.

**Key approach:**
```
REPRODUCE → HYPOTHESIZE → ISOLATE → FIX → VERIFY → REGRESSION TEST
```

**Key principle:** Never fix where the error appears — trace backward to find the original trigger.

### 2. Investigation Lens (`investigate/`)

Covers: Multi-system tracing, evidence gathering, gstack methodology (GATHER→STACK→TRACK→ACK→NARRATE→COMPLETE).

**Key approach:**
- Evidence first, theory second
- Distinguish proximate cause from root cause
- Trace the full call chain: client → load balancer → API → database
- Document findings in real time

### 3. Webapp Testing Lens (`webapp-testing/`)

Covers: Playwright patterns, data-testid selectors, condition-based waiting, cold start tolerance, multi-tab/multi-context.

**Key principles:**
- Use `data-testid` attributes (not CSS selectors)
- Wait for conditions, never hard-coded sleep
- Test behavior, not implementation
- Isolate tests from each other

### 4. Performance Lens (`performance-optimization/`)

Covers: Bundle size, lazy loading, memoization, query performance, caching strategies.

**Key questions:**
- Is the slow query using an index?
- Are N+1 queries eliminated?
- Is caching applied appropriately?
- Is bundle size minimal?

---

## Composite Workflow

Follow this 10-step process for any bug investigation:

### Steps 1-2: Reproduce and Document
1. **Confirm reproducibility** — Can you trigger the bug reliably? If not, gather more evidence first.
2. **Create minimal reproduction** — Isolate to fewest possible lines, self-contained, runnable without setup.

### Steps 3-5: Investigate and Hypothesize
3. **Gather evidence** — Error messages, stack traces, logs, timestamps, recent changes (`git log --oneline -20`).
4. **Trace the call chain** — Client → CDN → load balancer → API → database. Which hop is failing?
5. **Form hypothesis** — Write down your best guess BEFORE touching code. "Root cause hypothesis: ..."

### Steps 6-7: Isolate and Verify
6. **Test hypothesis** — Change one variable at a time. If wrong, refine and loop back to step 3.
7. **Verify with evidence** — Add temporary log/assertion, run reproduction, confirm evidence matches.

### Steps 8-10: Fix, Test, and Regression
8. **Fix the root cause** — Smallest change that eliminates the actual problem. Not the symptom.
9. **Write regression test** — Test that fails without the fix, passes with it.
10. **Run full test suite + health check** — No regressions. Service responds correctly.

---

## Cross-References

| Skill | What it adds |
|-------|-------------|
| `systematic-debugging/` | Debug loop, minimal reproduction, binary search, stack trace reading |
| `investigate/` | Multi-system tracing, evidence gathering, gstack workflow, communication templates |
| `webapp-testing/` | Playwright patterns, `data-testid` selectors, condition-based waiting |
| `performance-optimization/` | Bundle analysis, query optimization, caching strategies, lazy loading |

---

## Heuristic Collection: Top 10 Debugging + Testing Heuristics

| # | Heuristic | When to apply |
|---|-----------|---------------|
| 1 | **Iron Law: No fixes without root cause** | Every bug fix — fix the cause, not the symptom |
| 2 | **Reproduce first** | Before changing anything — if you can't repro, you can't verify |
| 3 | **Change one thing at a time** | If you change two things and it works, you don't know which fixed it |
| 4 | **Top of stack is rarely the root cause** | Read full trace from bottom to top — trace backward |
| 5 | **3 strikes and escalate** | 3 failed hypotheses → architecture problem, not a simple bug |
| 6 | **data-testid > CSS selectors** | Refactoring won't break tests with stable test IDs |
| 7 | **Wait for condition, not delay** | `waitFor()` beats `sleep(N)` — race-condition-free |
| 8 | **Evidence first, theory second** | Gather before guessing — confirmation bias leads you astray |
| 9 | **Minimal reproduction is always possible** | If you can't isolate, it's usually an environmental difference |
| 10 | **Regression test = proof the bug is fixed** | No test = bug will come back |

### Pattern Table: Bug Type → Where to Look

| Bug Type | Signature | Where to look |
|----------|-----------|---------------|
| Race condition | Intermittent, timing-dependent | Shared state, concurrent access |
| Nil/null propagation | TypeError, NoMethodError | Missing guards on optionals |
| State corruption | Inconsistent data | Transactions, callbacks, hooks |
| Integration failure | Timeout, unexpected response | External API calls, service boundaries |
| Config drift | Works locally, fails prod | Env vars, feature flags, DB state |
| Stale cache | Old data, fixes on clear | Redis, CDN, browser cache |
| N+1 query | Slow with many records | ORM queries, loops over DB calls |
| Memory leak | Growing RSS over time | Object references, event listeners |

### Test Anti-Patterns to Avoid

- **Testing mock behavior** — Assert on real component behavior, not mock existence
- **Test-only methods in production** — Use test utilities instead
- **Hard-coded `sleep(N)`** — Race condition; use explicit waits
- **CSS class selectors** — Break on refactor; use `data-testid`
- **Not cleaning up between tests** — State leakage causes flaky tests
- **Missing console error capture** — Tests that pass with console errors hide real bugs

### Debugging Anti-Patterns to Avoid

- **Random fixes without hypothesis** — "Hoping" not debugging
- **"Works on my machine"** — CI is the source of truth
- **Fixing symptoms not causes** — Bug comes back
- **Not verifying the fix** — Without a test, the bug will return
- **Silence during investigation** — Stakeholders need updates
- **Not documenting** — Future you needs those notes
