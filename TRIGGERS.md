# TRIGGERS Ã¢â‚¬â€ Mandatory Session Lifecycle Protocol

**Version:** 2.0 Ã¢â‚¬â€ Phase C (checkpoint, mail, sprint stamp, tokens, archive)
**Effective:** 2026-05-27
**Applies to:** main-coordinator (primary), all sub-agents (secondary)
**Enforcement:** These triggers fire automatically. No exceptions without user override.

---

## T1 Ã¢â‚¬â€ Session START (Fires: when any session starts)

### What to do Ã¢â‚¬â€ IN ORDER:
1. **Check for checkpoint:** `Test-Path memory/checkpoint.yaml` → if exists, offer resume prompt: "Ã°Å¸Å¡Â§ Checkpoint found from [date]. Resume step X/Y? (yes/no)"
2. **Load `handover/latest.md`** → parse context, pending items, state snapshot
3. **Load `session.yaml`** → if exists and has tasks → offer resume prompt
4. **Load `project_active.md`** → current project state for mentioned projects
5. **Search knowledge graph** → most recent session entity for each project
5.5. **Auto-summarize past context (graph):**
    `node "$CONFIG\scripts\auto-summary.js" --project "{current_project}" --days 30 --max-tokens 2000`
    → inject result as `auto_summary` field in session.yaml
    → fire-and-forget: skip on error, never block session start
6. **Reset token budget** → `powershell scripts/track-tokens.ps1 -Action "reset"`
7. **Create session entity in knowledge graph:**
   ```js
   entityName: "{project[-branch][-intent]}"  // format: NO date prefix, NO Session- prefix
   entityType: "session"
   observations: [
     "date: {YYYY-MM-DD}",
     "session_name: {descriptive-name}",  // e.g. "myapp-feat", "api-debug-auth"
     "projects_touched: [{projects}]",
     "purpose: {what-we're-doing}",
     "status: in_progress"
   ]
   ```
6. **Create or update `session.yaml`:**
   ```yaml
   session_name: "{descriptive-name}"
   started: "{ISO datetime}"
   projects_touched: [{name, dir, branch, git_sha}]
   tasks: []
   decisions: []
   lessons: []
   blockers: []
   files_changed: []
   state: {key: value}
   next_steps: []
   ```
7. **Wire relations:**
   ```
   Session → touches → Project
   ```
8. **Present to user (DESCRIPTIVE Ã¢â‚¬â€ for OpenCode auto-naming):**
   ```
   Session: {descriptive name} Ã¢â‚¬â€ {project}
   Context: {what we're doing, max 1 line}
   State: {pending items if resuming, or "fresh start"}
   ```
   This MUST be at least 2-3 lines. OpenCode uses the first exchange to auto-name the session. A compressed "Resuming." gives no signal → timestamp session name.

9. **Create session node in context graph (fire-and-forget):**
   Create a graph node representing this session. Graph writes are advisory -- failure must never block session start.
   `powershell
   # Graph write is fire-and-forget -- session start must never block on graph errors
   try {
     $sessionNode = & node "$CONFIG\scripts\graph-memory.js" create-node --type session --name "Session-$session_name" 2>$null
     if ($sessionNode) {
       Write-Host "Session graph node created: $sessionNode"
       # Create edges to each touched project
       foreach ($proj in $projects_touched) {
         & node "$CONFIG\scripts\graph-memory.js" create-edge --from "$sessionNode" --to "Project-$($proj.name)" --relationship touches 2>$null
       }
     }
   } catch {
     # Graph write failure is non-blocking -- session starts regardless
   }
   `
### Skip if:
- No handover/latest.md exists → start fresh, note "No prior handover"
- User says "fresh start" → skip handover load, start clean

---

## T2 [UPDATED 2026-06-03: Use t2-complete.ps1] Ã¢â‚¬â€ Task COMPLETES (Fires: every time ANY agent returns a result)

