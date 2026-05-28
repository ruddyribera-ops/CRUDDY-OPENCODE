# WIRED_POA — OpenCode Configuration: Gap Closure Plan of Action

**Date:** 2026-05-28  
**Purpose:** Convert the 5.3/10 documented system into a 8+/10 mechanically enforced system.  
**Principle:** If it's documented but not wired, it doesn't work. This POA closes every gap.  

---

## WHAT "WIRED" MEANS

| Before (Documented Only) | After (Mechanically Enforced) |
|--------------------------|-------------------------------|
| `budgets.yaml` defines limits | `track-tokens.ps1 -Action "check"` called before every routing |
| `budgets.yaml` says "enforced by main-coordinator" | Coordinator actually calls the script and REJECTS tasks over budget |
| Hooks `on-stop.ps1`, `post-edit.ps1` exist | OpenCode engine calls them (or PS profile triggers them) |
| T0-T8 lifecycle documented | Scripts fire at the right lifecycle points |
| Challenger Rule documented | Scans EVERY user message before routing |
| Phantom skills in YAML | YAML references only existing skill directories |
| Agent mail system documented | Agents check inbox at task start, send mail on blockers |
| Budget enforcement flow documented | check script reads budgets.yaml, returns go/no-go |

---

## PART 1: WIRED BUDGET ENFORCEMENT

### 1.1 Problem

`budgets.yaml` defines per-session and per-task token limits per agent. The enforcement flow is documented (check → calculate → reject/warn → route). **No code actually calls the check.** The coordinator mentions budgets in system prompt but doesn't mechanically enforce them.

### 1.2 Root Cause

`track-tokens.ps1` has `add` and `report` actions but no `check` action that returns a go/no-go signal. The coordinator would need to call it, parse the output, and make a routing decision — but there's no contract defined for how that works.

### 1.3 Solution

**Step 1:** Extend `track-tokens.ps1` with a `check` action that:
- Reads budgets from `rules/budgets.yaml`
- Reads current usage from `memory/session_log.md` (or `token_budget.yaml`)
- Calculates estimated tokens for the incoming task
- Returns exit code 0 (go) or 1 (reject) with a reason
- Returns also a `soft` vs `hard` signal (warn vs reject based on enforcement mode)

**Step 2:** Update `main-coordinator.md` to call `track-tokens.ps1 -Action check` at every routing, BEFORE calling the specialist.

**Step 3:** Add a budget check section to the coordinator's "Run BEFORE Routing" checklist.

### 1.4 Files to Change

```
scripts/track-tokens.ps1     → ADD "check" action
agents/main-coordinator.md  → ADD budget check to routing flow
memory/session_log.md       → UPDATE format to track per-agent tokens
rules/budgets.yaml         → NO CHANGE (already correct)
```

### 1.5 Implementation

```powershell
# track-tokens.ps1 — ADD this action:
elif ($Action -eq "check") {
    # Reads budgets.yaml for limits
    # Reads session_log.md for current usage
    # Estimates tokens for incoming task
    # Returns: "GO" | "REJECT" | "WARN" with reason
    # Exit code: 0=go, 1=reject, 2=warn
}
```

### 1.6 Verification

```
User: "add a login button"
  → coordinator calls track-tokens.ps1 -Action check -Agent code-builder -Tokens ~2000
  → script returns "GO" (code-builder: 15k used / 50k budget)
  → coordinator routes to code-builder

User: "build me a full auth system from scratch"
  → coordinator calls track-tokens.ps1 -Action check -Agent code-builder -Tokens ~12000
  → script returns "REJECT: per_task hard limit exceeded (12k > 12k)"  
  → coordinator responds: "code-builder budget hit for this task. Defer to next session or reduce scope?"
```

---

## PART 2: PHANTOM SKILL REMOVAL

### 2.1 Problem

9 agent YAMLs reference skills that exist only in `skills/.archive/` not in `skills/` (active). When agents load skills, the loader looks for `skills/<name>/SKILL.md` — archived skills are NOT found. Agents silently operate without the expected skill context.

### 2.2 List of Phantom References

From `OPENCODE_ARCHITECTURE_REPORT.md`:

| Skill | Referenced By | Active? |
|-------|---------------|---------|
| `security-basics` | code-builder, bug-fixer, code-analyzer, architecture-advisor | ❌ archive |
| `cs-fundamentals` | code-analyzer, architecture-advisor, code-explainer | ❌ archive |
| `performance-optimization` | code-builder, bug-fixer, code-analyzer, architecture-advisor | ❌ archive |
| `ui-design` | code-builder, project-generator | ❌ archive |
| `skill-learning` | skill-manager, evolution-agent | ❌ archive |
| `hermes-integration` | skill-manager | ❌ archive (Hermes uninstalled anyway) |
| `hermes-agent` | skill-manager | ❌ archive |
| `progressive-disclosure` | skill-manager | ❌ archive |
| `batch-skill-enrichment` | skill-manager, evolution-agent | ❌ archive |

