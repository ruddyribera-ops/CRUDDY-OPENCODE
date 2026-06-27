---
name: superpowers-subagent-driven-development
description: Subagent orchestration pattern for parallel work — implementer/reviewer split, task briefs, review packages. Use when delegating complex multi-step tasks to subagents, running parallel review workflows, or building task pipelines. Triggers: subagent task, delegation, parallel review, implementer prompt, task brief, review package.
---

# Subagent-Driven Development Skill

## When to Use

Use this skill when:
- A task is too large/complex for one agent
- You need parallel work streams (implement + review simultaneously)
- You want systematic quality gates before completion
- Multiple subagents need coordinated handoffs

## Core Pattern: Implementer + Reviewer Split

```
┌─────────────────────────────────────────────────────────┐
│  TASK BRIEF (scripts/task-brief)                        │
│    - Clear requirements                                 │
│    - Acceptance criteria                                │
│    - File structure                                     │
└─────────────────────────────────────────────────────────┘
         │                                    │
         ▼                                    ▼
┌─────────────────────┐          ┌─────────────────────┐
│    IMPLEMENTER      │          │    TASK REVIEWER    │
│  (general-purpose)  │          │  (general-purpose)  │
│                     │          │                     │
│ - Reads brief       │          │ - Reads brief       │
│ - Implements        │          │ - Reads diff        │
│ - Writes tests      │          │ - Verifies spec     │
│ - Self-reviews      │          │ - Code quality      │
│ - Reports back      │          │ - Returns verdict   │
└─────────────────────┘          └─────────────────────┘
         │                                    │
         ▼                                    ▼
┌─────────────────────────────────────────────────────────┐
│  COORDINATOR AGGREGATES → PASS or FIX + RE-REVIEW       │
└─────────────────────────────────────────────────────────┘
```

## Implementer Prompt Template

Use when dispatching an implementer subagent:

```
Subagent (general-purpose):
  description: "Implement Task N: [task name]"
  model: [MODEL — REQUIRED per SKILL.md Model Selection]
  prompt: |
    You are implementing Task N: [task name]

    ## Task Description
    Read your task brief first: [BRIEF_FILE]

    ## Before You Begin
    If you have questions about requirements, approach, or anything unclear — ask NOW.

    ## Your Job
    1. Implement exactly what the task specifies
    2. Write tests (following TDD if required)
    3. Verify implementation works
    4. Commit your work
    5. Self-review before reporting back

    ## When You're in Over Your Head
    STOP and escalate when:
    - Task requires architectural decisions
    - You can't find clarity in provided context
    - Uncertain about approach correctness

    ## Self-Review Checklist
    - Completeness: Did I implement everything?
    - Quality: Is this my best work?
    - Discipline: Did I avoid overbuilding?
    - Testing: Do tests verify real behavior?

    ## Report Format
    Write full report to [REPORT_FILE]:
    - What was implemented
    - Test results with TDD evidence
    - Files changed
    - Self-review findings

    Then report back (under 15 lines):
    - Status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - Commits created
    - Test summary
    - Concerns if any
```

## Task Reviewer Prompt Template

Use when dispatching a task reviewer subagent:

```
Subagent (general-purpose):
  description: "Review Task N (spec + quality)"
  prompt: |
    You are reviewing one task's implementation.

    ## What Was Requested
    Read: [BRIEF_FILE]

    ## What the Implementer Claims
    Read: [REPORT_FILE]

    ## Diff Under Review
    Base: [BASE_SHA]
    Head: [HEAD_SHA]
    Diff: [DIFF_FILE]

    ## Do Not Trust the Report
    Verify claims against the diff. Judge on merits.

    ## Part 1: Spec Compliance
    - Missing: requirements skipped
    - Extra: over-engineering
    - Misunderstood: right feature, wrong approach

    ## Part 2: Code Quality
    - Clean separation of concerns?
    - Proper error handling?
    - Edge cases handled?

    ## Output Format
    ### Spec Compliance
    - ✅ Compliant | ❌ Issues found

    ### Strengths
    [What's well done?]

    ### Issues
    #### Critical (Must Fix)
    #### Important (Should Fix)
    #### Minor (Nice to Have)

    ### Assessment
    **Task quality:** [Approved | Needs fixes]
```

## Tooling: scripts/task-brief

Prints the task brief file path for a given plan number:

```bash
scripts/task-brief PLAN <number>
# Returns: /path/to/brief-N.md
```

## Tooling: scripts/review-package

Creates a review package with diff for reviewer:

```bash
scripts/review-package BASE_SHA HEAD_SHA
# Returns: /path/to/review-package-<hash>.md
```

## When to Use This vs Simpler Delegation

| Scenario | Use This Pattern | Use Simple Delegation |
|----------|------------------|----------------------|
| < 3 files, < 100 lines | ❌ | ✅ Single dispatch |
| Multi-file feature | ✅ Implementer + Reviewer | ⚠️ Simple dispatch |
| Cross-cutting changes | ✅ Review gate | ❌ |
| High-stakes/complex | ✅ Quality loop | ❌ |

## Anti-Patterns

- ❌ Dispatching without a clear brief
- ❌ Skipping the reviewer (trusting implementer only)
- ❌ Reviewer re-running tests (trust the report)
- ❌ Implementing without self-review
- ❌ Ignoring escalations from implementer

## Quality Gates

**Implementer must achieve:**
- All tests pass
- Self-review complete
- No TODO comments as implementation
- No empty files or stub functions

**Reviewer verifies:**
- Spec compliance (nothing missing/extra/misunderstood)
- Code quality (clean, tested, maintainable)
- Verdict: APPROVED or NEEDS FIXES

## References

See source files:
- `implementer-prompt.md` — Full implementer template
- `task-reviewer-prompt.md` — Full reviewer template
- `scripts/task-brief` — Task brief printer
- `scripts/review-package` — Review package generator