---
description: Get current status of a factory project. Hill chart position, task counts, today's focus, blockers, next milestone. Run by the AM to populate the daily digest, or by anyone on the team for a quick check-in.
usage: /factory-status [project-id] [--detailed] [--format digest|full]
---

# /factory-status — Project status snapshot

Returns the current state of a project. Optimized for the daily 9am digest format.

## What you get

For any project-id, returns:

```
Project: <name>
Status: <in-progress | delivered | blocked | ...>
Hill: <climbing | top | downhill>
Tasks: <done>/<total>  (<in-progress> in progress, <blocked> blocked)
Today's focus: <1 line>
Blockers: <count> — <top blocker if any>
Next demo: <date>
Days to demo: <N>
```

## Flags

- `--detailed` — show all tasks, all blockers, all risks
- `--format digest` — output the daily 9am digest format (for AM to relay)
- `--format full` — verbose, with every task and every risk

## What to do with the result

- If Hill is "climbing" for too long → flag to the AM, something might be stuck
- If "blocked" count > 0 → check if the blocker is client-side. If so, the AM needs to escalate.
- If "next demo" is <2 days away and tasks done < 50% → ask the team to scope down (Shape Up: fixed time, variable scope)

## How it works

1. Reads `memory/factory/projects/<project-id>/sprint.md`
2. Parses the task list, blocker list, Hill position
3. Formats per the output spec
4. Returns as JSON or plain text depending on flag

## Edge cases

- **Project doesn't exist** → return `{ok: false, error: "project not found"}` and suggest `/factory-kickoff` to start one
- **sprint.md missing** → return `{ok: false, error: "sprint not planned yet — PM needs to run"}` and dispatch to PM
- **Project is delivered** → return the sign-off summary instead of sprint state

## See also

- `/factory-blocker <project-id> <description>` — add a blocker
- `/factory-kickoff "<idea>"` — start a new project
- `/factory-end <project-id>` — sign off (Sprint 1F)