### Compliance Checklist (3 mandatory questions):

| # | Question | If YES → Action | If NO → |
|---|----------|----------------|---------|
| 1 | **Lesson?** Was there something unexpected? | Write to `lessons_learned.md` + create KG Lesson entity + notify user | Skip |
| 2 | **Decision?** Did we choose something that matters? | Append to `session.yaml` decisions + create KG Decision entity | Skip |
| 3 | **State change?** Did project state change? | Update `project_active.md` + update KG Project entity + notify user | Skip |

### Mechanical actions (ALWAYS):
1. **Append to `session_log.md`:**
   ```markdown
   | {task description} | {agent} | {emoji result} | ~{tokens} |
   ```
   Script: `powershell scripts/append-session-log.ps1 -TaskName "..." -Agent "..." -Result "..." -TokensEst "~N"`
2. **Append to `session.yaml` tasks:**
   ```yaml
   - id: {next}
     description: "{task}"
     agent: "{agent}"
     files: ["{file1}", "{file2}"]
     status: completed
     tokens_est: {N}
     duration_min: {N}
     result: "{summary}"
   ```
   Script: `powershell scripts/update-session-yaml.ps1 -Action "add-task" -TaskDescription "..." -Agent "..." -Result "..."`
3. **Track tokens (C4):** `powershell scripts/track-tokens.ps1 -Action "add" -Agent "{agent}" -Tokens {N}`
4. **Stamp sprint (C3):** `powershell scripts/stamp-sprint.ps1 -TaskDescription "{short summary}"`
5. **Update session entity in knowledge graph** → append observation: `"task_N_completed: {description}"`
6. **Update `session.yaml` state + next_steps** if changed
7. **Save checkpoint if multi-step (C2):** If this task is part of a POA with remaining steps → `powershell scripts/save-checkpoint.ps1 -TaskId "{N}" -TaskDescription "..." -CurrentStep {X} -TotalSteps {Y}"
8. **Write to context graph (fire-and-forget):**
   Record task completion as a graph node with edge to session. Graph writes are advisory -- failure must never block task flow.
   `powershell
   # Graph write is fire-and-forget -- task completion must never block on graph errors
   try {
     $taskNode = & node "$CONFIG\scripts\graph-memory.js" create-node --type task --name "Task-$task_id" 2>$null
     if ($taskNode -and $session_name) {
       & node "$CONFIG\scripts\graph-memory.js" create-edge --from "Session-$session_name" --to "$taskNode" --relationship completes 2>$null
     }
   } catch {
     # Graph write failure is non-blocking -- task flow continues regardless
   }
   `
### Notification Rules:
| Event | Notify? | Format |
|-------|---------|--------|
| Lesson learned | Ã¢Å“â€¦ | `Ã°Å¸â€œÂ Saved lesson: [one-liner]` |
| State change | Ã¢Å“â€¦ | `Ã°Å¸â€œÂ¦ Project updated: [what changed]` |
| Decision recorded | Ã¢ÂÅ’ | Silent |
| session_log append | Ã¢ÂÅ’ | Silent |
| KG update | Ã¢ÂÅ’ | Silent |

---

## T3 Ã¢â‚¬â€ Session END (Fires: user signs off, 30+ min idle, project switch, error/crash)

### What to do Ã¢â‚¬â€ IN ORDER:
1. **Auto-archive old handovers (C5):** `powershell scripts/archive-handovers.ps1 -MaxAgeDays 7`
2. **Token budget report (C4):** `powershell scripts/track-tokens.ps1 -Action "report"` → include in notification
3. **Write `handover/latest.md`:**
   ```markdown
   # Handover: {YYYY-MM-DD} Ã¢â‚¬â€ {Session Name}
   
   ## Context
   {what we were doing, why}
   
   ## What Was Done
   {numbered list of completed tasks}
   
   ## What's Pending
   {numbered list of pending items with Ã¢Â¬Å“}
   
   ## Key Decisions
   {bullet list}
   
   ## Open Questions
   {bullet list}
   
   ## Files Changed/Created
   {bullet list}
   
   ## State Snapshot
   - {key metrics}
   
   ## Knowledge Graph Entities
   {list of entities created/updated}
   ```
   Script: `powershell scripts/write-handover.ps1`
4. **Archive old handover** → move to `handover/archive/handover-{previous-date}.md`
5. **Update `project_active.md`** → reflect current state
6. **Stamp `current_sprint.md`** → `powershell scripts/stamp-sprint.ps1 -TaskDescription "{session summary}" -SessionEnd`
7. **Finalize session entity in KG** → `status: completed`
8. **Append session summary to `session_log.md`** → totals row
9. **Notify user:** "Ã°Å¸â€œâ€¹ Handover saved. [token report]. Pending: [summary]. See you next time."
10. **Clear `session.yaml`** → state is now in handover (keep as reference, reset tasks)

### Interim handover (30+ min idle / project switch):
Same as full handover but shorter. Prefix title with `[INTERIM]`.

### Crash/error handover:
Write minimal: what was happening, what failed, last known good state.

---

## T4 Ã¢â‚¬â€ User asks "Status" / "What's going on" / "QuÃƒÂ© hicimos"

### What to do:
1. Read `session.yaml` → current tasks, state
2. Read `handover/latest.md` → context if session just started
3. Read `project_active.md` → project state
4. Search KG for recent session entities

### Output format:
```
Ã°Å¸â€œâ€¹ Current: {session name}
Ã¢ÂÂ± Started: {time} ({duration} ago)
Ã¢Å“â€¦ Done: {N}/{M} tasks
   - {task 1} Ã¢Å“â€¦
   - {task 2} Ã¢Å“â€¦
