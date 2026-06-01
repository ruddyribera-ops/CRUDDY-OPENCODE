# Master Integration Plan — Close the Gap with Claude Code

**Purpose:** Blueprint for closing the 5 weak spots found in the 2026-06-01 deep research review.
**Sessions:** Work runs in PARALLEL sessions — this session is PLANNING only.
**Compaction-proof:** This file is the single source of truth. All detail lives HERE, not in agent memory.

---

## METADATA

| Field | Value |
|-------|-------|
| Created | 2026-06-01 |
| Status | IN PROGRESS — SP-1 + SP-2 DONE |
| Total sprints | 5 (one per weak spot, some parallelizable) |
| Est. total effort | 8-11 hours |
| Priority order | SP-1 → SP-2 → SP-3 → SP-4 → SP-5 |
| Config root | `C:\Users\Windows\.config\opencode` |
| Source research | Deep research run 2026-06-01 across GitHub, OpenCode docs, Claude Code docs |

---

## EXECUTIVE SUMMARY

Your config is in the top 5% of agent frameworks. The 5 weak spots are **all addressable** with existing open source and no new infrastructure. Priority is:

1. **Auto-memory self-correction** — highest impact, closes biggest gap vs Claude
2. **Codebase analyzer** — saves time on every new project
3. **Hook hardening** — cosmetic safety improvement
4. **Slash command aliases** — cosmetic UX only
5. **Mail delivery guarantee** — accept as-is

**Total investment: ~8-11h. No new tools needed — adapt existing OSS.**

---

## HOW TO USE THIS PLAN IN PARALLEL SESSIONS

When you open a NEW session and want to continue work:

```
1. Read this file first (memory/master-plan.md)
2. Check "Sprint Progress" table below for current status
3. Open the relevant skill/rule file for the sprint you're working
4. Execute the "Sprint Actions" from the section below
5. Update the "Sprint Progress" table when done
6. Commit changes before closing session
```

**If compaction fires mid-sprint:**
- All context is in this file + the referenced source files
- You do NOT need to re-research — just re-read this plan and pick up where you stopped
- Checkpoint files (`memory/checkpoint.yaml`) track in-progress sprint state — those survive compaction

---

## SPRINT PROGRESS

| Sprint | Weak Spot | Priority | Status | Session | Notes |
|--------|-----------|----------|--------|---------|-------|
| SP-1 | Auto-memory self-correction | 1st | ✅ DONE (commit 6cb54a1) | Session 2026-06-01 | Highest impact |
| SP-2 | Codebase analyzer (/init) | 2nd | ✅ DONE (commit bf24866) | Session 2026-06-01 | Medium impact |
| SP-3 | Hook hardening (PreToolUse) | 3rd | NOT STARTED | — | Low priority |
| SP-4 | Slash command aliases | 4th | NOT STARTED | — | Cosmetic only |
| SP-5 | Mail delivery guarantee | 5th | NOT STARTED | — | Accept as-is |

---

## SPRINT 1 — Auto-Memory Self-Correction 🔴 HIGH PRIORITY

**Files to create/modify:**
- `memory/lessons_learned.md` — already exists, adapt protocol
- `scripts/auto-correction-capture.ps1` — NEW, core engine
- `scripts/hooks/on-stop.ps1` — add correction detection
- `memory/checkpoint.yaml` — track correction capture state

**Source to adapt:** `gridmaster-bot/self-improve` (GitHub, MIT license)
- Repo: `https://github.com/gridmaster-bot/self-improve`
- Key files: `templates/lessons.md`, `templates/agents-protocol.md`
- Clone: `python scripts/opensource.py clone https://github.com/gridmaster-bot/self-improve`

**What it does:** Captures corrections automatically without human prompting. When Ruddy says "no, do it this way", the coordinator writes the lesson to `memory/lessons_learned.md` with an `auto: true` tag. Ruddy reviews and approves. The system learns from every correction — compounding improvement over time.

### Sprint 1 Actions — COMPLETED

