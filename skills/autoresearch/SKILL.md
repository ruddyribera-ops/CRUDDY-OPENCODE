---
name: autoresearch
description: Autonomous configuration improvement using iterative evaluation. Mirrors Karpathy's 3-file pattern with prepare.py (read-only eval), train.py (pointer), program.md (skill), and iterate.py (loop runner). Optimizes any config file against measurable metrics.
triggers: optimize, tune, improve, autoresearch, iterative
auto_load: code-builder, bug-fixer
---

# Autoresearch Skill

Autonomous configuration improvement using a fixed evaluation harness and iterative modification.

**When to use:** Optimize any single text file in the OpenCode config against a measurable metric. Use when tuning challenger rules, DNA thresholds, gate parameters, or any hand-tuned config that has a measurable outcome.

**What it does:** Mirrors Karpathy's 3-file autoresearch pattern:
- `prepare.py` — fixed evaluation harness (READ-ONLY, SHA-verified)
- `train.py` — pointer to the actual config file being improved
- `program.md` — the skill/content the agent reads to understand what to change
- `iterate.py` — the loop runner: read → change → eval → keep/revert → repeat

**Metrics supported:**
- `gate_failure_rate` — parse session_log.md + gate-check.ps1 output
- `routing_misroute_count` — count corrected routings in session_log.md
- `challenger_false_positive_rate` — count times user overrode challenger
- `file_token_count` — simple token counter for prompt size
- `test_pass_rate` — if tests exist
- Custom via JSON config

**Constraints:**
- Fixed time budget per run (default 5 min, configurable)
- Single metric per run
- Lower=better or higher=better (configurable direction)
- Idempotent: re-running picks up where results.tsv left off
- Parallel runs on same target detected via git lock

**Files created by this skill:**
- `scripts/autoresearch/prepare.py` — evaluation harness (do not modify)
- `scripts/autoresearch/train.py` — pointer file (the one you edit)
- `scripts/autoresearch/program.md` — this skill's content
- `scripts/autoresearch/iterate.py` — loop runner
- `scripts/autoresearch/results.tsv` — experiment log
- `scripts/autoresearch/analyze.py` — post-process results
- `scripts/autoresearch/README.md` — usage documentation
- `skills/autoresearch/references/examples.md` — 3 worked examples

**Usage:**
```powershell
# Dry-run to verify setup
uv run --no-project .\scripts\autoresearch\iterate.py --target .\rules\challenger-rule.md --metric challenger_false_positive_rate --budget 30s --dry-run

# Live 3-iteration run
uv run --no-project .\scripts\autoresearch\iterate.py --target .\rules\challenger-rule.md --metric challenger_false_positive_rate --budget 10s --max-iter 3

# Analyze results
uv run --no-project .\scripts\autoresearch\analyze.py --results .\scripts\autoresearch\results.tsv
```
