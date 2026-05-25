# [Project Name] — Agent Instructions

<!-- This file overrides/extends global AGENTS.md. Keep under 300 lines. -->

## 1. What This Project Is (READ FIRST)
<!-- The agent MUST understand this before doing anything -->
- **App:** [One sentence: what the app does, who it's for]
- **Services:** [What services make up the app? API, frontend, worker, etc.]
- **Dependencies:** [Key external services: Railway, Supabase, Vercel, etc.]
- **Critical context:** [Anything the agent would never guess: "Filesystem is ephemeral on Railway", "Seed data runs on startup", etc.]

## 2. Tech Stack
- **Language:** [Python 3.12, TypeScript, etc.]
- **Framework:** [Streamlit, FastAPI, React, etc.]
- **Database:** [PostgreSQL on Railway, SQLite local-only, etc.]
- **Deploy:** [Railway, Vercel, Docker, etc. — include URL if deployed]

## 3. Project Rules

**Do:**
- [Convention 1]
- [Convention 2]

**Don't:**
- [Constraint 1 — e.g., "Never use SQLite for production data"]
- [Constraint 2 — e.g., "Don't touch the legacy auth module"]

## 4. Known Issues
<!-- Documented bugs the agent should be aware of -->
- [Issue 1]: description and workaround
- [Issue 2]: description and workaround

## 5. Commands
- **Run:** [command to start dev server]
- **Test:** [command to run tests]
- **Lint:** [command to lint]
- **Build:** [command to build]
- **Deploy:** [command to deploy or push trigger]

## 6. Key Files
<!-- Point the agent to the right files immediately -->
- `src/main.py` — entry point
- `src/config.py` — configuration
- `src/auth.py` — authentication logic