### 2.3 Solution

**Option A (preferred):** Remove phantom references from agent YAMLs. The skills are archived because they're not actively used — removing references cleans the manifests.

**Option B:** Restore skills from `.archive/` to active `skills/` — but this risks confusing which skills are actually current.

### 2.4 Files to Change

```
agents/code-builder.yaml    → REMOVE security-basics, performance-optimization, ui-design
agents/bug-fixer.yaml       → REMOVE security-basics, performance-optimization
agents/code-analyzer.yaml   → REMOVE security-basics, cs-fundamentals, performance-optimization
agents/architecture-advisor.yaml → REMOVE security-basics, cs-fundamentals, performance-optimization
agents/project-generator.yaml → REMOVE ui-design
agents/code-explainer.yaml  → REMOVE cs-fundamentals
agents/skill-manager.yaml    → REMOVE skill-learning, hermes-integration, hermes-agent, progressive-disclosure, batch-skill-enrichment
agents/evolution-agent.yaml → REMOVE skill-learning, batch-skill-enrichment
```

### 2.5 Verification

```
Run: python scripts/agent-registry.py validate
Before: 9 phantom skill warnings
After: 0 phantom skill warnings
```

---

## PART 3: HOOK WIRING (on-stop.ps1, post-edit.ps1)

### 3.1 Problem

`on-stop.ps1` (session cleanup) and `post-edit.ps1` (auto-test after edits) exist in `scripts/` and are documented in `AGENTS.md` END-OF-TASK CHECKLIST. The OpenCode Go engine does NOT call these hooks — they exist but never fire.

### 3.2 Root Cause

OpenCode's Go engine does not have a plugin/hook system for calling custom PowerShell scripts on events. The hooks were designed assuming engine support that was never implemented.

### 3.3 Solution

**Workaround 1: PowerShell Profile** — Add hook calls to PowerShell profile so they fire on shell startup/exit (partial coverage, not event-driven).

**Workaround 2: Manual calling** — Add hooks to the END-OF-TASK CHECKLIST that the coordinator triggers via `auto-memory.ps1`.

**Workaround 3: Accept limitation** — Document that full hook wiring requires OpenCode engine support. Focus on what CAN be mechanically enforced.

### 3.4 Recommended Approach

For now, wire what we can through the END-OF-TASK CHECKLIST (already enforced by coordinator):

1. `on-stop.ps1` → call from `auto-memory.ps1` at T3 (session end)
2. `post-edit.ps1` → call from coordinator AFTER any file edit task completes

Update `main-coordinator.md` to explicitly call these scripts in the post-task checklist.

### 3.5 Files to Change

```
agents/main-coordinator.md  → ADD hook calls to END-OF-TASK CHECKLIST
scripts/auto-memory.ps1     → ADD on-stop.ps1 call at T3
scripts/post-edit.ps1       → VERIFY script works (exists but untested)
scripts/on-stop.ps1         → VERIFY script works (exists but untested)
```

### 3.6 Verification

```
Task: "add a function to auth.py"
  → code-builder edits auth.py
  → post-edit.ps1 fires, runs pytest on auth.py
  → coordinator sees test result before declaring done
```

---

## PART 4: T4 STATUS HANDLER

### 4.1 Problem

TRIGGERS.md defines T0-T8. `session_machine.ps1` handles T0, T1, T2, T3, T5, T6, T7, T8. **T4 (Status query) is "not implemented".** When a user asks "what's the status?" or "what are we working on?", there's no handler.

### 4.2 Solution

Add T4 handler to `session_machine.ps1`:

```powershell
T4: Status query
  → Read session.yaml for current task
  → Read session_log.md for recent activity
  → Read project_active.md for project states
  → Return concise status to user
```

### 4.3 Files to Change

```
scripts/session_machine.ps1 → ADD T4 handler
memory/TRIGGERS.md           → UPDATE T4 status (currently marked not implemented)
```

---

## PART 5: CREWAI + AGENT FACTORY

### 5.1 Plan

Install CrewAI and create the Dev Agency agent factory per `DEV_AGENCY_INTEGRATION_PLAN.md`.

### 5.2 Steps

**Step 1: Install dependencies**
```powershell
pip install crewai crewai-tools langchain langchain-openai python-dotenv
```

**Step 2: Create lib/agents/ directory**
```
C:\Users\Windows\.config\opencode\lib\agents\
```

**Step 3: Create crew_factory.py** — 6 agents (PM, Backend, Frontend, QA, DevOps, Coordinator) with task delegation workflow.

**Step 4: Create lib/workflows/langgraph_coordinator.py** — DAG with conditional edges (test gate, approval gate, retry loop).

