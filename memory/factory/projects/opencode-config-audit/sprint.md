# Sprint — OpenCode Config Audit

**Started:** 2026-06-10
**Appetite:** 5 days (audit + fix sprint)
**Hill position:** climbing

## Tasks

1. [IN_PROGRESS] Audit: hooks + rules — code-analyzer — day 1
2. [QUEUED] Audit: agents + skills — code-analyzer — day 2
3. [QUEUED] Audit: harnesses + scripts — code-analyzer — day 3
4. [QUEUED] Audit: memory system — code-analyzer — day 3
5. [QUEUED] Fixes: hooks + rules — code-builder — day 4
6. [QUEUED] Fixes: agents + skills + harnesses + scripts — code-builder — day 4-5
7. [QUEUED] QA verify + final report — qa-engineer — day 5

## Today's focus

- code-analyzer audits hooks + rules

## Blockers

- (none yet)

## Risks

- Fix budget ($200) may not cover all 7 areas if findings are heavy in late audits
- SECURITY flags deferred to AM for client approval before fix

## Findings Categories

- DUPLICATE: duplicate files, rules, skills, scripts
- BROKEN_WIRE: broken imports/references, missing hook wiring
- DEAD_CODE: unused files, orphaned rules, unreachable agents
- STYLE: formatting, naming inconsistencies
- SECURITY: permission issues, exposed secrets, unsafe patterns (no auto-fix)

## Audit Batch Schedule

| Day | Areas |
|-----|-------|
| 1 | hooks, rules |
| 2 | agents, skills |
| 3 | harnesses, scripts, memory system |
| 4 | auto-fixes batch 1 (hooks + rules) |
| 5 | auto-fixes batch 2 + QA + report |
