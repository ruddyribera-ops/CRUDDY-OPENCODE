# Session Audit Rule

## Requirement
Every answer and project output MUST include timestamp/date stamps to ensure sessions are auditable.

## Implementation

### Answers
- Include ISO 8601 timestamp at end of every response
- Format: `YYYY-MM-DD HH:mm UTC` (or local timezone)
- Example: `2026-05-10 14:30 UTC`

### Projects
- Include creation timestamp in project metadata
- Include last-modified timestamp in project files
- Log session start/end times in project audit log

## Rationale
- Traceable debugging across sessions
- Compliance with audit requirements
- Reproducible context for future reference