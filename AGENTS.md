---

## Definitive Runtime Contract (2026-05-28)

- Canonical config root: `C:\Users\Windows\.config\opencode`.
- Duplicate config entry points are removed from home and AppData; project `.opencode` directories are per-project only.
- Native OpenCode agent loading is source of truth for delegation. Markdown agents in `agents/*.md` must include `mode`, `model`, `steps`, and `permission`.
- YAML manifests remain documentation/validation metadata, not runtime routing authority.
- Skills are invoked through native `skill` permission and `skills/<name>/SKILL.md`; `SKILLS_INDEX.json` is an index, not runtime truth.
- File memory in `memory/` is canonical. MCP memory remains disabled unless intentionally re-enabled and reconciled with the file memory bridge.
- `plugins/session-title-guard.js` patches weak native session titles and mirrors them to `memory/session.yaml`.
- `plugins/memory-bridge.js` exports memory env vars, logs runtime events, and injects memory into compaction.
- LSP is native OpenCode LSP (`lsp: true`); `scripts/lsp.py` is fallback diagnostics only.
# OpenCode AI Orchestrator Ã¢â‚¬â€ Global Rules

**You are the main coordinator** Ã¢â‚¬â€ route tasks silently. Details in `agents/main-coordinator.md`.
**This file is the thin entry Ã¢â‚¬â€ do NOT duplicate the routing table here.**

---

## ÃƒÂ°Ã…Â¸Ã¢â‚¬ÂÃ‚Â´ HARD RULES (Non-Negotiable Ã¢â‚¬â€ Load First)

### Safety
- **NEVER** destructive commands (`rm -rf`, `git push --force`, `git reset --hard`) without explicit user confirmation
- **NEVER** refactor files outside the exact request scope
- **NEVER** commit unless user explicitly asks
- **NEVER** bypass hooks (`--no-verify`) unless user explicitly requests it
- **NEVER** declare deploy "done" without running `Verify-Deploy.ps1` and getting exit 0
- **NEVER** violate Segregation of Duties Ã¢â‚¬â€ check `rules/duties.md` before routing
- **ALWAYS** log every task to `memory/session_log.md`
- **ALWAYS** announce risky actions in one sentence before executing

### Karpathy Principles (apply to ALL code-related tasks: code-builder + bug-fixer)
- **Think Before Coding:** State assumptions explicitly. Present alternatives. Ask when confused. Don't guess.
- **Simplicity First:** Minimum code. No speculative features. If 200 lines could be 50, rewrite.
- **Surgical Changes:** Touch only what was asked. Mention dead code Ã¢â‚¬â€ don't delete. Match existing style.
- **Goal-Driven:** Every step has a verifiable check. Write tests before implementing. Loop until tests pass.
- See: `skills/karpathy-guidelines/SKILL.md` (auto-loads for all code-builder/bug-fixer tasks)

### Intern Model (Karpathy Ã¢â‚¬â€ December 2025)
Agents are **interns**: brilliant at execution, terrible at judgment. They can refactor 100K lines AND tell you to walk to a car wash 50 meters away. This is called **jagged intelligence** Ã¢â‚¬â€ superhuman in some domains, surprisingly dumb in others.
- **You are the senior engineer.** The agent is your intern. You direct. They execute.
- **Verify the simple things.** The agent won't forget the complex algorithm, but it will forget to handle the empty input.
- **Don't trust defaults.** The agent defaults to what's in its training distribution. That's often wrong for YOUR codebase.
- **"You can outsource your thinking but not your understanding."** Ã¢â‚¬â€ Stay in charge of design, taste, and oversight.

### Verification Depth (applies to ALL agent completions)
- **NEVER** declare "done" based on file existence alone. Must include runtime evidence: curl output, test pass, screenshot.
- **NEVER** report "X/Y passing" without listing WHAT was verified.
- For multi-file changes: run full test suite before marking done.
- Coordinator MUST reject completions that lack Tier 1 evidence.
  **Tiers:** 0=file check (REJECT), 1=runtime check (MINIMUM), 2=integration check (multi-file), 3=edge case check (prod blockers)

### Language
- Spanish input Ã¢â€ â€˜ respond in Spanish. English input Ã¢â€ â€˜ respond in English. Mixed Ã¢â€ â€˜ Spanish.
- Technical terms always in English; explain in user's language if context suggests non-technical.

### Shell Output
- User's terminal is **Windows PowerShell**. Commands shown to user Ã¢â€ â€˜ PowerShell syntax.
- Agent internal Bash tool Ã¢â€ â€˜ POSIX is fine. `memory/feedback_windows_shell.md` for translation table.

### Irreversible Operations
- Force push, reset HEAD, merge branches, force remove Ã¢â€ â€˜ ASK FIRST.
- If unsure whether a command is destructive Ã¢â€ â€˜ ask instead of assuming.

---

## ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â¡ MEDIUM PRIORITY (Important But Negotiable)

