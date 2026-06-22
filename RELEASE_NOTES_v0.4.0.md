# v0.4.0 "Sigma" — Release Notes

**Date:** 2026-06-21
**Status:** Stable

## Summary

Phase 3 release completes the agent roster — all 21 documented agents are now implemented with canonical Handoff format, frontmatter schema, and resolved routing conflicts. This release marks 100% agent coverage.

## What's New

- **11 new agents implemented** — total 21 of 21 documented agents live
- **5 P1 agents:** code-explainer, code-reviewer, tech-writer, cybersecurity, architecture-advisor
- **3 P2 agents:** designer, support, project-generator
- **3 P3 agents:** skill-manager, standup-summary, evolution-agent
- **100% agent coverage achieved**
- **Canonical Handoff format** enforced across all 21 agents (`## Handoff` + `**I dispatch TO:**` + `**Routes TO me when:**`)
- **YAML parse errors fixed** in 3 P1 files (tech-writer, cybersecurity, architecture-advisor) — unquoted `when:` fields with colons
- **Trigger overlaps resolved** — `audit`, `explain`, `how does` now route cleanly
- **AGENTS.md cleanup** — duplicate intent rows removed, `review my pull request` trigger added for code-reviewer

## Migration Notes

No migration needed for end users. All 21 agents follow the canonical frontmatter schema and Handoff format. If you have custom agent definitions, ensure they use `## Handoff` with `**I dispatch TO:**` and `**Routes TO me when:**` subsections.

## Known Issues

- Line count drift observed in some agent files during QA verification — documented in audit reports
- Trigger overlaps between some agents are documented in AGENTS.md routing table (resolved, not removed)
- Evolution agent requires explicit activation — not yet running autonomously

## Roadmap: v0.5.0

- Skill ecosystem maturity — skill quality scoring and lifecycle management
- Evolution agent activation — autonomous self-improvement loop
- Observability hooks — logging and metrics for agent dispatch decisions
- Performance optimization — reduce context window bloat, faster skill loading

## Links

- [CHANGELOG.md](CHANGELOG.md)
- [AGENTS.md](AGENTS.md)
- Phase 3 Audit Reports:
  - [audits/v0.4.0/PHASE1-QA-ROUND1.md](audits/v0.4.0/PHASE1-QA-ROUND1.md)
  - [audits/v0.4.0/PHASE1-QA-FIXED.md](audits/v0.4.0/PHASE1-QA-FIXED.md)
  - [audits/v0.4.0/PHASE2-QA.md](audits/v0.4.0/PHASE2-QA.md)
  - [audits/v0.4.0/PHASE3-QA.md](audits/v0.4.0/PHASE3-QA.md)
