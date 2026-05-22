# Memory Index — Global Knowledge

**Purpose:** Lightweight file-based memory. No MCP server required. Agents read this at session start.

## How It Works

1. Each memory is a small `.md` file with frontmatter.
2. This index points to all memories with a one-line hook.
3. Agents read `MEMORY.md` first, then fetch specific files only when relevant.
4. Projects can have their own local `.opencode/memory/MEMORY.md` that extends this one.

## Types

- `user_*.md` — who the user is, preferences, language, workflow
- `feedback_*.md` — rules learned ("always X", "never Y") + why + how to apply
- `project_*.md` — facts about active projects (deadlines, architecture, stakeholders)
- `reference_*.md` — pointers to external resources (URLs, IDs, channels)

## Active Memories

- [Windows shell gotchas](feedback_windows_shell.md) — bash-on-Windows: `;` not `&&`, forward slashes, heredocs, CRLF/LF diff trap, PowerShell interop
- [User preferences](user_preferences.template.md) — edit this file with your details if not using USER.md
- [Reference links](reference_links.md) — live URLs, library docs, external resources
- [Lessons learned](lessons_learned.md) — self-improvement log; key decisions, failures, and session lessons
- [Background servers in PowerShell](feedback_background_servers.md) — Start-Process with -RedirectStandardOutput NUL -RedirectStandardError NUL
- [Debug hypothesis discipline](feedback_debug_hypothesis.md) — inspect body + headers to locate which layer returned a 4xx/5xx
- [E2E waits on cold-start](feedback_e2e_waits.md) — prefer wait_for_selector over fixed timeouts

## Rules for Writing Memory

1. **Keep it short.** Each file should fit on one screen.
2. **State the rule first**, then `**Why:**` and `**How to apply:**` for feedback/project types.
3. **Update or delete** stale memories — don't let them pile up.
4. **Project-local memory wins** over global when both apply.
