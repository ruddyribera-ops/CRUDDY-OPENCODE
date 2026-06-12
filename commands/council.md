---
description: Multi-agent deliberation on architectural decisions, complex choices, and tech tradeoffs. Spawns Architect, Skeptic, and Advocate perspectives in parallel.
usage: /council "<question or decision to deliberate>" [--mode brainstorm|quick|standard]
---

# /council — Multi-Agent Deliberation

Runs a three-agent council (Architect / Skeptic / Advocate) in parallel to synthesize a recommendation. Based on multi-agent consensus patterns (LangChain, Openlayer, Mar 2026) and CRISPY framework.

## Modes

| Mode | Duration | When to use |
|------|----------|-------------|
| `brainstorm` | ~30s | Fast gut-check, no deep analysis |
| `quick` | ~2min | Well-scoped decisions with clear options |
| `standard` | ~5min | Complex architecture, multi-tradeoff decisions |

Default: `standard`

## Flow

```
User fires /council "<question>"
  → Coordinator spawns 3 agents in parallel
      ├─ @architecture-advisor → "Architect" (builds the proposal)
      ├─ @bug-fixer            → "Skeptic"    (challenges, finds holes)
      └─ @standup-summary      → "Advocate"   (checks viability, resources, alignment)
  → Agents return in parallel
  → Coordinator synthesizes into:
      - Decision recommendation
      - Trade-off table (3 perspectives)
      - Remaining concerns
      - Suggested next step
```

## Participant Roles

**Architect** (@architecture-advisor)
- Builds the strongest case for the decision
- Identifies trade-offs clearly
- References past ADRs if relevant

**Skeptic** (@bug-fixer)
- Finds the holes in the proposal
- Challenges assumptions
- Names what could go wrong

**Advocate** (@standup-summary)
- Checks feasibility (time, resources, team alignment)
- Flags blockers
- Validates context (is this the real problem?)

## Coordinator Synthesis Output Format

```
## Council Deliberation — [topic]

### Decision Direction
[One sentence: what the council is leaning toward]

### Perspectives

| Dimension | Architect | Skeptic | Advocate |
|-----------|-----------|---------|----------|
| Complexity | [view] | [view] | [view] |
| Risk | [view] | [view] | [view] |
| Feasibility | [view] | [view] | [view] |
| Time/Cost | [view] | [view] | [view] |
| Alignment | [view] | [view] | [view] |

### Remaining Concerns
- [Skeptic's unresolved challenge]
- [Advocate's feasibility flag]

### Recommended Next Step
[One sentence: what to do to resolve remaining concerns or proceed]

### Confidence
High / Medium / Low — [reason]
```

## Rules

1. Coordinator synthesizes, does NOT re-argue — uses what agents said
2. If agents disagree strongly, surface the tension explicitly
3. Do not smooth over disagreements — represent them faithfully
4. Skeptic gets the last word on risks
5. If question is too vague, ask ONE clarifying question before spawning council

## Examples

```
/council "Should we add Redis caching to the auth service?"
/council "Microservices vs monolith for a 5-person team — PRIA app" --mode quick
/council "What's the best way to handle file uploads in the current stack?" --mode standard
```

## Research Sources
- Multi-agent architecture patterns: OpenLayer (Mar 2026), LangChain multi-agent guide (Jan 2026)
- Council/moderator pattern: edoardo schepis "Democracy in Multi-Agent AI Systems" (May 2025)
- Deliberation modes inspired by: dtsong /council, CRISPY workflow (Tyler Folkman)