# M3 Compensation Rules — Hard System Rules

**Purpose:** MiniMax M3 four behavioral failure modes, countered by mandatory pre-route actions.
**These are NOT suggestions. They fire on every routing decision.**

---

## FAILURE MODE 1 — Accepts roadmap, never questions

**Detection:** None (silent). The agent just does what is asked without scrutiny.

### COUNTER — Forced Alternative Preamble

**Rule:** Before every handover to any specialist, state ONE alternative approach.

**Format (mandatory prefix — inject verbatim into EVERY handover):**

```
Before implementing, state ONE alternative approach and why you chose this one.
```

**How to inject:** Copy the line above verbatim into the handover prompt BEFORE the task description.
**No variation allowed.** "Maybe state an alternative" = non-compliant.

---

## FAILURE MODE 2 — Reports done based on file creation

**Detection:** Agent says "all files created" without runnable proof.

### COUNTER — Exit Criteria Must Include Runtime Command

**Rule:** Every POA exit criteria MUST include a runnable verification command.

- GOOD: "curl /api/motores → 200 OK"
- BAD: "12/12 schemas created"
- GOOD: "pytest tests/ --tb=short → 45 passed, 0 failed"
- BAD: "all tests passing" (no command listed)

**Rule:** Coordinator exits at Tier 1 minimum. File existence alone = tier 0 = REJECT to specialist.

---

## FAILURE MODE 3 — Happy-path only

**Detection:** Agent tests only the success case. Never tests edge conditions.

### COUNTER — Every Exit Criteria Block Must Include One Edge Case

**Rule:** Every exit criteria block MUST include one edge case test.

**Format (mandatory — add after each main criteria):**

```
Also verify: [edge case] → [expected output]
```

**Examples:**
- "Also verify: empty input → 422 validation error"
- "Also verify: 21st request → 429 rate limit response"
- "Also verify: missing API key → 401, not 500"
- "Also verify: max file size (50MB) →413PayloadTooLarge"

**No edge case per item = non-compliant.**

---

## FAILURE MODE 4 — Needs ultra-specific instructions

**Detection:** Vague handovers produce vague output. Specialist says "I don't understand" or does wrong thing.

### COUNTER — Compressed Handover Format Required

**Rule:** All coordinator → specialist handovers use this EXACT format:

```
════════════════════════════════════════════
TITLE — Project | Phase
════════════════════════════════════════════
Project: <path>
Current: <1-line state>
Target:  <1-line goal>

ITEM 1 — Name (effort estimate)
WHY: <1 sentence>
FILES TO CREATE/MODIFY:
  path/to/file.ts — <what changes>
PATTERN:
  <code block showing exact approach>
VERIFY:
  <runnable command + expected output>
Done when:
    <specific, verifiable criteria>
    <at least one edge case>

════════════════════════════════════════════
EXECUTION ORDER
Batch 1: <independent items>
Batch 2: <dependent items>
════════════════════════════════════════════

EXIT CRITERIA
    <item 1 criteria>
    <item 2 criteria>
    All previous tests still pass (no regressions)
```

**Rules:**
- Header is 5 lines MAX
- Each item: WHY (1 sentence) + FILES (paths) + PATTERN (code) + VERIFY (command)
- Target: ~3K tokens per handover (never >8K)
- One edge case per item

**Anti-patterns that fail:**
- "Improve the pipeline" (too vague)
- "Fix the bugs" (no file paths)
- "10/10 passing" (no list of what, no command)
- Handover >8K tokens

---

## Auto-Injection Checklist (Coordinator runs at routing time)

Before every route, coordinator verifies ALL of:

- [ ] **Alternative preamble** injected verbatim? ("Before implementing, state ONE alternative approach...")
- [ ] **Every exit criteria has a runtime command** listed in VERIFY block?
- [ ] **Every item has an edge case** listed in "Also verify:"?
- [ ] **Handover format compliant** (header ≤5 lines, ~3K tokens)?
- [ ] **Tier 1 minimum enforced** (runtime command exists, not just "files created")?

**If ANY item unchecked:** fix before routing. Do not proceed.

---

## Escalation Rule

Route to DeepSeek V4 Pro (NOT M3) when task involves:
- Architecture decisions with multiple valid approaches
- Refactoring with ambiguous scope
- Debugging without clear error message

This is the ONLY exception to the tier-routing model.

---

*Date: 2026-05-28 — Hardened from feedback_m2_compensation.md (advisory) → rules/m27-compensation.md (mandatory)*
