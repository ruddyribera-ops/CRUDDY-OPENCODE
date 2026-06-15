# Handover: 2026-06-01 — auth.md + Context Graph Architecture Research

## Context
The user watched two talks and wants to evolve the OpenCode CLI configuration:

**Talk 1 — WorkOS auth.md (MCP Night):** Open protocol for agent registration. Agents get an ID-JAG (signed identity JWT) from their provider (the coordinator), present it to services (Cloudflare, Firecrawl, Resend, etc.), and receive API keys automatically — no human sign-up forms. Already adopted by Cloudflare, Firecrawl, Resend, Monday.com. IETF draft `draft-ietf-oauth-identity-assertion-authz-grant-04` (May 2026).

**Talk 2 — Neo4j Context Graphs (AI Engineer):** Decision framework for AI agents using graph-based memory. Three memory layers: short-term (conversations), long-term (people, orgs, projects), reasoning (policies, rules, the WHY). Agents traverse a graph to understand context, assess risk/value, check authority, and record decisions for future reference.

**Key insight:** Both complement each other. auth.md solves "how the agent enters a service." Context Graph solves "which service to pick and why."

## What Was Done (Research)
1. Full spec fetch: `workos/auth.md` GitHub repo (reference implementation in TypeScript/Express, pnpm workspace, MIT license)
2. IETF draft ID-JAG: 65-page spec, `urn:ietf:params:oauth:token-type:id-jag`, ES256 signatures, 5-min TTL, replay protection via jti
3. auth.md discovery: Two-hop via `.well-known/oauth-protected-resource` (RFC 9728) → `.well-known/oauth-authorization-server` (+ `agent_auth` block)
4. Two registration flows: Agent Verified (ID-JAG, synchronous) + User Claimed (OTP, asynchronous)
5. Context Graph decision framework: Problem framing → Global context → Risk-Value analysis → Proposal → Authority check → Self-learning
6. Current config audited: 21 rules, 38 memory files, 22 agent manifests, 57 scripts, 9 MCP servers, 10 agents

## What's Pending — Two Tracks

### Track A: auth.md — Agent Registration (8-10 on complexity scale)

| Item | What | Type | Depends On |
|------|------|------|------------|
| A1 | **AgentIdentityProvider** — ES256 keygen + ID-JAG minting in coordinator | `scripts/agent-identity.js` (NEW, ~80 lines) | — |
| A2 | **JWKS endpoint** — public key for service verification | `.well-known/jwks.json` (NEW, auto-generated) | A1 |
| A3 | **ID-JAG injection** — coordinator signs sub-agents at task dispatch | `agents/main-coordinator.md` (mod, ~10 lines prompt) | A1 |
| A4 | **auth.md registration skill** — agents discover + register to services | `skills/authmd-registration/SKILL.md` (NEW, ~60 lines) | A3 |
| A5 | **Trusted services list** — which services accept our ID-JAGs | `opencode.json` → `agent_identity.services` block | A1 |
| A6 | **Credential cache** — API keys from auth.md stored per session | `memory/credentials/` (NEW, ~40 lines) | A4 |
| A7 | **Dynamic MCP discovery** — agents find new MCP servers via auth.md | `opencode.json` → `mcp_dynamic` block | A4 |

### Track B: Context Graph — Decision Architecture (7-9 on complexity scale)

| Item | What | Type | Depends On |
|------|------|------|------------|
| B1 | **Graph schema** — node types (session, task, decision, lesson, project, file, rule_challenge) + relationship types | `memory/graph/schema.yaml` (NEW, ~30 lines) | — |
| B2 | **GraphMemory engine** — JSON-LD file-based graph, CRUD for nodes/edges | `scripts/graph-memory.js` (NEW, ~120 lines) | B1 |
| B3 | **Migration: TRIGGERS.md T2/T5/T6** — write decisions + lessons to graph in addition to flat files | `TRIGGERS.md` (mod), `update-session-yaml.ps1` (mod) | B2 |
| B4 | **Decision framework** — modify coordinator decision tree for Moderate+ tasks to consult graph before routing | `agents/main-coordinator.md` (mod, ~20 lines logic) | B3 |
| B5 | **Graph queries** — "what did we learn about deploy?", "why did we choose X?" | `scripts/graph-query.js` (NEW, ~40 lines) | B2 |
| B6 | **Challenger Rule → graph** — every override logged as edge in graph | `challenger-rule.md` (mod) | B3 |
| B7 | **Credential cache migration** — move auth.md credentials to graph instead of flat files | merge A6 into B2 | A6 + B2 |

