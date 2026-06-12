---
name: evaluator-optimizer
description: Evaluator-optimizer loop — code-builder implements, code-reviewer critiques, loop until quality passes. Use when: complex task, multi-file change, thorough review needed, quality gates, iterative improvement.
tags: [loop, quality, review, build, iterate, critique]
auto_load: code-builder, code-reviewer
---

# Evaluator-Optimizer Loop — Build-Review-Fix Pattern

## When to Use

Trigger this skill when:
- Task complexity ≥ 4 (Moderate) with ≥ 3 files modified
- User explicitly asks for code review or quality check
- Tier 3 (Thorough) pipeline task
- Multi-file feature implementation
- Any task where quality gates are required

**Do NOT trigger for:**
- Trivial/Simple tasks (score 0-3) — single agent faster
- Single-file edits under 10 lines
- Read-only analysis tasks
- When user explicitly says "just do it fast"

---

## Loop Architecture

```
┌─────────────────────────────────────────────────────┐
│                    COORDINATOR                       │
│         (main-coordinator manages the loop)        │
└──────────────────────┬──────────────────────────────┘
                       │
         ┌─────────────┴─────────────┐
         ▼                           ▼
┌─────────────────────┐    ┌─────────────────────┐
│    code-builder     │    │   code-reviewer     │
│  (implements task)  │    │   (reviews work)   │
└──────────┬──────────┘    └──────────┬──────────┘
           │                            │
           │  issues?                   │ verdict
           └─────────────┬─────────────┘
                         ▼
                   LOOP ENDS
                   (PASS) or
                   (max 3 iterations)
```

---

## Loop Protocol (Step by Step)

### Phase 1: Build

1. **Coordinator** receives user request
2. **Classify complexity** — score 0-10
3. **If score ≥ 4 AND ≥ 3 files** → trigger evaluator-optimizer loop
4. **Route to @code-builder** with:
   - Full task context
   - Original user request
   - Pattern maturity data (if available)
   - Verification requirements

### Phase 2: Review

5. **code-builder completes** → reports to coordinator
6. **Coordinator routes to @code-reviewer** with:
   - Task summary
   - Files that were modified
   - Original user request
   - Verification evidence from builder

### Phase 3: Evaluate

7. **code-reviewer** reads all modified files
8. **Runs verification commands** (tests, lint, type check)
9. **Produces verdict:**
   - **PASS** → loop ends, coordinator reports done
   - **FAIL** → extract CRITICAL + HIGH issues → continue to Phase 4

### Phase 4: Fix (Iterate)

10. **Coordinator routes back to @code-builder** with:
    - Issue list (CRITICAL + HIGH only)
    - Specific fix instructions per file + line
11. **code-builder fixes** → reports back
12. **Coordinator routes to @code-reviewer** again
13. **Loop**: Review → verdict → fix (up to 3 iterations)

### Phase 5: Resolve

14. **After 3 FAIL iterations with no progress** → surface to user
15. **On PASS** → record outcome, log success, report done

---

## Severity Classification

| Severity | Meaning | Blocks PASS? |
|----------|---------|-------------|
| **CRITICAL** | Security vulnerability, data loss risk, production crash | YES — always |
| **HIGH** | Bug causing incorrect behavior, missing error handling | YES — always |
| **MEDIUM** | Performance issue, maintainability problem, style violation | No |
| **LOW** | Nitpick, suggestion, preference | No |

**Rule:** CRITICAL + HIGH always trigger fix round. MEDIUM + LOW are recommendations only.

---

## Outcome Recording

After each loop completion (success or failure), record to patterns.jsonl:

```powershell
powershell -File "$CONFIG/scripts/outcome-record.ps1" -TaskType "<type>" -Success <0|1> -FilesTouched <N> -Agent "code-builder" -DurationSeconds <sec> -StrategyUsed "evaluator-optimizer-loop"
```

After session, compute updated pattern scores:

```powershell
powershell -File "$CONFIG/scripts/outcome-score.ps1"
```

---

## Quality Gates (All Must Pass)

Before declaring PASS, code-reviewer verifies:
- [ ] All CRITICAL/HIGH issues resolved
- [ ] Tests pass (unit + integration if applicable)
- [ ] Type check clean (no `any` escapes)
- [ ] Lint clean (no violations)
- [ ] Implementation matches original request
- [ ] Edge cases handled (empty input, failure paths, large inputs)
- [ ] No hardcoded secrets or credentials
- [ ] Security scan complete (OWASP Top 10 checks)

---

## Anti-Patterns (Avoid These)

1. **Skip the review** — "it's fine, I tested it" → NOT PASS until reviewer approves
2. **Pass on first review** — 3+ files almost always have issues on first pass
3. **Iterate without verification** — fix → must re-run review before claiming done
4. **Max iterations without escalation** — 3 failures with no progress → escalate to user

---

## Coordinator Scripts (Reference)

| Script | Purpose |
|--------|---------|
| `outcome-record.ps1` | Log success/failure to patterns.jsonl |
| `outcome-score.ps1` | Compute pattern maturity scores |
| `track-tokens.ps1` | Check budget before routing |