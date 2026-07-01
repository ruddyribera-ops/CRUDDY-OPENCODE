---
name: review-loop
description: "Auto-review changed files until they pass quality gates. Inspired by Greptile + GrepLoop. Use when you want iterative review of recent changes without manually re-running checks. Triggers: review my code, check for issues, run quality checks, find bugs, gate check, iterative review."
triggers:
  - review my code
  - check for issues
  - run quality checks
  - find bugs
  - gate check
  - iterative review
  - auto review
applies_to:
  - code-reviewer
  - main-coordinator
---

# Review Loop — Auto-Review Until Gates Pass

## When to use this

Load this skill when:

- You want to automatically re-run quality checks after each change
- You're iterating on a fix and want to know when quality gates clear
- You want a "red light → green light" workflow for code review
- You need to enforce code quality without manual re-checking

Do NOT use this skill when:

- You want a one-shot code review (use code-reviewer directly)
- The changes are docs-only or trivial (overkill)
- You want adversarial review for bugs (use expert-tester)

---

## How it works

The review loop runs quality gates iteratively until they pass or a stop condition is met.

### Gates (configurable)

Default gates:

1. **Lint** — `biome check`, `ruff check`, `eslint`, or equivalent
2. **Type check** — `tsc --noEmit`, `mypy`, or equivalent
3. **Tests** — `pytest`, `npm test`, or equivalent
4. **Format** — `biome format`, `black`, or equivalent

### Loop behavior

```
iteration = 0
max_iterations = 5   # safety: prevent infinite loops
all_passing = False

while not all_passing and iteration < max_iterations:
    iteration += 1
    run all gates
    if all pass: all_passing = True
    else:
        report failures
        # User fixes the issues, then re-runs the loop

report final state
```

### Exit conditions

- `ALL_PASSING` — all gates green
- `MAX_ITERATIONS_REACHED` — give up, surface remaining issues
- `USER_ABORTED` — user interrupts

### Per-iteration output

```
[Iteration 3/5]
  Lint:       FAIL (3 errors in src/auth/jwt.py)
  Type check: FAIL (TS2322 in src/types/user.ts:42)
  Tests:      PASS (47/47)
  Format:     PASS

  Issues to fix:
    1. jwt.py:23 — unused import
    2. jwt.py:45 — bare except clause
    3. user.ts:42 — 'string' is not assignable to 'number'

[Iteration 4/5]
  Lint:       PASS
  Type check: PASS
  Tests:      PASS
  Format:     PASS

ALL PASSING — exit GREEN
```

---

## Stop conditions (safety rails)

Same as `loop-operator-safety.md`:

- max_iterations default: 5, hard cap 10
- Each iteration: bounded by sub-agent-guard 5-min timeout
- Stall detection: 3 consecutive identical failure signatures → STALLED

---

## Configuration

Per-project gates can be customized:

```yaml
# .opencode/review-loop.yaml
gates:
  - name: lint
    command: "npm run lint"
  - name: typecheck
    command: "npm run typecheck"
  - name: tests
    command: "npm test"
  - name: format
    command: "npm run format:check"
max_iterations: 5
```

---

## Cross-references

- `rules/loop-operator-safety.md` — safety rails for the loop pattern
- `agents/code-reviewer.md` — single-pass review (use when loop is overkill)
- `skills/evaluator-optimizer/SKILL.md` — for LLM-based review loops

---

## Status

Starter skill (created 2026-06-29). Integration with project-specific gates requires per-project `.opencode/review-loop.yaml` setup.