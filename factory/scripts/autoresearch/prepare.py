"""
Autoresearch Evaluation Harness — READ-ONLY
SHA-verified before each run. DO NOT MODIFY.
Usage: python prepare.py --metric <name> --target <path> [--baseline]
Metrics: gate_failure_rate, routing_misroute_count, challenger_false_positive_rate, file_token_count, test_pass_rate, <custom>
Exit codes: 0=success, 1=unmeasurable, 2=not found, 3=SHA mismatch, 4=invalid metric
"""

import argparse
import hashlib
import json
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

# Paths
CONFIG_DIR = Path.home() / ".config" / "opencode"
MEMORY_DIR = CONFIG_DIR / "memory"
AUTORESEARCH_DIR = Path(__file__).parent
SHA_FILE = AUTORESEARCH_DIR / "prepare.sha"

def compute_sha256(filepath: Path) -> str:
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        for b in iter(lambda: f.read(4096), b""):
            h.update(b)
    return h.hexdigest()

# READ-ONLY enforcement: store SHA on first run, compare on subsequent runs
EXPECTED_SHA = compute_sha256(Path(__file__)) if SHA_FILE.exists() else (SHA_FILE.write_text(compute_sha256(Path(__file__))) or compute_sha256(Path(__file__)))

METRICS_CONFIG = {
    "gate_failure_rate": {"lower_is_better": True, "needs_baseline": True, "description": "Gate check failure rate"},
    "routing_misroute_count": {"lower_is_better": True, "needs_baseline": True, "description": "Corrected routing decisions"},
    "challenger_false_positive_rate": {"lower_is_better": True, "needs_baseline": True, "description": "Challenger rule overrides"},
    "file_token_count": {"lower_is_better": True, "needs_baseline": False, "description": "Token count for target file"},
    "test_pass_rate": {"lower_is_better": False, "needs_baseline": False, "description": "Pytest pass rate"},
}

def verify_sha() -> bool:
    actual = compute_sha256(Path(__file__))
    if actual != EXPECTED_SHA:
        print(f"[prepare.py] SHA mismatch! Expected: {EXPECTED_SHA[:16]}..., Actual: {actual[:16]}...", file=sys.stderr)
        return False
    return True

# Metric implementations
def metric_gate_failure_rate(target: Path, baseline: bool = False) -> float:
    gate_log = MEMORY_DIR / "gate-system.log"
    if not gate_log.exists():
        return -1.0
    try:
        content = gate_log.read_text(encoding="utf-8", errors="ignore")
        total = failures = 0
        for line in content.split("\n"):
            if "[gate-check]" in line:
                total += 1
                if "FAIL" in line:
                    failures += 1
        return failures / total if total > 0 else -1.0
    except Exception:
        return -1.0

def metric_routing_misroute_count(target: Path, baseline: bool = False) -> float:
    session_log = MEMORY_DIR / "session_log.md"
    if not session_log.exists():
        return -1.0
    try:
        content = session_log.read_text(encoding="utf-8", errors="ignore")
        return float(content.count("routing") + content.count("RouteChange") + content.count("misroute"))
    except Exception:
        return -1.0

def metric_challenger_false_positive_rate(target: Path, baseline: bool = False) -> float:
    session_log = MEMORY_DIR / "session_log.md"
    if not session_log.exists():
        return -1.0
    try:
        content = session_log.read_text(encoding="utf-8", errors="ignore")
        return float(content.count("Challenger-Override") + content.count("override") + content.count("proceed"))
    except Exception:
        return -1.0

def metric_file_token_count(target: Path, baseline: bool = False) -> float:
    if not target.exists():
        return -1.0
    try:
        content = target.read_text(encoding="utf-8", errors="ignore")
        try:
            import tiktoken
            enc = tiktoken.get_encoding("cl100k_base")
            return float(len(enc.encode(content)))
        except ImportError:
            return float(len(content) / 4)
    except Exception:
        return -1.0

