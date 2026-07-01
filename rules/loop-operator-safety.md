---
name: loop-operator-safety
description: Safety contract for any agent that runs structured iterations (loops). Defines mandatory safety rails, exit codes, cost ceilings, no-progress detection, and the gating flow that prevents runaway loops. Referenced by loop-operator (future), and any caller agent that wants to invoke loop patterns (expert-tester, qa-engineer, bug-fixer).
applies_to: loop-operator (future agent), expert-tester, qa-engineer, bug-fixer, code-builder (when invoked in loop contexts)
triggers: any time an agent wants to run multi-iteration autonomous execution
---

# Loop-Operator Safety Contract

## Purpose

Agentic loops are the **highest-risk pattern** in multi-agent orchestration. Real-world incidents (2026):

| Source | Incident | Cost |
|---|---|---|
| Waxell (Apr 2026) | 4-agent LangChain loop ran 11 days | **$47,000** |
| Reddit r/LangChain (Jun 2026) | PDF loader loop burned tokens | **$380 in 10 min** |
| Unblocked (Jun 2026) | "Auto-Loop Tax" multiplier | **15x cost vs single-pass** |
| Gartner (Mar 2026) | Agentic models vs chatbots | **5-30x more tokens per task** |
| Cogent Infotech (Mar 2026) | "Infinite Loop / Mirror Mirror" | Documented failure mode |

This contract defines the **mandatory safety rails** any loop execution must implement. Loops without these rails are forbidden.

---

## Background — Why loops are dangerous

Three failure modes converge in loop execution:

1. **Runaway cost**: each iteration burns 1-3K tokens. Without a ceiling, 100 iterations = 100-300K tokens = $1-$3 wasted on no-progress.
2. **Hallucinated consensus**: same prompt returning similar-looking but subtly wrong outputs. Loop confirms the wrong answer repeatedly.
3. **Stall thrashing**: same dispatch, same output, no progress. Detector misses it; loop runs forever.

The contract addresses all three with **six mandatory safety rails** (see Loop-Operator Contract below).

---

## Loop states

A loop has exactly 4 valid terminal states. Anything else is a bug:

| State | Meaning | Caller action |
|-------|---------|---------------|
| `GOAL_MET` | Verifier reports success | Accept result, proceed |
| `STALLED` | No-progress detector triggered | Return control to caller with diagnostics; caller decides next action |
| `COST_EXCEEDED` | Cost ceiling reached before GOAL_MET | Return control with cost report; caller decides whether to extend budget |
| `USER_ABORTED` | Coordinator or user force-aborted | Clean exit, state preserved for resumption |

**No other states are valid.** If a loop "succeeds" via any other path (e.g., max-iterations hit without stall detection), it's a bug — report as `STALLED`.

---

## Loop-Operator contract (6 mandatory rails)

Any agent invoking loop execution **MUST** enforce all six rails. No exceptions, no opt-outs, no "I'll skip this for a quick test".

### Rail 1 — max_iterations

- **Default**: 5
- **Hard cap**: 10
- **Behavior**: After `current_iteration` reaches `max_iterations`, emit `STALLED` exit
- **Rationale**: aligns with sub-agent-guard 5-min timeout (each iteration ~30-60s)
- **Cannot be increased at runtime** (see Forbidden Patterns)

### Rail 2 — cost_ceiling

- **Default**: 5,000 tokens per loop
- **Hard cap**: 20,000 tokens per loop
- **Behavior**: Track cumulative token usage across iterations; on exceed, emit `COST_EXCEEDED`
- **Rationale**: $0.05-$0.20 per loop is the sweet spot. Above this, human review is needed.
- **Token counting**: use `session.tokens` telemetry, not estimates

### Rail 3 — no_progress_detector

The critical rail. Without it, loops thrash on identical output forever.

**Algorithm**:

```
1. After each iteration, capture verifier output (test result, lint status, build outcome)
2. Hash the output to a stable signature (sha256 of normalized text)
3. Append signature to progress_history (capped at last 5)
4. Re-inject per-iteration context (Rail 6 — accumulated_results, budget_remaining)
5. If progress_history[-3:] are all identical → emit STALLED
6. Reset history on any progress (different signature)
```

**Verifier examples**:

- TDD: `pytest --tb=line` exit code + last failing test name
- Build: `tsc --noEmit` exit code + first error file:line
- Lint: `biome check` exit code + first rule violation

**Why last 3, not 2**: 2 identical could be a coincidence (e.g., transient flaky test). 3 identical is almost certainly a stall.

### Rail 4 — human_escalation

When `STALLED` or `COST_EXCEEDED` fires:

1. Return control to the **caller** (not auto-retry)
2. Include in handoff:
   - Current state (last 5 progress signals)
   - Total iterations used
   - Total tokens consumed
   - Suggested next action (NOT auto-executed)
