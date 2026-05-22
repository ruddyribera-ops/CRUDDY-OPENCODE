# Project Scaffold — 120x-Style Folder Template

**For new projects.** Created by project-generator when user says "new project" or "build an app."
Based on 120x.ai's architect-builder file structure.

---

## Folder Structure

```
project-name/
│
│   # ── Entry Points ──────────────────────────
├── AGENTS.md              # Main router — first file every agent reads
├── README.md              # Human overview
├── CLAUDE.md              # Claude Code / Codex adapter (thin, not the brain)
│
│   # ── Documentation ─────────────────────────
├── docs/
│   ├── architecture.md    # System map — major parts and how they fit
│   ├── data-model.md      # Core entities, fields, relationships
│   ├── api.md             # Endpoints, contracts, inputs/outputs
│   ├── permissions.md     # Roles, access rules
│   └── validation.md      # How we prove the system is correct
│
│   # ── Planning ──────────────────────────────
├── planning/
│   ├── state.md           # Current moment: sprint, what happened, what's next
│   ├── decisions.md       # Decisions made (don't relitigate)
│   ├── domain.md          # Business: terminology, workflows, users, rules
│   ├── risks.md           # Known traps, fragile assumptions
│   ├── questions.md       # Open questions for stakeholder
│   ├── meetings/          # Meeting notes and transcripts
│   │   └── YYYY-MM-DD_topic.md
│   └── sprints/
│       ├── sprint-001/
│       │   ├── requirements.md
│       │   ├── blueprint.md
│       │   ├── acceptance.md
│       │   ├── risks.md
│       │   └── handoff.md
│       └── sprint-002/    # (same structure)
│
│   # ── Source Code ───────────────────────────
├── src/
│   ├── assets/            # Static files
│   ├── lib/               # Shared utilities
│   ├── tests/             # Test files
│   └── main.py            # Entry point
│
│   # ── Reference Materials ───────────────────
├── references/
│   ├── file-inventory.md  # Source materials: PDFs, spreadsheets, exports
│   └── samples/           # Sample data files
│
│   # ── Configuration ─────────────────────────
├── .env.example           # Environment variables (no secrets)
├── .gitignore
├── requirements.txt       # Python dependencies
├── package.json           # Node dependencies
└── docker-compose.yml     # (optional)
```

---

## Key Files Explained

### AGENTS.md
The main router. Every AI agent (Claude Code, Codex, etc.) reads this first.
It tells them:
- What this project is
- Where to find documentation
- What rules to follow
- What workflow to use

### CLAUDE.md
A thin adapter file. In Claude Code, this file gives basic context. 
It should NOT contain the entire project brain — just enough to route to the right docs.

### planning/state.md
The most important file. Updated after every sprint:
- Current sprint
- What was just completed
- What's next
- What's blocked

### planning/decisions.md
Append-only decision log. Every architectural or business decision goes here.
Format:
```
YYYY-MM-DD: Decision — {what was decided} — {why}
```

### planning/sprints/sprint-NNN/
Each sprint gets an Architect Pack (see `workflows/architect-pack-template.md`):
- requirements.md — WHAT we're building
- blueprint.md — HOW we build it
- acceptance.md — What "done" means
- risks.md — What could go wrong
- handoff.md — The prompt to give the builder

---

## Workflow

```
1. USER: "I need a system that does X"
2. ARCHITECT (ChatGPT/Claude Chat):
   → Asks discovery questions
   → Produces Architect Pack for each sprint
   → Files go into planning/sprints/sprint-001/

3. BUILDER (Codex/Claude Code):
   → Reads architect pack
   → Implements
   → Writes code to src/
   → Updates planning/state.md

4. REVIEW:
   → Tell architect: "Here's what was built"
   → Architect reviews against requirements
   → If issues → adjust plan, re-run
   → If clean → next sprint
```
