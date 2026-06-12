# Sprint 1G — Factory Wiring Polish

**Goal:** Fix the Factory delegation gap that surfaced in Sprint 1F (one agent doing all the work, no coordination).

**Started:** 2026-06-08
**Closed:** 2026-06-08

---

## What Got Built

### Layer 1 — Routing Table (manual)
- `C:\Users\Windows\.config\opencode\AGENTS.md` — 94-line routing table (intent → agent)
- `C:\Users\Windows\.config\opencode\opencode.json` — added `routing` section
  - **BUG CAUGHT:** The `routing` key broke `opencode serve` (not a valid OpenCode schema key). Removed.
  - **Lesson:** AGENTS.md is the source of truth, not opencode.json. Only put valid OpenCode schema in opencode.json.
- All 16 agent instruction files verified at `C:\Users\Windows\.config\opencode\agents\`

### Layer 2A — Server-based Dispatcher (built, partially abandoned)
- `C:\Users\Windows\.config\opencode\scripts\factory-dispatcher.ps1` — 270-line PowerShell dispatcher
- Polls `memory/factory/pipeline-queue.jsonl`
- Uses OpenCode HTTP API (`/session` + `/session/:id/message`) to spawn agents
- Checkpoint-aware (skips done stages, resumes)
- **Works for fast agents (<2 min)** — AM ran in 45s and produced correct output
- **FAILS for slow agents** — PM agent took 5+ min, bash tool killed dispatcher, HTTP response lost

### Layer 2B — Active-Session Routing (the WIN)
- Coordinator uses the `task` tool to dispatch in real time
- User sees every step: dispatch → agent response → handoff
- Full chain verified: AM → PM → code-builder → delivery (6/6 criteria pass)
- test01 project: tip calculator, 5.4KB, 199 lines, all inline

---

## The test01 Project (proof the chain works)

**Path:** `C:\Users\Windows\.config\opencode\memory\factory\projects\test01\`

| Stage | Agent | Result File | Status |
|-------|-------|-------------|--------|
| 1. Brief | account-manager | `am-result.md` | ✓ |
| 2. Sprint plan | project-manager | `pm-result.md` | ✓ |
| 3. Build | code-builder | `D:\opencode-health-dashboard\tip-calculator.html` | ✓ |
| 4. Verify | delivery-engineer | `delivery-result.md` | ✓ (6/6) |
| 5. Done flag | — | `DONE.flag` | ✓ |

**Total elapsed (active session):** ~5 min for full chain (4 dispatches)

---

## Lessons Learned (HARD-WON)

1. **The user wants to SEE the work, not trust a black box.** Active-session routing via `task` tool > detached background dispatcher for learning. Server-based dispatcher is for unattended/automation only.

2. **AGENTS.md is the routing source of truth.** Don't add custom top-level keys to `opencode.json` — OpenCode validates the schema and will refuse to start with `routing: { ... }`. The error was caught: "Unrecognized key: routing".

3. **Checkpoint files are essential.** Long agent runs will be interrupted. Save result files per stage (`*-result.md`) and check them before re-running. The dispatcher is now resume-safe.

4. **The HTTP API endpoint is blocking.** `POST /session/:id/message` waits for the agent to finish. If bash kills the process, the response is lost. Use `prompt_async` for production, or active-session routing for learning.

5. **Bash tool has a 5-min default timeout.** Always pass `--timeout 600000` (10 min) or higher for agent dispatches. The dispatcher has 600s internal timeout but bash may kill it first.

6. **PowerShell string interpolation gotcha.** `$(...)` inside double-quoted strings is subexpression evaluation. To embed a variable name literally, use string concatenation: `"Your job as " + $var` or single quotes for the whole string.

7. **`opencode` is a .cmd shim, not a .exe.** Use `Resolve-Path` to find the real binary, or call via `cmd.exe /c opencode ...`. The dispatcher's `Find-OpenCode` helper handles this.

8. **The Factory CAN chain automatically.** It just needs a hub. Active session (me routing) works perfectly. Server-based works for fast agents. The architecture is sound.

---

## What's in `C:\Users\Windows\.config\opencode\scripts\`

| File | Status | Purpose |
|------|--------|---------|
| `factory-dispatcher.ps1` | Shipped (with caveats) | Server-based chain runner. Use only for fast agents or with detached `Start-Process`. |
| `system-dashboard.ps1` | Existing | Source of the dashboard data the user's dashboard parses |
| `auto-memory.ps1` | Existing | T2 logging + memory writes |
| `gate/*.ps1` | Existing | Gate enforcement scripts |

---

## What 1G Did NOT Solve

- The PM agent is slow (5+ min for a trivial task). Need faster agent prompts or smaller scopes.
- No retry logic in the dispatcher (failed sessions leave the queue item in place, but there's no auto-retry timer).
- No parallel dispatch (the chain is strictly sequential: AM → PM → Builder → QA). Could parallelize some stages (e.g., architect + tech-lead simultaneously).
- No notification to user when chain completes (user has to poll status).
- The dispatcher's `-Background` mode was discussed but not built.

---

## Verdict

**Sprint 1G closed successfully.** The Factory is no longer one agent doing all the work. The coordinator routes, the agents execute, the user sees the chain. That's the win.

**Next sprint candidate:** 2A — Specialist roles. See sprint roadmap.