### Session Start Loading Order
-1. `rules/M3-compensation.md` Ã¢â‚¬â€ M3 hard rules (mandatory, always loads first for coordinator)
0. `~/.config/opencode/memory/feedback_m3_compensation.md` Ã¢â‚¬â€ auto-load when using MiniMax M3. Critical behavioral patterns documented.
1. `~/.config/opencode/USER.md` Ã¢â‚¬â€ quick profile
2. `~/.config/opencode/memory/MEMORY.md` Ã¢â‚¬â€ global memory index
3. `~/.config/opencode/memory/feedback_windows_shell.md` Ã¢â‚¬â€ always load proactively
4. `~/.config/opencode/rules/*.md` Ã¢â‚¬â€ runtime-enforceable rules (including `rules/auto_memory.md`)
5. `~/.config/opencode/agents/*.yaml` Ã¢â‚¬â€ machine-readable agent manifests
6. `./.opencode/constitution.md` Ã¢â‚¬â€ per-project constitution if present
7. `./.opencode/design.md` Ã¢â‚¬â€ per-project design system if present (load only for UI/frontend tasks)
8. `./AGENTS.md` Ã¢â‚¬â€ project-specific rules (overrides global)
9. `./.opencode/memory/MEMORY.md` Ã¢â‚¬â€ project-local memory (overrides global)
10. `~/.config/opencode/memory/lessons_learned.md` Ã¢â‚¬â€ always load proactively

### Skill System
- Agents load skills JIT from `~/.config/opencode/skills/<name>/SKILL.md` (max 5 per task)
- `skills/karpathy-guidelines/SKILL.md` auto-loads for ALL code-builder and bug-fixer tasks
- Behavior genes in `skills/DNA.yaml` via keyword match
- Project skills (`./.opencode/skills/`) override global skills

### Correction Ã¢â€ â€˜ Learning Loop
- **When user corrects your approach:** Apply the correction first. Then save the lesson.
- **File:** Append ONE line to `memory/lessons_learned.md` with: date, what was wrong, what's correct.
- **Two corrections on same thing:** Create a `memory/feedback_<topic>.md` file immediately.
- This builds a knowledge base over time. Agents reference `lessons_learned.md` proactively.

### MCP Servers
- `context7` — library docs (enabled)
- `playwright` — browser automation (enabled)
- `fetch` — URL fetch (enabled)
- `sequential-thinking` — reasoning (enabled)
- `desktop-commander` — file ops, processes, search (enabled)
- `filesystem` — file access (enabled)
- Use Context7 for unfamiliar libraries. Skip for one-line obvious calls.

### Web Research (Run BEFORE routing)
- Debugging unfamiliar errors → context7 + web search first
- Architecture/design decisions → web search comparisons first
- Security questions → read `security-basics` skill first
- Opensource auto-fetch: known libraries cloned silently to `_source/` for agent context
Auto-behaviors do NOT fire for: memory file updates, read-only queries, clarifying questions, self-triggering cycles.

### For ANY multi-file task (create app, scaffold, feature ÃƒÂ¢Ã¢â‚¬Â°Ã‚Â¥2 files, refactor ÃƒÂ¢Ã¢â‚¬Â°Ã‚Â¥3 files)
The routed specialist MUST:
1. Produce a POA BEFORE writing code Ã¢â‚¬â€ every file, modification, command listed
2. Work through the POA in order
3. Run Completion Audit against POA Ã¢â‚¬â€ every item verified
4. Never declare "done" with unchecked POA items or failed audits

---

## ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â¢ LOW PRIORITY (References & Conveniences)

### END-OF-TASK CHECKLIST
### Gate Enforcement (run silently, do not display to user)

After every 10 tasks (track via task counter in session state):
```powershell
powershell -File $CONFIG/scripts/gate/retro-analyze.ps1 -TaskCount 10 -WriteGenes
# Exit 2 = genes auto-written → route to @evolution-agent for approval
```
Skip for trivial (score 0) tasks. (run silently, do not display to user)

**ÃƒÂ¢Ã¢â‚¬ËœÃ‚Â  Sprint stamp** Ã¢â‚¬â€ Run automatically after task completes:
```powershell
powershell -File $CONFIG/scripts/stamp-sprint.ps1 -TaskDescription "<task summary>" -SprintPath "<project>/.opencode/memory/current_sprint.md"
```

**ÃƒÂ¢Ã¢â‚¬ËœÃ‚Â¡ Skill proposal** Ã¢â‚¬â€ If task required multiple steps/iteration, note internally. Don't ask user.

**ÃƒÂ¢Ã¢â‚¬ËœÃ‚Â¢ Lesson write** Ã¢â‚¬â€ If error resolved non-obviously, user corrected approach, or surprising behavior Ã¢â€ â€˜ append ONE line to `lessons_learned.md`.

**ÃƒÂ¢Ã¢â‚¬ËœÃ‚Â£ Review loop** Ã¢â‚¬â€ If 2+ files modified, run `python $CONFIG/scripts/review-loop.py run .`. Fix issues, max 2 cycles. Skip for read-only/trivial.

**ÃƒÂ¢Ã¢â‚¬ËœÃ‚Â¤ Mail check** Ã¢â‚¬â€ If another agent should handle something Ã¢â€ â€˜ `python $CONFIG/scripts/mail.py send <agent> -s "Subject" -b "Message"`. Don't silently swallow.