Ã¢Â¬Å“ Pending:
   - {pending 1}
   - {pending 2}
Ã°Å¸â€œÂ Decisions: {bullet}
Ã¢Å¡Â Ã¯Â¸Â Blockers: {bullet or None}
Ã°Å¸â€œÅ  {Metrics}
```

---

## T5 Ã¢â‚¬â€ Lesson discovered (Fires: on unexpected behavior, user correction, non-obvious fix)

### What to do Ã¢â‚¬â€ BOTH simultaneously:

1. **Append to `lessons_learned.md`:**
   ```markdown
   ## [YYYY-MM-DD] {Brief title}
   
   **Context:** {what were we doing}
   **What happened:** {what went wrong / what we learned}
   **Lesson:** {what to do differently}
   **Applied:** {YES/NO}
   **Category:** {shell|fastapi|deploy|rosariosis|architecture|workflow|security|bug}
   ```
2. **Create KG entity:**
   ```js
   entityName: "Lesson-{short-hyphenated-name}"
   entityType: "lesson"
   observations: ["date:", "what_happened:", "correct_approach:", "category:", "applied:"]
   ```
3. **Wire relation:** `Current-Session → discovers → Lesson-{name}`
4. **Notify user:** `Ã°Å¸â€œÂ Saved lesson: [one-liner]`
5. **Write lesson to context graph (fire-and-forget):**
   Record lesson as a graph node with edge to session. Graph writes are advisory.
   `powershell
   # Graph write is fire-and-forget -- lesson logging must never block
   try {
     $lessonNode = & node "$CONFIG\scripts\graph-memory.js" create-node --type lesson --name "Lesson-$lesson_id" 2>$null
     if ($lessonNode -and $session_name) {
       & node "$CONFIG\scripts\graph-memory.js" create-edge --from "Session-$session_name" --to "$lessonNode" --relationship discovers 2>$null
     }
   } catch {
     # Graph write failure is non-blocking -- lesson is already saved to flat files
   }
   `
## T6 Ã¢â‚¬â€ Decision made (Fires: on architectural/design choices, AND Challenger Rule overrides)

### What to do:
1. **Append to `session.yaml` decisions:**
   ```yaml
   decisions:
     - "{context} → {decision} (alternatives: {alt}, rationale: {why})"
   ```
2. **Create KG entity:**
   ```js
   entityName: "Decision-{short-hyphenated-name}"
   entityType: "decision"
   observations: ["date:", "context:", "decision:", "alternatives:", "rationale:"]
   ```
3. **Wire relation:** `Current-Session → makes → Decision-{name}`
4. **Silent** Ã¢â‚¬â€ no user notification unless significant
5. **Write decision to context graph (fire-and-forget):**
   Record decision as a graph node with edge to session. Graph writes are advisory.
   `powershell
   # Graph write is fire-and-forget -- decision logging must never block
   try {
     $decisionNode = & node "$CONFIG\scripts\graph-memory.js" create-node --type decision --name "Decision-$decision_id" 2>$null
     if ($decisionNode -and $session_name) {
       & node "$CONFIG\scripts\graph-memory.js" create-edge --from "Session-$session_name" --to "$decisionNode" --relationship makes 2>$null
     }
   } catch {
     # Graph write failure is non-blocking -- decision is already saved to session.yaml
   }
   `
### Challenger Rule Override Ã¢â‚¬â€ Special Decision Type
When user overrides a Challenger Rule challenge ("yes, proceed" or "override"), this is logged as a T6 decision with special prefix:

```powershell
& "$CONFIG/scripts/session_machine.ps1" -Trigger T6 `
  -Decision "Challenger-Override: {pattern}" `
  -DecisionContext "{risky pattern} Ã¢â‚¬â€ user insisted" `
  -Rationale "{risk accepted at timestamp}. Alternative: {correct approach}."
```

