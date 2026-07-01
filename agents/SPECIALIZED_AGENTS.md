---
name: specialized-agents
description: REFERENCE DOCUMENT - aspirational multi-agent design using CrewAI + LangGraph. Not implemented. See roadmap for future state.
color: "#71717A"
emoji: "📐"
---

# SPECIALIZED AGENTS — Reference Document (Aspirational)

> **This is a reference/design document.** The system described here (CrewAI + LangGraph multi-agent orchestration) is NOT currently implemented.

This is an aspirational design doc. It documents a possible future state for the agent system, using a multi-agent architecture pattern with:
- Planner role
- Backend specialist
- Frontend specialist
- QA specialist
- DevOps specialist
- Analyst role
- Security specialist
- Docs specialist

## Status

**Reference only.** The current system uses the 27-agent flat-routing approach documented in `AGENTS.md`. The CrewAI + LangGraph multi-agent orchestration is a future-state design.

## Why it exists here

This file exists to preserve the original design exploration (per backup at `_fixes_backup_20260517_091745/SPECIALIZED_AGENTS.md`) so the design rationale is not lost. It also satisfies the reference check in `validate-config.ps1` which verifies the doc exists.

## When to use this

DO NOT use this for current work. The active agent registry is in `AGENTS.md`. Refer to this file only when planning future migrations to a graph-based multi-agent architecture.

## See also

- `AGENTS.md` — current active agent routing table
- `rules/agent-handoff-contract.md` — delegation contract (applies to both current and future architectures)
- `MASTER_PLAN_AUDIT.md` — system audit log
