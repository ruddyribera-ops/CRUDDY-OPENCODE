# MiniMax M3 — Behavioral Patterns & Fixes

**Date:** 2026-05-25 | **Session:** PRIA v10, 3 sprints

## Pattern 1: Accepts roadmap, never questions

**Fix:** Coordinator prepends to every handover:
> "Before implementing, state ONE alternative approach and why you chose this one."

## Pattern 2: Reports done based on file creation

**Fix:** Exit criteria must include runtime command, not file count.
- ❌ "12/12 schemas created"
- ✅ "curl /api/motores (invalid JSON) → 422"

## Pattern 3: Happy-path only

**Fix:** Every exit criteria block MUST include one edge case.
- ✅ "Also verify: 21st request returns 429, rate limit resets after window"

## Pattern 4: Needs ultra-specific instructions

**Fix:** Coordinator ALWAYS uses compressed format:
- Header (3 lines) → Items (file + pattern + exit criteria) → No context repetition
- Never send: "improve the pipeline" — too vague for M3

## Escalation Rule

Route to DeepSeek V4 Pro (not M3) when task involves:
- Architecture decisions with multiple valid approaches
- Refactoring with ambiguous scope
- Debugging without clear error message
