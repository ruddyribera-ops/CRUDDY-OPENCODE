"""
Iterate.py — Autoresearch Loop Runner
Runs: read -> change -> eval -> keep/revert -> repeat.
Usage: python iterate.py --target <file> --metric <metric> [--budget <time>] [--max-iter <n>] [--dry-run]
Exit codes: 0=success, 1=not found, 2=unmeasurable, 3=budget exceeded, 4=SHA mismatch, 5=git lock
"""

import argparse
import hashlib
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

# Paths
CONFIG_DIR = Path.home() / ".config" / "opencode"
AUTORESEARCH_DIR = CONFIG_DIR / "scripts" / "autoresearch"
PREPARE_PY = AUTORESEARCH_DIR / "prepare.py"
RESULTS_TSV = AUTORESEARCH_DIR / "results.tsv"
GIT_DIR = CONFIG_DIR / ".git"
TS_FORMAT = "%Y-%m-%d %H:%M:%S"

def log(msg: str, level: str = "INFO"):
    print(f"[{datetime.now().strftime(TS_FORMAT)}] [{level}] {msg}", file=sys.stderr)

def compute_sha256(filepath: Path) -> str:
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        for b in iter(lambda: f.read(4096), b""):
            h.update(b)
    return h.hexdigest()

def run_prepare(target: Path, metric: str, baseline: bool = False) -> tuple[float, bool]:
    try:
        result = subprocess.run([sys.executable, str(PREPARE_PY), "--metric", metric, "--target", str(target)], capture_output=True, text=True, timeout=30)
        if result.returncode != 0:
            return -1.0, False
        return float(result.stdout.strip()), True
    except Exception:
        return -1.0, False

def git_revert_target(target: Path) -> bool:
    try:
        return subprocess.run(["git", "-C", str(CONFIG_DIR), "checkout", "--", str(target)], capture_output=True, timeout=10).returncode == 0
    except Exception:
        return False

def git_lock_exists() -> bool:
    return (GIT_DIR / "index.lock").exists()

def read_results() -> list[dict]:
    if not RESULTS_TSV.exists():
        return []
    results = []
    for line in RESULTS_TSV.read_text(encoding="utf-8", errors="ignore").split("\n")[1:]:
        if not line.strip():
            continue
        parts = line.split("\t")
        if len(parts) >= 7:
            results.append({"timestamp": parts[0], "experiment_id": parts[1], "change_summary": parts[2], "metric_before": float(parts[3]) if parts[3] else 0, "metric_after": float(parts[4]) if parts[4] else 0, "kept": parts[5] == "yes", "sha256": parts[6]})
    return results

def write_result(result: dict):
    header = "timestamp\texperiment_id\tchange_summary\tmetric_before\tmetric_after\tkept\tsha256"
    if not RESULTS_TSV.exists():
        RESULTS_TSV.write_text(header + "\n", encoding="utf-8")
    line = "\t".join([result["timestamp"], result["experiment_id"], result["change_summary"], str(result["metric_before"]), str(result["metric_after"]), "yes" if result["kept"] else "no", result["sha256"]])
    with open(RESULTS_TSV, "a", encoding="utf-8") as f:
        f.write(line + "\n")

def rotate_results_if_needed():
    if RESULTS_TSV.exists() and RESULTS_TSV.stat().st_size > 10 * 1024 * 1024:
        RESULTS_TSV.rename(AUTORESEARCH_DIR / f"results-{datetime.now().strftime('%Y%m%d-%H%M%S')}.tsv")

def parse_budget(s: str) -> float:
    s = s.lower().strip()
    if s.endswith("s"):
        return float(s[:-1])
    elif s.endswith("m"):
        return float(s[:-1]) * 60
    elif s.endswith("h"):
        return float(s[:-1]) * 3600
    return 300.0

def run_iteration(target: Path, metric: str, experiment_id: str, change_desc: str) -> dict:
    metric_before, ok = run_prepare(target, metric, baseline=False)
    if not ok or metric_before < 0:
        return {"experiment_id": experiment_id, "change_summary": change_desc, "metric_before": -1, "metric_after": -1, "kept": False, "status": "metric_unmeasurable"}
    metric_after, _ = run_prepare(target, metric, baseline=False)
    return {"timestamp": datetime.now().strftime(TS_FORMAT), "experiment_id": experiment_id, "change_summary": change_desc, "metric_before": metric_before, "metric_after": metric_after, "kept": metric_after < metric_before, "sha256": compute_sha256(target), "status": "ok"}

