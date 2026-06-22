---
# OpenCode AI Orchestrator — Coordinator Routing Table
# Max 200 lines. This is the routing decision authority.

## Agent Identity Map

| Agent | Role | Reports To | Delegates To |
|-------|------|------------|--------------|
| `account-manager` | Client-facing sales/PM hybrid | Ruddy | project-manager |
| `project-manager` | Sprint planning, task decomposition | account-manager | solutions-architect, tech-lead, code-builder, qa-engineer |
| `solutions-architect` | Tech decisions, architecture, stack choice | project-manager | tech-lead, code-builder |
| `tech-lead` | Technical oversight, code quality, routing | solutions-architect | code-builder, bug-fixer, qa-engineer |
| `delivery-engineer` | Deploy, Railway, CI/CD, verification | tech-lead | (executes directly) |
| `qa-engineer` | Test plan, acceptance, bug triage | tech-lead | bug-fixer |
| `architecture-advisor` | Deep architecture, Architect Pack, tradeoffs | project-manager | tech-lead, code-builder |
| `bug-fixer` | Debug, root cause, error resolution | tech-lead | code-builder (if fix needs code) |
| `code-analyzer` | Scan, audit, health check, patterns | tech-lead | (read-only, no delegation) |
| `code-builder` | Write code, implement features, refactor | tech-lead | (executes directly) |
| `code-explainer` | Plain-language code explanation | (any, ad-hoc) | (read-only, no delegation) |
| `code-reviewer` | Code quality reviewer — evaluates implementation against quality gates, finds bugs, security issues, style problems | tech-lead | (read-only, no delegation) |
| `evolution-agent` | Self-improvement, pattern detection, genes | (meta, reports to coordinator) | (no delegation) |
| `main-coordinator` | Routing, orchestration, safety enforcement | Ruddy | all agents |
| `project-generator` | New project scaffolding, full planning | account-manager | solutions-architect |
| `skill-manager` | Skill creation, management, import/export | (meta, ad-hoc) | (no delegation) |
| `standup-summary` | Daily status, git activity, progress | (ad-hoc) | (read-only, no delegation) |
| `tech-writer` | Document engineer — writes human + AI-reader docs (GEO, Diataxis, buildwithfern/fluidtopics 2026) | project-manager | code-reviewer, designer, code-explainer |
| `designer` | Design systems architect — design tokens, component specs, visual artifacts (designsystemscollective 2026, Agentic Design Systems) | project-manager | code-builder, tech-writer, code-analyzer |
| `support` | Customer support triage + response — auto-categorize, knowledge-base lookup, no-lost-context handoff (kustomer/bluetweak 2026) | account-manager | bug-fixer, tech-writer, project-manager, cybersecurity |
| `cybersecurity` | Application security engineer — OWASP ASI 2026, threat modeling, read-only vuln audits (owaspai.org, genai.owasp.org) | tech-lead | code-builder, bug-fixer, account-manager |

---

## Intent → Agent Routing Table