**Mandatory for every override.** No exceptions. Audit trail in `session.yaml` + lessons_learned if incident occurs.

**Graph write on override (fire-and-forget):**
Also log the override as a RuleChallenge node in the context graph with edge to the decision.
`powershell
# Graph write is fire-and-forget -- override audit trail is already in session.yaml
try {
  $challengeNode = & node "$CONFIG\scripts\graph-memory.js" create-node --type rule_challenge --name "RuleChallenge-$override_pattern" 2>$null
  if ($challengeNode -and $decision_id) {
    & node "$CONFIG\scripts\graph-memory.js" create-edge --from "Decision-$decision_id" --to "$challengeNode" --relationship overrides 2>$null
  }
} catch {
  # Graph write failure is non-blocking -- override is already logged in session.yaml
}
`
## T7 Ã¢â‚¬â€ State change (Fires: project state, deploy status, test count changes)

### What to do:
1. **Update `project_active.md`** → edit entry for affected project
2. **Update KG project entity** → add observation with new state
3. **Notify user:** `Ã°Å¸â€œÂ¦ Updated project state: {what changed}`

---

## T8 Ã¢â‚¬â€ Mail between agents (Fires: cross-domain issue found)

### Command:
```powershell
python $CONFIG/scripts/mail.py send {agent-name} -s "{subject}" -b "{message}"
python $CONFIG/scripts/mail.py inbox [{agent}]    # Check mailbox
python $CONFIG/scripts/mail.py read {msg-id}       # Read + mark read
python $CONFIG/scripts/mail.py clear [{agent}]      # Clear mailbox
```

### Challenger Rule Ã¢â‚¬â€ Audit Trail (MANDATORY)

Every time the user says "yes, proceed anyway" or "override" to a Challenger Rule challenge, the coordinator MUST log this as a decision:

```powershell
# After user override confirmation:
& "$scriptsDir/session_machine.ps1" -Trigger T6 `
  -Decision "Challenger-Override: [pattern]" `
  -DecisionContext "[the risky pattern the user insisted on]" `
  -Rationale "User confirmed override at [timestamp]. Risk accepted."