## Key Decisions (from analysis)
- **Start with Context Graph first:** It uses existing data (38 memory files, session.yaml, lessons_learned) and provides immediate value. auth.md requires external service adoption to work.
- **File-based graph (no Neo4j):** JSON-LD on disk is sufficient for this scale. No external database needed. Migrate to Neo4j only if graph exceeds ~10K nodes.
- **Dual writes for graph:** Same pattern as current dual-write (KG + files). Graph writes don't replace file memory — they add query capability.
- **Evolution agent scope:** DNA.yaml genes + rule proposals + config proposals. Code scripts go to code-builder.

## Open Questions
- Should auth.md registration be synchronous (block sub-agent until registered) or background (fire-and-forget with retry)?
- Graph memory: JSON-LD files vs SQLite vs embedded LiteGraph? JSON-LD chosen for zero-dependency simplicity.
- Should the coordinator consult the graph BEFORE routing (proactive) or only when explicitly asked?
- Trusted provider list for ID-JAG: hardcoded in opencode.json vs discovered dynamically?

## Priority Items for Evolution Agent (DNA + Config)
These are config-only changes the evolution agent can handle directly:

1. **DNA.yaml gene: COORD-004** — "Inject agent identity into task dispatch"
   Behavior: coordinator appends ID-JAG to sub-agent prompt
2. **DNA.yaml gene: COORD-005** — "Consult context graph before routing Moderate+ tasks"
   Behavior: before routing, query graph for relevant decisions/lessons
3. **DNA.yaml gene: TRIGGER-002** — "Write decisions to graph on T6"
   Behavior: when decision is made, create node + edges in graph
4. **New rule: `rules/authmd-discovery.md`** — how agents discover and use auth.md
5. **New rule: `rules/graph-memory.md`** — schema and query conventions for graph memory
6. **opencode.json proposal:** `agent_identity` block with provider config
7. **opencode.json proposal:** `graph_memory` block with path + schema

## Files That Need Creation (for code-builder)
- `scripts/agent-identity.js` — ES256 keygen + JWT minting
- `scripts/graph-memory.js` — JSON-LD graph CRUD
- `scripts/graph-query.js` — query helpers
- `skills/authmd-registration/SKILL.md` — discovery + registration skill
- `memory/graph/schema.yaml` — node and edge type definitions
- `memory/graph/nodes/` — node storage directory
- `memory/graph/edges/` — edge storage directory
- `.well-known/auth.md` — expose harness identity to other agents
- `.well-known/jwks.json` — public keys for signature verification

## Files That Need Modification (code-builder)
- `opencode.json` — add `agent_identity` and `graph_memory` blocks
- `agents/main-coordinator.md` — add ID-JAG injection + graph consultation
- `TRIGGERS.md` — T2/T5/T6 write to graph
- `challenger-rule.md` — log overrides to graph
- `update-session-yaml.ps1` — also write decisions to graph nodes

## State Snapshot
- **Sprint:** Current sprint is Phase C (checkpoint, mail, tokens, archive)
- **Config maturity:** Phase C operational. auth.md + Context Graph would be Phase D.
- **Current sprint.md:** Last updated 2026-05-22, Phase C active
- **Handover:** This is a research-to-planning handover. No code written yet.

## Summary for User
auth.md y Context Graphs son las dos piezas que transforman OpenCode de "un asistente que ejecuta tareas" a "un harness agentic completo". auth.md le da credenciales propias a tus agentes para que no te frenen pidiendo API keys. Context Graph conecta toda tu memoria para que los agentes aprendan de decisiones pasadas. Juntos, crean un sistema que mejora solo.

Próximo paso lógico: arrancar con el Context Graph (Track B) porque ya tenés los datos — solo falta conectarlos. El evolution agent puede empezar con los genes y reglas. Después un code-builder implementa los scripts.
