# Rule: Automated Memory — No Reminders

**Enforced by:** all agents (coordinator + executors)  
**Trigger:** after EVERY task completion (specialist returns, or coordinator completes a sub-task)  
**User override:** "skip memory" or "no log" → skip only that session

---

## What Fires (Automatically — No User Prompt)

```
┌─────────────────────────────────────────────────────┐
│  after task completes                               │
│    │                                               │
│    ▼                                               │
│ auto-memory.ps1                                     │
│   ├── ① Log to session_log.md                      │
│   ├── ② Sprint stamp (if sprint context)           │
│   ├── ③ Touch project_active.md (mark fresh)       │
│   └── ④ Lesson entry if tokens > 1500              │
└─────────────────────────────────────────────────────┘
```

## Called By

- **Coordinator:** after specialist returns → `powershell .../auto-memory.ps1 -TaskName "..." -Agent "code-builder" -Result "..." -TokensEst "~N"`
- **code-builder:** after POA audit passes → same call
- **M3 agent:** in END-OF-TASK block → same call with sprint number

## Never Ask The User

> "Should I log this?" → NO. Log automatically.  
> "Want me to update memory?" → NO. Update automatically.  
> "Should I write to session_log?" → NO. Write automatically.

The ONLY exception: user says "skip memory" or "no log" in the same message as the task.

## Implementation

```powershell
# After every task:
powershell -File $CONFIG/scripts/auto-memory.ps1 -TaskName "<task>" -Agent "<agent>" -Result "<result>" -TokensEst "~N" -ProjectDir "<pwd>" -SprintNumber "1"

# Skip lesson write (light task):
powershell -File $CONFIG/scripts/auto-memory.ps1 -TaskName "<task>" -Agent "<agent>" -Result "<result>" -TokensEst "~N" -NoLesson
```

## Memory Files Updated Per Sprint

| Sprint | Files Updated |
|--------|--------------|
| S1 | session_log.md, sprint-1.md, project_active.md, MEMORY.md, lessons_learned.md |
| S2-S8 | Same pattern — auto-memory handles all |

## Why This Exists

The user said: "I don't want to be thinking about reminding out all the time."  
This rule makes memory management invisible — agents do it without being asked.

## Violation Detection

- Coordinator checks: did auto-memory.ps1 run after the last task? (logged in hook-errors.log)
- If missed: run it retroactively + log the miss