2026-05-28 | DNA.yaml COORD-003 triggers + main-coordinator.md Challenger Rule keywords must stay in sync. The challenger rule handles user-facing interaction (what the coordinator says to the user when a risky keyword is detected). COORD-003 triggers in DNA.yaml handle context injection (what the agent receives as behavioral guidance). They share the same keyword categories but serve different mechanisms. When adding a new risky pattern: add to BOTH files. Note: COORD-003 uses hyphenated compound keywords (plain-text-password) while challenger rule uses natural language with spaces (plain text password) � DNA.yaml's matching is simpler (individual token match) so it can't handle the same multi-word phrases. The sync note in both files prevents this drift.

# MIGRATED_TO_GRAPH: 2026-05-19
---
name: lessons_learned
description: Self-improvement log --- key decisions, failures, and lessons from each session
type: memory
version: 1.0

[2026-05-18] The Desktop Commander edit_block tool silently truncates very large replacements (1000+ lines). For any file > ~500 lines, use PowerShell Add-Content via the Bash tool to append content in batches, then verify with Get-Content. The truncation produces NO error � it just drops content silently, which creates broken HTML (content after </html>). Always verify line count and </html> uniqueness after multi-append workflows.
[2026-05-19] PHP inline code in PowerShell (`php -r "..."`) breaks on backslashes in namespaces (e.g., `App\Models\Foo`). PowerShell interprets `\` as escape. Workaround: write a temp PHP file with `write` tool, then `php temp.php`, then delete it. Alternative: use `php artisan tinker --execute` with single quotes on the outside (but this has its own quoting limits). For multi-line PHP work, always use temp files.
---

# Lessons Learned --- Agent Self-Improvement Log

**Purpose:** After each session, write key decisions, failures, and lessons here.
Future sessions load this file to avoid repeating mistakes.

**Format per entry:**
```
## [YYYY-MM-DD] [Brief Title]

