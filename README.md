# CRUDDY-OPENCODE — OpenCode Configuration

This repository contains a custom **OpenCode** configuration: agents, skills, rules, plugins, contracts, and scripts that orchestrate a multi-agent coding workflow.

The same configuration lives at ~/.config/opencode/ on the maintainer's machine. This repo is the versioned, shareable copy.

## What this is

A **multi-agent AI orchestrator** for OpenCode. The setup includes:

- **27 specialist agents** (gents/) — code-builder, bug-fixer, expert-tester, architecture-advisor, code-reviewer, qa-engineer, etc.
- **38+ skills** (skills/) — domain-specific knowledge (Python, TypeScript, FastAPI, React, security, observability, etc.)
- **6 safety contracts** (ules/) — formal state machines and pre-flight check patterns for delegation, loop execution, session lifecycle, hook isolation, T2 protocol, and CASS indexing
- **12 plugins** (plugins/) — session lifecycle hooks, gate enforcement, sub-agent guards, CASS indexer
- **PowerShell T2 protocol** (scripts/) — 8-step end-of-task logging with per-step resilience

## Core architecture

The routing is layered:

1. **main-coordinator** receives every user request (routing agent, no execution)
2. **Routing table** in AGENTS.md maps intents to specific agents
3. **4-element handoff contract** (ules/agent-handoff-contract.md) governs every delegation
4. **Pre-flight checks** (skills/safe-delegation/) verify files, tools, and preconditions BEFORE action
5. **Safety contracts** enforce state machine transitions and exit conditions

## Why these design choices?

**Why main-coordinator can't edit code:**
The coordinator has edit: deny and ash: deny in its permission block. This is structural enforcement, not a gentle suggestion. If routing and execution lived in the same agent, the coordinator would be tempted to "just quickly fix it" instead of dispatching. The permission layer makes the right path the only path.

**Why contracts exist:**
Without explicit state machines, agent transitions are ambiguous. Does "done" mean "function returns" or "file written and verified"? Contracts like session-start-contract.md define FSM states (ABSENT → PENDING → STARTING → ACTIVE → IDLE → ENDED/FAILED) so every agent agrees on what each state means. Ambiguity is the root cause of half-started sessions and silent failures.

**Why pre-flight checks matter:**
The safe-delegation skill enumerates the 4 most common delegation failure modes: (1) file creation in non-existent directories, (2) references to non-existent tools or skills, (3) reads or edits of non-existent files, and (4) unmanaged server lifecycles. Pre-flight checks catch these before tool calls fail, not after.

## Directory structure

\\\
opencode/
├── agents/           # 26 agent definitions (YAML + markdown pairs)
│   ├── main-coordinator.md + .yaml
│   ├── code-builder.md + .yaml
│   ├── bug-fixer.md + .yaml
│   ├── expert-tester.md + .yaml
│   └── ... (22 more)
├── rules/            # Safety contracts and conventions
│   ├── agent-handoff-contract.md    # 4-element delegation pattern
│   ├── loop-operator-safety.md     # 4 mandatory safety rails
│   ├── session-start-contract.md    # FSM session lifecycle
│   ├── cass-index-contract.md      # CASS entry invariants
│   ├── hook-system-contract.md     # 12-plugin failure isolation
│   ├── t2-protocol-contract.md     # 8-step resilience
│   ├── spec-validation.md          # PRELIMINARY/VALIDATED/REJECTED
│   └── ... (20+ more conventions)
├── skills/           # 38+ skill packages (each with SKILL.md)
│   ├── safe-delegation/
│   ├── python-patterns/
│   ├── javascript-typescript/
│   ├── evaluation/
│   └── ... (34 more)
├── plugins/          # 12 lifecycle hooks (JavaScript)
│   ├── memory-bridge.js        # T1/T2/T3 lifecycle events
│   ├── gate-system.js          # Pre-tool gate enforcement
│   ├── pre-tool-guard.js       # Dangerous command blocking
│   ├── sub-agent-guard.js      # 5-minute subagent timeout
│   ├── session-start-memory.js  # Session start persistence
│   ├── checkpoint-guard.js     # Checkpoint validation
│   └── ... (6 more)
├── scripts/          # PowerShell T2 protocol + utilities
│   ├── t2-complete.ps1         # 8-step end-of-task logging
│   ├── gate-check.ps1          # Pre-deployment verification
│   ├── checkpoint-save.ps1      # State persistence
│   ├── mail.py                  # Inter-agent messaging
│   └── ... (80+ more utilities)
├── factory/          # Sub-system orchestration
│   ├── hooks/
│   ├── planning/
│   ├── scripts/
│   └── tools/
├── opencode.json     # Model routing + provider config
└── AGENTS.md        # Agent routing table
\\\

