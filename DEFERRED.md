# Deferred Audit Items

This file tracks audit findings that were intentionally NOT fixed, with rationale.

---

## L-2: Hardcoded Windows paths in plugin configs (DEFERRED)

**Original finding:** 11 plugins referenced `C:\Users\Windows\...` directly in `opencode.json`.

**Why deferred:**
- `opencode.json` now uses `{env:USERPROFILE}` for plugin paths — RESOLVED via portability refactor.
- A small number of paths in factory/docs/ and scripts/hooks/ also referenced the user's home, and were converted to `~/.config/opencode/` notation (POSIX-style for human-readable docs) or `{env:USERPROFILE}` (for runtime substitution).
- The original "portability across machines" goal was achieved through these substitutions — `L-2` is no longer applicable in its original form.

**Recommendation:** No further action needed unless you migrate this config to a non-standard filesystem layout (e.g., XDG_CONFIG_HOME override on Linux).

---

## Other items deferred with rationale

| Item | Original severity | Why deferred |
|------|-------------------|--------------|
| M-2: `hook-errors.log` empty (5 bytes) | MEDIUM | Working as intended — no errors have occurred yet. Re-evaluate if log remains empty after extended use. |
| L-4: `hook-config.json` relative path | LOW | Works as-is in current setup. |
| L-6: `skills/*/sections/` and `skills/*/agents/` nested dirs | LOW | Cosmetic — these are skill scaffolds for specific projects. |
| L-7: `opencode.json` lacks `.jsonc` companion | LOW | Preference, not a bug. JSON-only is more portable. |

---

*Generated during the audit round 2026-06-26. See `audits/` for full reports.*
