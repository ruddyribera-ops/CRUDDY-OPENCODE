# OpenCode Config Adversarial Test — 2026-06-26

## Summary
- **CRITICAL:** 3
- **HIGH:** 5
- **MEDIUM:** 6
- **LOW:** 4

---

## Test Scenarios Executed (15 scenarios)

1. `simplifyPrompt("")` / `simplifyPrompt(null)` / `simplifyPrompt(undefined)` → returns falsy value unchanged (preserves null, empty string)
2. `simplifyPrompt(100KB string)` → truncates at 300 chars with `...` ✅
3. `simplifyPrompt("text \`code\` end")` (single backtick code spans) → strips `[code stripped]` ✅
4. `simplifyPrompt("text ```code``` end")` (fenced code blocks) → strips `[code stripped]` ✅
5. `simplifyPrompt("text 🚀🚀...emoji")` → passes through intact (unicode safe) ✅
6. `simplifyPrompt("text 中文中文...CJK")` → passes through intact (unicode safe) ✅
7. `simplifyPrompt("a\`b\`c")` (inline backticks without fence) → `a[code stripped]c` — **WRONG: strips literal single-backtick spans too**
8. `track-tokens.ps1 -Action check -Agent nonexistent -Tokens 1000` → GO (no error, budget silently defaults to 50000)
9. `track-tokens.ps1` YAML parse: `ConvertFrom-Yaml` not available in PowerShell 5.1 → **silently falls through, returns GO**
10. `checkpoint-save.ps1` with `-FilesModified ""` → **FAIL: missing argument (empty string not accepted)**
11. `validate-config.ps1` full run → **44 FAIL issues: missing .yaml for ai-evaluator/expert-tester/observability-sre, 5 missing SKILL.md, 31 broken skill references**
12. `opencode.json` plugin list: PowerShell `ConvertFrom-Json | Select-Object -ExpandProperty plugin` → blank output (array expansion issue)
13. Checkpoint staleness: 5 checkpoint files dated 2026-06-12 (14+ days old) remain in `memory/checkpoints/` → **stale files never cleaned up**
14. `checkpoint-save.ps1` with valid args → **exit 0, creates session JSON + index entry** ✅
15. Hook config `hook-config.json` → parses correctly, shows 3 hooks active ✅

---

## CRITICAL

### C-1: `track-tokens.ps1` — `ConvertFrom-Yaml` not available in PowerShell 5.1, silently bypasses all budget enforcement
- **Scenario:** `powershell -File track-tokens.ps1 -Action check -Agent code-builder -Tokens 999999`
- **Expected:** REJECT exit 1 when tokens exceed budget
- **Actual:** GO exit 0 regardless of token count — YAML is never parsed, hard-coded fallback returns GO
- **Repro:**
  ```powershell
  powershell -NoProfile -File "C:\Users\Windows\.config\opencode\scripts\track-tokens.ps1" -Action check -Agent "code-builder" -Tokens 999999
  # EXIT: 0  (should be 1 — 999999 >> 80000 budget)
  ```
- **File:** `C:\Users\Windows\.config\opencode\scripts\track-tokens.ps1:30`
- **Fix:** Replace `ConvertFrom-Yaml` with a PowerShell-native YAML parser (e.g., `powershell-yaml` module or manual regex parsing), or hard-code budget limits directly in the script as a fallback.

### C-2: `sub-agent-guard.js` `simplifyPrompt()` — strips single-backtick inline code spans, corrupting prompts that legitimately use backticks
- **Scenario:** User prompt contains a SQL query with backtick identifiers: `` `user_table`.`id` ``
- **Expected:** Single-backtick spans preserved; only triple-backtick fenced code blocks stripped
- **Actual:** All backtick pairs stripped as `[code stripped]`, corrupting the prompt content
- **Repro:**
  ```js
  node -e "const {simplifyPrompt} = require('C:/Users/Windows/.config/opencode/plugins/sub-agent-guard.js');
  console.log(JSON.stringify(simplifyPrompt('SELECT `id` FROM `users` WHERE `active`=1')));
  // Output: \"SELECT [code stripped] FROM [code stripped] WHERE [code stripped]=1\" — WRONG"
  ```
- **File:** `C:\Users\Windows\.config\opencode\plugins\sub-agent-guard.js:38`
- **Fix:** Change regex from `/```[\s\S]*?```/g` (strips both single and triple backticks) to `/``````[\s\S]*?``````/g` (only triple-backtick fenced blocks).

