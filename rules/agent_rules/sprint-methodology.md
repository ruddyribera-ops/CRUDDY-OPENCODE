---
name: sprint-methodology
description: Methodology rules for multi-sprint project execution. Prevents task tool cancellations, interactive command stalls, and mid-flight scope changes observed in 2026-06-20 World Cup Budokai sprint.
triggers: sprint, build, scaffold, deploy, project-execution, multi-step
applies_to: code-builder, tech-lead, project-manager, delivery-engineer, all dispatchers
---

# Sprint Methodology

> Born from `D:\Temp\opencode\world-cup-budokai\POSTMORTEM.md` (2026-06-20). Six cancellations in one sprint. Recovery: short, explicit prompts to code-builder.

## The Pattern Observed

Sprint execution has a recurring failure mode: **task tool interruptions + interactive command stalls + mid-flight scope changes**. When one happens, recovery follows the same pattern: **short, direct prompts with explicit step-by-step instructions to code-builder**.

The rules below encode that recovery into prevention.

## Rule 1: Scaffold-then-Build with Verification Between

NEVER combine scaffold + build into one dispatch.

```
WRONG:
  "Scaffold a Next.js project AND build the Budokai bracket"
  → one dispatch does both → if scaffold fails, all build work is lost

RIGHT:
  Dispatch 1: "Scaffold Next.js 15 + React 19 + Tailwind v4 at <path>. Verify with `npm install` + `npm run dev`."
  Wait for scaffold verification.
  Dispatch 2: "Build the Budokai bracket component at <path>."
```

Why: isolates failure modes. A failed scaffold doesn't kill the build dispatch.

## Rule 2: Never Use `create-next-app` in Automation

The official scaffolder is interactive. It waits for prompts that never come in a non-TTY environment.

```
WRONG:
  npx create-next-app@latest .

RIGHT (pick one):
  Option A: Manual scaffold — code-builder creates all config files by hand
  Option B: npx --yes create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --use-npm
  Option C: Use a non-interactive template
```

## Rule 3: Short, Direct Prompts

**Keep dispatch prompts under 300 chars** for the actual work request. Detail goes in `--context` flags or referenced files, not the prompt body.

```
WRONG (1500 char prompt with full spec):
  "Build a Budokai bracket tracker with PANINI cards, 32 teams, Round of 16..."

RIGHT (under 300 chars):
  "Build Budokai bracket component. Spec: D:\path\spec.md. Read it. Build it."
```

Why: the task tool has truncation issues. Sub-agents receiving empty prompts is a real failure mode.

## Rule 4: Add `--yes` to Every `npx` Command

Any `npx` command may stall waiting for interactive confirmation.

```
WRONG:
  npx create-next-app
  npx shadcn-ui init

RIGHT:
  npx --yes create-next-app ...
  npx --yes shadcn-ui@latest init
```

If a tool doesn't support `--yes`, use a non-interactive equivalent or manual setup.

## Rule 5: Confirm Hosting Intent Upfront

Hosting decisions made mid-sprint cost a full deployment attempt.

```
WRONG:
  Sprint 4: Dispatch Railway deployment
  Client: "Wait, deploy locally only."
  Sprint 4 redo.

RIGHT:
  Sprint 0 (Brief): "Will this be hosted? Where? When?"
  Document in brief.md
  Sprint 4: Dispatch deployment with no surprises
```

## Pattern: When Task Tool Cancels

If a dispatch returns `EXECUTION ABORTED` or empty result:

1. **Don't retry the same prompt.** Reduce scope by 50%.
2. **Switch specialist.** If project-manager cancelled, try tech-lead. If tech-lead cancelled, try code-builder directly.
3. **Simplify the prompt.** Strip context. Reference a file instead of pasting content.
4. **Third attempt with different shape** usually works. Don't burn more than 3 attempts on the same shape.

## What Worked (from the post-mortem)

The recovery pattern that saved the sprint:
- 8-question brief in 15 minutes → no scope creep
- Manual scaffold after `create-next-app` stalled → faster than debugging the scaffolder
- Static seed data → no API risk
- One-pass build → no incremental verification needed
- `npm run build` clean on first attempt

These are observations, not rules. The rules above prevent needing recovery in the first place.

(End of file - total 143 lines)
