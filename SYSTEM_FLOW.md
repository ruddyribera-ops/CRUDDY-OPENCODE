# AI Software Factory — System Flow Reference

> **TL;DR** — A Ruddy-managed orchestrator routes client requests through `account-manager` → `project-manager` → `tech-lead` → specialists. `main-coordinator` handles intent classification and routing. 21 agents, 5 layers, 3 common patterns.

<!-- last-verified: 2026-06-21 -->
<!-- source: AGENTS.md (D:\Users\Windows\.config\opencode\AGENTS.md) -->

---

## 1. The System at a Glance

The AI Software Factory is a multi-agent orchestrator that transforms client requests into delivered software. Ruddy oversees the `main-coordinator`; the client-facing entry point is `account-manager`. Work flows: `account-manager` receives the brief, `project-manager` decomposes it into tasks, `tech-lead` dispatches to specialists, and `delivery-engineer` ships the result.

---

## 2. The Dispatch Chain (ASCII diagram)

```
                          Ruddy
                            |
                     main-coordinator  (intent classification, routing)
                            |
        +-------------------+-------------------+
        |                   |                   |
        v                   v                   v
  account-manager     (standalone          (standalone
  (client entry)       quick tasks)         queries)
        |                                       |
        v                                       v
  project-manager                     standup-summary
  (task decomposition)                      (status)
        |
        +---> solutions-architect  --> tech-lead --> code-builder
        |                                        |
        |                                        +---> bug-fixer
        |                                        |
        |                                        +---> qa-engineer
        |                                        |
        |                                        +---> delivery-engineer
        |
        +---> architecture-advisor  (deep tradeoffs, any phase)
        |
        +---> project-generator  (new projects only)
        |
        +---> evolution-agent  (background, meta)
        |
        +---> skill-manager  (ad-hoc)
```

**Parallel dispatch:** Frontend+Backend → two `code-builder`. Bug+Impact → `bug-fixer`+`code-analyzer`. Code+Tests → `code-builder`+`code-builder`.

---

## 3. The Layers

| Layer | Primary Agent(s) | Purpose | Routes TO | Routes FROM |
|-------|-----------------|---------|-----------|-------------|
| Client-Facing | `account-manager` | Receives client briefs, manages scope, returns results | `project-manager`, `standup-summary`, `support` | Ruddy (via main-coordinator) |
| Project Coordination | `project-manager` | Sprint planning, task decomposition, blocker tracking | `solutions-architect`, `tech-lead`, `architecture-advisor`, `project-generator` | `account-manager` |
| Architecture | `solutions-architect`, `architecture-advisor`, `tech-lead` | Tech stack decisions, deep tradeoffs, code quality gate | `code-builder`, `bug-fixer`, `qa-engineer` | `project-manager` |
| Execution | `code-builder`, `bug-fixer`, `code-analyzer`, `code-explainer`, `code-reviewer`, `qa-engineer`, `delivery-engineer`, `designer`, `tech-writer`, `cybersecurity` | Do the actual work | `delivery-engineer` (final output) | `tech-lead` |
| Special | `project-generator` | Scaffold whole projects from scratch | `solutions-architect` | `account-manager` |

---

## 4. Three Common Flow Patterns

### Pattern A: New project
1. Client: "I want to build X"
2. `main-coordinator` classifies intent → routes to `account-manager`
3. `account-manager` confirms scope, gathers brief → calls `project-generator`
4. `project-generator` creates scaffolding + calls `solutions-architect`
5. `solutions-architect` picks stack → calls `tech-lead`
6. `tech-lead` dispatches `code-builder` (x2 for frontend+backend)
7. `delivery-engineer` deploys → `qa-engineer` verifies
8. `account-manager` returns live URL to client

### Pattern B: Technical task on existing project
1. Client: "fix this bug"
2. `main-coordinator` → routes to `account-manager`
3. `account-manager` → routes to `project-manager` (bypass if urgent)
4. `project-manager` triages → calls `bug-fixer`
5. `bug-fixer` root-causes + fixes → `code-reviewer` approves
6. `delivery-engineer` deploys fix
7. `account-manager` confirms fix to client

### Pattern C: Status query
1. Client: "where are we?"
2. `main-coordinator` → routes to `account-manager`
3. `account-manager` → calls `standup-summary`
4. `standup-summary` returns git activity + progress
5. `account-manager` surfaces to client

---

## 5. The Handoff Contract

