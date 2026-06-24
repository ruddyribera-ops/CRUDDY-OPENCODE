# Acceptance Criteria — OpenCode Config Health Fix Sprint 001

---

## Tier 1: "System Boots Cleanly" (Blocking — must pass before anything else)

After ALL fixes applied and OpenCode restarted:
- [ ] `opencode --version` or `opencode --info` runs without error
- [ ] `C:\Users\Windows\.config\opencode\hook-errors.log` remains 0 bytes (no new hook errors)
- [ ] OpenCode starts and the main-coordinator agent is available
- [ ] No JSON parse errors in opencode.json (run `Get-Content opencode.json -Raw | ConvertFrom-Json`)

---

## Per-Area Acceptance Criteria

### F1: Plugin Loading (PASS/FAIL from Area 0 runtime verify)

| Criterion | Verification |
|---|---|
| Plugins load without error | `hook-errors.log` stays 0 bytes after OpenCode restart |
| Named exports are sufficient | If OpenCode starts and plugins work as-is → F1 is PASS without any plugin edits |

**If named exports are INSUFFICIENT (Area 1 was needed):**
| Criterion | Verification |
|---|---|
| All 10 plugins have a usable export | `Select-String "export default" plugins\*.js` finds 10 matches |
| Each plugin returns a hook object | Manual review of each `export default` body |

---

### F2: Agent Inline Dedup

| Criterion | Verification |
|---|---|
| `opencode.json` `agent:` block is removed (or reduced to main-coordinator only) | `(Get-Content opencode.json -Raw \| ConvertFrom-Json).agent.PSObject.Properties.Count -lt 5` |
| All 16 agents still dispatch | Each agent responds to a test prompt (or `opencode --info` shows them) |
| No config merge ambiguity | Agent behavior matches what `agents/*.md` defines (not conflicting with old inline) |

---

### F3: Provider API Keys

| Criterion | Verification |
|---|---|
| No hardcoded API keys remain in opencode.json | No regex match for `gsk_`, `sk-or-v1-`, `csk-` in the file |
| All provider apiKey values use `{env:VAR}` syntax | `(Get-Content opencode.json -Raw) -match ''\{env:[A-Z_]+\}'''` returns multiple matches |
| `GROQ_API_KEY`, `OPENROUTER_API_KEY`, `CEREBRAS_API_KEY` are set in shell | `echo $GROQ_API_KEY` (or equivalent) returns non-empty value |
| Provider calls work end-to-end | groq/openrouter/cerebras tabs in OpenCode produce valid responses |

---

### W1-W4, W15: Permission Cleanup

| Criterion | Verification |
|---|---|
| `write` key is absent from top-level permission | `(Get-Content opencode.json -Raw) -notmatch '"write":'` |
| `filesystem` key is absent | `(Get-Content opencode.json -Raw) -notmatch '"filesystem":'` |
| Agent names (account-manager, etc.) absent from top-level | All 8 agent names absent from permission block |
| MCP names (context7, fetch, playwright, sequential-thinking, auto-browser) absent | All 5 MCP names absent from permission block |
| `repo_clone`, `repo_overview` absent | Both absent |
| Schema-valid keys still present | `read`, `edit`, `bash`, `task`, `webfetch`, `websearch`, `doom_loop` all present |
| Permission prompts still fire for `edit`, `bash`, `webfetch` | Tested manually: confirm the `ask` behavior works |

---

### W5-W6: MCP Configuration

| Criterion | Verification |
|---|---|
| playwright MCP uses `env:` not `environment:` | `(Get-Content opencode.json -Raw) -notmatch '"environment":'` |
| codebase-memory MCP has no `args:` key | `(Get-Content opencode.json -Raw) -notmatch '"args":'` |
| MCP servers initialize without error | `opencode --info` shows all enabled MCPs as connected |

---

### W7-W8: Agent Frontmatter

| Criterion | Verification |
|---|---|
| 8 agents have `mode:` in frontmatter | Count of agent .md files containing `^mode:` = 8 |
| 9 agents have `permission:` block | Count of agent .md files containing `^permission:` = 9 |
| Agents still dispatch correctly | main-coordinator can route to each agent type |

---

### W9: SPECIALIZED_AGENTS.md Rename

| Criterion | Verification |
|---|---|
| File renamed to `specialized-agents.md` | `Test-Path "agents/specialized-agents.md"` = True |
| Old filename gone | `Test-Path "agents/SPECIALIZED_AGENTS.md"` = False |
| Frontmatter name still `specialized-agents` | `Select-String "name: specialized-agents" agents/specialized-agents.md` |

---

### W10: Skill Descriptions

