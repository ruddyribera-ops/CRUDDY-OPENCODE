# Autoresearch Examples — 3 Worked Examples

## Example 1: Reducing Challenger False Positives

**Target:** `rules/challenger-rule.md`
**Metric:** `challenger_false_positive_rate`
**Goal:** Reduce the rate at which users override the challenger rule

### Setup

```powershell
# Initialize baseline
uv run --no-project .\scripts\autoresearch\prepare.py `
  --metric challenger_false_positive_rate `
  --target .\rules\challenger-rule.md `
  --init-baseline
```

### Iteration Log

| Iter | Change | Before | After | Kept? |
|------|--------|--------|-------|-------|
| 1 | Added "I know, do it anyway" to skip list | 0.15 | 0.12 | yes |
| 2 | Added "override" to skip list | 0.12 | 0.10 | yes |
| 3 | Added "procede" to skip list | 0.10 | 0.11 | no (reverted) |

### Result

Best experiment saved: `exp-0002`
Final metric: 0.10 (33% improvement from baseline)

---

## Example 2: Reducing Gate Failure Rate

**Target:** `rules/gate-system.md`
**Metric:** `gate_failure_rate`
**Goal:** Reduce the rate of gate check failures

### Setup

```powershell
# Initialize baseline
uv run --no-project .\scripts\autoresearch\prepare.py `
  --metric gate_failure_rate `
  --target .\rules\gate-system.md `
  --init-baseline
```

### Iteration Log

| Iter | Change | Before | After | Kept? |
|------|--------|--------|-------|-------|
| 1 | Relaxed "summary-sha" proof type tolerance | 0.22 | 0.18 | yes |
| 2 | Added more proof types for edge cases | 0.18 | 0.19 | no (reverted) |
| 3 | Simplified gate state initialization | 0.18 | 0.15 | yes |

### Result

Best experiment saved: `exp-0003`
Final metric: 0.15 (32% improvement from baseline)

---

## Example 3: Optimizing File Token Count

**Target:** `agents/code-builder.md`
**Metric:** `file_token_count`
**Goal:** Reduce the token count to improve prompt efficiency

### Setup

```powershell
# Initialize baseline
uv run --no-project .\scripts\autoresearch\prepare.py `
  --metric file_token_count `
  --target .\agents\code-builder.md `
  --init-baseline
```

### Iteration Log

| Iter | Change | Before | After | Kept? |
|------|--------|--------|-------|-------|
| 1 | Removed redundant examples section | 2400 | 2100 | yes |
| 2 | Shortened step descriptions | 2100 | 1950 | yes |
| 3 | Consolidated similar rules | 1950 | 2000 | no (reverted) |

### Result

Best experiment saved: `exp-0002`
Final metric: 1950 tokens (17% reduction from baseline)

---

## Common Patterns

### Pattern 1: Start with Baseline
Always initialize baseline before running experiments on metrics that need it.

### Pattern 2: Small Changes First
Start with small, surgical changes. Large rewrites are harder to evaluate and revert.

### Pattern 3: Keep a Change Log
Document what you changed and why in `change_summary` for later analysis.

### Pattern 4: Watch for Reverts
If a change is reverted, examine why. Sometimes the "worse" metric is actually correct behavior.

### Pattern 5: Budget Management
- Quick test: `--budget 30s --max-iter 5`
- Full run: `--budget 5m --max-iter 100`
- Overnight: `--budget 1h --max-iter 1000`