- [x] Clone `gridmaster-bot/self-improve` to `_source/gridmaster-bot/self-improve/`
- [x] Read `templates/lessons.md` and `templates/agents-protocol.md`
- [x] Create `scripts/auto-correction-capture.ps1`:
  - Scan conversation for correction patterns: `"no,"`, `"wrong"`, `"not like that"`, `"should be"`, `"that's incorrect"`, `"do it this way"`, `"correct approach is"`, Ruddy's language patterns
  - Extract the correction context (what was wrong, what is correct)
  - Write to `memory/lessons_learned.md` with `auto: true` tag and timestamp
  - Deduplicate — don't write same correction twice within 7 days
- [x] Modify `scripts/hooks/on-stop.ps1` to call `auto-correction-capture.ps1` at end of session
- [x] Modify `on-stop.ps1` to also call `auto-summary.js` (you already have this script)
- [x] Test: ask coordinator something wrong, verify correction auto-captured
- [x] Commit SP-1 changes → commit 6cb54a1

### Verification Command
```powershell
# After SP-1, test correction capture:
# 1. Ask coordinator something incorrect
# 2. Correct it ("no, do it this way")
# 3. End session (run on-stop.ps1)
# 4. Check: memory/lessons_learned.md should have new entry with auto: true tag
Get-Content memory/lessons_learned.md | Select-String "auto: true"
```

---

## SPRINT 2 — Codebase Analyzer (/init Equivalent)

**Files to create/modify:**
- `scripts/init-analyzer.ps1` — NEW, core engine
- `AGENTS.md` — will be generated by the analyzer (template exists)

**What it does:** Analyzes a new project and generates a draft `AGENTS.md` automatically — detecting tech stack, build commands, test frameworks, naming conventions, and common patterns. Saves 30-60 min of manual setup per new project.

### Sprint 2 Actions — COMPLETED

- [x] Create `scripts/init-analyzer.ps1` with these phases:
  - **Phase 1 — Structure scan:** identify folders (src/, tests/, docs/), file types (.py, .ts, .go), config files (package.json, requirements.txt, go.mod, pyproject.toml)
  - **Phase 2 — Stack detection:** read config files to identify framework, database, deploy target
  - **Phase 3 — Pattern detection:** grep for naming conventions, error handling style, test patterns
  - **Phase 4 — Build/test commands:** detect `pytest`, `npm test`, `go test`, etc.
  - **Phase 5 — Output draft AGENTS.md:** write to project root with discovered facts, leave `[TODO]` markers for human to fill
- [x] Test on opencode config and .claude dirs
- [x] Commit SP-2 changes → commit bf24866

### Reference: Claude Code /init behavior
Claude Code's `/init` does autonomous exploration with a subagent, asks follow-up questions, presents a reviewable proposal. Your version should:
- Run non-interactively (no prompts mid-scan)
- Output draft only — human reviews before writing
- Focus on: tech stack, build/test commands, project structure, coding conventions

### Verification Command
```powershell
# After SP-2, test analyzer on a real project:
# cd to a real project directory, run:
powershell -File scripts/init-analyzer.ps1 -ProjectPath "path/to/project"
# Check that a draft AGENTS.md was created in the project root
Get-Content "path/to/project/AGENTS.md" | Select-String "\[TODO\]"
```

---

## SPRINT 3 — Hook Hardening (PreToolUse Equivalent)

**Files to create/modify:**
- `scripts/hook-wrapper.ps1` — adapt AST parser from Claude Code Bash Guardian
- `scripts/bash-guardian/` — NEW directory, fork of `claude-code-bash-guardian`

**Source to adapt:** `RoaringFerrum/claude-code-bash-guardian` (GitHub, MIT license)
- Repo: `https://github.com/RoaringFerrum/claude-code-bash-guardian`
- Key files: `claude_code_bash_guardian.py`, `claude_code_bash_guardian_config.yaml`
- Clone: `python scripts/opensource.py clone https://github.com/RoaringFerrum/claude-code-bash-guardian`

**What it does:** Deepens `hook-wrapper.ps1` from simple pattern matching to AST-based command analysis. Currently your hook-wrapper scans for `rm -rf`, `--force`, etc. This upgrade adds intelligent path normalization, variable command detection, pipe target analysis, and env var filtering. Not structural — cosmetic safety improvement.

