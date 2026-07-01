# Research Synthesis — OpenCode Local Setup

**Date:** 2026-05-09
**Scope:** 11 repos + 4 APILayer APIs researched via parallel sub-agents

## ✅ IMPLEMENTED (2026-05-11)

### Rich Persona Encoding (from agency-agents)
All 5 core agents enhanced with YAML frontmatter + persona sections:
- `agents/code-builder.md` — 🛠️ clean code architect
- `agents/bug-fixer.md` — 🔧 relentless investigator
- `agents/code-analyzer.md` — 🔍 systematic cartographer
- `agents/architecture-advisor.md` — 🏛️ principled权衡者
- `agents/main-coordinator.md` — 🎯 calm air traffic controller

Each now has: emoji, color, vibe, Identity & Memory, Critical Rules, Communication Style, Success Metrics.

### Onboarding Completeness Rule (from Agency-in-a-BOX)
`scripts/Init-Project.ps1` now validates ALL required files exist before declaring done.
If any file is missing → ERROR exit with list of missing files.

---

## Top Findings (Reference)

### Tier 1 — Implement Now

1. **cocoindex-code** — AST-based semantic code search, 70% token savings vs grep. MCP server. Self-hosted (local embeddings, SQLite). Complement to grep, not replacement.

2. **violit** — Python web framework, "Streamlit without reruns." Signal-based reactivity, built-in ORM/auth/background jobs, desktop native mode. Alpha but production-ready for internal tooling.

3. **@faker-js/faker** — Test data generation. 15.3k stars, 80 locales, seed reproducibility, mustache templates. Use for E2E fixtures, seed data, mock API responses.

4. **awesome-agent-skills ecosystem** — OpenCode format already compatible. Could adopt: references/ split pattern, scripts/ black-box helpers, evaluation QA pairs, contribution guidelines.

### Tier 2 — Medium Priority

5. **feynman (steveyeow)** — Multi-agent deliberation. 3-layer persona system, two-layer memory (global + per-user), RAG grounding, parallel responses with @mention targeting. Reference architecture only.

6. **public-apis contribution model** — One skill per PR, strict format, CI validation. Good pattern for community skill curation.

### Tier 3 — Reference Only

7. **tldraw** — Canvas/visual thinking (895 related repos, MIT)
8. **DevToys** — Tool aggregation patterns (140+ related repos)
9. **PDFCraft** — Privacy-first PDF ops (90+ browser tools)
10. **arc-kit** — UK Government enterprise architecture (63+ commands, not general-dev relevant)
11. **APILayer APIs** — screenshotlayer redundant (Playwright MCP), pdflayer redundant (write_pdf), serpstack free tier tight (100 req/mo)

## Full Report

See: `C:/Users/Windows/Desktop/research_synthesis_2026-05-09.md` (421 lines)

## New Skills to Create

| Skill | Trigger | Purpose |
|-------|---------|---------|
| `fake-data-generator` | "generate test data", "seed database", "mock responses" | Faker.js patterns for test fixtures |
| `ast-semantic-search` | "find where X is implemented", "search semantically" | Cocoindex integration |
| `violit-app-builder` | "build tool UI", "create dashboard" | Reactive Python web UIs |