### C-3: `checkpoint-save.ps1` — mandatory `$FilesModified` parameter rejects empty string, breaking zero-modification checkpoints
- **Scenario:** Auto-checkpoint fires for a read-only task with no file modifications
- **Expected:** `-FilesModified ""` accepted (empty = no files modified)
- **Actual:** `MissingArgument` error, script exits 1, checkpoint not saved
- **Repro:**
  ```powershell
  powershell -NoProfile -File "C:\Users\Windows\.config\opencode\scripts\checkpoint-save.ps1" `
    -SessionId "test" -ProgressPercent 50 -FilesModified "" -Strategy "read-only" -NextAction "continue"
  # Result: "Missing an argument for parameter 'FilesModified'" — EXIT 1
  ```
- **File:** `C:\Users\Windows\.config\opencode\scripts\checkpoint-save.ps1:7`
- **Fix:** Change `$FilesModified = ""` to make the parameter accept empty string: add `[AllowEmptyString()]` attribute, or remove the mandatory flag and default to empty.

---

## HIGH

### H-1: Stale checkpoint files (>14 days old) accumulate in `memory/checkpoints/` — no auto-cleanup
- **Scenario:** Periodic interval checkpoints from 2026-06-12 remain in directory
- **Expected:** Auto-cleanup of checkpoints older than 24h (per `main-coordinator.md` checkpoint protocol) or session-start cleanup
- **Actual:** 5 checkpoint files dated 2026-06-12 still present, no cleanup ever runs
- **Repro:**
  ```powershell
  Get-ChildItem "C:\Users\Windows\.config\opencode\memory\checkpoints" -File |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
    Select-Object Name, LastWriteTime
  # Returns: checkpoint-interval-20260612-*.json (14+ days old)
  ```
- **File:** `memory/checkpoints/` (cleanup logic referenced in `main-coordinator.md` but no script implements it)
- **Fix:** Implement `cleanup-checkpoints.ps1` run at session start: delete checkpoints older than 24h, keep max 3 concurrent.

### H-2: `validate-config.ps1` — 3 agents missing `.yaml` files: `ai-evaluator`, `expert-tester`, `observability-sre`
- **Scenario:** Coordinator dispatches to `@ai-evaluator`, `@expert-tester`, or `@observability-sre`
- **Expected:** `agents/ai-evaluator.yaml`, `agents/expert-tester.yaml`, `agents/observability-sre.yaml` exist
- **Actual:** Only `.md` files exist; YAML metadata files missing
- **Repro:**
  ```powershell
  powershell -NoProfile -File "C:\Users\Windows\.config\opencode\scripts\validate-config.ps1"
  # FAIL: agent ai-evaluator.md -> ai-evaluator.yaml - missing ai-evaluator.yaml
  # FAIL: agent expert-tester.md -> expert-tester.yaml - missing expert-tester.yaml
  # FAIL: agent observability-sre.md -> observability-sre.yaml - missing observability-sre.yaml
  ```
- **File:** `agents/` directory
- **Fix:** Create `ai-evaluator.yaml`, `expert-tester.yaml`, `observability-sre.yaml` with required metadata (model, steps, color, vibe).

### H-3: `validate-config.ps1` — 5 skills missing `SKILL.md`: `android-native-dev`, `autoresearch`, `flutter-dev`, `ios-application-dev`, `react-native-dev`
- **Scenario:** Specialist loads a skill that was supposedly migrated/archived
- **Expected:** Every skill directory referenced in `SKILLS_INDEX.json` has a `SKILL.md`
- **Actual:** 5 skill directories exist (with `references/` subdirs) but no `SKILL.md`
- **Repro:** `validate-config.ps1` output shows these as FAIL
- **File:** `skills/android-native-dev/`, `skills/flutter-dev/`, etc.
- **Fix:** Either create `SKILL.md` for each or remove from `SKILLS_INDEX.json` to prevent broken skill loading.

### H-4: 31 broken skill references in agent `.md` files — agents load non-existent skills
- **Scenario:** `@code-builder` or `@architecture-advisor` loads referenced skill that doesn't exist (e.g., `skills/auth-patterns/SKILL.md`)
- **Expected:** All skill references in agent files point to existing `SKILL.md`
- **Actual:** 31 skill references broken — `auth-patterns`, `realtime-patterns`, `code-review`, `python-patterns`, `js-modern-patterns`, `ci-cd-patterns`, `msoffice-tools`, `data-analysis`, `testing-standards`, `git-workflow`, `design`, `desktop-manager`, `skill-learning`
- **Repro:** `validate-config.ps1` section [4/8] Skill references — 31 FAIL entries
- **File:** `agents/code-builder.md`, `agents/architecture-advisor.md`, `agents/bug-fixer.md`, `agents/code-analyzer.md`, `agents/main-coordinator.md`
- **Fix:** Either create the missing skill files or update agent references to point to existing skills.

### H-5: Unknown agent in `track-tokens.ps1` silently defaults to 50000 budget — no warning
- **Scenario:** Coordinator dispatches to a new agent not yet in `token-budgets.yaml`
- **Expected:** Warn (exit 2) or at minimum log that agent is unknown
- **Actual:** Silently uses 50000 default, returns GO with no warning
- **Repro:**
  ```powershell
  powershell -NoProfile -File "C:\Users\Windows\.config\opencode\scripts\track-tokens.ps1" `
    -Action check -Agent "newly-created-agent" -Tokens 1000000
  # Result: GO (should warn about unknown agent)
  ```
