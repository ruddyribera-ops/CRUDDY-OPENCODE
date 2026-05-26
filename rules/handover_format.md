# Compressed Handover Format

## Rule

All coordinator-to-specialist handovers MUST use this format.
No exceptions for M2.7 agents. Strongly recommended for all agents.

## Structure

```
═══════════════════════════════════════════
TITLE — Project | Phase
═══════════════════════════════════════════
Project: <path>
Current: <1-line state>
Target:  <1-line goal>
───────────────────────────────────────────
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
───────────────────────────────────────────
EXECUTION ORDER
Batch 1: <independent items>
Batch 2: <dependent items>
───────────────────────────────────────────
EXIT CRITERIA
    <item 1 criteria>
    <item 2 criteria>
    All previous tests still pass (no regressions)
═══════════════════════════════════════════
```

## Rules

1. Header is 5 lines MAX (title, project, current, target)
2. Each item: WHY (1 sentence) + FILES (paths) + PATTERN (code) + VERIFY (command)
3. Target: ~3K tokens per handover. Never repeat context agents already have.
4. Exit criteria must include ONE edge case
5. Verification includes specific command + expected output

## Anti-Patterns

- ❌ "Improve the pipeline" (too vague)
- ❌ "Fix the bugs" (no file paths)
- ❌ Repeating project architecture in every item
- ❌ Handover >8K tokens
- ❌ Exit criteria: "10/10 passing" (no list)