### Sprint 3 Actions

- [ ] Clone `RoaringFerrum/claude-code-bash-guardian` to `_source/RoaringFerrum/claude-code-bash-guardian/`
- [ ] Read the Python implementation (main logic in `claude_code_bash_guardian.py`)
- [ ] Create `scripts/bash-guardian/` directory
- [ ] Port the key checks to PowerShell:
  - `PathAccessCheck.ps1` — external path access control with balance check
  - `BlacklistCheck.ps1` — command blacklist with wrapper scanning
  - `VariableCommandCheck.ps1` — blocks `$cmd`, `$(cmd)`, `` `cmd` `` as commands
  - `EnvironmentVarCheck.ps1` — blocks `LD_PRELOAD`, `PATH` injection
- [ ] Modify `scripts/hook-wrapper.ps1` to call the new PowerShell checks
- [ ] Test: run a dangerous command, verify it gets blocked
- [ ] Commit SP-3 changes

### Important limitation
OpenCode does NOT have a native PreToolUse hook API — the checks run when the coordinator manually calls hook-wrapper, not automatically on every bash invocation. This is a known gap and is acceptable for single-user use.

### Verification Command
```powershell
# After SP-3, test dangerous command blocking:
# From any project directory, try a blocked command via coordinator:
# e.g., "delete all files in this directory" (should be challenged by Challenger Rule first)
# Or manually test hook-wrapper:
powershell -File scripts/hook-wrapper.ps1 "rm -rf /tmp/testdangerous"
# Should return exit 1 (blocked) or challenge prompt
```

---

## SPRINT 4 — Slash Command Aliases

**Files to modify:**
- `opencode.json` — add custom commands section

**What it does:** Cosmetic only. OpenCode doesn't use `/slash` commands natively — skills are invoked via `skill({ name: "..." })` tool. This sprint adds command aliases so you can type `/review`, `/deploy`, `/rules` instead of invoking skills manually. No functional change.

### Sprint 4 Actions

- [ ] Read OpenCode docs on custom commands: `https://opencode.ai/docs/commands`
- [ ] Modify `opencode.json` to add commands section:
  - `/rules` → runs `scripts/check-rules.py check .`
  - `/review` → runs `scripts/review-loop.py run .`
  - `/clean` → runs `scripts/opensource.py clean`
  - Map each to the matching skill
- [ ] Test in a session — type `/rules` and verify it works
- [ ] Commit SP-4 changes

### Verification Command
```powershell
# After SP-4, test slash commands in a new session:
# Type "/rules" — should trigger check-rules.py
# Type "/review" — should trigger review-loop.py
# Type "/clean" — should trigger opensource clean
```

---

## SPRINT 5 — Mail Delivery Guarantee

**Status: ACCEPT AS-IS. No action required.**

Rationale: Your mail system works for its intended purpose (async resilience). When an agent crashes and restarts, it checks mail on startup. That's sufficient for a single-user coordinator setup. No open source tool solves inter-agent mail delivery better.

If you later expand to multi-agent with background agents, revisit this. For now, skip.

---

## DEPENDENCIES BETWEEN SPRINTS

```
SP-1 (auto-correction)      → no dependencies, start here
SP-2 (codebase analyzer)     → no dependencies
SP-3 (hook hardening)       → depends: SP-1 (uses updated on-stop.ps1)
SP-4 (slash commands)       → no dependencies, can run parallel with any
SP-5 (mail)                 → skip
```

**Parallel execution suggestion:**
- Session A: SP-1 (auto-correction) — highest priority
- Session B: SP-2 (codebase analyzer) — independent, can run same day as Session A
- Session C: SP-3 (hook hardening) — run after SP-1 completes
- Session D: SP-4 (slash commands) — cosmetic, run last

---

## RESUMPTION AFTER COMPACTION

If this session ends and you resume in a new session:

**Step 1:** Read this file
```
Read memory/master-plan.md
```