- **File:** `C:\Users\Windows\.config\opencode\scripts\track-tokens.ps1:25-28`
- **Fix:** Return exit 2 (WARN) for unknown agents so coordinator at least logs the mismatch.

---

## MEDIUM

### M-1: `simplifyPrompt()` — null/undefined returned as-is instead of empty string
- **Scenario:** Sub-agent dispatch with null prompt (edge case from malformed task call)
- **Expected:** `simplifyPrompt(null)` returns `""` for safe string concatenation
- **Actual:** Returns `null` unchanged — may cause `TypeError` in calling code expecting string
- **Repro:**
  ```js
  node -e "const {simplifyPrompt} = require('C:/Users/Windows/.config/opencode/plugins/sub-agent-guard.js');
  console.log(JSON.stringify(simplifyPrompt(null)));  // null (not \"\")
  ```
- **File:** `plugins/sub-agent-guard.js:34`
- **Fix:** `if (!prompt) return prompt ?? ""`

### M-2: `memory-bridge.js` — `session.idle` fires with `sessionID="unknown"` in OpenCode Go
- **Scenario:** Idle event from unnamed session floods `session_events.jsonl` with unknown entries
- **Expected:** Idle events only logged for real sessions with known IDs
- **Actual:** Code acknowledges this ("Note: session.idle fires with sessionID='unknown'") but still tracks and logs them
- **Repro:** Observed in `memory-bridge.js` comment at line handling session.idle
- **File:** `plugins/memory-bridge.js:94-105`
- **Fix:** Add filter: if `sessionId === "unknown"` AND `title === "untitled"`, skip all logging.

### M-3: Duplicate intent routing entries in `AGENTS.md` — `tech-writer` and `designer` appear twice
- **Scenario:** User says "design system" — triggers both `designer` (first match) and `tech-writer` (second match via docs route)
- **Expected:** One agent per intent, unambiguous routing
- **Actual:** `designer` and `tech-writer` both appear in the intent routing table with overlapping trigger words
- **File:** `AGENTS.md` Intent → Agent routing table
- **Fix:** Deduplicate the routing table; move `tech-writer` and `designer` to separate intent categories with non-overlapping trigger words.

### M-4: `checkpoint-guard.js` — `modifying bash` detection uses weak regex, misses PowerShell aliases
- **Scenario:** User runs `del /s /q *.tmp` (Windows `del` alias) or `Move-Item` with short alias
- **Expected:** Checkpoint triggered before any state-modifying command
- **Actual:** `MODIFYING_BASH_PATTERNS` regex only matches `rm|mv|cp|write|edit|delete|...` — misses `del`, `rd`, `ren`, PowerShell aliases
- **Repro:**
  ```js
  // In checkpoint-guard.js:
  const MODIFYING_BASH_PATTERNS = /\b(rm|mv|cp|write|edit|delete|move|copy|Set-Content|Remove-Item|...)\b|>>?|<\s*</i
  // "del file.txt" does NOT match — no pre-bash checkpoint fired
  ```