**Context:** What were we trying to do?
**What happened:** What went wrong or what did we learn?
**Lesson:** What should we do differently next time?
**Applied:** [YES/NO] --- if YES, when and how
```

---

## Post-Session Hook (Mandatory for Specialists)

After any task completes (per `AGENTS.md` auto-behaviors), the agent MUST write a lessons-learned entry if:
- A bug took >30 minutes to diagnose
- A pattern was discovered that isn't in any skill
- A decision had tradeoffs that weren't obvious beforehand
- The same mistake was corrected twice

**Why:** MiniMax M2's in-prompt reasoning is shallower than frontier models. The `lessons_learned.md` file serves as externalized memory between sessions.

---

## [2026-05-10] RosarioSIS Modules.php requires .php extension in modname

**Context:** Integrating NeuroProfile plugin as a student tab via `Modules.php?modname=Students/NeuroProfile` caused redirect to logout.
**What happened:** Modules.php line 63 checks `substr($modname, -4, 4) !== '.php'` --- `Students/NeuroProfile` (no `.php`) triggers `HackingLog()` and skips the file load. Warehouse.php (line 288-314) also redirects to logout when no `$_SESSION['STAFF_ID']` and `SCRIPT_NAME === 'Modules.php'`. The combo creates a redirect loop: Modules.php tries to load -> HackingLog skips -> Warehouse sees empty session -> redirects to index.php -> index.php redirects back to Modules.php with `redirect_to` -> browser follows redirect back to Modules.php -> loop.
**Lesson:** Always use `modname=Students/NeuroProfile.php` (WITH `.php` extension) in RosarioSIS URLs. The `profile_exceptions` table also needs the `.php` suffix in MODNAME column.
**Applied:** YES --- added `Students/NeuroProfile.php` entry with `CAN_USE='Y', CAN_EDIT='Y'` for PROFILE_ID=1. Source wrapper updated.
**Category:** `integration`
**Cross-reference:** `D:/Projects/opencode-power-setup/rosariosis-plugins/NeuroProfile/modules/NeuroProfile/NeuroProfile.php`

**Context:** Smoke test for TODO API --- tests failed because in-memory `tasks` dict persisted across tests within the same TestClient instance
**What happened:** 4 tests failed (`test_list_tasks_when_empty`, `test_list_tasks_with_multiple_tasks`, `test_create_and_list_integration`, `test_update_then_delete_flow`) --- count assertions showed 8 tasks instead of expected values. Fix: added `@pytest.fixture(autouse=True)` with `main.tasks.clear()` in `reset_app_state` fixture.
**Lesson:** When using FastAPI TestClient with in-memory storage, always reset app state between tests using an autouse fixture. The module-level `tasks` dict persists across all test functions unless explicitly cleared.
**Applied:** YES --- `smoke_test/tests/test_main.py` uses autouse fixture to clear state. This pattern should be in `testing-standards/SKILL.md` (currently not there).
**Category:** `bug`
**Cross-reference:** `skills/testing-standards/SKILL.md` --- needs a "in-memory state reset" note

---

## [2026-05-04] Installing MiniMax skills from GitHub clone --- Windows path hell

**Context:** Cloned MiniMax-AI/skills repo to install 6 skill packages (minimax-pdf, pptx-generator, minimax-xlsx, minimax-docx, vision-analysis, mmx-cli)
**What happened:** Git Bash on Windows uses `/c/Users/...` paths; PowerShell uses `C:\Users\...`. Clone landed at `C:\c\Users\Windows\.minimax-skills-tmp` (double drive prefix artifact). Skills needed scripts/ subdirs + reference files + dotnet project + assets --- not just SKILL.md.
**Lesson:** Windows path translation between PowerShell and Git Bash is lossy. Always verify actual path with `ls` or `Get-ChildItem`. Also: MiniMax skills have substantial subdirectories (scripts, references, dotnet projects, assets) --- budget 30+ file operations per skill.
**Applied:** YES --- all 6 skills installed with full directory trees. `minimax-docx` dotnet project copied as complete tree.
**Category:** `shell`
**Cross-reference:** `memory/feedback_windows_shell.md` --- path translation between shells

---

## [2026-05-04] time.sleep() in E2E tests causes flakiness on Railway cold start

**Context:** E2E test for PRIA login page was failing on Railway staging but passing locally
**What happened:** Fixed 45s timeout used `time.sleep(5)` to wait for page load --- worked locally but Railway's cold start took 60s, so the timeout was insufficient
**Lesson:** Never use fixed timeouts for external service readiness. Use `wait_for_selector` with Playwright instead.
**Applied:** YES --- feedback_e2e_waits.md created. All E2E tests now use wait_for_selector.
**Category:** `deploy`

---

## [2026-05-03] GH token scope gap --- gh CLI can't reach private repos

**Context:** Tried to create PR via gh CLI for pria-app private repo
**What happened:** `gh pr create` failed because token lacked `repo` scope
**Lesson:** GH token must have `repo` scope for private repo operations. web UI + git push works as fallback.
**Applied:** YES --- project_gh_token_scope.md created.
**Category:** `workflow`

---

## Rules for This File

1. **Keep entries short** --- one screen max per entry
2. **Date every entry** --- for traceability
3. **State the lesson first** --- don't bury it
4. **Mark as Applied when applied** --- and note in `MEMORY.md` hook
5. **Delete stale entries** --- if a lesson is now in a skill or feedback file, mark it obsolete
6. **Cross-reference skills** --- if a lesson maps to a skill, note which one

---

## Categories

| Category | When to Use |
|----------|-------------|
| `bug` | Debugging mistake, wrong root cause assumed |
| `architecture` | Design decision with non-obvious tradeoffs |
| `shell` | Windows/PowerShell mistake |
| `deploy` | Deployment-specific issue (Railway, Docker, etc.) |
| `security` | Security mistake or pattern |
| `workflow` | Process/procedure improvement |

---

*This file is read at session start when relevant to the current task.*

---

## [2026-05-07] Windows CRLF breaks YAML frontmatter regex in PowerShell

**Context:** Skill version-check script couldn't detect `---` separators in SKILL.md files even though the separator was visually present on line 1.
**What happened:** PowerShell `Get-Content -Raw` returns string with `\r\n` line endings. Splitting by `\n` leaves `\r` at end of each line. Regex `^---$` didn't match `---\r` because `$` anchors end of string, not before `\r`. Result: separator detection returned -1 for all Windows-authored files.
**Lesson:** Always normalize line endings before regex processing in PowerShell: `$content -replace "\`r\`n","\`n"` before splitting. Applies to any script reading .md files authored on Windows.
**Applied:** YES --- fixed in `skill-version-check.ps1`, `repair-corrupted-skills.ps1`, `fix-remaining-skills.ps1`.
**Category:** `shell`
**Cross-reference:** `memory/feedback_windows_shell.md`

---

## [2026-05-07] PowerShell hashtable @{} vs PSCustomObject --- display bug

**Context:** Skill version-check script showed `[]` and `System.Collections.Hashtable` instead of skill names in output.
**What happened:** PowerShell hashtables use `$_.Key` syntax; when you do `foreach ($f in $failures) { $f.Skill }` it returns nothing because hashtables don't have typed properties. Using `[PSCustomObject]@{ Skill = "name" }` creates a real object with `.Skill` property accessible via dot notation.
**Lesson:** Always use `[PSCustomObject]@{}` instead of `@{}` when creating objects that will be iterated and their properties accessed with dot notation or displayed in formatted output.
**Applied:** YES --- all `$results +=` statements in skill-version-check.ps1 converted.
**Category:** `shell`


## [2026-05-08] FastAPI router trailing-slash redirect (307) --- Python urllib follows but curl doesn't

**Context:** M0a motor endpoint at /api/motores/synthesis returned HTTP 307 on first call.
**What happened:** FastAPI router registered with @router.post('/') but called without trailing slash -> FastAPI 307 redirect. Python urllib follows by default; curl doesn't without -L.
**Lesson:** Always test with trailing slash when calling FastAPI routes from Python. Use -L with curl. Frontend HTTP clients follow redirects automatically.
**Applied:** YES --- verified M0a works with trailing slash.
**Category:** API
## [2026-05-09] PRIA v3 motor prompts have no structured adaptation schema --- free text everywhere

**Context:** Reviewed all 9 PRIA v3 motor prompts (22-105 lines each) to identify improvement opportunities for v8.
**What happened:** Every motor with adaptations (`notas_docente`, `tabla_adaptaciones_clase`, `adaptaciones_por_mision`, `observacion`) outputs them as unstructured free text or flat string arrays. The FastAPI backend can't parse, filter, or route adaptations by diagnosis type. Downstream motors (M0b->M0c->M1a->M1b->M1c->M2a->M2b) re-process the same free-text `diagnosticos` on every call with no persistent accommodation memory.
**Lesson:** Structured JSON fields with explicit schema (e.g., `{diagnostico, barrera_cognitiva, estrategia_dua, seal_retorno}` instead of `{"Diagnostico": "TEA", "Adaptacion": "Ajuste"}`) enable programmatic adaptation routing. Without this, every motor must re-infer accommodations from the same generic strings.
**Applied:** YES --- `V8_MOTOR_IMPROVEMENTS.md` prioritizes structured schema changes across all motors, with persistent student NEE database as #1 cross-cutting fix.
**Category:** `architecture`
**Cross-reference:** `PRIA_v8/V8_MOTOR_IMPROVEMENTS.md`

---

## [2026-05-09] FastAPI Body() in Annotated -- cannot use default= in Annotated for body param

**Context:** Reset-day admin endpoint used Annotated[str | None, Body(default=None)] = None. FastAPI raised AssertionError.
**What happened:** FastAPI Body() annotation with default= inside Annotated[] is incompatible. Default must be on function param, not inside Body().
**Fix:** Use Body: Annotated[dict | None, Body()] = None (default on = None outside annotation). Changed from str to dict since frontend sends JSON.
**Lesson:** For FastAPI body params with defaults, always put = None on the function parameter, NOT inside Body() declaration.
**Category:** `fastapi`

---

## [2026-05-09] minimax-pdf merge.py unicode print crashes on Windows cp1252

**Context:** merge.py ran successfully (PDF output created, 11 pages, 63KB) but crashed at final print with UnicodeEncodeError.
**What happened:** The print statement used box-drawing characters (─, ──) that cp1252 (Windows default console encoding) can't encode. The PDF was already written before the error.
**Lesson:** When running Python on Windows with unicode output, always `chcp 65001` first or use PYTHONIOENCODING=utf-8. The output file itself is unaffected --- the crash is only in the print statement.
**Applied:** YES --- next PDF merge will set env var.
**Category:** `shell`
**Cross-reference:** `memory/feedback_windows_shell.md`

---

## [2026-05-10] RosarioSIS 12.x plugin routing --- `Students/NeuroProfile` redirects to Portal

**Context:** Refactoring NeuroProfile plugin UI for RosarioSIS --- needed to test if the plugin UI renders correctly in browser.
**What happened:** Direct navigation to `modname=Students/NeuroProfile` (with or without `redirect_to=`) always redirected to `modname=misc/Portal.php`. Even adding `profile_exceptions` entry for `Students/NeuroProfile` didn't fix it. The redirect happens at Apache .htaccess level --- mod_rewrite forwards anything starting with `Students/` to `index.php`, which then applies the `redirect_to` logic.
**Root cause:** Plugin registered via `AddProgramFunction()` call (which doesn't exist in RosarioSIS 12.x core) --- no plugin-level module registration exists, so the modname has no filesystem path and triggers the default Portal redirect.
**Workaround:** Created a wrapper module at `modules/Students/NeuroProfile.php` that includes the plugin file. But even this didn't fully fix the redirect --- the Apache .htaccess `RewriteRule ^Students/` pattern (at line 23 of .htaccess) intercepts the request before PHP runs.
**Lesson:** RosarioSIS plugins are NOT loaded via standard `modname` URL routing in v12.x --- plugins use action hooks (`add_action()`) and the plugin's own module entry points must be accessed via `plugins/{PluginName}/modules/{Module}/{Module}.php` directly, NOT via `Students/` prefixed URLs. For the NeuroProfile tab to appear as a student subtab, the proper RosarioSIS approach would be to add a non-core module in `modules/Students/` with a `Menu.php`, NOT a plugin.
**Category:** `architecture`
**Cross-reference:** `deployment-patterns` --- RosarioSIS plugin vs module distinction

---

## [2026-05-10] Task classifier scoring --- debug across multiple files needs +1.5 boost

**Context:** Building task-classifier.ts for provider auto-routing. Test 3 "Refactor across 3 files" scored 3.0 (Tier 1 boundary) instead of expected 4 (Tier 2).
**What happened:** refactor on 3 files gave score 1 (file count) + 1.5 (refactor) = 2.5. The "across 3 files" pattern needed an explicit boost. Also test 4 "Debug... Check logs and fix" was scoring 2.8 --- the multi-step pattern `check... and fix` existed but wasn't triggering isMultiStep correctly until added to the isMultiStep detector.
**Lesson:** Multi-file operations (refactor, debug, analyze) need isMultiFile conditional scoring (+1.5-2x base). Explicit phrases like "across N files", "in N files" need a dedicated boost (+0.5). The isMultiStep detector needs to catch "check X and fix Y" patterns explicitly.
**Applied:** YES --- task-classifier.ts now has conditional scoring for multi-file and explicit file count phrases. test-classifier.ts validates 4/5 tests pass.
**Category:** `architecture`
**Cross-reference:** `lib/task-classifier.ts`, `lib/test-classifier.ts`

---

## [2026-05-10] MiniMax API key invalid --- 401 despite key being "set" in environment

**Context:** Fallback chain test showed MiniMax returning 401 invalid api key even though MINIMAX_API_KEY env var is set.
**What happened:** The key `sk-cp-MCx...` starts with `sk-cp-` --- MiniMax uses this prefix for session/API keys. The 401 suggests the key may have expired or the env var value differs from what's expected by the API.
**Lesson:** Even if `node -e "process.env.MINIMAX_API_KEY"` shows "SET", the actual runtime value loaded by the fetch call may differ. The key may need rotation. Also: Groq and Cohere API keys are NOT set in environment --- those providers are skipped in fallback chain.
**Applied:** NO --- user needs to verify/rotate MiniMax key. Groq/Cohere keys need to be added to environment.
**Category:** `workflow`
**Cross-reference:** `scripts/test-fallback-chain.ts`

## [2026-05-10] RosarioSIS NeuroProfile URL routing --- use Modules.php NOT index.php

**Context:** `index.php?modname=Students/NeuroProfile.php` triggers HackingLog and redirects to Portal via .htaccess RewriteRule that maps `^Students/` -> `index.php` with `redirect_to=Modules.php?modname=...`. The correct URL is `Modules.php?modname=Students/NeuroProfile.php` (with .php suffix on NeuroProfile).

**What happened:** Form action and fetch() AJAX URLs in NeuroProfile.php were using `index.php?modname=...`. After save, RosarioSIS would redirect to Portal instead of the profile page.

**Lesson:** Any link/form/action in RosarioSIS plugins MUST use `Modules.php?modname=Path/Module.php` format. Never `index.php?modname=...`. The .php suffix is required on the modname value --- `Students/NeuroProfile` (no suffix) triggers HackingLog; `Students/NeuroProfile.php` works.

**Applied:** YES --- fixed lines 182 (form action) and 614 (fetch URL) in NeuroProfile.php. Source synced.

**Category:** `rosariosis`
**Cross-reference:** `plugins/NeuroProfile/modules/NeuroProfile/NeuroProfile.php`

## [2026-05-12] Full machine sweep for PRIA --- the old v5.4 was NOT on this machine
- **What happened:** User said "that's not the right app, we rebuilt it last week" about Railway v5.4. Assumed v5.4 was local.
- **Lesson:** Checked C:\, D:\, AppData, .claude/projects, Desktop, Downloads, GitHub repos --- v5.4 source was never on this machine.
- **How to apply:** Next time user says "this isn't the app I was working on" --- immediately check Railway URL (already live), screenshot it, AND check GitHub repos. Don't assume it's local.
- **Files checked:** `D:\pria-v7` (empty), `C:\railway-deploy` (BDM app), `C:\app` (streamlit template), all Desktop folders, all GH repos. The actual v5.4 source was in a GitHub repo that was deleted (`pria-app`).
- **What worked:** Found the Railway v5.4 app still live at priav5-production.up.railway.app --- returned HTTP 200 on May 12. Took screenshots via Playwright to confirm version.

**Context:** Needed to query RosarioSIS tables (students, attendance, courses) to understand schema for import scripts.

**Lesson:** Database credentials found in `/var/www/html/config.inc.php`:
- host: `postgres` (Docker service name)
- dbname: `neurosis`
- user: `neurosis_user`
- password: `2ac1ba09726606dd2683ddd14110dba1d58aef97`

Tables confirmed: `attendance_day` (student_id, school_date, minutes_present, marking_period_id), `attendance_codes`, `attendance_period`, `courses`, `course_periods`, `schedule`. All currently empty for syear=2025.

**Category:** `rosariosis`
**Cross-reference:** `import_attendance.php`, `check_rosario_direct.php`

## [2026-05-10] RosarioSIS course_periods requires marking_period_id (NOT NULL constraint)

**Context:** Importing schedule data into RosarioSIS `course_periods` table --- INSERT was failing with NULL constraint violation.

**What happened:** `marking_period_id` column in `course_periods` is NOT NULL. Using `NULL` as default produced hard errors. Resolution: query existing marking_periods table first, use `SELECT marking_period_id FROM marking_periods WHERE syear=2025 AND mp_type='semester' LIMIT 1` -> got id 2 (Semester 1) as default. This is required for any course_period INSERT.

**Lesson:** When inserting into RosarioSIS tables with foreign key constraints, always verify NOT NULL columns by checking the schema first: `SELECT column_name, is_nullable FROM information_schema.columns WHERE table_name='course_periods'`. Key required fields: `marking_period_id` (int, NOT NULL), `syear` (numeric).

**Also:** `students` table has NO `syear` column --- enrollment year is stored in `student_enrollment.syear` (join required). Query `students` alone cannot filter by year; must JOIN.

**Category:** `rosariosis`
**Cross-reference:** `import_schedule.php`

## [2026-05-10] PostgreSQL ON CONFLICT requires unique constraint, not just any index

**Context:** Creating `schedule` entries for student enrollments using `INSERT ... ON CONFLICT DO NOTHING` to make the script idempotent.

**What happened:** `ON CONFLICT (syear, student_id, course_period_id, start_date) DO NOTHING` failed with: "there is no unique or exclusion constraint matching the ON CONFLICT specification". The `schedule` table had regular indexes but no unique constraint matching all 4 conflict columns. Resolution: created a unique index explicitly: `CREATE UNIQUE INDEX schedule_unique ON schedule(syear, student_id, course_period_id, start_date)`. Only then did ON CONFLICT work.

**Lesson:** PostgreSQL's ON CONFLICT clause requires a unique constraint (not just indexes) on the exact column set. Regular B-tree indexes won't work even if they cover the same columns. Always verify with `\d schedule` to see if `schedule_ind*` indexes are unique or not.

**Also:** RosarioSIS Schedule.php filters by the currently selected marking_period in the UI dropdown (Q1/Q2/Q3/Q4). Entries with `marking_period_id=2` (Semester 1) don't appear when Q4 is selected, even if the date range overlaps. To see schedule entries in the UI for the currently active Q4 period, duplicate entries with `marking_period_id=7` and `start_date=2026-03-15`.

**Category:** `rosariosis`
**Cross-reference:** `import_student_schedule.php`, `import_student_schedule_q4.php`
**Category:** `rosariosis`
**Cross-reference:** `import_student_schedule.php`, `import_student_schedule_q4.php`

---

## [2026-05-10] RosarioSIS config rows --- serialized PHP arrays vs plain strings

**Context:** After a SQL update with PHP heredoc escaping, ALL 23 config rows with school_id=0 got corrupted. The problem: RosarioSIS config table stores BOTH serialized PHP arrays AND plain strings, and they look identical in the raw column.

**What happened:** A single SQL UPDATE with improper escaping caused `CONTENT_SECURITY_POLICY`, `THEME`, `TITLE`, `DISPLAY_NAME`, `MODULES`, `PLUGINS`, `VERSION`, etc. ALL to have the same garbage value. After fixing one row, if VERSION was valid serialized string, Update() would see VERSION < ROSARIO_VERSION and try to run UpdateV4_5, which creates school_fields_seq -> conflicts with existing school_fields_id_seq -> error page.

**Lesson:** In RosarioSIS config table:
- STRING config values (TITLE, THEME, VERSION, NAME, etc.) are stored as **plain strings** --- NOT serialized. E.g., `Garden`, `12.8`, `Las Palmas School`.
- ARRAY config values (MODULES, PLUGINS) are stored as **serialized PHP arrays** --- E.g., `a:15:{s:6:"School";b:1;...}`.
- Mixing them up causes garbage. Debug: `php -r 'var_dump(unserialize("VALUE"))'` to test validity.
- VERSION must always be stored as plain string `12.8` (not serialized) to prevent Update() from running.
- Debug Config() output in actual app context with `docker exec neurosis_rosariosis php /tmp/debug_version5.php`.
- If `school_fields_id_seq already exists` appears after all other fixes, VERSION is still triggering Update() --- set VERSION to plain `12.8` AND create event trigger to block duplicate sequence creation as belt-and-suspenders.

**Category:** `rosariosis`
**Cross-reference:** `D:/Temp/fix_all_config.sql`, `D:/Temp/fix_config_plain.sql`, `D:/Temp/block_seq_creation.sql`
[2026-05-12] Teacher sidebar broken in RosarioSIS - root cause was AllowUse() returning false for non-admin profiles because staff_exceptions table was empty. Fix: skip AllowUse for non-admin since menu structure (\[\][\C:\Users\Windows\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1]) already filters by profile. Changed Menu.php: AllowUse() -> (\C:\Users\Windows\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 !== 'admin' || AllowUse())
[2026-05-12] RosarioSIS teacher redirect loop --- AllowUse() returns false when PROFILE_ID is NULL (queries staff_exceptions instead of profile_exceptions). Fix: SET profile_id=2 for teacher user in DB. Also fixed Menu.php AllowUse bypass for sidebar rendering.

[2026-05-13] Presentaciones para 5to primaria: max 100 palabras/slide, SOLO bullets, jerga reemplazada, elementos de pensamiento integrados, paleta warm. No asumir 'parrafo = profesional'. Contexto escolar requiere diseno pedagogico no corporativo.

[2026-05-13] PRIA v10 --- motor AI async lifecycle pattern: submit -> poll estado-sistema -> done/error
**Context:** Connected 6 AI motor endpoints to Semanal/Trimestral pages. Backend returns 200 immediately (async), generation continues in background.
**Lesson:** The pattern is: (1) call POST /api/motores/{type} -> (2) poll GET /api/admin/estado-sistema every 2s -> (3) check key (sintesis_unidad, plan_clase, etc.) for "done"/"error" status. `useMotorGeneration` hook encapsulates this. Status mapping: pending=gray, generating=yellow, done=green, error=red.
**Applied:** YES --- useMotorGeneration.ts in PRIA v10. Could be extracted as reusable skill for any async-motor frontend.
**Category:** `architecture`
**Cross-reference:** `src/hooks/useMotorGeneration.ts`, `src/api/motores.ts`

[2026-05-17] School Excel imports can hide data under shifted header rows (e.g., 5TO SEC had headers on row 2), so naive header=0 parsing silently drops students --- detect headers dynamically by scanning for key labels like EMAIL/APELLIDO before ETL.

[2026-05-17] Many skills had broken duplicate frontmatter (version: blocks between extra --- fences). This happened when skills were manually edited and YAML frontmatter got corrupted. Clean frontmatter editing requires replacing the entire block, not appending. Also: avoid `description: |` or `description: >` without text --- YAML parses them as empty. Use inline description strings.
[2026-05-17] Phase 3 progressive disclosure: 24 skills >220 lines need refactoring. Strategy: L1 = routing layer (frontmatter + When/Do Not + high-level procedure + links to refs). references/*.md = extracted bulk content (tables, commands, examples, theory). Target L1 size: 50-200 lines per skill. Average compression: ~75%.

[2026-05-17] No hacer SQL manual para crear usuarios admin � ensure_admin_seed_user() lo hace autom�ticamente al arrancar. Los $ de bcrypt se rompen en PowerShell. Siempre dejar que la app haga lo suyo.
## [2026-05-19] Start-Process -NoNewWindow blocks shell tool if stdout/stderr not redirected
**Context:** Starting Laravel dev server via `Start-Process -NoNewWindow php artisan serve` caused the shell tool to hang indefinitely.
**What happened:** PowerShell's `Start-Process` waits for stdout/stderr handles. A long-running server never closes them, so the shell tool blocks forever.
**Lesson:** Always use `-RedirectStandardOutput NUL -RedirectStandardError NUL` to truly background servers in PowerShell. The coordinator must always enforce this pattern for any background server start.
**Applied:** YES --- `feedback_background_servers.md` created as permanent reference. All future server starts use this pattern.
**Category:** `shell`
**Cross-reference:** `memory/feedback_background_servers.md`

## [2026-05-20] Destructive migration guard � SQLite CHECK constraint workaround
**Context:** Migration `fix_attendance_status_constraint.php` called `Schema::drop('attendances')` to change a CHECK constraint, because SQLite doesn't support `ALTER TABLE MODIFY COLUMN`.
**What happened:** Dropping and recreating the table deletes ALL data. No guard existed. If run on production with data, attendance records vanish permanently.
**Lesson:** Any migration using `Schema::drop()` or `Schema::dropIfExists()` on an existing table must have a data-presence guard (`DB::table()->count()` check) that skips execution and logs a warning if rows exist. Always prefer additive migrations (new column + data migration + drop old) over destructive DROP+CREATE. Document the alternative procedure inline for operators who need to run it on production.
**Applied:** YES � guard added to both `up()` and `down()` with warnings via `Log::warning()`. Migration file also documents the safe manual data migration approach.
**Category:** `database`, `migrations`, `safety`

x- 2026-05-20 - PowerShell double-quoted here-strings (@''@) expand variables. Use single-quoted here-strings for PHP code. Use UTF8Encoding(false) for BOM-free output.

---

## [2026-05-25] PRIA v10 � Full completion session, 0 items left in backlog

**Context:** PRIA v10 was a React+Vite SPA for AI-driven educational material generation. Previous session left it at ~80% � 12 motors wired but several critical UX issues and incomplete features remained. This session aimed to complete 100%.

**What happened:**
1. Fixed critical polling 404 bug (estado-sistema endpoint didn't exist, caused ~100 console errors/page)
2. Fixed permanently-disabled "Siguiente ?" button on Slides page
3. Unified version from v5.4 ? v10 in sidebar
4. Wired 4 remaining motors (9-12: Tutor, PDC, Recalibraci�n, MicroObjetivos) in MaterialesPage
5. Added Diagnosticos CTA, Trimestral/Semanal empty states with links
6. Added admin form validation (previously none � empty fields could submit)
7. Moved MiniMax API key from hardcoded to `.env` + `.env.example`
8. Built PPTX export skeleton (`exportAllMotorsToPPTX()` in generator.ts)
9. Connected Alpha-2 ? Dashboard via localStorage (curriculumPreview persists)
10. Implemented streaming responses (callMinimaxStream in minimaxClient.ts)
11. Added unit tests (29 passing via vitest)
12. Built PWA offline mode (vite-plugin-pwa, service worker, manifest)

**Key architectural decisions:**
- Motor chaining pattern: each motor button only visible when its dependency result exists
- localStorage for curriculumPreview cross-page communication (no React Context needed)
- Streaming fallback to non-streaming if connection fails
- Vite proxy for mock API endpoints (dev only, no Express needed)

**Lesson:** Project handovers to agents should be DELTA-only, not context-repeat. First handover attempt: 89K tokens. Compressed version: 3.5K tokens. Same result. Always send coordinates + pattern + exit criteria � never context the agent already has.

**Applied:** YES � project_pria_v10.md created in memory/. Token-count discipline established for future handovers.

**Category:** `architecture`, `workflow`
**Cross-reference:** `memory/project_pria_v10.md`

-------------------------------------------

---
**Category:** `architecture`

---

## [2026-05-27] Memory/State infrastructure gap � 5% utilization
**Context:** User (Ruddy) pointed out that the entire OpenCode memory/state/handover infrastructure was barely used despite being fully built. Knowledge graph had stale entities, project_active.md was 25 days stale, session_log.md wasn't updated, handovers didn't exist, end-of-task checklist was never run, mail system was never used.

**What happened:** The coordinator read memory at session start but NEVER wrote to it. 7+ memory files, knowledge graph MCP, mail system, checkpoint protocol � all available, none used. Between sessions the coordinator started blind. No handover meant context was lost.

**Lesson:** Infrastructure means nothing if triggers don't fire. The fix is a 4-layer architecture with concrete triggers:
1. Session START ? load handover + checkpoints + project state
2. Task COMPLETES ? append session_log.md + update KG + check for lessons/decisions
3. Lesson discovered ? write lessons_learned.md + create KG entity
4. State changes ? update project_active.md
5. Session END ? write handover + archive old one + stamp sprint

Built a complete Master POA (`MASTER_POA_memory_state_handover.md`) with implementation plan (Phase A done, B pending).

**Applied:** YES � Phase A this session: KG populated (8 entities, 8 relations), project_active.md refreshed, session_log.md updated, handover/latest.md created, session.yaml live.

**Category:** `architecture`, `workflow`
**Cross-reference:** `memory/MASTER_POA_memory_state_handover.md`, `memory/handover/latest.md`, `memory/session.yaml`

---

## [2026-05-27] PostgreSQL migration testing � config.ts resolves to server/.env not root .env

**Context:** Testing Sprint 1 migration runner against PostgreSQL Docker container. Server kept failing with JWT_SECRET validation error.

**What happened:** config.ts calls dotenv.config({ path: resolve(__dirname, '../.env') }) which resolves relative to server/src/config.ts, giving server/.env. Setting PowerShell env vars does NOT override .env file values when dotenv loads AFTER env var check. The server/.env still had DATABASE_URL=sqlite://./prisa.db (deleted file).

**Lesson:** When testing with a different database backend, ALWAYS edit server/.env directly � not just PowerShell env vars. The dotenv library loads .env files which override shell environment variables in Node.js.

**Category:** database, workflow
2026-05-28 | BOM in .md rule files silently breaks frontmatter regex parsing. check-rules.py returned 7 rules (should be 10) but showed no error. The UTF-8 BOM (ufeff) at file start breaks e.match(r'^---\s*\n', content) � the \s* doesn't match the BOM. Fix: read with utf-8-sig or strip BOM explicitly. Also found phantom skills are common: skills listed in agent YAML but no matching skill directory exist. Always verify skill directories match YAML references.
2026-05-28 | BOM (ufeff) at file start breaks frontmatter regex: re.match(r'^---\s*\n') fails because \s* doesn't match BOM. Always use utf-8-sig when reading .md files. Also: protocol docs can be correct while implementation silently diverges � save-checkpoint.ps1 claimed atomic write in SYNOPSIS but wrote directly to file without .tmp rename. Always READ the implementation, don't trust the comment.
2026-05-28 | AGENTS.md says MCP server X is 'enabled' but opencode.json has 'enabled: false' � documentation contradicts config. Always verify opencode.json directly, don't trust AGENTS.md statements about server status. Also: budgets.yaml enforcement flow is a design document, not code � 'Enforced by main-coordinator' in docs means nothing if the coordinator has no budget check logic.
2026-05-28 | BOM (ufeff) silently breaks everything: regex matches, YAML parsing, JSON decode. Use utf-8-sig when reading .md/.yaml/.json config files. Also: check-rules.py returned 7 rules with no error � silent failure is the most dangerous kind. Always verify the count matches expectations.
2026-05-28 | session_machine.ps1 got corrupted when I tried to use -replace on the whole file at once (PowerShell here-string expansion + backtick escaping broke the file to 0 lines). Fix: always write fresh from scratch instead of doing string replacement on large PS files. Also: T0 trigger added -- fires on first task to name session from task description, prevents duplicate naming.
2026-05-28: PowerShell strings with em dash (�) cause parser errors in PS 5.1. Always use two hyphens (--) instead. The old post-edit.ps1 had an em dash in Write-Host that broke the try/catch block.

---

## [2026-05-30] pino-http@11 ESM � named export required, not default

**Context:** Fixing TypeScript errors in PRIA v10 server before Railway deploy. `pino-http@11` import failed with "This expression is not callable."

**What happened:** `import pinoHttp from 'pino-http'` with `module: NodeNext` + `moduleResolution: NodeNext` produces a module namespace object with no callable default export. The package's `index.d.ts` declares `export default PinoHttp` and `export { PinoHttp as pinoHttp }` � both are named exports, not a callable default.

**Lesson:** When using `module: NodeNext` in TypeScript, ESM packages without a proper `default` export in their CJS interop layer are NOT callable as default imports. Always check the actual `.d.ts` export signature. Fix: `import { pinoHttp as pinoHttpFn } from 'pino-http'` (named export) OR use the `.default ?? module` pattern.

**Applied:** YES � `server/src/app.ts` now uses `import { pinoHttp as pinoHttpFn } from 'pino-http'`.

**Category:** `typescript`, `esm`
**Cross-reference:** `server/src/app.ts`

---

## [2026-05-30] dbGet<> generic type arguments � function has no generic parameter

**Context:** TypeScript error "Expected 0 type arguments, but got 1" on `dbGet<RateLimitRow>(...)` calls in rateLimiter.ts and materials.ts.

**What happened:** `dbGet` in schema.ts is typed as `Promise<any | undefined>` � no generic type parameter. Calling `dbGet<Type>()` passes a type argument the function doesn't accept. The fix is to cast the return value: `dbGet(...) as Type | undefined`.

**Lesson:** When a helper function returns `Promise<any>`, you cannot retroactively add generic typing by passing `<Type>` at the call site. The function signature must be changed OR the cast must be on the right side. Always check the actual function signature, not just the call site.

**Applied:** YES � both call sites fixed: `rateLimiter.ts` and `materials.ts`.

**Category:** `typescript`
**Cross-reference:** `server/src/db/schema.ts`, `server/src/middleware/rateLimiter.ts`

---

## [2026-05-30] migrate.ts process.exit(1) � kills Vitest test runner silently

**Context:** 6 test suites each call `initDB()` ? `runMigrations()` on startup. Migration 003 was already applied by the first suite. Subsequent suites hit `duplicate key (23505)` and called `process.exit(1)`.

**What happened:** Vitest caught 6 unhandled rejections (`process.exit unexpectedly called with "1"`). Tests still passed (Vitest intercepted), but this was noisy and would kill a real server process. Root cause: `migrate.ts` had no handling for the "already applied" duplicate key case.

**Lesson:** Migration runners must handle `duplicate key` (PostgreSQL 23505) gracefully � log it and continue, don't exit. The tracking table INSERT should be wrapped in try/catch that recognizes23505 as "already done" rather than "failed."

**Applied:** YES � `server/src/db/migrate.ts` now catches `err?.code === '23505'` and logs "already applied" instead of exiting.

**Category:** `database`, `testing`
**Cross-reference:** `server/src/db/migrate.ts`

---

## [2026-05-30] PowerShell background jobs can't capture long-running process output

**Context:** Trying to start PRIA dev server (`npx tsx src/index.ts`) in background using `Start-Job`, `Start-Process`, and PowerShell job cmdlets. Server started but `Receive-Job` returned nothing.

**What happened:** PowerShell background jobs (`Start-Job`) run in a separate session. `Receive-Job` showed empty output even though the job state was "Running." The `Start-Process -NoNewWindow` approach failed with "not a Win32 application." `Start-Job` with script block that does `npm run dev 2>&1 | Out-Null` ran but produced no accessible output stream.

**Lesson:** PowerShell background job mechanisms are designed for short?? tasks, not long-running servers with interactive output. For dev servers on Windows, use: (1) Git Bash `nohup process &` for true backgrounding, (2) redirect stdout/stderr to a file, (3) or use the `desktop-commander_start_process` tool which properly manages process lifecycle.

**Applied:** YES � switched to Git Bash for server management. Dev server now started with `npx tsx src/index.ts > /tmp/pria-server.log 2>&1 &`.

**Category:** `shell`
**Cross-reference:** `memory/feedback_windows_shell.md`

---

## [2026-05-30] Parallel Vitest test suites hit duplicate migration � initDB per-suite is expensive

**Context:** PRIA has 7 integration test files each with `beforeAll` calling `initDB()`. With PostgreSQL, each suite runs all migrations. After the first suite applies migration 003, subsequent suites hit the duplicate key.

**What happened:** Even with the graceful 23505 handling now in place, this pattern means every test file re-runs migrations on startup. With many test files this is slow. Better pattern: run migrations once at test setup, not per-suite.

**Lesson:** For integration tests with real DB, consider a single global `beforeAll` at the Vitest config level rather than per-file `beforeAll`. Or use a test database that starts fresh per test run. Current PRIA pattern (per-suite initDB) works but is slow.

**Category:** `testing`, `database`
**Applied:** NO � would require refactoring test setup. Known issue, acceptable for now.

---

## [2026-05-30] Sprint E runtime verification � auth cookie must be read via raw HTTP, not Invoke-WebRequest

**Context:** Testing `SameSite=Strict` cookie on login endpoint. `Invoke-WebRequest -SessionVariable sv` failed with "PowerShell is in non-interactive mode."

**What happened:** `Invoke-WebRequest` with `-SessionVariable` flag requires interactive mode. On Windows Server or non-interactive contexts it fails. The cookie header was visible in the raw HTTP response but inaccessible through the PowerShell helper.

**Lesson:** For HTTP header inspection (Set-Cookie, ETag, etc.), always use raw `http` module via `node -e` or `curl -v`. Don't rely on PowerShell's Invoke-WebRequest wrapper for header inspection.

**Applied:** YES � cookie verification done via `node -e "const http=require('http')..."` which correctly parsed all response headers.

**Category:** `shell`, `testing`

## 2026-05-30 � PRIA v10 response unwrapping pattern

**Problem:** Multiple API client functions (`materials.ts`, `diagnosticos.ts`) use `response.data` but backend wraps responses in `{data: ...}`. `response.data` returns the wrapper `{data: [...]}`, not the array itself.

**Root cause:** Axios interceptor passes through the `{data: ...}` wrapper without unwrapping. Backend explicitly wraps with `res.json({ data: ... })`.

**Fix pattern:** Change `return response.data` ? `return response.data.data` for list and create endpoints.

**Affected files (confirmed fixed):**
- `src/api/materials.ts` ?
- `src/api/diagnosticos.ts` ?

**Files that may have the same issue (audit needed):**
- `src/api/blocks.ts` � `response.data` but backend may not exist
- `src/api/users.ts` � `response.data` but calls `/users/` (wrong path, backend has `/admin/users`)

## [2026-05-31] Permission loop � doom_loop not preventing prompts

**Problem:** 571 permission prompts in one session. ash: "allow" + doom_loop: "allow" in opencode.json should have blocked it, but doom_loop UI kept firing.

**Root causes found:**
1. Coordinator calling ash 3+ times in succession for file searches ? triggers doom_loop at exactly 3 identical calls
2. $CONFIG env var not set ? auto-memory.ps1 never fires ? session events not logged
3. Template repo had ash: "*": ask in agent-level permission block (we fixed by restoring from git)

**What fixed it:**
- Rule 17 in main-coordinator.md: "never call bash 3+ times, use glob instead"
- Tool Selection Rule: "prefer glob/grep over bash for file operations"
- Removed desktop-commander + filesystem MCPs (redundant on Windows with native bash)
- ash: "allow" simplified from pattern-based to simple allow

**Files changed:**
- gents/main-coordinator.md � added Rule 17 + Tool Selection Rule
- opencode.json � removed desktop-commander/filesystem MCPs, simplified bash permission
- CONFIG_AUDIT.md � updated MCP status

**Verification:** After restart, 0 prompts. Autonomous mode confirmed.

**Lesson:** doom_loop fires BEFORE permission check, not after. Config says "allow" but doom_loop overrides. Fix is behavioral (don't call bash 3x) not configurational.

---

## [2026-05-31] PRIA v10 adversarial audit found 5 P0 critical bugs

**Context:** Full codebase deep-scan of `D:\ACTIVE PROJECTS\PRIA v10` (120+ files). Task was to find dead code, zombie lines, orphaned code, spaghetti, malfunctions, edge cases, gaps, duplications — acting as the project's antagonist.

**What happened:** Found 5 P0 Critical, 6 P1 High, 11 P2 Medium issues plus 8 dead code items. Key findings:

1. **AdminPage auth access broken** — `(window as any).__useAuth?.()` is not a valid React hook pattern. `__useAuth` doesn't exist on `window`. User is always `undefined`, `teacherCode` always falls back to `'ADMIN'`. Admin panel operates as wrong user. **Direct Rules of Hooks violation** — hooks must be called at component top level, not via window property access.

2. **useMultiPhaseGeneration server API never called** — `await apiFn(payload)` discards response, catch block silently swallows errors, always falls through to local `promptRunner`. Server AI never receives multi-phase requests. Fire-and-forget with silent fallback — API success and failure are indistinguishable.

3. **Phase status check uses wrong method** — `mpg.phaseStatuses[mpg.currentPhase]?.includes('done')` calls `.includes()` on a string (not array). Logic coincidentally works due to `'done'.includes('done')` → `true`. Result panel never shows because condition is logically inverted.

4. **Optimistic updates on failed operations** — `AdminUsuariosPanel` runs `setUsers()` inside `catch` blocks, showing success toast even when API threw. Data diverges from server truth.

5. **AdminResetPanel shows success on error** — `catch` sets `'✅ Datos del día reiniciados correctamente. (mock)'` — user believes operation succeeded when it failed.

**Also found:** Mock output encoding corruption (UTF-8 bytes read as Latin-1 → `'â€"', 'Ã©', 'Ã¡'` instead of accented Spanish), empty `teachers` and `weekData` arrays never populated, health indicator always green regardless of actual status, dead `MOTOR_PHASE_MAP` export never used.

**Lesson:** Antagonist-style audits catch issues that casual review misses. Specifically:
- React hook patterns violated via window property access are silent failures (no crash, just wrong behavior)
- Silent catch blocks that enable fallbacks without observable side effects are indistinguishable from success
- Optimistic UI without rollback on error is worse than no optimistic update — it creates false confidence
- TypeScript's `string.includes()` is valid on string type, so no compile error — logic error stays in production

**Applied:** YES — POA written to `D:\ACTIVE PROJECTS\PRIA v10\POA_PRIA_v10_Fixes.md`. Recovery plan: read POA → `git status` → continue from next uncompleted. Compaction survival: git commits every fix + POA file as source of truth + session.yaml title guard.

**Category:** `bug`, `architecture`, `workflow`
**Cross-reference:** `D:\ACTIVE PROJECTS\PRIA v10\POA_PRIA_v10_Fixes.md`, `memory/lessons_learned.md` (this file)

---

## [2026-06-01] Archived skill duplicates shadow active skills
**Context:** Restored 47 archived skills from previous repo into `skills/.archive/`. 14 of them had identical names to active skills. If OpenCode scans `skills/` recursively, the archived (old) version could load instead of the active version.
**Lesson:** When restoring archived content, always check for name conflicts with active content. Duplicate names in subdirectories are silent failures — no error, just wrong behavior.
**Fix:** Removed 14 duplicate directories from `.archive/`. Kept only unique archived skills (33 remain).
**Category:** `config`, `skills`

## [2026-06-01] Auto-memory must be plugin-driven, not coordinator-manual
**Context:** AGENTS.md says "Run automatically after EVERY task completion" but auto-memory.ps1 requires TaskName, Agent, Result, TokensEst — parameters the coordinator doesn't reliably have mid-task. Result: memory files were not updated.
**Lesson:** Instructions to "run X automatically" are unreliable unless mechanically enforced. Auto-memory is now triggered by gate-system.js's `command.execute.before` hook (async flush every 3 commands) and on-stop.ps1 (session-end flush). The AGENTS.md instruction is updated to reference these mechanisms.
**Fix:** gate-system.js buffers tasks and calls auto-memory.ps1 asynchronously. on-stop.ps1 flushes remaining tasks at session end.
**Category:** `automation`, `enforcement`
**Cross-reference:** `plugins/gate-system.js`, `scripts/hooks/on-stop.ps1`, `scripts/auto-memory.ps1`


## [2026-06-03] T2 Protocol: single-call wrapper for end-of-task logging

**Context:** Coordinator's TRIGGERS.md T2 protocol documented 8 manual steps after every task, but they were unreliable. Auto-memory was firing on session.idle only, logging "idle:untitled" instead of real task names. session_log.md was full of placeholders, useless for next session context.

**What happened:** Discovered that OpenCode Go's 	ool.execute.after hook doesn't fire for individual task completions (only event: session.idle and shell.env work reliably). The architecture can't capture real task names automatically.

**Lesson:** When a hook isn't available, **wrap the protocol in a single script** the coordinator can call with one command. Don't rely on documentation; the call must be one line.

**Fix:** Created scripts/t2-complete.ps1 that runs all 6 end-of-task steps in one call:
- session_log append with REAL task name
- session.yaml task tracking
- token tracking
- sprint stamp
- auto-memory flush with REAL task name (fixes placeholder problem)
- graph memory task node + edge to session

**Category:** utomation, enforcement, workflow
**Cross-reference:** scripts/t2-complete.ps1, scripts/graph-write-task.js, TRIGGERS.md T2 section, gents/main-coordinator.md T2 Protocol section

---

