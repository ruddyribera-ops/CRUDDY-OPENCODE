# Memory Index — Global Knowledge

**Purpose:** Lightweight file-based memory. No MCP server required. Agents read this at session start.

## How It Works

1. Each memory is a small `.md` file.
2. This index points to all memories with a one-line hook.
3. Agents read `MEMORY.md` first, then fetch specific files only when relevant.
4. Projects can have their own local `.opencode/memory/MEMORY.md` that extends this one.

## Types

- `user_*.md` — who the user is, preferences, language, workflow
- `feedback_*.md` — rules learned ("always X", "never Y") + why + how to apply
- `project_active.md` — **single source of truth for ALL active projects** (tech stack, deploy, issues)
- `reference_*.md` — pointers to external resources (URLs, IDs, channels)

## Active Memories

- `project_active.md` — ALL 7 active projects: PRIA v10 (complete), Palma Coin, Math Platform, EduFlow, BDM App, OpenCode Setup, PC Optimizer
- `user_preferences.md` — edit this file with your details
- `feedback_windows_shell.md` — bash-on-Windows: `;` not `&&`, forward slashes, CRLF/LF, PowerShell interop
- `feedback_background_servers.md` — Start-Process for background servers
- `feedback_debug_hypothesis.md` — inspect body + headers to locate which layer returned a 4xx/5xx
- `feedback_e2e_waits.md` — prefer wait_for_selector over fixed timeouts
- `feedback_playwright_eaccess.md` — Windows Defender blocks browser spawn
- `feedback_palma_lessons.md` — Railway ephemeral fs, WS proxy, PG migration patterns
- `lessons_learned.md` — self-improvement log; key decisions, failures, and session lessons
- `reference_links.md` — live URLs, GitHub, Railway, library docs

## 🚨 Session Triggers (MANDATORY — Load & Follow)

**File:** `TRIGGERS.md` — session lifecycle protocol (T1-T8).

**Must follow at every:**
- Session start → T1 (load handover, create session state, create KG entity)
- Task completion → T2 (append log, update yaml, 3-question check)
- Lesson discovered → T5 (write file + KG + notify)
- Decision made → T6 (append yaml + KG)
- State change → T7 (update project_active + KG + notify)
- Session end → T3 (write handover, archive, stamp sprint, finalize KG)
- Status query → T4 (aggregate and display)

**Scripts:**
- `scripts/append-session-log.ps1` — append task entry to session_log.md
- `scripts/update-session-yaml.ps1` — update session.yaml fields
- `scripts/write-handover.ps1` — generate handover/latest.md from session.yaml

---

## Rules for Writing Memory

1. **Keep it short.** Each file should fit on one screen.
2. **State the rule first**, then `**Why:**` and `**How to apply:**`.
3. **Update or delete** stale memories — don't let them pile up.
4. **Project data goes into `project_active.md` ONLY.** Do NOT create separate `project_<name>.md` files.
5. **Never log API keys, tokens, or real secrets in any memory file.**
6. **Update `project_active.md` after EVERY session that changes project state.**

## Active Projects (Quick Reference)

| # | Project | Stack | Status |
|---|---------|-------|--------|
| 1 | PRIA v10 | React+Vite+MiniMax+PptxGenJS | ✅ Complete |
| 2 | Palma Coin | Node+React+SSE+better-sqlite3 | ✅ Complete — all bugs fixed, 27 tests, Docker verified |
| 3 | Math Platform | FastAPI+Next.js+Redis | 🔵 In progress — code fragments, no coherent project |
| 4 | EduFlow | Laravel+Next.js+PostgreSQL | 🔵 Active |
| 5 | BDM App | Vite+React+Express+Gemini | ✅ Phase A-F |
| 6 | OpenCode Setup | Markdown+Python+PowerShell | 🔵 Active |
| 7 | PC Optimizer | FastAPI+HTML | 🟡 Simulated |
