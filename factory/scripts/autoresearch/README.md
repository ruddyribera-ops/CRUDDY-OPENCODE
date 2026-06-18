# Autoresearch — README

Autonomous configuration improvement using iterative evaluation.

## Overview

This system adapts Karpathy's 3-file autoresearch pattern to improve OpenCode config files against measurable metrics. It runs iterative experiments: make a change, evaluate, keep or revert, repeat.

## Files

| File | Purpose | Read-Only? |
|------|---------|------------|
| `prepare.py` | Evaluation harness — computes metrics | YES (SHA-verified) |
| `train.py` | Pointer to target file | NO (but agent edits target) |
| `program.md` | Skill content for the agent | NO |
| `iterate.py` | Loop runner | NO |
| `results.tsv` | Experiment log | Append-only |
| `analyze.py` | Post-process results | NO |

## Quick Start

### 1. Verify Setup (Dry-Run)

```powershell
uv run --no-project .\scripts\autoresearch\iterate.py `
  --target .\rules\challenger-rule.md `
  --metric challenger_false_positive_rate `
  --budget 30s `
  --dry-run
```

Expected output:
```
[setup ok, target loaded, metric computed: X.XX, dry-run complete, ready for live loop]
```

### 2. Initialize Baseline (if needed)

```powershell
uv run --no-project .\scripts\autoresearch\prepare.py `
  --metric challenger_false_positive_rate `
  --target .\rules\challenger-rule.md `
  --init-baseline
```

### 3. Run Live Experiment

```powershell
uv run --no-project .\scripts\autoresearch\iterate.py `
  --target .\rules\challenger-rule.md `
  --metric challenger_false_positive_rate `
  --budget 10s `
  --max-iter 3
```

### 4. Analyze Results

```powershell
uv run --no-project .\scripts\autoresearch\analyze.py `
  --results .\scripts\autoresearch\results.tsv
```

## Metrics

| Metric | Lower is Better | Needs Baseline | Description |
|--------|-----------------|---------------|-------------|
| `gate_failure_rate` | Yes | Yes | Gate check failure rate |
| `routing_misroute_count` | Yes | Yes | Corrected routing decisions |
| `challenger_false_positive_rate` | Yes | Yes | Challenger rule overrides |
| `file_token_count` | Yes | No | Token count for target file |
| `test_pass_rate` | No | No | Pytest pass rate |
| `<custom>` | — | — | Load from `metrics.json` |

## Metrics Configuration

Create `scripts/autoresearch/metrics.json` for custom metrics:

```json
{
  "my_metric": {
    "lower_is_better": true,
    "needs_baseline": false,
    "command": ["python", "custom_metric.py", "--target", "{target}"],
    "parse_output": "float"
  }
}
```

## Edge Cases

### Target file doesn't exist
```
iterate.py exits with code 2 + clear error
```

### Metric unmeasurable
```
Returns "needs baseline, run --init-baseline first"
```

### Edit causes syntax error
```
git-revert automatically, log "syntax_fail" in results.tsv
```

### Loop exceeds budget
```
Auto-abort with "budget_exceeded" marker, partial results preserved
```

### Two parallel runs on same target
```
Second run detects git-lock and exits cleanly (code 5)
```

### prepare.py is modified by user
```
Detect via SHA, refuse to run, prompt to revert (code 3)
```

### results.tsv grows past 10MB
```
Auto-rotate to results-{date}.tsv
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Completed successfully |
| 1 | Target file not found |
| 2 | Metric unmeasurable |
| 3 | Budget exceeded |
| 4 | prepare.py SHA mismatch |
| 5 | Git lock detected (parallel run) |
| 99 | Keyboard interrupt |

## Experiment Log Format

`results.tsv` columns:
```
timestamp | experiment_id | change_summary | metric_before | metric_after | kept (yes/no) | sha256
```

## Idempotency

Re-running `iterate.py` on the same target picks up where the last run left off. The experiment ID is incremented based on existing results.

## Custom Metrics

To add a custom metric:

1. Create the metric script (e.g., `my_metric.py`)
2. Add configuration to `metrics.json`
3. Use `--metric my_metric` in iterate.py

## Tips

- Start with `--dry-run` to verify setup
- Use `--budget 30s` for quick tests
- Use `--max-iter 10` for longer experiments
- Check `results.tsv` manually between runs for manual intervention
- The best experiment SHA is preserved — you can `git show <sha>` to see what changed
