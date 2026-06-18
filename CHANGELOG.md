# Changelog

All notable changes to CRUDDY-OPENCODE are documented here.

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