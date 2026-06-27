# Verification Depth Rule

## Tiers

| Tier | Name | Evidence | Required For |
|------|------|----------|-------------|
| 0 | File check | "Created file X" | NOT valid |
| 1 | Runtime | curl output, test pass, screenshot | All tasks |
| 2 | Integration | Full test suite pass, cross-feature check | Multi-file changes |
| 3 | Edge case | Empty input, error state, load test | Production blockers |

## Coordinator Gate

When specialist returns "done":
1. **Tier ≥1?** No → REJECT
2. **Evidence specific (not just number)?** No → REJECT
3. **Multi-file + Tier <2?** No → REJECT

## Examples

| Specialist reports | Tier | Verdict |
|-------------------|------|---------|
| "12/12 schemas created" | 0 | ❌ REJECT — file check only |
| "curl /api/motores → 200 OK" | 1 | ✅ PASS (single file) |
| "Full test suite: 45 passed, 0 failed" + file list | 2 | ✅ PASS (multi-file) |
| Same as above + "Tested with empty input → 422, tested with 200KB PDF → 200" | 3 | ✅ PASS (edge cases) |
