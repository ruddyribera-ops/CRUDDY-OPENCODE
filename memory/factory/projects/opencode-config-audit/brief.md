# OpenCode Config Audit — Project Brief

## What
Full audit of the OpenCode configuration at `C:/Users/Windows/.config/opencode/`.
Goal: zero duplicates, clean wiring, everything auto-fixed within budget.

## Success at 90 days
- 0 duplicate files, rules, skills, or scripts
- Every hook fires correctly (verified by test)
- Every agent manifest is consistent with actual capabilities
- Every skill is loadable and non-duplicative
- No broken wires between rules → agents → hooks → skills
- Audit report shows: findings count, fixes applied, remaining flags

## Scope (7 areas)
1. **Hooks** — scripts/hooks/*.ps1, hook-config.json, hooks-config.md
2. **Rules** — rules/*.md, rules/agent_rules/*.md
3. **Agents** — agents/*.md, agent identity, dispatch logic
4. **Skills** — skills/*.md, skills/.archive/*, SKILLS_INDEX.json
5. **Harnesses** — workflows/*.md, workflows/*.yaml
6. **Scripts** — scripts/*.ps1, scripts/*.js, scripts/hooks/
7. **Memory system** — memory/*.md, memory/factory/, memory/graph/

## Out of scope
- Any external service (Railway, Supabase, etc.)
- User's application code
- New feature development

## Auto-fix policy
- code-builder fixes automatically up to budget
- Fixes include: remove duplicates, fix broken imports/references, consolidate rules, wire missing hooks
- Flags (no auto-fix): security issues, architectural decisions requiring your input

## Budget
- API spend: $50/day cap
- Staging deploys: 5/day max
- Fix budget: $200 total for auto-fixes

## Team
- project-manager: sprint plan, coordinate audit batches
- code-analyzer: scan all 7 areas, produce findings list
- code-builder: apply fixes for non-critical findings
- qa-engineer: verify hook firing, skill loading, agent dispatch
- delivery-engineer: verify no regressions after fixes

## Friday demo
- URL: staging config (local, no deploy needed)
- Walkthrough: audit report + before/after comparison