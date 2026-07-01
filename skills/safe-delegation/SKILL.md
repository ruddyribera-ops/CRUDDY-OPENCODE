---
name: safe-delegation
description: "Pre-flight check pattern for sub-agents receiving delegations. Forces verification of file paths, tool names, and preconditions BEFORE acting. Prevents the 4 most common delegation failure modes: file creation in non-existent dirs, references to non-existent tools/skills, reads/edits of non-existent files, and unmanaged server lifecycle. Use when: you are a sub-agent receiving a task() dispatch, when the dispatcher's handoff references files/tools/servers, when you need to verify preconditions before acting."
triggers:
  - sub-agent receiving delegation
  - task() dispatch received
  - handoff with file paths
  - handoff with server commands
applies_to:
  - code-builder
  - bug-fixer
  - code-analyzer
  - code-reviewer
  - expert-tester
  - delivery-engineer
  - tech-writer
  - all specialist agents
---

# Safe Delegation — Pre-Flight Check Pattern

## When to use this

Load this skill when:

- You are a sub-agent receiving a `task()` dispatch from main-coordinator (or another dispatcher)
- The dispatcher's handoff references specific file paths, tools, or server commands
- You need to verify preconditions before taking action
- The dispatcher says "verify" or "check" or "make sure" anywhere in the handoff

Do NOT use this skill when:

- You're the main-coordinator (not a sub-agent)
- The handoff is vague enough that verification is impossible (refuse and request clarification instead — see "Forbidden patterns" below)
- The handoff is purely informational (no action required)

## The 4 Pre-Flight Checks

Before taking ANY action on a delegation, run these 4 checks. If any fails, report BLOCKED and STOP.

### Check 1: Verify file paths exist

```bash
# For each file path mentioned in the handoff:
Test-Path "C:\path\to\file" -PathType Leaf  # file
Test-Path "C:\path\to\dir" -PathType Container  # directory
```

If a file path is mentioned but doesn't exist:
- **If the handoff says "create it"**: verify the parent directory exists, then create the file
- **If the handoff says "read" or "edit"**: STOP. Report BLOCKED with the missing path. Do NOT create the file.

### Check 2: Verify tool/skill names exist

```bash
# Check the skill exists in SKILLS_INDEX.json
Test-Path "C:\Users\Windows\.config\opencode\skills\<name>\SKILL.md"

# Check the agent exists in AGENTS.md routing table
Select-String -Path "AGENTS.md" -Pattern "<agent-name>"
```

If a tool or skill is referenced that doesn't exist:
- STOP. Report BLOCKED with the missing name.
- Do NOT attempt to invoke a non-existent tool.

### Check 3: Verify file readability/editable state

```bash
# If reading:
Get-Content "path\to\file" -ErrorAction Stop

# If editing, check it's not locked or read-only:
Get-Item "path\to\file" | Select-Object IsReadOnly, LastWriteTime
```

If the file is locked, read-only when it shouldn't be, or otherwise inaccessible:
- Report BLOCKED with the specific issue.
- Do NOT retry blindly.

### Check 4: Verify server lifecycle (if applicable)

```bash
# Check if server is already running on the expected port:
Test-NetConnection -ComputerName localhost -Port <port> -InformationLevel Quiet

# Check if process is already running:
Get-Process -Name "<server-name>" -ErrorAction SilentlyContinue
```

If server work is involved:
- **Already running?**: Report state, don't try to start a second one.
- **Port conflict?**: Report BLOCKED.
- **Need to start?**: Document the start command, expected port, stop command.
- **Need to kill?**: Use graceful shutdown first, force-kill only as last resort.

## Refusing a Bad Handoff

If the dispatcher's handoff is too vague to act on, REFUSE the delegation. Output:

```json
{
  "status": "BLOCKED",
  "reason": "vague_handoff",
  "missing": [
    "specific file path (currently says 'the auth file')",
    "output format (no JSON structure specified)",
    "tools to use (no specific tools named)"
  ],
  "next_action": "main-coordinator to re-dispatch with complete 4-element handoff"
}
```

Do NOT guess. Do NOT proceed with assumptions. A refused delegation is better than a stalled one.

## What This Prevents

| Failure mode | Pre-flight check that catches it |
|---|---|
| File in non-existent dir | Check 1: Test-Path parent directory before Write |
| Non-existent tool/skill | Check 2: Test-Path skill file or grep AGENTS.md |
| Non-existent file read/edit | Check 3: Test-Path before Read/Edit |
| Server start/kill issues | Check 4: Test-NetConnection + Get-Process |

## Cross-References

- `rules/agent-handoff-contract.md` — the dispatcher's contract
- `agents/main-coordinator.md` — the dispatcher that uses this contract
- `rules/spec-validation.md` — sibling contract (different domain, same structure)

---

## Status

**APPROVED — 2026-06-30.** Adopted as part of delegation enforcement sprint.
