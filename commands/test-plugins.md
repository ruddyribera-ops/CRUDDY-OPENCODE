---
description: Run plugin test suite — verifies all 8 OpenCode plugins load and the 3 performance improvements (pattern cache, lint debounce, LRU eviction) work correctly.
usage: /test-plugins
---

# /test-plugins — Plugin Health Check

Runs the regression test suite for all OpenCode plugins. **Run this after any plugin edit** to catch regressions before they hit production.

## What It Tests

| # | Test | What it verifies |
|---|---|---|
| 1 | Plugin load | All 8 plugins import without syntax errors, expected exports exist |
| 2 | Pattern cache | `pre-tool-guard.js` warm-up log fires on module load (72 patterns across 7 categories) |
| 3 | Lint debounce | 20 file writes batch into ≤3 lint runs (proves the 5s setTimeout debounce works) |
| 4 | LRU eviction | `memory-bridge.js` handles 150 sessions without crash, `trackActivity` cap is reasonable (50-500) |

## Execution

```bash
node --test "$env:USERPROFILE\.config\opencode\scripts\test-plugins.mjs"
```

## Expected Output

```
▶ Plugin test suite
  ✓ All 8 plugins loaded successfully
  ✔ [load] all plugins importable from their directory
▶ Performance improvements
  ✓ Cache warmed: 72 patterns, 7 categories
  ✓ 1 batch(es) for 20 writes (proves debounce works)
  ✓ 150 sessions processed, LRU cap = 100, trackActivity wired
✔ 4 tests pass, 0 fail
```

## Exit Codes

- `0` — all tests pass
- `1` — any test fails (full output above shows which one)

## When To Use

- **Before committing** any plugin change
- **After OpenCode restart** to confirm plugins loaded correctly
- **After upgrading Node.js** (in case ESM semantics changed)
- **Periodically** (e.g., weekly) to catch silent breakage

## What It Catches

Recent bugs this test caught:
- `require("node:fs")` in ESM `setImmediate` (Phase 1 — would have been silent)
- Self-reference bug from find-replace in 3 plugin refactors (Phase 2)
- Missing `appendFileSync` import after refactor (Phase 2)

Without this test, all three would have shipped as silent failures in production.

## When NOT to Use

- During a long session (debounce test waits 5.5 seconds)
- When testing edge cases (this is a smoke test, not exhaustive)

## Related

- `scripts/test-perf-improvements.mjs` — original 3-test version
- `scripts/test-plugins.mjs` — current 4-test version (plugin load + 3 perf)
- `commands/review.md` — code review (different concern)
- `commands/rules.md` — rules engine check (different concern)
