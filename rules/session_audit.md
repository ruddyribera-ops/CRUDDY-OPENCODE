# Session Audit Rule

## Requirement
Every answer and project output SHOULD include timestamp/date stamps to ensure sessions are auditable.

## Implementation

### Answers
- Include ISO 8601 timestamp at end of every response (when not automated)
- Format: YYYY-MM-DD HH:mm UTC (or local timezone)
- Example: 2026-05-10 14:30 UTC
- **Note:** This is handled automatically by session-title-guard.js plugin for session names.
  The coordinator adds timestamps to memory files (session.yaml, session_log.md) via uto-memory.ps1.
  Manual timestamp in responses is optional when infrastructure is active.

### Projects
- Include creation timestamp in project metadata
- Include last-modified timestamp in project files
- Log session start/end times in project audit log

## Rationale
- Traceable debugging across sessions
- Compliance with audit requirements
- Reproducible context for future reference

## Compliance Note
Timestamps in session state are maintained automatically:
- memory/session.yaml — updated on every task via uto-memory.ps1
- memory/session_log.md — appended on every task via ppend-session-log.ps1
- Session title — managed by session-title-guard.js plugin
