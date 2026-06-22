# Changelog

All notable changes to CRUDDY-OPENCODE are documented here.

## [v0.4.0] - 2026-06-21 — "Sigma"

### Added
- 11 new agents implemented, total 21 of 21 documented agents live
- 5 P1 agents: code-explainer, code-reviewer, tech-writer, cybersecurity, architecture-advisor
- 3 P2 agents: designer, support, project-generator
- 3 P3 agents: skill-manager, standup-summary, evolution-agent
- 100% agent coverage achieved

### Changed
- AGENTS.md routing table: removed duplicate intent rows (tech-writer, designer, cybersecurity)
- AGENTS.md routing table: added `review my pull request` trigger for code-reviewer
- agents/architecture-advisor.md: missing Handoff subsections added
- agents/cybersecurity.md: forbidden_triggers converted from string to YAML list
- All 21 agents now use canonical Handoff format (## Handoff + **I dispatch TO:** + **Routes TO me when:**)

### Fixed
- agents/evolution-agent.md: Handoff subsections reordered (was reversed); code-builder typo corrected to code-analyzer
- agents/architecture-advisor.md: was missing both Handoff subsections
- Trigger overlaps resolved: `audit` (code-analyzer → `code audit`), `explain` (tech-writer removed, code-explainer kept), `how does` (removed from code-analyzer)
- YAML parse errors fixed: 3 P1 files (tech-writer, cybersecurity, architecture-advisor) had unquoted `when:` field with colons

### Audit reports
- audits/v0.4.0/PHASE1-QA-ROUND1.md
- audits/v0.4.0/PHASE1-QA-FIXED.md
- audits/v0.4.0/PHASE2-QA.md
- audits/v0.4.0/PHASE3-QA.md

### Roadmap
- v0.5.0: skill ecosystem maturity, evolution agent activation, observability hooks, performance optimization

## [v0.3.0] - 2026-06-21 — "Omega"

### Added
- 10 of 21 documented agents now implemented in agents/ folder
- 4 P0 agents created: code-builder, bug-fixer, main-coordinator, code-analyzer
- 5 skills migrated to agents/ (project-manager, solutions-architect, tech-lead, delivery-engineer, qa-engineer)
- Canonical frontmatter schema enforced: name, description, when, do_not, triggers, forbidden_triggers
- Handoff section standard: ## Handoff with I dispatch TO + Routes TO me when
- rules/common.md §3.1 Dual-Schema Convention (agents/ vs skills/)
- AGENTS.md: new "Landing page design" intent routes to designer

### Changed
- rules/common.md §3: trigger format rule amended (lowercase + [a-z0-9 _-], spaces allowed)
- rules/common.md line 5: applies_to count fixed (was inaccurate)
- AGENTS.md routing table: status and design routing conflicts resolved

### Fixed
- account-manager.md: added missing ## Handoff section
- project-manager.md, tech-lead.md: deduplicated triggers
- qa-engineer.md: removed bare "bug" trigger
- delivery-engineer.md: YAML parse error in description
- Multiple routing conflicts between AM dispatch table and AGENTS.md

### Audit reports
- audits/v0.3.0/PHASE1-QA.md
- audits/v0.3.0/PHASE1-VERIFY.md
- audits/v0.3.0/PHASE2-QA-ROUND1.md
- audits/v0.3.0/PHASE2-QA-FIXED.md

### Roadmap
- v0.4.0: implement remaining 11 agents (code-explainer, code-reviewer, tech-writer, cybersecurity, architecture-advisor, designer, support, project-generator, skill-manager, standup-summary, evolution-agent)

## [0.1.0] - 2026-06-18

### Added
- Autoresearch skill: Karpathy's pattern applied to config self-improvement (modify → evaluate → keep/revert → repeat)
- Hybrid memory retrieval layer: BM25 + vector + graph (all-MiniLM-L6-v2 + SQLite FTS5 + NetworkX) — 100% local, $0 cost
- Pre-flight snapshot tools: PowerShell + Python, mandatory before batch file ops
- Hook integration: JS plugin (`session-start-memory.js`) with 90s forced-idle fallback
- Scheduled tasks: nightly autoresearch + on-logon memory watcher (Windows Task Scheduler)
- Incident-aware safety rule: `batch-file-modification-safety.md` (born from 2026-06-17 PDC destruction)
- Consolidated structure: all system code under `factory/` single directory
- Skills catalog: 9 curated skills from open-source ecosystem (awesome-investigate, awesome-office-hours, awesome-ask-questions-if-underspecified, awesome-webapp-testing, awesome-differential-review, superpowers-writing-skills, superpowers-systematic-debugging, superpowers-test-driven-development, superpowers-subagent-driven-development)
- codebase-memory MCP server integration (DeusData/codebase-memory-mcp 0.8.1)

### Design Principles
- **Safety-first**: pre-flight snapshot + incident-aware rules + permission gates
- **Self-improving**: overnight autoresearch loop with keep/revert ratchet
- **Local-first**: 100% on-device, no external API required for core features
- **Single source of truth**: all system code under `factory/`
- **Verified at every layer**: tier-1 evidence required for every change

### Known Limitations
- Windows-only (designed for Windows 11; WSL2 untested)
- No public benchmark yet — v0.2.0 will add autoresearch effectiveness benchmark
- Documentation is functional, not polished — README + factory/README + this CHANGELOG are the entry points

## [0.1.1] - 2026-06-18

### Added
- **Origin Story** section crediting [opencode-power-setup](https://github.com/ruddyribera-ops/opencode-power-setup) as the predecessor
- **Agents on Deck** — documented all 21 agents (was previously listed as ~10)
- **Skills Catalog** — corrected count to 54 active + 29 archived (was previously listed as 9 curated)
- **MCP Servers** — listed all 5 (was previously listed as 2)
- **Plugins** — corrected count to 12 (was previously listed as 10)
- **By the Numbers** table

### Fixed
- Removed `git-init.ps1` from public repo (contained PII; was internal agent script)

## [0.1.2] - 2026-06-19

### Fixed
- Removed remaining PII from repo (env-var references, user paths, git history scrubbed)
- Corrected rule count from 1 to 3 (added `account-manager-discipline.md` and `sprint-methodology.md`)

## [0.2.0] - 2026-06-21

### Added
- **`rules/common.md`** — Cross-cutting rules for all agents (tool-call budget, banned phrases, frontmatter template, handoff format, forbidden action enforcement)
- **`SYSTEM_FLOW.md`** — One-page master agent interaction graph showing the complete dispatch chain (AM → PM → Architect → Tech Lead → Specialists)
- **Improved `agents/account-manager.md`** with 5 specific improvements:
  1. Post-Mortem Reference section (cites the 4 incident rules)
  2. Client Memory protocol (cross-session preference/context/history)
  3. Re-Dispatch & Feedback Loop (re-dispatch when specialist returns "unknown")
  4. Quantitative Discovery Stop Criteria (replaces qualitative stop signals)
  5. Relationship to main-coordinator (clear delineation of roles)
- **`rules/sprint-methodology.md`** — 5 rules for sprint execution (encoded 2026-06-20, included in this release)

### Fixed
- **`factory/scripts/autoresearch/iterate.py`** — replaced `Path.home()` (broken under SYSTEM context) with `Path(__file__).parent`. Scheduled task was failing for 3 days because of this. Now the nightly autoresearch loop actually runs.

### Library state
- Rules: 4 (3 incident-derived + 1 cross-cutting)
- Self-improving: each new incident → new rule
- See `SYSTEM_FLOW.md` for the full system reference