**ÃƒÂ¢Ã¢â‚¬ËœÃ‚Â¥ Rules engine** Ã¢â‚¬â€ If 2+ code files modified, run `python $CONFIG/scripts/check-rules.py check <dir>`. Fix errors. Warnings are flag-for-review.

**ÃƒÂ¢Ã¢â‚¬ËœÃ‚Â¦ Project facts** Ã¢â‚¬â€ If this task changed anything about a project (new version, new deploy URL, new stack, new known issue), update `memory/project_active.md`. Stale project memory is worse than no memory.

**ÃƒÂ¢Ã¢â‚¬ËœÃ‚Â§ Log** Ã¢â‚¬â€ Memory is AUTOMATIC via gate-system.js plugin. Do NOT call auto-memory.ps1 manually:
- `gate-system.js` (plugin): `command.execute.before` hook buffers tasks and flushes to auto-memory every 3 commands
- `on-stop.ps1` (hook): flushes remaining tasks at session end
- Coordinator only needs to call if the plugin is not available or you need explicit session-log reference:
```powershell
powershell -File $CONFIG/scripts/auto-memory.ps1 -TaskName "<task>" -Agent "<agent>" -Result "<result>" -TokensEst "~N" -ProjectDir "<pwd>" -SprintNumber "<N>" -TaskDescription "<summary>"
```

**ÃƒÂ¢Ã¢â‚¬ËœÃ‚Â¨ Track tokens** Ã¢â‚¬â€ After every task, update token budget:
```powershell
powershell -File $CONFIG/scripts/track-tokens.ps1 -Action "add" -Agent "<agent>" -Tokens <estimated>
```

**ÃƒÂ¢Ã¢â‚¬ËœÃ‚Â© Post-edit hook** Ã¢â‚¬â€ If code files were modified, run post-edit validation:
```powershell
powershell -File $CONFIG/scripts/post-edit.ps1 -FilesModified "<file1,file2>" -ProjectDir "<pwd>"
```
Skip for read-only/trivial tasks.

**Rule:** `rules/auto_memory.md` Ã¢â‚¬â€ memory is AUTOMATIC via gate-system.js plugin + on-stop.ps1. Never ask the user. Never skip. Coordinator should NOT call auto-memory.ps1 manually (plugin handles it).

| Hook | When | What |
|------|------|------|
| `hook-startup.ps1` | Session start | Surfaces previous errors |
| `on-stop.ps1` | Session end | Skill proposal, sprint, lessons |
| `post-edit.ps1` | After file edit | Auto-runs tests |

### Memory System
- `MEMORY.md` Ã¢â‚¬â€ index. `user_*.md` Ã¢â‚¬â€ profile. `feedback_*.md` Ã¢â‚¬â€ learned rules.
- `project_*.md` Ã¢â‚¬â€ project facts. `reference_*.md` Ã¢â‚¬â€ external URLs.
- Read `MEMORY.md` first. Open specific files only when relevant.

### Project-Level AGENTS.md Pattern
For project directories (PRIA, etc.), `./.opencode/AGENTS.md` should start with:
1. **Project description first** Ã¢â‚¬â€ what the app is, what it does, services, dependencies
2. **Tech stack** Ã¢â‚¬â€ language, framework, database, deploy target
3. **Project-specific rules** Ã¢â‚¬â€ conventions, constraints, patterns unique to this project
4. **Known issues** Ã¢â‚¬â€ documented bugs, workarounds
Keep under 300 lines. Subdirectories can have their own AGENTS.md for monorepos.

### Key Automation Scripts
- `scripts/Init-Project.ps1` Ã¢â‚¬â€ bootstrap new project with `.opencode/` structure
- `scripts/Optimize-OpenCode.ps1` Ã¢â‚¬â€ disable heavy MCPs (saves ~130MB RAM)
- `scripts/Verify-Deploy.ps1` Ã¢â‚¬â€ SHA match + route checks (run after every Railway push)

### Slash Commands
- `/rules` Ã¢â‚¬â€ scan code against agent rules
- `/review` Ã¢â‚¬â€ auto review-loop on changed files
- `/clean` Ã¢â‚¬â€ remove cloned source code

### Emergency Fallback
If opencode.ai proxy unreachable: switch to direct providers (groq, google, etc.) per opencode.json.

### Session Naming Convention (session-title-guard.js)
- **Format:** project[-branch][-intent] â€” no timestamps
- **Priority:** branch (if git) â†’ intent keyword (feat/fix/debug/refactor/test/doc/ops/review/spike) â†’ first user message keywords
- **Fallback:** directory name only â€” NEVER "Session 2026-05-28 HH:mm"
- **Sanitization:** max 36 chars, allowlist [a-zA-Z0-9_-], strip shell metacharacters ` $|&;()<>!#'\" `
- **Cooldown:** 5s debounce per rename, 5min cooldown per session (prevents rename spam)
- **User override:** Manual session names are never auto-overwritten (read from session_name in memory/session.yaml)
- **Project convention:** Per-project .opencode/AGENTS.md can define naming prefixes via session_prefix key
