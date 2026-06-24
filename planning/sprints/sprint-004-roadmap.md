# Sprint Roadmap 004-006 — AI-Era Team Hardening

> **Generated:** 2026-06-24 | **Status:** APPROVED | **Total work:** ~8-12 hours across 3 sprints

## Sprint 004 — Quick wins (1-2h)

### 1. evolution-agent auto-trigger
- File: `agents/evolution-agent.md`
- Add to body: "After every 5 completed tasks in a session, the evolution agent auto-fires to read `memory/outcomes/patterns.jsonl` and propose new genes."
- Wire trigger via plugin or session-end hook.

### 2. code-reviewer → expert-tester handoff
- Files: `agents/main-coordinator.md`, `AGENTS.md` routing table
- New routing rule: "After code-reviewer signs off on a feature change, automatically dispatch expert-tester for adversarial deep review (unless user opts out)."
- This implements Anthropic's canonical evaluator-optimizer pattern.

### 3. delivery-engineer post-deploy smoke test
- File: `agents/delivery-engineer.md`
- New body section: "After deployment, run health-check smoke test. Verify: app responds 200 on health endpoint, no error spike in logs, key user paths still functional. Alert on failure."
- Add to skill loadout: `webapp-testing`, `deployment-patterns`.

### 4. cybersecurity — add OWASP LLM + Agentic ASI
- File: `agents/cybersecurity.md`
- Add to body: explicit reference to OWASP LLM Top 10 (2026) and OWASP Agentic ASI Top 10 (2026).
- Add to skill loadout: new `owasp-llm-top10` skill (if not exists).

## Sprint 005 — ai-evaluator (3-4h)

### 1. New skill: `skills/evaluation/SKILL.md`
- RAGAS methodology (faithfulness, context precision, answer relevancy)
- DeepEval patterns (hallucination, bias, toxicity)
- LLM-as-judge patterns
- Eval-driven CI gates (fail PR if regression)

### 2. New agent: `agents/ai-evaluator.md`
- Model: minimax-m2.7 (workhorse)
- Mode: subagent
- Color: `#9333EA` (purple — distinguishes from code-testing red)
- Emoji: `🎯` (target — eval hits precision)
- Vibe: "LLM output quality specialist. Where expert-tester asks 'does the code work?', I ask 'does the model output hold up?' Hallucinations, bias, groundedness, prompt-injection resistance — I hunt the bugs that exist only in AI behavior."
- Trigger phrases: evaluate AI feature, hallucination check, RAG eval, prompt-injection test, model bias, LLM-as-judge, response quality

### 3. Routing updates
- AGENTS.md routing table: add ai-evaluator row
- main-coordinator inline table: add ai-evaluator row
- Parallel dispatch trigger: "Feature with AI/LLM components + eval" → code-builder + ai-evaluator

## Sprint 006 — Observability / SRE (4-6h)

### 1. New skill: `skills/tracing/SKILL.md`
- Distributed tracing for agent calls
- Span model (agent invocation → sub-task → tool call)
- MCP integration (Anthropic, Augment 2026 patterns)

### 2. New skill: `skills/cost-tracking/SKILL.md`
- Token attribution per span
- Per-model cost calculation
- Caching strategy (Helicone-style 95% cache hit)
- Rate limiting

### 3. New agent: `agents/observability-sre.md`
- Model: minimax-m2.7
- Mode: subagent
- Color: `#0EA5E9` (sky blue — operations)
- Emoji: `📊` (observability)
- Vibe: "Production reality check. Catches what slips past dev — silent failures, cost overruns, latency regressions, capacity issues. Post-deploy monitoring and incident response."
- Trigger phrases: is deploy healthy, track costs, trace this failure, where tokens are lost, capacity plan, post-mortem, alert me, SRE, observability

### 4. main-coordinator observability hook
- File: `plugins/main-coordinator-tracing.js` (NEW)
- Logs every routing decision: timestamp, source request, target agent, duration, success/failure
- Writes to `memory/coordination-log.jsonl`
- Powers future observability-sre queries

### 5. Routing updates
- Add observability-sre to AGENTS.md and main-coordinator routing tables
- Parallel dispatch: "Production incident" → delivery-engineer + observability-sre

---

## Verification Strategy

After all 3 sprints:
- Run `expert-tester` adversarial review (the proven pattern from Sprint 003)
- Re-run the original health check from Sprint 001 → confirm 0 CRITICAL findings
- Verify env var state still clean
- Verify all agents discoverable

## Rollback

Each sprint is independent. Snapshots taken before each sprint at:
- `D:\Temp\opencode\BEFORE_SPRINT_004_<ts>\`
- `D:\Temp\opencode\BEFORE_SPRINT_005_<ts>\`
- `D:\Temp\opencode\BEFORE_SPRINT_006_<ts>\`

If any sprint breaks, restore from its snapshot.

---

## Definition of Done

- All 3 sprints implemented
- expert-tester review returns no CRITICAL findings
- OpenCode restart succeeds with no errors
- All new agents discoverable via @ autocomplete
- All routing references updated in AGENTS.md and main-coordinator
- T2 logs clean for all sprints
