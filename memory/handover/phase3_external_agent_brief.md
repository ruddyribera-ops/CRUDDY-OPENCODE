You are a deepseek-v4-flash agent in a parallel opencode session.
Your job: complete Phase 3 of the auth.md + Context Graph initiative for
this user's opencode configuration.

# CONTEXT (read fully before doing anything)

The user watched two talks and asked the main-coordinator to apply both to
their opencode config. A code-builder agent already implemented the
infrastructure (Phase 1 + Phase 2). Your job is the integration step
(Phase 3) — modify the existing markdown/powerShell files to USE the
new scripts.

## The two concepts

**1. auth.md (WorkOS, IETF draft 04)**: Open protocol for agent
registration. An agent provider (us = main-coordinator) mints an ID-JAG
(signed JWT) for a sub-agent. The sub-agent presents the ID-JAG to
external services (Cloudflare, Firecrawl, Resend) to register and get
API keys automatically — no human form-filling.

**2. Context Graph (Neo4j)**: Replace flat memory files with a graph
where nodes (sessions, tasks, decisions, lessons, projects) are
connected by edges (touches, makes, discovers, completes, triggers).
Better querying, self-learning from precedent.

# CURRENT STATE (Phase 1 + 2 complete and audited)

## Infrastructure that already works
- `scripts/agent-identity.js` — ES256 keygen + ID-JAG minting + JWKS export
  - CLI: `node agent-identity.js init|mint|jwks`
  - `mint` requires `--sub` and `--task-id` (bug fix from audit, no silent defaults)
- `scripts/graph-memory.js` — JSON-LD file-based graph CRUD
  - CLI: `node graph-memory.js create-node|get-node|create-edge|query`
  - Nodes go to `memory/graph/nodes/{type}-{timestamp}-{shortid}.jsonld`
  - Edges go to `memory/graph/edges/{source}->{target}::{relationship}.jsonld`
- `scripts/graph-query.js` — semantic query wrappers
  - CLI: `node graph-query.js past-decisions|lessons|blockers|session`
  - Flags: `--domain`, `--days`, `--keywords`, `--project`, `--limit`
- `skills/authmd-registration/SKILL.md` — discovery + ID-JAG presentation
- `memory/graph/schema.yaml` — 5 node types, 5 edge types defined

## Config that already exists
- `opencode.json` lines 170-200: `agent_identity` + `graph_memory` blocks
- `skills/DNA.yaml` lines 292-321: 3 new genes
  - `COORD-004` inject_agent_identity (triggers: dispatch, route, task, etc.)
  - `COORD-005` consult_context_graph (triggers: route, moderate, complex)
  - `TRIGGER-002` write_decisions_to_graph (triggers: t2, t5, t6)

## Audit results (all green)
- 16/16 files exist with content
- All CLI commands work (init, mint, jwks, create-node, query, create-edge, etc.)
- Bug found: `mint` used silent defaults — fixed (now requires explicit flags)
- Zod validation: 24/24 tests passing
- opencode boots without errors
- Graph is empty (audit cleaned test data)

# YOUR MISSION — PHASE 3 (3 file modifications)

## Modification 1: TRIGGERS.md

**File:** `C:\Users\Windows\.config\opencode\TRIGGERS.md`

**Goal:** T2, T5, T6 triggers should ALSO write to the context graph
in addition to the existing flat-file writes. Fire-and-forget — never
block task flow on graph writes. Graceful fallback if
`scripts/graph-memory.js` doesn't exist.

### Specific changes:

**In T2 section (around lines 65-100), add a new mechanical action after
the existing ones (between step 5 and step 6).** The new step should be:

```markdown
6. **Write to context graph (fire-and-forget):** 
   `node scripts/graph-memory.js create-node --type task --id {task_id} --props {"description":"{desc}","agent":"{agent}","result":"{summary}","timestamp":"{iso}"}`
   Then create edge: `node scripts/graph-memory.js create-edge --from Session-{current_session} --to Task-{task_id} --relationship completes`
   Wrap in PowerShell: `try { node scripts/graph-memory.js create-node ... } catch { }` — never fail the task on graph error.
```

**In T5 section (Lesson discovered), add similar graph writes:**

```markdown
4. **Write to context graph:** 
   `node scripts/graph-memory.js create-node --type lesson --id Lesson-{shortid} --props {"title":"{title}","category":"{cat}","correct_approach":"{approach}"}`
   Create edge: `create-edge --from Session-{current} --to Lesson-{id} --relationship discovers`
   Fire-and-forget.
```

**In T6 section (Decision made), add similar graph writes:**

```markdown
3. **Write to context graph:**
   `node scripts/graph-memory.js create-node --type decision --id Decision-{shortid} --props {"context":"{ctx}","choice":"{choice}","rationale":"{why}","timestamp":"{iso}"}`
   Create edge: `create-edge --from Session-{current} --to Decision-{id} --relationship makes`
   If user override happened: also `create-edge --from Decision-{id} --to RuleChallenge-{pattern} --relationship overrides`
   Fire-and-forget.
```

**T1 (Session START) should also create a graph node:**

```markdown
9. **Create session node in context graph:**
   `node scripts/graph-memory.js create-node --type session --id Session-{session_name} --props {"name":"{name}","start_time":"{iso}","purpose":"{purpose}"}`
   Create edges: `create-edge --from Session-{name} --to Project-{project_id} --relationship touches` (one per project)
```

