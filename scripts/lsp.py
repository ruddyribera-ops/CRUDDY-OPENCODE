"""
Diagnostics wrapper â€” runs pyright type checker.

Usage:
  python lsp.py check <file-or-dir>    # Run type checker
  python lsp.py status                  # Check if pyright is available

Returns JSON with results.
"""
import argparse
import json
import os
import subprocess
import sys
from pathlib import Path


    # Try pip-installed pyright
    for path_env in os.environ.get("PATH", "").split(";"):
        for name in ("pyright", "pyright.exe", "pyright.cmd"):
            p = Path(path_env) / name
            if p.exists():
                return str(p)

    # Try node-based pyright
    try:
        result = subprocess.run(
            ["npx", "--yes", "pyright", "--version"],
            capture_output=True, text=True, timeout=30
        )
        if result.returncode == 0:
            return "npx pyright"
    except Exception:
        pass

    # Try pip-based pyright
    try:
        result = subprocess.run(
            [sys.executable, "-m", "pyright", "--version"],
            capture_output=True, text=True, timeout=30
        )
        if result.returncode == 0:
            return f"{sys.executable} -m pyright"
    except Exception:
        pass

    return None


def cmd_check(path):
    """Run pyright type checker on a file or directory."""
    pyright = _find_pyright()
    if not pyright:
        return {"ok": False, "error": "pyright not found. Install: pip install pyright"}

    p = Path(path)
    if not p.exists():
        return {"ok": False, "error": f"path not found: {path}"}

    cmd = pyright.split() + [str(p.absolute())]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120, cwd=str(p.parent if p.is_file() else p))
        return {
            "ok": result.returncode == 0,
            "data": {
                "path": str(p),
                "exit_code": result.returncode,
                "issues_count": len([l for l in result.stdout.split("\n") if "error" in l.lower() or "warning" in l.lower()]),
                "output_last_20": "\n".join(result.stdout.split("\n")[-20:]),
            }
        }
    except subprocess.TimeoutExpired:
        return {"ok": False, "error": "pyright check timed out (120s)"}
    except Exception as e:
        return {"ok": False, "error": str(e)}


def cmd_status():
    """Check if LSP tools are available."""
    status = {}
    status["pyright"] = _find_pyright() is not None
    return {"ok": True, "data": status}


def main():
    parser = argparse.ArgumentParser(description="LSP Wrapper for agent code intelligence")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_check = sub.add_parser("check")
    p_check.add_argument("path", help="File or directory to type-check")

    sub.add_parser("status")

    args = parser.parse_args()

    if args.cmd == "check":
        result = cmd_check(args.path)
    elif args.cmd == "status":
        result = cmd_status()

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
