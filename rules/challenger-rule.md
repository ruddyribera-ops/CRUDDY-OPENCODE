## Challenger Rule (Scan BEFORE Routing — Literal Keyword Match)

**Before routing, run this exact keyword scan over the user's message** (case-insensitive). If ANY keyword matches, do NOT route yet — issue the Challenge Template response, then wait for the user.

### Matching Rules (Prevent False Positives)

- **Whole-token match only.** `--force` matches `--force` or `--force ` or end-of-line — does NOT match `--force-color`, `--forceful`, `--force-exit`.
- **`any` / `: any`** matches a TypeScript type annotation — does NOT match `anyone`, `company`, `many`.
- **`sleep(`** matches a function call — does NOT match "sleep cycle", "went to sleep".
- **`add redis`** requires both words adjacent — does NOT match "I want to add redirect logic".
- If a keyword appears inside a file path, URL, quoted string, or code comment the user is PASTING (not proposing), skip the challenge — they're showing, not asking.

### Trigger Keywords (scan for these exact phrases)

> ðŸ”„ **SYNC:** These keywords are also maintained in `skills/DNA.yaml` ↑ `COORD-003` triggers.
> Add new risky patterns to **both files** — the challenger rule handles interaction (what the user sees),
> DNA.yaml handles context injection (what the agent receives). One system, two mechanisms.

| Category | Keywords/phrases to match | Mandatory challenge |
|---|---|---|
| Weak crypto | `md5`, `sha1`, `sha-1`, `plain text password`, `encrypt password`, `custom hash`, `obfuscate password` | "That's broken for passwords — bcrypt or argon2. Use one of those?" |
| Auth shortcuts | `skip auth`, `disable auth`, `bypass login`, `no auth for now`, `trust the client`, `skip jwt` | "Skipping auth ships a security hole. Minimal auth (bcrypt + session cookie) is 20 lines. Do that instead?" |
| Silent failure | `except: pass`, `except Exception: pass`, `catch (e) {}`, `catch {}`, `swallow error`, `ignore error` | "Silencing errors hides the bug that will bite next. Log it at minimum. Proceed with logging + re-raise?" |
| Type escape | `ts-ignore`, `@ts-ignore`, `: any`, `as any`, `noqa`, `# type: ignore` | "That mutes the type checker that's trying to tell you something. Want to fix the underlying type instead?" |
| Destructive git | `--force`, `-f ` (in git context), `--no-verify`, `reset --hard`, `push --force`, `force push`, `skip hooks` | "That's destructive/skips safety. Confirm you mean it, or want the safer form?" |
| Overkill stack | `add redis`, `add kafka`, `add microservice`, `kubernetes`, `rewrite in`, `migrate to (new framework)` | "That's heavy for the current scale. Start simpler (name the lighter option). Upgrade only when you hit a real wall?" |
| Deploy-and-pray | `deploy without test`, `skip tests`, `just push it`, `test in prod`, `we'll fix it in prod` | "On Railway, stale-build caching has burned you before. Want the commit-hash-verify step from `deployment-patterns` first?" |
| Fresh-DB amnesia | `new deploy`, `first deploy`, `fresh database`, `empty db`, `reset db` (without "seed" mentioned) | "Fresh DB means no users = broken login. Confirm seed-on-startup is wired (see `database-patterns` + `deployment-patterns` first-deploy checklist)?" |
| Timer-based fixes | `sleep(`, `setTimeout` (for "waiting for something to be ready"), `wait_for_timeout`, `time.sleep` in a test | "Timers flake under load (see `feedback_e2e_waits.md`). Want `wait_for_selector` / polling / explicit signal instead?" |
| Fresh-package risk | `pip install`, `npm install`, `add` (any package name) — when the package is unknown to the project | "That package was released recently / is unfamiliar. Check if it's older than 14 days before installing. New packages are the #1 supply-chain attack vector. Proceed with audit anyway?" |

### Challenge Template (use this exact shape)

```
âš ï¸ [one-sentence naming what's risky]
   Better: [one-sentence alternative]
   Proceed as-is anyway? (yes/no)
```

### When to Skip the Challenge

- User typed "yes proceed" / "I know, do it anyway" / "override" / "procede" in the SAME message
- **Session memory:** If you already challenged this exact category in this session AND the user confirmed ↑ skip. Re-challenging the same approved pattern IS a loop bug.
- Purely stylistic (2 vs 4 spaces, single vs double quotes, variable naming)
- Trivial direct-work cases (see below)
- Keyword appeared inside a paste/quote/path, not as the user's proposal (per Matching Rules above)

### After the Challenge

- User says "no, use the better way" ↑ route to the specialist with the corrected ask
- User says "yes, do it my way" ↑ route with the original ask, don't re-challenge
- User explains a valid reason you didn't see ↑ route with the original ask

**Do not moralize. Do not repeat the challenge. One sentence, one alternative, then act.**

### Graph Write on Override (fire-and-forget)

When the user overrides a challenge, the T6 trigger (session_machine.ps1) fires FIRST
to create the Decision node. Then the graph write adds the RuleChallenge node and
the overrides edge. Both are non-blocking — the override is already logged in session.yaml.

**Sequence:**
1. Challenger fires → capture `$decision_id = "Decision-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')"`
2. User confirms override → T6 fires: `session_machine.ps1 -Trigger T6 -Decision "Challenger-Override: $pattern" ...`
3. Graph write (fire-and-forget):
```powershell
try {
  $challengeNode = & node "$CONFIG\scripts\graph-memory.js" create-node --type rule_challenge --name "RuleChallenge-$override_pattern" --data '{"pattern":"$override_pattern","user_response":"proceed","timestamp":"'$(Get-Date -Format o)'"}' 2>$null
  if ($challengeNode -and $decision_id) {
    & node "$CONFIG\scripts\graph-memory.js" create-edge --from $decision_id --to $challengeNode --type overrides 2>$null
  }
} catch {
  # Non-blocking -- the override is already logged in session.yaml
}
```

**RuleChallenge node** schema:
- `@type`: rule_challenge
- `name`: RuleChallenge-{pattern}-{timestamp}
- `data.pattern`: the risky keyword that triggered the challenge
- `data.user_response`: "proceed" or the user's actual words
- `data.timestamp`: ISO datetime

**Edge `overrides`:** Decision-{id} → RuleChallenge-{pattern}-{timestamp}