- **File:** `plugins/checkpoint-guard.js:28`
- **Fix:** Expand regex to include `del|rd|ren|Move-Item|Copy-Item|Remove-Item` and other common mutation aliases.

### M-5: `compaction-survival.js` — no fallback if `checkpoint_index.jsonl` is corrupted
- **Scenario:** `checkpoint_index.jsonl` has a malformed JSON line (disk full mid-write)
- **Expected:** `loadCheckpointIndex()` returns null, recovery context skipped gracefully
- **Actual:** `JSON.parse` on corrupted line throws, entire compaction context injection fails silently (caught by try/catch)
- **Repro:** Write a null byte into `memory/checkpoints/checkpoint_index.jsonl` — `loadCheckpointIndex` silently returns null
- **File:** `plugins\_shared.js:loadCheckpointIndex` + `plugins\compaction-survival.js`
- **Fix:** Add `try/catch` per-line in `loadCheckpointIndex` so one bad line doesn't poison the whole index.

### M-6: `memory-bridge.js` — `flushMutex` is in-memory only, lost on plugin reload
- **Scenario:** `memory-bridge.js` is unloaded/reloaded (plugin hot-reload or restart) during a flush — mutex lost, duplicate flushes possible
- **Expected:** Mutex persists or is backed by filesystem
- **Actual:** Module-level `flushMutex` Map is in-process memory; survives plugin reload but resets to empty
- **File:** `plugins/memory-bridge.js:55`
- **Fix:** Use a file-based lock (`memory/checkpoints/.flush.lock`) instead of in-memory Map for cross-reload safety.

---

## LOW

### L-1: `sub-agent-guard.js` — `MAX_PROMPT_LEN` is 300 but `DEFAULT_TIMEOUT_MS` is 300000 (5 min) — asymmetry suggests the 300-char limit was never tuned
- **Scenario:** A 500-char prompt (well within reason for a task description) gets truncated to 297 chars + `...`
- **Expected:** Truncation limit calibrated to preserve meaningful task context
- **Actual:** 300-char limit is extremely aggressive; a typical task description with 50 chars of context around code blocks gets gutted
- **File:** `plugins/sub-agent-guard.js:12-13`
- **Fix:** Calibrate `MAX_PROMPT_LEN` to something like 1000-1500 chars; add comment explaining why 300 was chosen.

### L-2: `opencode.json` — 11 plugins use absolute Windows paths hard-coded in config
- **Scenario:** Config shared or migrated to another Windows machine with different username
- **Expected:** Config is portable via environment variable `OPENCODE_CONFIG_HOME`
- **Actual:** All plugin paths use `C:\Users\Windows\.config\opencode\...` — won't work on other machines
- **File:** `opencode.json:plugin[]`
- **Fix:** Use `%OPENCODE_CONFIG_HOME%` or `~/.config/opencode/` relative paths in config, resolve at runtime.

### L-3: `track-tokens.ps1` — `per_task` enforcement is `soft` per `rules/budgets.yaml`, but script only checks `agent_budgets` (per-session equivalent)
- **Scenario:** Large task (12000 tokens) to `code-builder` which has `per_task: 12000` but `per_session: 50000`
- **Expected:** Per-task budget enforced for single large task
- **Actual:** `track-tokens.ps1` only checks `agent_budgets` (per-session limit), ignores `rules/budgets.yaml` per-task limits
- **File:** `scripts/track-tokens.ps1:25-28` vs `rules/budgets.yaml:per_task`
- **Fix:** Implement per-task limit checking in `track-tokens.ps1`.

### L-4: `hook-config.json` — `sessionStart.memoryRetrieval.script` references `.opencode/hooks/session_start.py` (relative path) but the file may not exist
- **Scenario:** New session starts, hook system tries to load `.opencode/hooks/session_start.py`
- **Expected:** Script exists and is executable
- **Actual:** Path is relative; if OpenCode starts from a different working directory, script not found
- **File:** `scripts/hooks/hook-config.json:sessionStart.memoryRetrieval.script`
- **Fix:** Use absolute path or resolve relative to `OPENCODE_CONFIG_HOME`.

---

## Coverage Gaps