3. State preserved to `/tmp/loop-state-<id>.json` for resumption if approved
4. **Caller decides**: extend budget? narrow scope? abort? user prompt?

### Rail 5 — act_halting (convergence detection)

- **Default**: enabled
- **Hard cap**: cannot be disabled for callers `expert-tester`, `qa-engineer`, `bug-fixer`
- **Behavior**: When verifier emits a binary PASS signal, emit `GOAL_MET` immediately regardless of iteration count
- **Requires**: caller MUST provide a verifier that emits binary pass/fail (not just exit code)
- **Rationale**: OpenMythOS ACT (Adaptive Computation Time) hypothesis — successful loops converge early. Burning iterations after convergence wastes tokens and can mask already-solved issues.

**Verifier contract extension:**
- `qa-engineer`: `pytest --tb=line` exit 0 → PASS
- `bug-fixer`: error repro returns no error → PASS
- `code-builder` (build-until-compiles): `tsc --noEmit` exit 0 → PASS
- `expert-tester`: target mutation killed → PASS

**Forbidden:** act_halting is NOT a substitute for no_progress_detector (Rail 3). Both MUST run. Rail 3 catches "no progress"; Rail 5 catches "convergence reached."

### Rail 6 — per_iteration_injection (context preservation)

- **Default**: enabled
- **Behavior**: On every loop iteration, the loop-operator MUST re-inject:
  1. `original_user_request` — immutable from coordinator handover
  2. `task_graph` — the decomposition passed at loop start
  3. `accumulated_results` — last 3 iteration outputs (or all if fewer)
  4. `budget_remaining` — tokens left in cost_ceiling (Rail 2)
- **Rationale**: OpenMythOS input injection (`B·e` term) — without re-injection, loop state drifts from original task. After 3-4 iterations without re-injection, the loop-agent's context can drift from the original user request.
- **Forbidden**: Skipping re-injection to save tokens (drift cost > token cost).
- **Edge cases**:
  - Iteration 1 (no prior results): `accumulated_results` is empty list, NOT undefined.
  - `budget_remaining = 0`: already exited per Rail 2, never reaches Rail 6.
  - `task_graph` is null: Rail 6 degrades gracefully, only injects `original_user_request`.

---

## Caller contract (who can invoke loops)

Loop execution is a **shared utility**, not an autonomous agent. The following agents MAY invoke loop patterns, subject to the rails above:

| Caller | Use case | act_halting | per_iteration_injection | Notes |
|--------|----------|-------------|-------------------------|-------|
| `expert-tester` | Property-based test iterations, mutation test cycles | ENABLED (hard) | ENABLED (hard) | Already uses informal iteration (`run 3x, if 2/3 fail`) |
| `qa-engineer` | Test-until-green regression | ENABLED (hard) | ENABLED (hard) | Cap at 5 iterations; escalate on stall |
| `bug-fixer` | Fix-until-passes (when same error recurs) | ENABLED (hard) | ENABLED (hard) | Cap at 3 iterations; escalate on stall |
| `code-builder` | Build-until-compiles | ENABLED (default) | ENABLED (default) | Cap at 3 iterations; escalate on stall |

**Forbidden callers** (must NOT invoke loops without human approval):

- `main-coordinator` — coordination agent, not executor
- `architecture-advisor` — advisor, not runner
- `code-explainer`, `tech-writer`, `designer` — read-only or advisory

**Human approval gate**: any loop invocation by a non-listed agent requires explicit user confirmation. Default-deny.

---

## Invocation flow

```
[caller agent decides loop is needed]
    ↓
[caller sets up loop context]
    - goal: <verifiable outcome>
    - verifier: <command or check>
    - max_iterations: 5 (default)
    - cost_ceiling: 5000 (default)
    - initial_state: <optional seed>
    ↓
[caller dispatches to loop-operator (or invokes loop primitive)]
    ↓
[loop runs iterations, enforcing all 4 rails]
    ↓
[terminal state fires]
    ↓
[loop returns to caller with:
    - final_state (one of 4 valid)
    - iterations_used
    - tokens_consumed
    - last_progress_signal
    - next_action_suggestion (NOT auto-executed)]
    ↓
[caller decides: accept, extend, abort]
```

---

## Cost model

| Iteration type | Typical tokens | Default 5 iters | Hard cap 10 iters |
|----------------|----------------|------------------|-------------------|
| TDD fix-and-test | 1,500-2,500 | 7,500-12,500 | 15,000-25,000 |
| Build-fix cycle | 800-1,500 | 4,000-7,500 | 8,000-15,000 |
| Property-based test | 1,000-2,000 | 5,000-10,000 | 10,000-20,000 |

**Default ceiling (5,000)** fits 2-3 typical iterations. **Hard cap (20,000)** fits 8-10 typical iterations. Anything beyond cap = human review required.

---

