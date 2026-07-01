# Health Check Report — CRUDDY-OPENCODE

**Generated:** 2026-07-01
**Last major change:** Config Hardening Sprint (ECC adoption, OpenMythos patterns, CI functional, path portability Stage 4) + Delegation enforcement sprint + Audit fixup sprint

---

## Overall Status: HEALTHY

---

## Recent Changes (since last report 2026-06-24)

### Delegation Enforcement Sprint
- Created `rules/agent-handoff-contract.md` — defines 4-element handoff structure and pre-flight check pattern
- Created `skills/safe-delegation/SKILL.md` — forces verification of file paths, tool names, and preconditions before sub-agents act

### Audit Fixup Sprint — 5 New Safety Contracts
All APPROVED and now referenced in AGENTS.md:
- `rules/spec-validation.md` — prevents hallucinated-consensus in brownfield spec extraction (spec-miner → architecture-advisor validation chain)
- `rules/loop-operator-safety.md` — mandates 4 rails: max_iterations, cost_ceiling, no_progress_detector, human_escalation (prevents $380–$47K real incidents)
- `rules/session-start-contract.md` — defines valid FSM states (ABSENT → PENDING → STARTING → ACTIVE → IDLE → ENDED/FAILED), prevents half-started sessions
- `rules/cass-index-contract.md` — required entry fields, producer/consumer obligations, failure recovery for session search index
- `rules/hook-system-contract.md` — each of 12 plugins must fail independently without cascading, specifies failure isolation + fallback
- `rules/t2-protocol-contract.md` — each of 8 T2 steps must have explicit fallback on failure, replaces silent `$null` redirects with logged degradation
- `rules/agent-handoff-contract.md` — 4-element handoff structure, pre-flight check pattern (file/dir/tool/existence), prevents 4 most common delegation failures

### CI Setup
- Added `.github/workflows/ci.yml` with Linux Node + Windows PowerShell matrix

### Validator Rewrite
- Replaced broken `validate-skills.ts` with tiered YAML validation (FAIL/WARN/INFO tiers)

### Documentation Fix
- Rewrote `README.md` — removed false DEPRECATED banner, expanded from 37 to 159 lines

### P1 Bug Fixes (all resolved)
- Fixed opencode.json URL comment-stripper bug
- Fixed `check-rules.py` exit code regression
- Restored `SPECIALIZED_AGENTS.md` reference (was renamed/missing)

### Plugin Count Update
- Grew from 10 → **11 plugins** — added `main-coordinator-tracing.js`

---

## Agent Registry (26 agents)

All agents exist as `.md` + `.yaml` pairs in `agents/`:

| # | Agent | File |
|---|-------|------|
| 1 | account-manager | ✅ |
| 2 | ai-evaluator | ✅ |
| 3 | architecture-advisor | ✅ |
| 4 | bug-fixer | ✅ |
| 5 | code-analyzer | ✅ |
| 6 | code-builder | ✅ |
| 7 | code-explainer | ✅ |
| 8 | code-reviewer | ✅ |
| 9 | cybersecurity | ✅ |
| 10 | delivery-engineer | ✅ |
| 11 | designer | ✅ |
| 12 | evolution-agent | ✅ |
| 13 | expert-tester | ✅ |
| 14 | loop-operator | ✅ |
| 15 | main-coordinator | ✅ |
| 16 | observability-sre | ✅ |
| 17 | project-generator | ✅ |
| 18 | project-manager | ✅ |
| 19 | qa-engineer | ✅ |
| 20 | skill-manager | ✅ |
| 21 | solutions-architect | ✅ |
| 22 | spec-miner | ✅ |
| 23 | standup-summary | ✅ |
| 24 | support | ✅ |
| 25 | tech-lead | ✅ |
| 26 | tech-writer | ✅ |

Plus:
- `SPECIALIZED_AGENTS.md` — reference doc (not an agent)
- `agent-schema.yaml` — schema definition (not an agent)

---

## Skills Registry (38 skills)

| Category | Skills |
|----------|--------|
| **Languages/Frameworks** | android-native-dev, api-patterns, flutter-dev, ios-application-dev, js-modern-patterns, python-patterns, react-native-dev |
| **Methodology** | awesome-ask-questions-if-underspecified, awesome-investigate, awesome-office-hours, codemap, cs-fundamentals, database-patterns, deployment-patterns, investigation, karpathy-guidelines, performance-optimization, systematic-debugging, testing-and-debugging, tracing, webapp-testing |
| **Security** | authmd-registration, differential-review, secure-coding, security-basics, sql-safety |
| **Observability/Cost** | cost-tracking, evaluation, production-readiness |
| **Delegation** | safe-delegation, superpowers-subagent-driven-development, superpowers-writing-skills |
| **AI/Specialized** | autoresearch, ocr-tools, review-loop, ui-design, no-silent-failure |
| **Config/OpenCode** | customize-opencode |

---

## Plugins (11 hooks — all CI-wired)

| Plugin | Purpose |
|--------|---------|
| memory-bridge | Session memory persistence |
| gate-system | Depth/cost gate enforcement |
| pre-tool-guard | Pre-tool invocation guard |
| post-tool-guard | Post-tool invocation guard |
| sub-agent-guard | Sub-agent call guard |
| compaction-survival | Context compaction survival |
| session-title-guard | Session title enforcement |
| session-start-memory | Session start memory injection |
| post-turn-biome | Post-turn biome enrichment |
| checkpoint-guard | Checkpoint safety guard |
| main-coordinator-tracing | Coordinator-level tracing |