- **Concurrency/race:** Could not test: concurrent `bash` edits to same file, parallel agent dispatches modifying shared state, `start-job`/`stop-job` mid-script. These require a live OpenCode session.
- **MCP server errors:** Could not test: what happens when an MCP server (e.g., `context7`) returns HTTP 500 mid-task. Would require network fault injection.
- **Token exhaustion:** Could not test: actual token budget exhaustion mid-task — the `track-tokens.ps1` script itself is broken so this path can't be verified.
- **Long-running scripts:** Could not test: scripts >5 min — no script in the repo exceeds this, so timeout handling was not exercised.
- **PowerShell 5.1 vs 7+:** Only tested on PowerShell 5.1 (available). Scripts using PowerShell 7+ specific syntax (`Split-String -sb` etc.) could not be verified.
- **OWASP LLM Top 10 / Agentic ASI:** These attack patterns require a running LLM session with the config loaded — cannot be tested against static config files alone.
- **Hook exception handling:** Could not test: what happens when `auto-memory.ps1` throws — the try/catch in `memory-bridge.js` is documented but not exercised.

---

## Risk Assessment

**After recommended fixes:**

| Finding | Current Risk | Residual After Fix |
|---------|-------------|-------------------|
| C-1 track-tokens broken | **CRITICAL** — budget enforcement is non-functional | Low — YAML parser fix restores enforcement |
| C-2 simplifyPrompt backtick | **CRITICAL** — silently corrupts prompts with backtick identifiers | Low — regex fix only strips fenced blocks |
| C-3 checkpoint-save empty | **CRITICAL** — read-only tasks fail to checkpoint | Low — AllowEmptyString attribute fixes it |
| H-1 stale checkpoints | **HIGH** — disk bloat, stale state served on restart | Medium — cleanup script needed |
| H-2 missing agent YAML | **HIGH** — agent dispatch may fail or use wrong config | Low — create YAML files |
| H-3 missing SKILL.md | **HIGH** — skill loading breaks for 5 skills | Low — create or remove references |
| H-4 broken skill refs | **HIGH** — agents load non-existent skills silently | Medium — 31 references need updating |
| H-5 unknown agent silent | **HIGH** — new agents bypass budget silently | Low — WARN exit for unknown agents |

---

## Recommendations (Priority Order)

1. **IMMEDIATE:** Fix `track-tokens.ps1` — install `powershell-yaml` module or hard-code budget limits as fallback. Budget enforcement is currently completely non-functional.
2. **IMMEDIATE:** Fix `simplifyPrompt()` regex to only strip triple-backtick blocks — current behavior silently corrupts SQL, shell commands, and other backtick-annotated content.
3. **IMMEDIATE:** Fix `checkpoint-save.ps1` to accept empty `FilesModified` — every read-only task currently fails to checkpoint.
4. Run `validate-config.ps1` and address all 44 FAIL items — start with the 3 missing agent YAMLs and 5 missing SKILL.md files.
5. Implement checkpoint cleanup: run `cleanup-checkpoints.ps1` at session start, delete files >24h old, max 3 concurrent.
6. Expand `MODIFYING_BASH_PATTERNS` in `checkpoint-guard.js` to catch `del`, `ren`, `Move-Item` aliases.
7. Add per-task budget checking to `track-tokens.ps1`.
8. Deduplicate the `AGENTS.md` intent routing table.

---

## Reproducers (One-liners)

```powershell
# C-1: Budget enforcement bypass
powershell -NoProfile -File "C:\Users\Windows\.config\opencode\scripts\track-tokens.ps1" -Action check -Agent code-builder -Tokens 999999; echo "EXIT: $LASTEXITCODE"

# C-2: Backtick corruption
node -e "const {simplifyPrompt} = require('C:/Users/Windows/.config/opencode/plugins/sub-agent-guard.js'); console.log(JSON.stringify(simplifyPrompt('SELECT `id` FROM `users`')));"

# C-3: Empty FilesModified fails
powershell -NoProfile -File "C:\Users\Windows\.config\opencode\scripts\checkpoint-save.ps1" -SessionId test -ProgressPercent 50 -FilesModified "" -Strategy test -NextAction t; echo "EXIT: $LASTEXITCODE"

# H-1: Stale checkpoints
Get-ChildItem "C:\Users\Windows\.config\opencode\memory\checkpoints" -File | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | Select Name, LastWriteTime

# H-2/H-3/H-4: Full config validation
powershell -NoProfile -File "C:\Users\Windows\.config\opencode\scripts\validate-config.ps1"; echo "EXIT: $LASTEXITCODE"
```