| Transition | What sender gives | What receiver returns | Failure mode |
|------------|-------------------|----------------------|--------------|
| Client → AM | Raw request (verbal or written) | Brief confirmed with scope | Misunderstood requirements → wrong deliverable |
| AM → PM | Client brief (requirements, constraints) | Sprint plan with tasks + estimates | Unclear scope → missed deadlines |
| PM → SA | POA (plan of action) | Tech stack recommendation, architecture doc | Wrong stack → rework later |
| SA → TL | Architecture decision | Implementation plan with complexity score | Gaps in plan → code-builder blocked |
| TL → Specialist | Task spec + context | Completed work + test results | Vague task → wrong output |
| Specialist → Delivery | Shippable artifact | Deployed + verified result | Broken artifact → production incident |
| Bug → Fix | Repro case + error trace | Root cause + fix PR | Can't reproduce → bug remains |

---

## 6. The Specialist Roster (21 agents)

| Agent | One-line role | Routes TO this agent when | Routes TO |
|-------|---------------|---------------------------|-----------|
| `account-manager` | Client-facing sales/PM | client, customer, pricing, scope | `project-manager`, `standup-summary`, `support` |
| `project-manager` | Sprint planning, task decomposition | sprint plan, what is next, kickoff | `solutions-architect`, `tech-lead`, `code-builder` |
| `solutions-architect` | Tech stack, integrations, security model | which database, which framework, stack | `tech-lead`, `code-builder` |
| `tech-lead` | Technical oversight, code quality, routing | (receives from SA) | `code-builder`, `bug-fixer`, `qa-engineer` |
| `bug-fixer` | Debug, root cause, error resolution | fix, error, bug, broken, crash | `code-builder` (if fix needs code) |
| `code-builder` | Write code, implement features | build, create, add, implement, refactor | (executes directly) |
| `code-analyzer` | Scan, audit, health check | scan, analyze, detect, audit, health | (read-only) |
| `code-explainer` | Plain-language code explanation | explain, what does, how does | (read-only) |
| `code-reviewer` | Code quality, security, style | review code, quality check | (read-only) |
| `delivery-engineer` | Deploy, Railway, CI/CD, verification | deploy, staging, prod, verify | (executes directly) |
| `qa-engineer` | Test plan, acceptance, bug triage | test plan, acceptance, QA | `bug-fixer` |
| `architecture-advisor` | Deep architecture, tradeoffs, Architect Pack | should I, tradeoff, pros cons, evaluate | `tech-lead`, `code-builder` |
| `designer` | Design tokens, component specs, visual artifacts | design system, color palette, typography | `code-builder`, `tech-writer`, `code-analyzer` |
| `tech-writer` | Human + AI-reader docs (GEO, Diataxis) | document, README, tutorial, how-to | `code-reviewer`, `designer`, `code-explainer` |
| `support` | Customer triage, knowledge-base, escalation | support, help, error, broken, ticket | `bug-fixer`, `tech-writer`, `project-manager` |
| `cybersecurity` | OWASP threat modeling, vuln audit | security, audit, vulnerability, OWASP | `code-builder`, `bug-fixer`, `account-manager` |
| `project-generator` | New project scaffolding | new project, I want to build, desde cero | `solutions-architect` |
| `evolution-agent` | Self-improvement, pattern detection | analyze performance, suggest improvements | (meta, no delegation) |
| `skill-manager` | Skill creation, import/export | save this as a skill, create a skill | (meta, no delegation) |
| `standup-summary` | Daily git activity, progress | daily, standup, status, recap | (read-only) |
| `main-coordinator` | Intent classification, routing | Ruddy's oversight layer | all agents |

---

## 7. Special Paths

| Path | Trigger | Route |
|------|---------|-------|
| Urgent bug fix | "urgent", "asap", "production down" | AM → `main-coordinator` → `bug-fixer` (bypasses PM) |
| Post-delivery support | "still broken", "after delivery issue" | AM → `support` (bypasses PM) |
| Architecture decision | "should I", "tradeoff", "evaluate" | AM → `architecture-advisor` directly (any phase) |
| Self-improvement | "evolve", "analyze performance", "genes" | `evolution-agent` runs in background, not main flow |
| Factory ops | Exact phrases: "factory ops", "internal mode" | `main-coordinator` → Ruddy only, no client agents |
| Complex project | Complexity 7-10 | DAG mandatory: `project-manager` → task_graph → batches → verify → aggregate |

---

## 8. Where to Look

| Question | Section |
|----------|---------|
| How does a new project start? | Section 4, Pattern A |
| What does `account-manager` do? | Section 3, Client-Facing layer |
| Who fixes bugs? | Section 6, `bug-fixer` row |
| What's the AM → PM handoff contract? | Section 5, first row |
| Where do the rules come from? | `rules/` directory (when present), especially `rules/common.md` |
| What happens in parallel? | Section 2, parallel dispatch note |
| How complex is this? | Section 3, Complexity 0–10 → DAG for 7–10 |

---

**Last verified:** 2026-06-21  
**Source:** `AGENTS.md` (line 1–124)  
**Budget:** 4 tool calls used (read x1, glob x1, write x1, verify x1)
