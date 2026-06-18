"""
Analyze.py — Post-Process Autoresearch Results
===============================================
Analyzes results.tsv and produces summary statistics.

Usage:
    python analyze.py --results <path_to_results.tsv>
    python analyze.py --results <path> --format table|json|summary

Exit codes:
    0  — success
    1  — results file not found
    2  — no data in results
"""

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional


def parse_results(path: Path) -> list[dict]:
    """Parse results.tsv into a list of dicts."""
    if not path.exists():
        return []
    
    results = []
    try:
        lines = path.read_text(encoding="utf-8", errors="ignore").split("\n")
        
        for line in lines[1:]:  # Skip header
            if not line.strip():
                continue
            parts = line.split("\t")
            if len(parts) >= 7:
                results.append({
                    "timestamp": parts[0],
                    "experiment_id": parts[1],
                    "change_summary": parts[2],
                    "metric_before": float(parts[3]) if parts[3] else 0,
                    "metric_after": float(parts[4]) if parts[4] else 0,
                    "kept": parts[5] == "yes",
                    "sha256": parts[6],
                })
    except Exception as e:
        print(f"Error parsing results: {e}", file=sys.stderr)
    
    return results


def analyze_results(results: list[dict]) -> dict:
    """
    Analyze results and produce summary statistics.
    """
    if not results:
        return {
            "total_experiments": 0,
            "error": "No data in results",
        }
    
    # Filter out budget_exceeded markers
    valid_results = [r for r in results if r["experiment_id"] != "budget_exceeded"]
    
    total = len(valid_results)
    kept = sum(1 for r in valid_results if r["kept"])
    reverted = total - kept
    
    # Calculate metric improvements
    improvements = []
    for r in valid_results:
        if r["metric_before"] > 0 and r["metric_after"] >= 0:
            delta = r["metric_before"] - r["metric_after"]
            improvements.append(delta)
    
    avg_improvement = sum(improvements) / len(improvements) if improvements else 0
    max_improvement = max(improvements) if improvements else 0
    min_improvement = min(improvements) if improvements else 0
    
    # Best experiment
    best_idx = -1
    best_delta = -float("inf")
    for i, r in enumerate(valid_results):
        if r["metric_before"] > 0 and r["metric_after"] >= 0:
            delta = r["metric_before"] - r["metric_after"]
            if delta > best_delta:
                best_delta = delta
                best_idx = i
    
    best_experiment = valid_results[best_idx] if best_idx >= 0 else None
    
    # Calculate time span
    timestamps = []
    for r in results:
        try:
            ts = datetime.strptime(r["timestamp"], "%Y-%m-%d %H:%M:%S")
            timestamps.append(ts)
        except Exception:
            pass
    
    time_span = ""
    if timestamps:
        delta = timestamps[-1] - timestamps[0]
        time_span = str(delta).split(".")[0]  # Remove microseconds
    
    return {
        "total_experiments": total,
        "kept": kept,
        "reverted": reverted,
        "keep_rate": kept / total if total > 0 else 0,
        "avg_improvement": avg_improvement,
        "max_improvement": max_improvement,
        "min_improvement": min_improvement,
        "best_experiment": best_experiment,
        "time_span": time_span,
        "budget_exceeded": any(r["experiment_id"] == "budget_exceeded" for r in results),
    }


def print_summary_table(stats: dict):
    """Print a summary table."""
    print("=" * 70)
    print("AUTORESEARCH RESULTS SUMMARY")
    print("=" * 70)
    print()
    print(f"  Total experiments:  {stats['total_experiments']}")
    print(f"  Kept:              {stats['kept']}")
    print(f"  Reverted:         {stats['reverted']}")
    print(f"  Keep rate:         {stats['keep_rate']:.1%}")
    print()
    print(f"  Avg improvement:   {stats['avg_improvement']:.4f}")
    print(f"  Max improvement:   {stats['max_improvement']:.4f}")
    print(f"  Min improvement:   {stats['min_improvement']:.4f}")
    print()
    
    if stats.get("time_span"):
        print(f"  Time span:         {stats['time_span']}")
    
    if stats.get("budget_exceeded"):
        print()
        print("  ⚠️  BUDGET EXCEEDED — partial results")
    
    print()
    
    if stats.get("best_experiment"):
        best = stats["best_experiment"]
        print("  BEST EXPERIMENT:")
        print(f"    ID:          {best['experiment_id']}")
        print(f"    Change:      {best['change_summary']}")
        print(f"    Metric:      {best['metric_before']:.4f} -> {best['metric_after']:.4f}")
        print(f"    Improvement: {best['metric_before'] - best['metric_after']:.4f}")
        print(f"    SHA256:      {best['sha256'][:16]}...")
    
    print()
    print("=" * 70)


def print_json(stats: dict):
    """Print stats as JSON."""
    # Convert best_experiment to JSON-serializable
    output = dict(stats)
    if output.get("best_experiment"):
        best = output["best_experiment"]
        output["best_experiment"] = {
            "experiment_id": best["experiment_id"],
            "change_summary": best["change_summary"],
            "metric_before": best["metric_before"],
            "metric_after": best["metric_after"],
            "improvement": best["metric_before"] - best["metric_after"],
            "sha256": best["sha256"],
        }
    print(json.dumps(output, indent=2))


def main():
    parser = argparse.ArgumentParser(description="Analyze Autoresearch Results")
    parser.add_argument("--results", "-r", required=True, help="Path to results.tsv")
    parser.add_argument("--format", "-f", choices=["table", "json", "summary"], default="table", help="Output format")
    
    args = parser.parse_args()
    
    results_path = Path(args.results).resolve()
    if not results_path.exists():
        print(f"Results file not found: {results_path}", file=sys.stderr)
        return 1
    
    results = parse_results(results_path)
    if not results:
        print("No data in results file", file=sys.stderr)
        return 2
    
    stats = analyze_results(results)
    
    if args.format == "json":
        print_json(stats)
    else:
        print_summary_table(stats)
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
