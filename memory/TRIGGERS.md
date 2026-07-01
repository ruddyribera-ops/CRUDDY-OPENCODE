# Session Triggers — T1 through T8

**Purpose:** Enforced session lifecycle protocol. Runs at every session boundary.

## Trigger Reference

| Trigger | When | Script | What |
|---------|------|--------|------|
| **T1** | Session start | `hook-startup.ps1` | Init session state, check for resume, surface previous errors |
| **T2** | Task completion | `append-session-log.ps1` | Append task entry to session_log.md |
| **T3** | Session end | `write-handover.ps1` + `stamp-sprint.ps1` | Write handover/latest.md, archive, stamp sprint |
| **T4** | Status query | (manual) | Aggregate: tasks/decisions/blockers |
| **T5** | Lesson learned | (manual) | Write lessons_learned.md + KG node + notify |
| **T6** | Decision made | `update-session-yaml.ps1` | Append to decisions in session.yaml + KG |
| **T7** | State change | `update-session-yaml.ps1` | Update project_active.md + KG + notify |
| **T8** | Error detected | `hook-startup.ps1` | Log to session log + KG |

## T1 — Session Start

```powershell
powershell -File $CONFIG/scripts/hook-startup.ps1
```

Fires on every session start:
1. Creates/refreshes `memory/session.yaml` (session_name, project, started_at)
2. Checks for checkpoint file — offers resume if found
3. Surfaces previous hook errors to user
4. Logs `NEW SESSION` to session_log

## T2 — Task Completion

```powershell
powershell -File $CONFIG/scripts/append-session-log.ps1 -TaskName "<name>" -Agent "<agent>" -Result "<result>" -TokensEst "~N"
```

Appends to `memory/session_log.md`:
- Task name, agent used, result, estimated tokens
- Used for sprint history and audit trail

## T3 — Session End

```powershell
powershell -File $CONFIG/scripts/write-handover.ps1
powershell -File $CONFIG/scripts/stamp-sprint.ps1 -TaskDescription "<desc>" -SprintPath "<project>/.opencode/memory/current_sprint.md"
```

Fires on session idle/error:
1. Writes handover/latest.md from session.yaml
2. Archives to handover/archive/YYYY-MM-DD-{session}.md
3. Stamps sprint progress
4. Finalizes KG queue (flushes pending nodes)
5. Logs `SESSION IDLE` or `SESSION ERROR`

## T4 — Status Query (On Demand)

Aggregates current session state — tasks done, decisions made, blockers:
```powershell
# Manual — read session.yaml + session_log for current sprint
```

## T5 — Lesson Learned

When user corrects approach or error resolved non-obviously:
1. Append ONE line to `memory/lessons_learned.md`
2. Write KG node (type: lesson, name: {topic}, data: {what happened})
3. If blocking issue resolved: send mail to relevant agent

Format: `YYYY-MM-DD | {topic} | {what was wrong} → {what fixed it}`

## T6 — Decision Made

Append to session.yaml decisions array:
```powershell
powershell -File $CONFIG/scripts/update-session-yaml.ps1 -Decision "<text>"
```

Writes to KG: Decision node + relation to project

## T7 — State Change

When project state changes (version bump, deploy, new issue):
1. Update `memory/project_active.md`
2. Write KG node (type: state_change, name: {change})
3. Notify relevant agents via mail if applicable

## T8 — Error Detected

Log error to session_log + KG:
- Write KG Error node with error message + stack
- Link to relevant Decision/Task nodes

---

## Auto-Fired (No Manual Call Needed)

- **Gate counter** → `gate-system.js` plugin fires every 3 bash commands
- **Post-edit** → `post-edit.ps1` fires after file edits
- **Auto-memory** → `gate-system.js` flushes every 3 tasks

## Notes

- All scripts are fire-and-forget (non-blocking)
- KG writes use retry up to 3 times on failure
- `session.yaml` is the single source of truth for session state