def make_dry_run_change(target: Path) -> str:
    if target.exists():
        lines = target.read_text(encoding="utf-8", errors="ignore").split("\n")
        return f"[dry-run] Would modify line ~{len(lines)//2}" if len(lines) > 5 else "[dry-run] Would make a small edit"
    return "[dry-run] Would make a small edit"

def iterate(target: Path, metric: str, budget: float = 300.0, max_iter: int = 100, dry_run: bool = False) -> int:
    log(f"Starting autoresearch loop")
    log(f"  target: {target}, metric: {metric}, budget: {budget}s, max_iter: {max_iter}, dry_run: {dry_run}")

    if not target.exists():
        log(f"Target file not found: {target}", "ERROR")
        return 1

    # Check prepare.py SHA
    sha_prepare = compute_sha256(PREPARE_PY)
    sha_file = AUTORESEARCH_DIR / "prepare.sha"
    expected_sha = sha_file.read_text().strip() if sha_file.exists() else (sha_file.write_text(sha_prepare) or sha_prepare)

    if sha_prepare != expected_sha:
        log(f"prepare.py SHA mismatch!", "ERROR")
        if not dry_run:
            return 4
        log("  Proceeding in dry-run mode...", "WARN")

    if git_lock_exists():
        log("Git lock detected — another run may be in progress. Exiting.", "ERROR")
        return 5

    rotate_results_if_needed()
    existing = read_results()
    start_iter = len(existing) + 1
    log(f"Resuming from iteration {start_iter} (found {len(existing)} existing results)")

    metric_initial, ok = run_prepare(target, metric, baseline=False)
    if not ok or metric_initial < 0:
        log("Initial metric unmeasurable — may need baseline. Use --init-baseline first.", "ERROR")
        return 2
    log(f"Initial metric value: {metric_initial}")

    start_time = time.time()
    experiments_kept = experiments_reverted = 0
    iteration = start_iter

    while iteration <= max_iter:
        elapsed = time.time() - start_time
        if elapsed >= budget:
            log(f"Budget exceeded ({elapsed:.1f}s >= {budget}s)", "WARN")
            log(f"  Experiments: {iteration - 1} total, Kept: {experiments_kept}, Reverted: {experiments_reverted}")
            write_result({"timestamp": datetime.now().strftime(TS_FORMAT), "experiment_id": "budget_exceeded", "change_summary": f"BUDGET_EXCEEDED after {iteration - 1} experiments", "metric_before": metric_initial, "metric_after": -1, "kept": False, "sha256": compute_sha256(target)})
            return 3

        experiment_id = f"exp-{iteration:04d}"
        if dry_run:
            change_desc = make_dry_run_change(target)
            result = run_iteration(target, metric, experiment_id, change_desc)
            result["status"] = "dry_run"
            log(f"[DRY-RUN] {experiment_id}: {change_desc}", "INFO")
            iteration += 1
            continue

        result = run_iteration(target, metric, experiment_id, f"[auto] iteration {iteration}")
        if result["status"] == "metric_unmeasurable":
            log(f"Metric became unmeasurable at iteration {iteration}", "ERROR")
            write_result(result)
            return 2

        if result["kept"]:
            experiments_kept += 1
            log(f"{experiment_id}: KEPT ({result['metric_before']:.4f} -> {result['metric_after']:.4f})", "OK")
        else:
            experiments_reverted += 1
            log(f"{experiment_id}: REVERTED ({result['metric_before']:.4f} -> {result['metric_after']:.4f})", "WARN")
            git_revert_target(target)

        write_result(result)
        iteration += 1

    log(f"Completed {iteration - 1} iterations, Kept: {experiments_kept}, Reverted: {experiments_reverted}")
    return 0

def main():
    parser = argparse.ArgumentParser(description="Autoresearch Loop Runner")
    parser.add_argument("--target", "-t", required=True)
    parser.add_argument("--metric", "-m", required=True)
    parser.add_argument("--budget", default="5m")
    parser.add_argument("--max-iter", type=int, default=100)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    return iterate(Path(args.target).resolve(), args.metric, parse_budget(args.budget), args.max_iter, args.dry_run)

if __name__ == "__main__":
    sys.exit(main())