| Criterion | Verification |
|---|---|
| 5 skills have non-trivial descriptions | All 5 have `description:` values longer than 10 characters |
| Skills visible to the system | After restart, OpenCode's skill list includes authmd-registration, awesome-differential-review, awesome-investigate, awesome-office-hours, review-loop |

---

### W11: Skill Collision Documentation

| Criterion | Verification |
|---|---|
| Collision report created | `planning/sprints/sprint-001/skill-collision-report.md` exists with side-by-side comparison |
| Per-skill decision documented for each of 54 collisions | Report lists each colliding skill with "keep local" / "keep external" / "keep both" |

---

### W12: references: Section

| Criterion | Verification |
|---|---|
| Either `references:` added to opencode.json OR documented as intentionally absent | Either the section exists and is populated, OR `planning/sprints/sprint-001/REFERENCES_DECISION.md` exists explaining why it is absent |

---

### W13: integration-test.js

| Criterion | Verification |
|---|---|
| File is either in plugin array OR deleted from disk | Either `opencode.json` contains `integration-test.js` in plugin array OR file does not exist at `plugins/integration-test.js` |

---

### W14: gate-system.log Rotation

| Criterion | Verification |
|---|---|
| gate-system.log is 0 bytes (new) | `Get-Item memory/gate-system.log).Length` = 0 |
| Archived log exists with timestamp | `Get-ChildItem memory/gate-system.*.log | Measure-Object` ≥ 1 |

---

### META: customize-opencode Skill

| Criterion | Verification |
|---|---|
| File exists at correct path | `Test-Path "skills/customize-opencode/SKILL.md"` = True |
| Skill has valid frontmatter (name, description) | Frontmatter parses correctly |
| Skill is referenced correctly in skill-learning and hermes-agent | No broken internal links |

---

## Final Verification Commands (Tier 1 — proves the whole pack works)

```powershell
# 1. JSON valid
Get-Content "C:\Users\Windows\.config\opencode\opencode.json" -Raw | ConvertFrom-Json | Out-Null
Write-Output "JSON: VALID"

# 2. No hardcoded keys
$raw = Get-Content "C:\Users\Windows\.config\opencode\opencode.json" -Raw
if ($raw -match 'gsk_\w+') { Write-Output "FAIL: groq hardcoded key" }
if ($raw -match 'sk-or-v1-\w+') { Write-Output "FAIL: openrouter hardcoded key" }
if ($raw -match 'csk-\w+') { Write-Output "FAIL: cerebras hardcoded key" }
Write-Output "API Keys: CLEAN"

# 3. No invalid permission keys
$invalid = @('write', 'filesystem', 'repo_clone', 'repo_overview',
              'account-manager', 'project-manager', 'solutions-architect',
              'tech-lead', 'delivery-engineer', 'qa-engineer')
$fail = $false
foreach ($k in $invalid) {
    if ($raw -match "`"$k`"") { Write-Output "FAIL: invalid permission key: $k"; $fail = $true }
}
if (-not $fail) { Write-Output "Permissions: CLEAN" }

# 4. No environment: (playwright) or args: (codebase-memory)
if ($raw -match '"environment":') { Write-Output "FAIL: playwright uses environment:" }
if ($raw -match '"args":') { Write-Output "FAIL: codebase-memory uses args:" }
if ($raw -notmatch '"environment":' -and $raw -notmatch '"args":') { Write-Output "MCP Config: CLEAN" }

# 5. Hook errors log empty
if ((Get-Item "C:\Users\Windows\.config\opencode\hook-errors.log").Length -eq 0) {
    Write-Output "Hook Errors: CLEAN"
} else {
    Write-Output "WARN: hook-errors.log has content"
}

# 6. customize-opencode skill exists
if (Test-Path "C:\Users\Windows\.config\opencode\skills\customize-opencode\SKILL.md") {
    Write-Output "customize-opencode: EXISTS"
} else {
    Write-Output "FAIL: customize-opencode skill missing"
}

# 7. All 10 plugins have usable exports (named OR default)
$pluginDir = "C:\Users\Windows\.config\opencode\plugins"
$plugins = Get-ChildItem $pluginDir -Filter "*.js"
$fail = $false
foreach ($p in $plugins) {
    $c = Get-Content $p.FullName -Raw
    if ($c -notmatch 'export (const|default)' ) {
        Write-Output "WARN: $($p.Name) has no export"
        $fail = $true
    }
}
if (-not $fail) { Write-Output "Plugins: CLEAN (have exports)" }

Write-Output "=== FINAL VERIFICATION COMPLETE ==="
```

---

*End of acceptance.md*