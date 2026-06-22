# v0.3.0 "Omega" — Release Notes

**Date:** 2026-06-21
**Version:** v0.3.0 "Omega"

## Summary

v0.3.0 marks the first major agent implementation milestone for CRUDDY-OPENCODE. Ten of twenty-one documented agents are now live in the `agents/` folder, with canonical frontmatter schemas, standardized handoff sections, and resolved routing conflicts across all dispatch tables.

## What's New

- **10 of 21 agents implemented** in `agents/` folder (code-builder, bug-fixer, main-coordinator, code-analyzer, project-manager, solutions-architect, tech-lead, delivery-engineer, qa-engineer, account-manager)
- **4 P0 agents created**: code-builder, bug-fixer, main-coordinator, code-analyzer
- **5 skills migrated to agents/**: project-manager, solutions-architect, tech-lead, delivery-engineer, qa-engineer
- **Canonical frontmatter schema** enforced: name, description, when, do_not, triggers, forbidden_triggers
- **Standardized Handoff section**: `## Handoff` with `I dispatch TO` + `Routes TO me when` format
- **Dual-Schema Convention** established in `rules/common.md §3.1` for agents/ vs skills/
- **Routing conflicts resolved**: AGENTS.md routing table updated with "Landing page design" intent → designer
- **4 audit reports generated**: Phase 1 QA, Phase 1 Verify, Phase 2 QA Round 1, Phase 2 QA Fixed

## Migration Notes

This release introduces a canonical frontmatter schema for all agent files. Existing agent files should be updated to include: `name`, `description`, `when`, `do_not`, `triggers`, and `forbidden_triggers` fields. The `rules/common.md §3` trigger format rule has been amended to allow lowercase alphanumeric characters, spaces, and underscores.

## Known Issues

1. **code-analyzer.md forbidden_triggers**: Contains cosmetic blank lines in the frontmatter that render awkwardly in some tools
2. **standup-summary agent**: Referenced in AGENTS.md routing table but not yet implemented as a standalone agent file

## Roadmap

**v0.4.0** will implement the remaining 11 agents:
- code-explainer, code-reviewer, tech-writer, cybersecurity, architecture-advisor, designer, support, project-generator, skill-manager, standup-summary, evolution-agent

## Links

- [Phase 1 QA Report](audits/v0.3.0/PHASE1-QA.md)
- [Phase 1 Verify Report](audits/v0.3.0/PHASE1-VERIFY.md)
- [Phase 2 QA Round 1](audits/v0.3.0/PHASE2-QA-ROUND1.md)
- [Phase 2 QA Fixed](audits/v0.3.0/PHASE2-QA-FIXED.md)
- [Changelog](CHANGELOG.md)