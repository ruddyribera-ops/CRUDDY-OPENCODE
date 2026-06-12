---
description: Add a blocker to a factory project. Categorizes (internal, technical, or client-side), logs to sprint.md, and routes to AM if the client needs to unblock. Use when something is preventing a task from being done.
usage: /factory-blocker <project-id> <description> [--category internal|technical|client] [--severity low|medium|high|critical]
---

# /factory-blocker — Log a blocker

When something is preventing a task from being done, log it. This is a 2-minute action. Don't let blockers fester.

## What you do

1. **Categorize the blocker**:
   - `internal` — waiting on another task in the same project. Just reorder or wait.
   - `technical` — unknown, needs investigation. Assign someone to look.
   - `client` — needs a decision or info only the client has. **Routed to AM to ask.**
2. **Assess severity**:
   - `low` — not blocking current work
   - `medium` — blocking one task, workarounds exist
   - `high` — blocking multiple tasks or the critical path
   - `critical` — sprint cannot continue without resolution
3. **Log it** in `memory/factory/projects/<project-id>/sprint.md` under `## Blockers`
4. **Route**:
   - `internal` → no action, just log
   - `technical` → assign to the right specialist (Architect, Tech Lead, etc.) via `task`
   - `client` → dispatch to AM via `task account-manager` with: the question, the default action, the 24h timer
5. **Time-box the default action**: if the client doesn't respond in 24 hours, proceed with the default.

## Output

```
Blocker logged.

Project: plant-watering-2026-06
ID: BLOCKER-007
Description: <description>
Category: client
Severity: high
Routed to: account-manager (will ask client)
Default action if no response in 24h: <what you'll do>
Logged in: memory/factory/projects/<id>/sprint.md
```

## Examples

```
/factory-blocker plant-watering-2026-06 "User hasn't specified which 2 plants to use as the walking skeleton" --category client --severity high
/factory-blocker app-redesign "Auth provider decision blocks scaffolding" --category technical --severity high
/factory-blocker newsletter-2026-06 "Copy review waiting on legal" --category internal --severity low
```

## NEVER

- Hide a blocker to make the team look better
- Set severity lower than reality
- Skip the time-box (blockers grow if not bounded)
- Forget to update the sprint.md

## See also

- `/factory-status <project-id>` — get current state
- `/factory-kickoff` — start a new project
- `/factory-end` — sign off (Sprint 1F)