def metric_test_pass_rate(target: Path, baseline: bool = False) -> float:
    try:
        result = subprocess.run(["python", "-m", "pytest", "--tb=no", "-q"], capture_output=True, text=True, timeout=60)
        output = result.stdout + result.stderr
        passed = int(re.search(r"(\d+) passed", output).group(1)) if re.search(r"(\d+) passed", output) else 0
        failed = int(re.search(r"(\d+) failed", output).group(1)) if re.search(r"(\d+) failed", output) else 0
        return passed / (passed + failed) if (passed + failed) > 0 else -1.0
    except Exception:
        return -1.0

def metric_custom(target: Path, metric_name: str, baseline: bool = False) -> float:
    config_path = AUTORESEARCH_DIR / "metrics.json"
    if not config_path.exists():
        return -1.0
    try:
        config = json.loads(config_path.read_text(encoding="utf-8"))
        if metric_name not in config:
            return -1.0
        cfg = config[metric_name]
        cmd = [c.replace("{target}", str(target)) for c in cfg["command"]]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        parse_mode = cfg.get("parse_output", "float")
        if parse_mode == "float":
            return float(result.stdout.strip())
        elif parse_mode.startswith("json:"):
            key = parse_mode.split(":", 1)[1]
            return float(json.loads(result.stdout)[key])
        return -1.0
    except Exception:
        return -1.0

METRIC_FUNCTIONS = {
    "gate_failure_rate": metric_gate_failure_rate,
    "routing_misroute_count": metric_routing_misroute_count,
    "challenger_false_positive_rate": metric_challenger_false_positive_rate,
    "file_token_count": metric_file_token_count,
    "test_pass_rate": metric_test_pass_rate,
}

def compute_metric(metric_name: str, target: Path, baseline: bool = False) -> tuple[float, dict]:
    if metric_name not in METRIC_FUNCTIONS:
        value = metric_custom(target, metric_name, baseline)
        return (value, {"source": "custom", "metric": metric_name}) if value >= 0 else (-1.0, {"error": f"unknown metric: {metric_name}"})
    func = METRIC_FUNCTIONS[metric_name]
    value = func(target, baseline)
    return value, {"source": metric_name, "metric": metric_name, "lower_is_better": METRICS_CONFIG.get(metric_name, {}).get("lower_is_better", True)}

def list_metrics():
    print("Available metrics:")
    for name, cfg in sorted(METRICS_CONFIG.items()):
        print(f"  {name}: {cfg['description']} (lower_is_better={cfg['lower_is_better']})")
    print("  <custom>: Load from metrics.json")

def main():
    parser = argparse.ArgumentParser(description="Autoresearch Evaluation Harness (READ-ONLY)")
    parser.add_argument("--metric", "-m", help="Metric to compute")
    parser.add_argument("--target", "-t", help="Target file to evaluate")
    parser.add_argument("--baseline", action="store_true", help="Compute baseline value")
    parser.add_argument("--list-metrics", action="store_true", help="List all available metrics")
    parser.add_argument("--verify", action="store_true", help="Verify SHA and exit")
    parser.add_argument("--init-baseline", help="Initialize baseline for a metric")
    args = parser.parse_args()

    if args.verify:
        return 0 if verify_sha() else 3

    if args.list_metrics:
        list_metrics()
        return 0

    if args.init_baseline:
        target = Path(args.target) if args.target else None
        if not target or not target.exists():
            return 2
        value, _ = compute_metric(args.init_baseline, target, baseline=True)
        if value < 0:
            return 1
        (AUTORESEARCH_DIR / f"baseline-{args.init_baseline}.json").write_text(json.dumps({"metric": args.init_baseline, "target": str(target), "value": value, "timestamp": datetime.now().isoformat()}, indent=2))
        print(f"Baseline initialized: {value}")
        return 0

    if not args.metric or not args.target:
        return 4 if not args.metric else 2

    target = Path(args.target)
    if not target.exists():
        return 2

    if not verify_sha():
        return 3

    value, info = compute_metric(args.metric, target, args.baseline)
    if value < 0:
        print(f"Metric {args.metric} is unmeasurable", file=sys.stderr)
        return 1

    print(f"{value}")
    print(json.dumps(info), file=sys.stderr)
    return 0

if __name__ == "__main__":
    sys.exit(main())