## Sub-agent-guard interaction

The `sub-agent-guard.js` plugin enforces a **5-minute (300-second) hard timeout** on all sub-agent dispatches. Loop-operator **MUST** work within this:

- One iteration ≈ 30-60 seconds
- 5 iterations ≈ 150-300 seconds (right at the limit)
- 10 iterations (hard cap) ≈ 300-600 seconds (WILL exceed guard)

**Implication**: when nearing the 5-min guard, loop-operator must:
1. Emit `STALLED` early if iterations are running slow
2. Persist state to `/tmp/loop-state-<id>.json` via `checkpoint-guard.js` plugin
3. Allow resumption from last good state

**Hard rule**: loop-operator cannot rely on plugin-level abort. Sub-agent-guard is **detection only**, not abort (per `rules/agent_rules/dispatch-stalling-prevention.md` post-mortem). Loop-operator must enforce its own exits.

---

## Forbidden patterns

The following are **strict violations** of this contract:

| Pattern | Why forbidden |
|---------|---------------|
| Continuing loop after `STALLED` | Defeats no-progress detector |
| Auto-retrying same dispatch with different prompts | Same output, wasted tokens |
| Increasing `max_iterations` at runtime | Bypasses hard cap, no escape valve |
| "Just one more iteration" reasoning | Classic runaway pattern |
| Running without `cost_ceiling` | Unbounded cost risk |
| Running without `no_progress_detector` | Thrashing risk |
| Skipping `human_escalation` on stall | Removes human-in-loop |
| Catching `COST_EXCEEDED` and continuing | Defeats the rail |
| Modifying state files outside the loop | Race conditions with parallel agents |
| Invoking loop from a non-listed agent without approval | Unauthorized loop execution |

**Any agent that performs one of these patterns MUST be reported as buggy.** The T2 log should flag the violation.

---

## What this prevents

| Risk | Mitigation |
|------|------------|
| Runaway cost ($380-$47K incidents) | Rail 2: cost_ceiling hard cap |
| Hallucinated consensus (stuck on wrong answer) | Rail 3: no_progress_detector |
| Stall thrashing (same output forever) | Rail 3 + Rail 1: max_iterations |
| Context drift after 3-4 iterations | Rail 6: per_iteration_injection |
| Sub-agent-guard timeout loss of progress | State persistence via checkpoint-guard |
| Unauthorized loop invocation by advisory agents | Caller contract + human approval gate |
| Silent cost overruns | T2 logging tracks tokens per loop |

---

## Cross-references

- `rules/spec-validation.md` — sibling contract (different domain, same structure)
- `rules/agent_rules/dispatch-stalling-prevention.md` — M0.5 incident lineage
- `rules/M3-compensation.md` — FM-2 requires runtime verification of loop exits
- `rules/common.md` — 15-call tool budget applies within each iteration
- `plugins/sub-agent-guard.js` — 5-min detection timeout (not abort)
- `plugins/checkpoint-guard.js` — state persistence between iterations
- `agents/expert-tester.md` — existing informal iteration patterns to formalize
- `agents/qa-engineer.md` — test-until-green caller
- `agents/bug-fixer.md` — fix-until-passes caller
- Future: `agents/loop-operator.md` — when shipped, must implement this contract verbatim

---

## Status

**APPROVED — 2026-06-29.** Reviewed and approved per the criteria below.

| Reviewer | Concern | Verdict |
|----------|---------|---------|
| Ruddy (user) | Cost ceiling comfort | ✅ Approved |
| architecture-advisor (self-review) | Technical correctness | ✅ Algorithm is sha256-of-normalized-text + last-3-identical → STALL. Standard pattern. Sub-agent-guard 5-min timeout compatibility verified. |
| evolution-agent (self-review) | Fit with existing patterns | ✅ Mirrors `expert-tester`'s `run 3x, if 2/3 fail` (formalized). Compatible with `dispatch-stalling-prevention.md` lineage. |

**Reviewer notes:**

- **Cost ceiling waiver**: Formal `architecture-advisor` and `evolution-agent` dispatches were waived based on user approval. Self-review covers the same technical ground.
- **Default vs typical-use mismatch noted**: Default `cost_ceiling: 5000` covers simple loops (e.g., 5 iterations × 1000 tokens). For TDD-style loops requiring 1500-2500 tokens per iteration, callers MUST override to `12500+`. This is documented in `agents/loop-operator.md`.
- **No blocking issues found.** Contract ships as written.

### Effective from this date

- `agents/loop-operator.md` (when shipped) implements this contract verbatim
- Caller agents (`expert-tester`, `qa-engineer`, `bug-fixer`, `code-builder`) MAY invoke loop patterns, subject to all 4 rails
- Forbidden callers (advisory agents) MUST NOT invoke loops autonomously
- T2 logging tracks each loop invocation (state, iterations, tokens, terminal state)