**Step 5: Test with one real PRIA feature** — end-to-end from spec to deploy.

### 5.3 Files to Create

```
lib/agents/crew_factory.py              # Agent factory + DevAgency class
lib/workflows/langgraph_coordinator.py # LangGraph workflow
lib/workflows/requirements.txt          # CrewAI + LangGraph deps
scripts/crew_start.ps1                  # Launcher script
```

### 5.4 Verification

```
Run: python lib/agents/crew_factory.py
Output: 6 agents initialized, ready to execute
Test: "Add dark mode to PRIA" → PM spec → Backend+Frontend → QA → DevOps deploy
```

---

## PART 6: KG QUEUE FLUSH

### 6.1 Problem

KG queue (`memory/kg_queue.json`) has stale entries — entities that failed to write because the MCP memory server (localhost:6274) was unreachable. Failed writes are lost, not retried.

### 6.2 Solution

Add retry/flush logic to `auto-memory.ps1`:
- On every T2 (task complete), attempt to flush kg_queue.json
- If MCP write succeeds → clear queue
- If fails → keep queue, retry next T2
- Log failures to `memory/kg-errors.log`

### 6.3 Files to Change

```
scripts/auto-memory.ps1    → ADD KG queue flush attempt at T2
memory/kg_queue.json      → MONITOR for staleness
memory/kg-errors.log      → CREATE if not exists
```

---

## PART 7: SESSION LOG FORMAT CLEANUP

### 7.1 Problem

Historical session_log.md entries (May 25, May 27) have 1-line-per-paragraph formatting — blank lines between every line. Caused by old buggy PS script runs. Makes the log harder to read.

### 7.2 Solution

Run cleanup pass on session_log.md to normalize formatting.

### 7.3 Files to Change

```
memory/session_log.md  → CLEANUP historical sections (lines 1-400)
```

---

## SUMMARY: ALL ACTIONS BY OWNERSHIP

| # | Action | Owner | Effort | Priority |
|---|--------|-------|--------|----------|
| 1 | **Wire budget enforcement** — add `check` action to track-tokens.ps1 + update coordinator | coordinator | 2-3h | 🔴 HIGH |
| 2 | **Remove phantom skills** from 8 agent YAMLs | coordinator | 30min | 🔴 HIGH |
| 3 | **Install CrewAI + create agent factory** | coordinator | 3-4h | 🔴 HIGH |
| 4 | **Wire hooks** (on-stop → auto-memory T3, post-edit → coordinator checklist) | coordinator | 1h | 🟡 MED |
| 5 | **Add T4 handler** to session_machine.ps1 | coordinator | 1h | 🟡 MED |
| 6 | **KG queue flush** retry logic in auto-memory.ps1 | coordinator | 2h | 🟡 MED |
| 7 | **Session log cleanup** (historical formatting) | coordinator | 30min | 🟢 LOW |

---

## WIRED_CRITERIA — How We Know It's Done

For each gap, define the verification:

| Gap | Verification |
|-----|-------------|
| Budget enforcement | Run `track-tokens.ps1 -Action check -Agent code-builder -Tokens 5000` → returns GO/REJECT. Test: route a task, verify script is called. |
| Phantom skills | `python scripts/agent-registry.py validate` → 0 phantom warnings |
| Hook wiring | After code-builder edits a file → post-edit.ps1 runs → coordinator sees output |
| T4 handler | `session_machine.ps1 -Trigger T4` → returns session status |
| KG queue | `memory/kg_queue.json` → empty after normal operation |
| CrewAI | `python lib/agents/crew_factory.py` → 6 agents initialized |
| Session log | `session_log.md` → clean table format (no extra blank lines) |

---

## TIMELINE

```
Day 1 (Today):
  ✅ Create this WIRED_POA.md
  ⏳ Wire budget enforcement (2-3h)
  ⏳ Remove phantom skills (30min)

Day 2:
  ⏳ Install CrewAI + create agent factory (3-4h)
  ⏳ Wire hooks (1h)

Day 3:
  ⏳ Add T4 handler (1h)
  ⏳ KG queue flush (2h)

Day 4:
  ⏳ Test end-to-end all wired systems
  ⏳ Session log cleanup (30min)

Result: OpenCode goes from 5.3/10 → 8+/10 mechanically enforced
```

---

## EXECUTE ORDER

Start with the items that give the most immediate confidence:

1. **Budget enforcement** — if this works, the system is spending tokens wisely
2. **Phantom skill removal** — clean manifests, no silent failures  
3. **CrewAI + factory** — enables the actual multi-agent Dev Agency vision

Everything else is polish. These three unlock the core value.

---

*Created: 2026-05-28*  
*Status: READY TO EXECUTE*  
*Next action: Wire budget enforcement — add `check` action to track-tokens.ps1*