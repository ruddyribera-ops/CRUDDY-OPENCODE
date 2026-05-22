# OpenCode Config Changelog

All notable changes to the agent configuration and harness system.

Format: [Agent Versioning Convention]
- `agent(name):` — agent behavior/instruction changes
- `skill(name):` — skill content changes
- `config:` — opencode.json, MCP, provider changes
- `memory:` — memory/learning system changes
- `rules:` — enforcement rules changes
- `harness:` — harness improvements (manifests, duties, DAG, etc.)

---

## [1.0.0] — 2026-05-19

### Harness Engineering — Phase 1-3 Complete

**Added:**
- **harness:** Agent manifests — `agents/*.yaml` files for all 9 agents with capabilities, tools, roles, guardrails
- **harness:** Segregation of duties — `rules/duties.md` with role definitions, conflict matrix, enforcement flow
- **harness:** Session observability — `memory/session_log.md` tracking every agent invocation
- **harness:** Checkpoint protocol — `memory/checkpoint.yaml` for task state persistence and resume
- **harness:** DAG execution — graph-based task decomposition for Complex (7-10) tasks
- **harness:** Scheduled agents — `memory/schedule.yaml` with cron-based autonomous execution
- **harness:** Cost enforcement — `rules/budgets.yaml` with per-agent token budgets
- **harness:** Evolution agent — `agents/evolution-agent.md` + `.yaml` for self-improvement loop
- **config:** Playwright MCP enabled with Chrome extension (`--extension` flag, token in env var)
- **rules:** Safety rules updated: duties enforcement + session logging mandatory

**Changed:**
- **agent(main-coordinator):** Added critical rules #4 (parallel dispatch), #11 (duties enforcement), #12 (session logging)
- **agent(main-coordinator):** Added Parallel Dispatch, Checkpoint, and DAG Execution sections
- **agent(code-builder):** Added STEP 0.5 (parallel-opportunity check)
- **agent(bug-fixer):** Added Parallel-Opportunity Check before Root Cause Analysis
- **agent(architecture-advisor):** Added Parallel-Opportunity Check before ADR
- **config(AGENTS.md):** Strengthened "may spawn" → "MUST spawn" in Parallel Agent Delegation
- **config(AGENTS.md):** Added agent manifests + duties to Session Start Loading Order

### System Health
- **Disk:** C: 42.8 GB free, D: 208.2 GB free
- **Docker:** Running on C: (1.6 GB VHDX), WSL Ubuntu on D: (1.4 GB)
- **OpenCode:** 9 agents, 56 skills, 8 MCPs, 3 model tiers, 10 harness improvements
- **Score:** 7/10 → 9.0/10 (estimated)

---

## [0.9.0] — 2026-05-17

- System optimization: 38.7 GB freed from C:, WSL moved to D:, skills refactored
- Three-model tier routing configured (MiniMax M2.7 + DeepSeek V4 Flash/Pro)
