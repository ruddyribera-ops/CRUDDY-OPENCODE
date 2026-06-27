"""
OpenSource — Fetch library source code as agent context.
Inspired by @mickey's workflow: clone any open-source repo so the agent reads code, not docs.

Usage:
  python opensource.py <github-url> [--dir <target>]

  python opensource.py https://github.com/streamlit/streamlit
  python opensource.py https://github.com/fastapi/fastapi --dir _source
  python opensource.py list                          # Show cloned repos with sizes
  python opensource.py clean                         # Remove all cloned repos

The cloned code goes into <project>/_source/<org>/<repo>/ so the agent can
reference it: "Look at _source/streamlit/ to understand how session_state works."
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path


def _ensure_git():
    """Check git is available."""
    try:
        subprocess.run(["git", "--version"], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False
    return True


def _project_root():
    """Find project root (where _source dir will live)."""
    cwd = Path.cwd()
    # Check if we're in .config/opencode — if so, use desktop or tmp
    if ".config\\opencode" in str(cwd) or ".config/opencode" in str(cwd):
        return Path.home() / "Desktop"
    return cwd


def cmd_clone(url, target_dir=None):
    if not _ensure_git():
        return {"ok": False, "error": "git not found — install git first"}

    root = _project_root()
    source_dir = root / (target_dir or "_source")

    # Parse org/repo from URL
    url = url.rstrip("/").removesuffix(".git")
    parts = url.split("/")
    if len(parts) < 2:
        return {"ok": False, "error": f"invalid URL: {url}"}
    org, repo = parts[-2], parts[-1]
    dest = source_dir / org / repo

    if dest.exists():
        # Already cloned — pull latest
        try:
            subprocess.run(["git", "pull", "--ff-only"], cwd=dest, capture_output=True, check=False, timeout=30)
            size = _dir_size(dest)
            return {"ok": True, "data": {"path": str(dest), "action": "updated", "size_kb": size}}
        except Exception:
            return {"ok": True, "data": {"path": str(dest), "action": "exists", "size_kb": _dir_size(dest)}}

    # Clone
    dest.mkdir(parents=True, exist_ok=True)
    try:
        start = time.time()
        proc = subprocess.run(
            ["git", "clone", "--depth=1", url, str(dest)],
            capture_output=True, text=True, timeout=120
        )
        elapsed = time.time() - start
        if proc.returncode != 0:
            shutil.rmtree(dest, ignore_errors=True)
            return {"ok": False, "error": f"clone failed: {proc.stderr.strip()}"}
        size = _dir_size(dest)
        return {
            "ok": True,
            "data": {
                "path": str(dest),
                "action": "cloned",
                "seconds": round(elapsed, 1),
                "size_kb": size,
                "files": _file_count(dest),
            }
        }
    except subprocess.TimeoutExpired:
        shutil.rmtree(dest, ignore_errors=True)
        return {"ok": False, "error": "clone timed out (120s)"}
    except Exception as e:
        shutil.rmtree(dest, ignore_errors=True)
        return {"ok": False, "error": str(e)}


def cmd_list(target_dir=None):
    root = _project_root()
    source_dir = root / (target_dir or "_source")
    if not source_dir.exists():
        return {"ok": True, "data": {"repos": [], "total_size_kb": 0}}

    repos = []
    total_size = 0
    for org_dir in sorted(source_dir.iterdir()):
        if org_dir.is_dir():
            for repo_dir in sorted(org_dir.iterdir()):
                if repo_dir.is_dir():
                    size = _dir_size(repo_dir)
                    total_size += size
                    repos.append({
                        "org": org_dir.name,
                        "repo": repo_dir.name,
                        "size_kb": size,
                        "files": _file_count(repo_dir),
                    })
    return {"ok": True, "data": {"repos": repos, "total_size_kb": total_size, "dir": str(source_dir)}}


def cmd_clean(target_dir=None):
    root = _project_root()
    source_dir = root / (target_dir or "_source")
    if source_dir.exists():
        shutil.rmtree(source_dir)
        return {"ok": True, "data": f"removed {source_dir}"}
    return {"ok": True, "data": "nothing to clean"}


def _dir_size(path):
    total = 0
    for f in path.rglob("*"):
        if f.is_file():
            try:
                total += f.stat().st_size
            except OSError:
                pass
    return round(total / 1024)


def _file_count(path):
    return sum(1 for _ in path.rglob("*") if _.is_file())


def main():
    parser = argparse.ArgumentParser(description="OpenSource — fetch library source code for agent context")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_clone = sub.add_parser("clone")
    p_clone.add_argument("url", help="GitHub repo URL (e.g., https://github.com/streamlit/streamlit)")
    p_clone.add_argument("--dir", default="_source", help="Target directory (default: _source/)")

    p_list = sub.add_parser("list")
    p_list.add_argument("--dir", default="_source")

    p_clean = sub.add_parser("clean")
    p_clean.add_argument("--dir", default="_source")

    args = parser.parse_args()

    cmd_map = {
        "clone": lambda: cmd_clone(args.url, args.dir),
        "list": lambda: cmd_list(args.dir),
        "clean": lambda: cmd_clean(args.dir),
    }

    result = cmd_map[args.cmd]()
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