```

Example:
- User says "use md5 for passwords" → Challenger Rule fires → user says "yes, proceed"
- Coordinator logs: `Challenger-Override: md5-password-hashing Ã¢â‚¬â€ User confirmed override 2026-05-27. Risk: bcrypt is required for passwords.`

**This is non-negotiable.** The audit trail lives in `session.yaml` decisions and in `lessons_learned.md` if the override leads to a incident.

**Graph write on override (fire-and-forget):**
Also log to context graph for queryable audit trail.
`powershell
# Graph write is fire-and-forget -- non-blocking
try {
  $challengeNode = & node "$CONFIG\scripts\graph-memory.js" create-node --type rule_challenge --name "RuleChallenge-$override_pattern" 2>$null
  if ($challengeNode -and $decision_id) {
    & node "$CONFIG\scripts\graph-memory.js" create-edge --from "Decision-$decision_id" --to "$challengeNode" --relationship overrides 2>$null
  }
} catch {
  # Non-blocking -- override is already logged in session.yaml
}
`
### Mail Decision Tree:

**When does an agent mail another?**
```
Specialist completes task
  Ã¢â€Å“Ã¢â€â‚¬ Found security smell (plaintext password, SQL injection, etc.)
  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬→ Mail to code-analyzer: "Security issue in [file]: [details]"
  Ã¢â€Å“Ã¢â€â‚¬ Found architectural issue (wrong pattern, scalability concern)
  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬→ Mail to architecture-advisor: "Architecture concern in [area]: [details]"
  Ã¢â€Å“Ã¢â€â‚¬ Found cross-domain bug (frontend issue while working backend)
  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬→ Mail to appropriate specialist: "Cross-domain issue in [file]: [details]"
  Ã¢â€Å“Ã¢â€â‚¬ Is blocked (missing API key, unclear requirement, external dependency down)
  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬→ Mail to main-coordinator: "BLOCKED on [reason]"
  Ã¢â€Å“Ã¢â€â‚¬ Discovered something another agent should handle later
  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬→ Mail to that agent: "FYI: [details]"
  Ã¢â€â€Ã¢â€â‚¬ Everything clean → No mail needed
```

### Check mail at task start (MANDATORY):
```powershell
python $CONFIG/scripts/mail.py inbox
```
Process unread messages BEFORE starting new work. If unread mail exists, summarize to user:
"Ã°Å¸â€œÂ¬ {N} unread messages. [subject list]. Process now?"

### Mail persistence:
- Mail survives crashes, restarts, context resets
- NOT real-time Ã¢â‚¬â€ recipient reads on next task start
- Max 50 unread per mailbox before auto-clear oldest

---


---

## T9 — Bash Hook Wrapper (Fires: before any destructive bash command)

### What to do:
1. **Wrap destructive commands** with `powershell scripts/hook-wrapper.ps1 "<command>"` before execution
2. **Patterns intercepted:** rm -rf, git push --force, git reset --hard, git clean -fd, Format-Volume, Clear-Disk, dd of=/dev/, Invoke-Expression
3. **Behavior:** warning + Y/N confirmation (default N)
4. **Skip if:** user has typed 'yes proceed' or 'override' in same message

### Examples:
```powershell
# Safe command — no match, exit 0
powershell scripts/hook-wrapper.ps1 "ls -la"
# → no prompt, command proceeds

# Destructive — match, prompt
powershell scripts/hook-wrapper.ps1 "rm -rf /tmp/test"
# → WARNING + [y/N] prompt, default N (block)
```

---

## ENFORCEMENT

These triggers override all other behavior. If a task completes and triggers T2 do not fire, that's a bug in the coordinator.

**Session start sequence (MANDATORY):**
```
1. Load TRIGGERS.md Ã¢â€ Â this file
2. Run T1 (session start protocol)
3. Present to user
4. Accept tasks
5. For each task → execute → run T2 (task complete protocol)
6. On end → run T3 (session end protocol)
```

**User override:** If user says "skip triggers" or "don't log this" → respect it silently.