**Important:** Use PowerShell `try { } catch { }` or shell `|| true`
to make all graph writes non-blocking. Add a comment: "Graph write
failure must never fail a task."

## Modification 2: rules/challenger-rule.md

**File:** `C:\Users\Windows\.config\opencode\rules\challenger-rule.md`

**Goal:** When user overrides a Challenger Rule, log it as a graph edge
linking the decision to the rule pattern that was overridden.

### Specific change:

In the "T6 — Decision made" section (look for "Challenger Rule
Override" subsection, around line 224 in TRIGGERS.md but the rule file
has its own version), add this step after the override is logged in
session.yaml:

```markdown
**Graph write on override:**
If the user overrides a Challenger Rule challenge, also write to context graph:
`node scripts/graph-memory.js create-node --type rule_challenge --id RuleChallenge-{pattern}-{timestamp} --props {"pattern":"{risky_pattern}","user_response":"{proceed}","timestamp":"{iso}"}`
Then: `create-edge --from Decision-{decision_id} --to RuleChallenge-{pattern}-{timestamp} --relationship overrides`
This builds an audit trail in the graph.
```

## Modification 3: agents/main-coordinator.md

**File:** `C:\Users\Windows\.config\opencode\agents\main-coordinator.md`

**Goal:** The coordinator should:
1. Inject ID-JAG into the handover when dispatching a sub-agent (gene COORD-004)
2. Consult the context graph before routing Moderate+ tasks (gene COORD-005)

### Specific changes:

**1. Add ID-JAG injection step in the routing table (around line 437-453
where the routing table lives).** Before each `task` tool call, add:

```markdown
**BEFORE dispatching to a sub-agent, inject ID-JAG identity:**

```powershell
$idjag = node scripts/agent-identity.js mint --sub {agent_name} --task-id {task_id} --audience "{service_or_default_to_opencode_self}" --user-email "{user_email_or_anonymous}" 2>$null
if ($idjag) {
  # Append to the sub-agent's prompt:
  $handover += @"

=== AGENT IDENTITY (ID-JAG) ===
Token: $idjag
Provider: main-coordinator
Signed: {current_time}
TTL: 5min
Use this identity to register with auth.md-compatible services
(Cloudflare, Firecrawl, Resend, etc.) without a human form.
JWKS for verification: file://.well-known/jwks.json
==============================
"@
}
```

**2. Add graph consultation step BEFORE routing Moderate+ tasks
(score 4+).** In the Discovery Gate or the routing logic section,
add:

```markdown
**BEFORE routing Moderate+ tasks (score 4+), consult context graph:**

```powershell
$graph_context = node scripts/graph-query.js past-decisions --days 7 --limit 5 2>$null
if ($graph_context) {
  # Append to handover:
  $handover += @"

=== GRAPH CONTEXT (past decisions, last 7 days) ===
$graph_context
==================================================
"@
}
$graph_lessons = node scripts/graph-query.js lessons --keywords "{task_keywords}" --limit 3 2>$null
if ($graph_lessons) {
  $handover += @"

=== GRAPH LESSONS (matching keywords) ===
$graph_lessons
====================================
"@
}
```

**3. Wrap both in `try { } catch { }` — never fail routing on graph/identity errors.**

# ACCEPTANCE CRITERIA

Phase 3 is done when ALL of the following are true:

1. **TRIGGERS.md modified:**
   - T1 has a step 9 that creates a session graph node
   - T2 has a new step 6 that writes task to graph (with edge)
   - T5 has a step 4 that writes lesson to graph (with edge)
   - T6 has a step 3 that writes decision to graph (with edge, including override edge)
   - All graph writes use `try { } catch { }` or `|| true`

2. **challenger-rule.md modified:**
   - Has a "Graph write on override" block
   - Documents RuleChallenge node creation + decision→override edge

3. **main-coordinator.md modified:**
   - Routing table includes ID-JAG injection step
   - Routing logic includes graph consultation step
   - Both wrapped in error handling

4. **Smoke test (run after modifications):**
   - `node scripts/graph-memory.js create-node --type session --id Session-test-20260601 --props '{"name":"test"}'`
   - `node scripts/graph-memory.js create-node --type decision --id Decision-test --props '{"context":"test","choice":"x"}'`
   - `node scripts/graph-memory.js create-edge --from Session-test-20260601 --to Decision-test --relationship makes`
   - `node scripts/graph-query.js past-decisions` → returns 1 result
   - Files appear in `memory/graph/nodes/` and `memory/graph/edges/`
   - No errors in opencode boot

5. **No regressions:**
   - 24/24 zod tests still pass
   - All existing flat-file writes still work
   - No new `except: pass` or silent failures (see Challenger Rule)

# CONSTRAINTS

- **Never use silent `try { } catch { }` without a comment explaining
  what failure mode is being ignored.** Graph writes can fail silently
  because they're advisory, but the code must be commented to say so.
- **All modifications are markdown/yaml additions.** No new code scripts
  needed — the scripts already exist.
- **Match the existing style** of each file (indentation, heading
  depth, terminology).
- **Don't break anything.** If a file is using a pattern you don't
  recognize, read more context first.
- **The user is Spanish-first** but the codebase is English. Write
  new content in English to match the codebase.

# REPORTS

When done, report:
1. Which files were modified (with line numbers)
2. The smoke test result (paste the actual output of the commands)
3. Any deviations from the spec and why
4. What wasn't done and why (if anything)

If you hit a blocker, write it to `memory/handover/blocker_phase3.md`
and report. Do not silently skip.