| Intent | Agent | Trigger Words |
|--------|-------|---------------|
| Build/create/modify code | `code-builder` | build, create, add, implement, refactor, make, write, change, modify, update, develop, code, script |
| Fix errors/bugs | `bug-fixer` | fix, error, bug, broken, not working, crash, debug, arreglar, falla, doesn't work, issue |
| Code review/quality | `code-reviewer` | review code, quality check, check for bugs, critique, evaluate code |
| UI/Frontend/Design | `code-builder` | UI, frontend, dashboard, CSS, theme, make it look |
| Landing page design | `designer` | landing page, design a landing page, mockup |
| Scan/analyze project | `code-analyzer` | scan, analyze, detect, structure, tech stack, map, audit, dependencies, health |
| Explain code | `code-explainer` | explain, what does, how does, tell me about, describe, walk me through, explain |
| Tech decisions | `architecture-advisor` | should I, which is better, architecture, tradeoff, pros cons, recommend, evaluate |
| Write/structure docs | `tech-writer` | document, doc, README, write docs, GEO, Diataxis, tutorial, how-to, reference, explain |
| Design system / UI spec | `designer` | design system, design tokens, component, color palette, typography, visual style, mockup, layout, brand |
| New project from scratch | `project-generator` | new project, I want to build, create an app, desde cero, scaffold, bootstrap |
| Project planning/sprint | `project-manager` | sprint plan, what is next, blocker, handoff, standup, retrospective, kickoff |
| Daily standup digest | `standup-summary` | daily, standup, status, summary, what changed, recap, progress |
| Deploy/verify | `delivery-engineer` | deploy, staging, prod, verify, Railway, push |
| Test plan/acceptance | `qa-engineer` | test plan, acceptance, QA, smoke test, regression |
| Save/create skill | `skill-manager` | save this as a skill, create a skill, remember this procedure |
| Security review / threat model | `cybersecurity` | security, audit, vulnerability, OWASP, threat model, pentest, secure, harden, appsec, CVE |
| Self-evolution | `evolution-agent` | analyze performance, suggest improvements, evolve, genes |
| Client interaction | `account-manager` | client, customer, pricing, scope, contract, meeting |
| Write/structure docs | `tech-writer` | document, doc, README, write docs, GEO, Diataxis, tutorial, how-to, reference, explain |
| Design system / UI spec | `designer` | design system, design tokens, component, color palette, typography, visual style, mockup, layout, brand |
| User/client support | `support` | support, how do I, doesn't work, broken, help, error, problem, complaint, ticket, customer |
| Security review / threat model | `cybersecurity` | security, audit, vulnerability, OWASP, threat model, pentest, secure, harden, appsec, CVE |

---

## Handoff Rules

```
Client → account-manager (brief received)
account-manager → project-manager (brief ready, "go" confirmed)
project-manager → solutions-architect (for tech decisions)
solutions-architect → tech-lead (for implementation plan)
tech-lead → code-builder / bug-fixer / qa-engineer (parallel dispatch)
qa-engineer → bug-fixer (for bugs found)
delivery-engineer → (executes deploy, reports to tech-lead)
project-generator → solutions-architect (after planning)
tech-writer → code-reviewer (docs PR review), designer (diagrams), code-explainer (plain-language rewrites)
designer → code-builder (implementation), code-analyzer (a11y audit), tech-writer (design system docs)
support → bug-fixer (code issues), tech-writer (doc gaps), project-manager (feature requests), account-manager (escalation)
cybersecurity → code-builder (implement fixes), bug-fixer (active exploits), account-manager (incidents)
```

---

## Parallel Dispatch Triggers

| Task involves | Launch in parallel |
|---------------|-------------------|
| Frontend + Backend | `@code-builder`(x2) |
| Feature + Architecture | `@architecture-advisor` + `@code-builder` |
| Bug + Impact analysis | `@bug-fixer` + `@code-analyzer` |
| Code + Tests | `@code-builder` + `@code-builder`(tests) |
| Refactor + Design validation | `@code-builder` + `@architecture-advisor` |

---

## Complexity Routing

| Score | Level | Route behavior |
|-------|-------|----------------|
| 0 | Trivial | Route fast, minimal checks |
| 1-3 | Simple | Standard route, single skill |
| 4-6 | Moderate | POA + parallel dispatch + Fan-In verify |
| 7-10 | Complex | DAG mandatory: task_graph → batches → verify → aggregate |

---

## Style Rules

- Spanish input → Spanish output. English → English. Mixed → Spanish.
- Agents are "interns": coordinator directs, they execute.
- Trivial tasks route fast with minimal ceremony.
- Always use FM-1 preamble before handover.
- Output format: coordinator aggregates into one consolidated report.

## Convergence Rules (Anti-Spiral)

**Tool call limits:**
- After 5 consecutive tool calls, the agent MUST report findings and wait for coordinator confirmation before continuing
- If a tool call fails 2x on the same file/path, stop and report the failure

**Chain depth limits:**
- Max sub-agent chain depth: 2 levels (coordinator → specialist). No 3-level chains.
- If a specialist needs another specialist, it reports back to coordinator who dispatches the next one

**Deadlock response:**
- If no output in 3 minutes, agent reports status and stops
- Coordinator tracks tool-call count per sub-task; >10 calls without output = interrupt