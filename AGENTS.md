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
| `expert-tester` | Adversarial deep tester — hunts edge cases the brief didn't anticipate. Complements qa-engineer (process gate), code-reviewer (static review), bug-fixer (reactive). | main-coordinator | (executes directly) |
| `ai-evaluator` | LLM output quality specialist — evaluates AI behavior with RAGAS, DeepEval, and LLM-as-judge patterns. Tests hallucination, groundedness, bias, prompt-injection resistance. | main-coordinator | (executes directly) |
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
| `observability-sre` | Production observability specialist — distributed tracing, latency monitoring, cost tracking, capacity planning, post-mortem analysis | tech-lead | (executes directly) |

---

## Intent → Agent Routing Table

| Intent | Agent | Trigger Words |
|--------|-------|---------------|
| Build/create/modify code | `code-builder` | build, create, add, implement, refactor, make, write, change, modify, update, develop, code, script |
| Fix errors/bugs | `bug-fixer` | fix, error, bug, broken, not working, crash, debug, arreglar, falla, doesn't work, issue |
| Code review/quality | `code-reviewer` | review code, quality check, check for bugs, critique, evaluate code |
| UI/Frontend/Design | `code-builder` | design, landing page, UI, frontend, dashboard, CSS, theme, make it look |
| Scan/analyze project | `code-analyzer` | scan, analyze, detect, structure, tech stack, map, audit, dependencies, health |
| Explain code | `code-explainer` | explain, what does, how does, tell me about, describe, walk me through, explain |
| Tech decisions | `architecture-advisor` | should I, which is better, architecture, tradeoff, pros cons, recommend, evaluate |
| Write/structure docs | `tech-writer` | document, doc, README, write docs, GEO, Diataxis, tutorial, how-to, reference, explain |
| Design system / UI spec | `designer` | design system, design tokens, component, color palette, typography, visual style, mockup, layout, brand |
| New project from scratch | `project-generator` | new project, I want to build, create an app, desde cero, scaffold, bootstrap |
| Project planning/sprint | `project-manager` | sprint plan, what is next, blocker, handoff, standup, retrospective, kickoff |
| Daily status | `standup-summary` | daily, standup, status, summary, what changed, recap, progress |
| Deploy/verify | `delivery-engineer` | deploy, staging, prod, verify, Railway, push |
| Test plan/acceptance | `qa-engineer` | test plan, acceptance, QA, smoke test, regression |
| Adversarial deep testing / property-based / fuzzing | `expert-tester` | test, edge case, fuzz, adversarial, stress, race condition, break it, find what's broken, property test, mutation test, exploratory, SFDIPOT, red team, OWASP LLM, deep test |
| AI/LLM output quality / hallucination / eval | `ai-evaluator` | evaluate AI, hallucination, RAG eval, prompt injection, model bias, LLM-as-judge, groundedness, response quality, AI output test, RAGAS, DeepEval |
| Save/create skill | `skill-manager` | save this as a skill, create a skill, remember this procedure |
| Security review / threat model | `cybersecurity` | security, audit, vulnerability, OWASP, threat model, pentest, secure, harden, appsec, CVE |
| Self-evolution | `evolution-agent` | analyze performance, suggest improvements, evolve, genes |
| Client interaction | `account-manager` | client, customer, pricing, scope, contract, meeting |
| Write/structure docs | `tech-writer` | document, doc, README, write docs, GEO, Diataxis, tutorial, how-to, reference, explain |
| Design system / UI spec | `designer` | design system, design tokens, component, color palette, typography, visual style, mockup, layout, brand |
| User/client support | `support` | support, how do I, doesn't work, broken, help, error, problem, complaint, ticket, customer |
| Observability / SRE / monitoring | `observability-sre` | observability, SRE, monitor, trace, latency, error rate, p99, p95, cost, token, capacity, post-mortem, incident, deploy healthy, track costs, trace failure, where tokens, alert |
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
## Auto-Handoff Pattern (Evaluator-Optimizer)

After `code-reviewer` signs off on a feature change, main-coordinator automatically dispatches `expert-tester` for adversarial deep review. This implements Anthropic canonical evaluator-optimizer workflow.

Trigger conditions:
- Code-reviewer returned PASS verdict
- The change touched 3+ files OR introduced new public APIs
- User did not explicitly opt out via `--no-adversarial`

Skip conditions:
- Documentation-only changes
- Sub-10-line typo fixes
- Pure config edits (opencode.json, AGENTS.md)
## Auto-Handoff Pattern: AI-Feature Eval (parallel to reviewer-tester)

After `code-builder` finishes a feature change, main-coordinator checks whether the change touches AI-feature code. If yes, dispatch `ai-evaluator` in parallel with the existing reviewer-tester handoff.

Why parallel (not sequential): `ai-evaluator` tests AI BEHAVIOR (hallucination, prompt injection, groundedness) which is independent of code quality. Waiting for `expert-tester` to finish would double the latency for AI-feature builds without adding signal.

Trigger conditions (ALL must be true):
- `code-builder` finished a non-trivial change (3+ files OR new public API)
- At least one changed file matches the AI-feature detection heuristic
- User did not explicitly opt out via `--no-eval`

AI-feature detection heuristic (OR logic â€” false positives OK, false negatives are the real risk):

**Path patterns (any match):**
- Filename contains: `prompt`, `rag`, `llm`, `completion`, `chat`, `embed`, `vector`, `chatbot`, `agent_system`
- Path segments: `ai/`, `llm/`, `prompts/`, `chatbot/`, `agents/`
- Suffix: `.prompt`, `.system`, `.tool` (prompt files)

**Content patterns (any match in source files):**
- Imports: `openai`, `anthropic`, `langchain`, `llamaindex`, `ai-sdk`, `vercel/ai`
- Calls: `chat.completions`, `messages.create`, `generate_text`, `embed_query`, `streamText`, `invoke_agent`
- Variables: `system_prompt`, `temperature=`, `max_tokens`, `model=`
- Strings: `You are a`, `function_call`, `tool_use`, `<|im_start|>`

Skip conditions:
- All test-only changes
- Documentation-only changes
- No source file matches path OR content patterns (heuristic returned false)

Handover format (consistent with expert-tester):
```
TASK: Evaluate AI feature in changed files for output quality
FILES_REVIEWED: [list of changed files matching AI-feature heuristic]
ORIGINAL_REQUEST: [user's original task description]
AI_FEATURE_CONTEXT: [which detection signals fired, why these files are AI-feature]
ITERATION: [1/2/3]
```

`ai-evaluator` runs its standard 7-step workflow (charter â†’ eval dataset â†’ RAGAS/DeepEval metrics â†’ LLM-as-judge sample â†’ OWASP LLM Top 10 sweep â†’ reproduce failures â†’ report) against the changed files.

Output: structured report with Findings (severity-ordered), Coverage Gaps, Recommendations, Risk Assessment. Same format as `expert-tester`.

User opt-out flags:
- `--no-eval` skips this handoff (alongside existing `--no-adversarial` for reviewer-tester)
- `--no-ai-handoff` skips only this one

Why this matters: Without this handoff, AI features ship without output quality validation. With it, every AI-touching change gets hallucination + bias + prompt-injection + groundedness checked automatically before QA sign-off.

Wired: this section is documentation. The actual dispatch logic lives in `agents/main-coordinator.md`'s routing table. If you find AI features slipping through unevaluated, that's the file to check.