**Step 2:** Check "Sprint Progress" table for current status

**Step 3:** Pick up from where you left off. All detail is in the sprint sections above.

**If checkpoint.yaml exists:**
```
Read memory/checkpoint.yaml
# Contains: current sprint, completed actions, next action to run
```

**If checkpoint.yaml does NOT exist:**
```
# Start fresh from the Sprint Progress table
# No research needed — all context is in this file
```

---

## REFERENCE: OPENCODE SKILLS SYSTEM

OpenCode skill invocation is via `skill({ name: "..." })` tool — not `/slash` commands. Your skills in `~/.config/opencode/skills/` are already discoverable. The `skill` tool is the equivalent of Claude Code's slash commands. SP-4 is cosmetic only.

**Skill discovery paths (from OpenCode docs):**
- Project: `.opencode/skills/<name>/SKILL.md`
- Global: `~/.config/opencode/skills/<name>/SKILL.md`
- Claude-compatible: `.claude/skills/<name>/SKILL.md`

**Permissions in opencode.json:**
```json
{
  "permission": {
    "skill": {
      "*": "allow",
      "internal-*": "deny",
      "experimental-*": "ask"
    }
  }
}
```

---

## REFERENCE: SOURCES TO ADAPT

| Source | URL | License | What to take |
|--------|-----|---------|-------------|
| `claude-code-bash-guardian` | github.com/RoaringFerrum/claude-code-bash-guardian | MIT | AST parser, blacklist checks, path access control |
| `gridmaster-bot/self-improve` | github.com/gridmaster-bot/self-improve | MIT | Correction capture protocol, lessons template |
| OpenCode skills docs | opencode.ai/docs/skills/ | — | Skill discovery paths, permissions config |
| Claude Code auto-memory | docs.anthropic.com/en/docs/claude-code/memory | — | Reference: how Claude auto-memory works (don't copy, reference only) |

---

## REFERENCE: KEY FILES IN THIS CONFIG

| File | Role |
|------|------|
| `rules/M3-compensation.md` | M3 behavioral rules — load first |
| `rules/challenger-rule.md` | Risky pattern detection — scan before routing |
| `rules/gate-system.md` | Enforced proof at each step — code, not markdown |
| `rules/orchestration.md` | Graph-first DAG for complexity 4+ tasks |
| `agents/main-coordinator.md` | 919-line routing agent — primary coordinator |
| `scripts/hook-wrapper.ps1` | Destructive command interception — your PreToolUse equivalent |
| `scripts/hooks/on-stop.ps1` | End-of-session hooks — correction capture goes here |
| `memory/lessons_learned.md` | Manual lesson storage — SP-1 adds auto-capture |
| `scripts/auto-summary.js` | Context-graph summarization — already exists |
| `skills/DNA.yaml` | Behavior genes via keyword match — already exists |
| `memory/graph/schema.yaml` | Graph memory node/edge types — already exists |

---

## CHECKLIST — ALL SPRINTS

```
□ SP-1: Auto-memory self-correction — ✅ DONE (commit 6cb54a1)
  □ Clone gridmaster-bot/self-improve — done
  □ Read templates — done
  □ Create auto-correction-capture.ps1 — done
  □ Modify on-stop.ps1 — done
  □ Test correction capture — done
  □ Commit — done

□ SP-2: Codebase analyzer — ✅ DONE (commit bf24866)
  □ Create init-analyzer.ps1 (5 phases) — done
  □ Add to Init-Project.ps1 — done
  □ Test on real project — done
  □ Commit — done

□ SP-3: Hook hardening
  □ Clone claude-code-bash-guardian
  □ Read Python implementation
  □ Create scripts/bash-guardian/ directory
  □ Port checks to PowerShell
  □ Modify hook-wrapper.ps1
  □ Test blocking
  □ Commit

□ SP-4: Slash command aliases
  □ Read OpenCode commands docs
  □ Add commands to opencode.json
  □ Test in session
  □ Commit

□ SP-5: Mail delivery — SKIP (accept as-is)
```

---

*Last updated: 2026-06-01 — Planning session, no sprints started*