## The 6 safety contracts

| Contract | File | Purpose |
|----------|------|---------|
| **Brownfield spec validation** | ules/spec-validation.md | PRELIMINARY specs must be validated by architecture-advisor before cited as ground truth. Prevents hallucinated consensus. |
| **Loop-operator safety** | ules/loop-operator-safety.md | 4 mandatory rails: max_iterations, cost_ceiling, 
o_progress_detector, human_escalation. Prevents runaway loops (has prevented \ incidents). |
| **Session start lifecycle** | ules/session-start-contract.md | FSM states: ABSENT → PENDING → STARTING → ACTIVE → IDLE → ENDED/FAILED. Defines required T1 steps per state. |
| **CASS index integrity** | ules/cass-index-contract.md | Entry field requirements (objective, output format, tools+source, return path). Producer/consumer obligations and failure recovery. |
| **Hook system isolation** | ules/hook-system-contract.md | Each of 12 plugins must fail independently without cascading. Specifies fallback behavior when a plugin fails. |
| **T2 protocol resilience** | ules/t2-protocol-contract.md | Each of 8 T2 steps must have explicit fallback on failure. Replaces silent $null redirects with logged degradation. |
| **Agent handoff delegation** | ules/agent-handoff-contract.md | 4-element structure: objective, output format, tools+source, return path. Pre-flight check pattern prevents 4 common failure modes. |

## Model selection

**main-coordinator** uses minimax/m3 — the largest context window and strongest reasoning model. Routing decisions are the highest-leverage operation in the system: a wrong routing decision wastes an entire specialist dispatch. The coordinator needs the best reasoning to disambiguate underspecified requests, detect scope drift, and choose the right specialist.

**Specialist agents** use minimax/m2.7 — the workhorse model. Specialists receive well-scoped tasks from the coordinator; they don't need maximum context. M2.7 is faster and cheaper per token, which matters when multiple specialists run in parallel. The coordinator's M3 context window is not passed to specialists — each specialist starts fresh with only its task brief.

## Plugins

| Plugin | Purpose |
|--------|---------|
| memory-bridge.js | Bridges T1/T2/T3 lifecycle events to the memory system |
| gate-system.js | Enforces pre-tool gates before command execution |
| pre-tool-guard.js | Blocks dangerous commands (rm -rf, DROP TABLE, etc.) |
| sub-agent-guard.js | Enforces 5-minute timeout on sub-agent dispatch |
| session-start-memory.js | Persists session start events to disk |
| checkpoint-guard.js | Validates checkpoint integrity before restore |
| compaction-survival.js | Handles session compaction gracefully |
| post-tool-guard.js | Post-execution artifact cleanup |
| post-turn-biome.js | Runs biome linter after each turn |
| main-coordinator-tracing.js | Distributed tracing for coordinator decisions |

## Quick start

This repo is the maintainer's personal OpenCode config, versioned for backup and sharing. To use it:

1. Clone this repo
2. Copy contents to ~/.config/opencode/ (or symlink)
3. Set environment variables referenced in opencode.json:
   - MINIMAX_API_KEY (for MiniMax/M2.7/M3 models)
   - OPENCODE_API_KEY (for OpenCode Go / DeepSeek)
   - GROQ_API_KEY (for Groq models)
4. Run scripts/validate-skills.ts to confirm skill YAML parses

## Documentation

- AGENTS.md — agent routing table + safety contracts section
- ules/loop-operator-safety.md — loop execution contract (4 mandatory rails)
- ules/spec-validation.md — brownfield spec extraction (PRELIMINARY/VALIDATED/REJECTED)
- ules/session-start-contract.md — session lifecycle FSM
- MASTER_PLAN_AUDIT.md — periodic self-audit
- health-check-report.md — current system health

## Status

Active. Maintained as the canonical OpenCode configuration. Last major sprint: delegation enforcement (agent-handoff-contract, safe-delegation skill, validator rewrite).

## License

MIT.