Plus `_shared.js` — shared utilities module.

---

## Safety Contracts (7 approved)

| Contract | File | Purpose |
|----------|------|---------|
| spec-validation | `rules/spec-validation.md` | Brownfield spec validation chain |
| loop-operator-safety | `rules/loop-operator-safety.md` | Loop safety rails |
| session-start-contract | `rules/session-start-contract.md` | Session FSM states |
| cass-index-contract | `rules/cass-index-contract.md` | CASS index integrity |
| hook-system-contract | `rules/hook-system-contract.md` | Plugin failure isolation |
| t2-protocol-contract | `rules/t2-protocol-contract.md` | T2 protocol resilience |
| agent-handoff-contract | `rules/agent-handoff-contract.md` | Delegation handoff structure |

---

## MCP Servers (9)

| Server | Type | Enabled |
|--------|------|---------|
| sequential-thinking | local (npx) | ✅ |
| context7 | remote | ✅ |
| fetch | local (uvx) | ✅ |
| playwright | local (npx) | ❌ (disabled) |
| MiniMax | local (uvx) | ✅ |
| chrome-devtools | local (npx) | ✅ |
| desktop-commander | local (npx) | ✅ |
| codebase-memory | local (exe) | ✅ |
| vibe-trading | local (exe) | ✅ |

---

## Validators (Tier-1 — CI-wired)

| Validator | Language | Purpose |
|-----------|----------|---------|
| validate-skills.ts | TypeScript | Skill YAML tiered validation (FAIL/WARN/INFO) |
| check-rules.py | Python | Agent rule compliance checking |
| validate-jsonc.js | JavaScript | JSONC config parsing |
| validate-config.ps1 | PowerShell | Config structural validation |
| validate-manifests.ps1 | PowerShell | Agent manifest validation |
| skill-version-check.ps1 | PowerShell | Skill version consistency |
| check-dependencies.ps1 | PowerShell | Dependency availability check |
| validate-definitive.ps1 | PowerShell | Definitive reference validation |

---

## Known Issues (P1–P3)

### P1 — Real Bugs (NEED FIX)
- **None** — all previously identified P1 bugs have been resolved

### P2 — Path Portability (PARTIALLY FIXED — 4 of ~30 scripts)
- **Action needed:** ~25 PS1 scripts still hardcode `$env:USERPROFILE\.config\opencode` directly instead of using the 4-tier env-var fallback (OPENCODE_CONFIG_HOME → USERPROFILE → HOME → relative)
- 4 files updated: opencode.json, nightly_run.ps1, watcher_run.ps1, batch-add-skill-fields.py
- Remaining scripts need staged migration: many are local-only health checks that shouldn't run in CI anyway

### P2 — Manifest/Validator Drift (MOSTLY RESOLVED)
- 14 manifests got `description:` field added (BOM was root cause for some)
- 11 duplicate `model_tier:` keys fixed (silent YAML overwrite bug)
- `cybersecurity.yaml` duplicate removed
- 34 skills now have `triggers:` and `applies_to:` fields (tier-2 warnings: 34 → 0)
- `agent-registry.py` established as canonical schema source
- 97% of manifest schema failures fixed

### P3 — Behavioral Tests (DEFERRED)
- **No behavioral tests for agents** — only schema conformance tests. Agents could produce wrong outputs while passing schema checks.
- **No rollback workflow** — git history is the only recovery path for config corruption.

## Dual-Context Validation Principle

The system has TWO execution contexts that require DIFFERENT validators:

| Context | Path | Validators that SHOULD run | Validators that MUST NOT run |
|---------|------|---------------------------|------------------------------|
| **Live machine** | `C:\Users\Windows\.config\opencode\` | validate-config.ps1, validate-manifests.ps1, skill-version-check.ps1 | tests/test-manifest-schema.mjs (CI-only) |
| **CI runner** | ubuntu-latest / windows-latest | tests/test-manifest-schema.mjs, validate-skills.ts, check-rules.py | validate-config.ps1 (local paths), skill-version-check.ps1 (local paths) |

**Design rule:** Local health checks (`validate-*.ps1`) should NEVER be wired into CI. Repo-state checks (`tests/*.mjs`, `scripts/validate-skills.ts`) should ONLY run in CI.

---

## Open Questions

1. Should we port `validate-manifests.ps1` to a modern schema, or update manifests to match current validator schema? (validator-vs-data drift resolution)

---

## Recent Verifications

**Date:** 2026-07-01

- ✅ All Tier-1 validators present and executable
- ✅ All 26 agent `.yaml` + `.md` pairs intact
- ✅ 7 safety contracts referenced in AGENTS.md
- ✅ 11 plugins configured in opencode.json
- ✅ 9 MCP servers defined (1 disabled: playwright)
- ✅ 38 skills in skills directory
- ✅ 94 scripts in scripts directory
- ✅ DEFERRED.md present — 1 L-2 item documented
- ✅ CI workflow present (`.github/workflows/ci.yml`)
- ✅ Last health report: 2026-06-24 (7 days ago)

---

*Report generated by code-analyzer audit — read-only, no files modified.*
