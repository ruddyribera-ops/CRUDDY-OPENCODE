---
name: agent-handoff-contract
description: Contract for agent-to-agent delegation. Both the dispatcher (coordinator) and the receiver (specialist) honor this contract. Mandates a 4-element handoff structure (objective, output format, tools and source, return path) and a pre-flight check pattern that prevents the 4 most common delegation failure modes: (1) file creation in non-existent directories, (2) tool/skill references to non-existent names, (3) read/edit of non-existent files, (4) start/kill of unmanaged servers.
applies_to: main-coordinator (dispatcher), all specialist agents (receivers)
triggers: any task() dispatch, any sub-agent invocation
---

# Agent Handoff Contract

## Purpose

Per the GitHub Copilot CLI engineering post (Jun 12, 2026), subagent delegation has 4 most common failure modes:
1. **Stale file paths** — agent tries to read/edit a file that doesn't exist
2. **Moved files** — agent uses a path that was valid in a previous context
3. **Incorrect relative paths** — agent's working directory differs from dispatcher's
4. **Workspace mismatches** — agent doesn't know what repo/branch it's in

These are not solved by making the subagent smarter. They are solved by the **dispatcher providing better handoff context**.

## The 4-Element Handoff Structure

Every delegation MUST include all 4 elements. If any is missing, the receiving agent should refuse and request the missing information.

### 1. Objective
What the user asked + what the sub-agent owns. Be specific about scope.

GOOD: "Update the user authentication in `src/auth/jwt.py` to support refresh tokens, including tests in `tests/auth/`. The current implementation uses HS256; switch to RS256 with a 24h access token / 7d refresh token split."

BAD: "Fix the auth thing" or "Update auth to be more secure"

### 2. Output Format
What the receiving agent should return. Be explicit about structure, fields, success criteria.

GOOD: "Return JSON with: {file_changes: [{path, before, after, diff_stats}], test_results: {pass, fail, skipped, coverage_pct}, blockers: [], verified: bool}"

BAD: "Just let me know when done" or "Tell me what you did"

### 3. Tools and Source
What the agent should use. List specific tools, file paths, and verification steps. If the agent must verify preconditions, say so explicitly.

GOOD: "Use the Read tool to verify `src/auth/jwt.py` exists before editing. If the file doesn't exist, report BLOCKED and do not create it. Run `pytest tests/auth/ -v` to verify. The working directory is `<repo-root>` — use absolute paths."

BAD: "Just fix the file" or "Use the standard tools"

### 4. Return Path
What to do if the work can't be completed as specified. Define escalation, abort, or partial completion.

GOOD: "If you encounter a blocker (e.g., dependency conflict, missing file, unclear spec), report it in the return JSON and STOP. Do not proceed with partial implementation."

BAD: (no return path specified — the subagent will either guess or stall)

## Pre-Flight Check Pattern (Sub-Agent Obligation)

When receiving a delegation, the sub-agent MUST verify these preconditions BEFORE acting:

### File Operations
- **Read/Edit target exists**: Use `Test-Path` or `Read` tool before `Edit` or `Write`. If missing, report BLOCKED.
- **Directory exists for new file**: Use `Test-Path` for the parent directory. If missing, create with `New-Item -ItemType Directory -Force` OR report BLOCKED if the user didn't authorize creation.
- **Path is absolute or working-directory-correct**: Confirm the working directory before assuming relative paths.

### Tool/Skill Operations
- **Tool/skill exists**: Check `~/.config/opencode/skills/<name>/SKILL.md` or `AGENTS.md` routing table before referencing. If missing, report BLOCKED.

### Server Operations
- **Server already running?**: Check before starting (use `Get-Process` or port check).
- **Kill cleanly**: Use graceful shutdown (Ctrl+C / SIGTERM) before force-kill.
- **Port conflicts**: Check port availability with `Test-NetConnection` before starting.
- **Document lifecycle**: Report server start/stop events to the dispatcher.

## Forbidden Delegation Patterns

These patterns in the dispatcher's handoff MUST be refused by the sub-agent:

- "Use the same approach as before" — too vague; specify which approach
- "Look around the codebase" — too broad; specify which files/area
- "Fix it" — too vague; specify what's broken
- "Use the standard tools" — too vague; specify which tools
- "Like X but for Y" — analogy without specifics; describe X and Y
- References to skill/tool names that don't exist in SKILLS_INDEX.json or AGENTS.md
- References to file paths that haven't been verified to exist
- Server commands without lifecycle handling

## What This Prevents

| Failure mode | How this contract helps |
|---|---|
| Sub-agent creates file in non-existent dir | Pre-flight check requires verifying parent dir first |
| Sub-agent uses non-existent tool/skill | Pre-flight check requires verification of SKILLS_INDEX |
| Sub-agent reads/edits non-existent file | Pre-flight check requires Test-Path before Read/Edit |
| Sub-agent manages server badly | Pre-flight check requires lifecycle documentation |

## Cross-References

- `agents/main-coordinator.md` — dispatcher side; uses this contract
- `skills/safe-delegation/SKILL.md` — receiver side; verifies pre-flight
- `rules/spec-validation.md` — sibling contract (different domain, same structure)
- `rules/loop-operator-safety.md` — sibling contract
- `AGENTS.md` — references this in Safety Contracts section

---

## Status

**APPROVED — 2026-06-30.** Adopted as part of delegation enforcement sprint.
