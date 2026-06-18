#!/usr/bin/env python3
"""File watcher for memory/ directory — rebuilds index on .md file changes.

Uses stdlib only (no watchdog). Polls os.stat mtime with debouncing.
Stop flag: if .opencode/watcher.stop exists, exit cleanly.
"""
import os
import sys
import time
import threading
from pathlib import Path

OPENCODE_ROOT = Path(os.environ.get("OPENCODE_ROOT") or r"<INSTALL_DIR>/.config\opencode")
WATCH_DIR = OPENCODE_ROOT / "memory"
DB_PATH = OPENCODE_ROOT / ".opencode" / "memory.db"
STOP_FLAG = OPENCODE_ROOT / ".opencode" / "watcher.stop"
LOG_FILE = OPENCODE_ROOT / "memory" / "watcher.log"
DEBOUNCE_SECS = int(os.environ.get("WATCHER_DEBOUNCE_SECS", "10"))
POLL_INTERVAL = 2  # seconds between stat checks


def log(msg: str) -> None:
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    line = f"{ts} {msg}"
    print(line)
    try:
        LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(line + "\n")
    except Exception:
        pass  # Never crash due to logging failures


def get_md_mtimes() -> dict:
    """Return {filepath: mtime} for all .md files in WATCH_DIR."""
    mtimes = {}
    if WATCH_DIR.is_dir():
        for fp in WATCH_DIR.rglob("*.md"):
            try:
                mtimes[str(fp)] = fp.stat().st_mtime
            except OSError:
                pass
    return mtimes


def trigger_rebuild() -> None:
    """Run the memory retrieval indexer."""
    log("Index rebuild triggered")
    try:
        import subprocess
        env = os.environ.copy()
        env["PYTHONPATH"] = str(WATCH_DIR.parent / "scripts")
        cmd = [
            sys.executable,
            "-m", "memory_retrieval",
            "index",
            "--source-dir", str(WATCH_DIR),
            "--db", str(DB_PATH),
        ]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300,
                               cwd=str(WATCH_DIR.parent), env=env)
        if result.returncode == 0:
            log("Index rebuild completed successfully")
        else:
            log(f"Index rebuild failed: {result.stderr[:200]}")
    except Exception as e:
        log(f"Index rebuild error: {e}")


def watch() -> None:
    """Poll loop with debounce."""
    log(f"Watcher started — watching {WATCH_DIR}")
    log(f"Debounce: {DEBOUNCE_SECS}s, poll interval: {POLL_INTERVAL}s")

    # Check stop flag before starting
    if STOP_FLAG.exists():
        log("Stop flag present — exiting")
        sys.exit(0)

    last_mtimes = get_md_mtimes()
    debounce_timer = None
    pending_rebuild = threading.Event()
    pending_rebuild.clear()

    while True:
        time.sleep(POLL_INTERVAL)

        # Check stop flag
        if STOP_FLAG.exists():
            log("Stop flag detected — exiting")
            break

        # Check for changes
        current_mtimes = get_md_mtimes()
        changed = current_mtimes != last_mtimes

        if changed:
            log(f"File changed: {set(current_mtimes.keys()) ^ set(last_mtimes.keys())}")
            last_mtimes = current_mtimes

            # Cancel pending rebuild and schedule new one
            if debounce_timer is not None:
                debounce_timer.cancel()

            def delayed_rebuild():
                pending_rebuild.set()
                trigger_rebuild()
                pending_rebuild.clear()

            debounce_timer = threading.Timer(DEBOUNCE_SECS, delayed_rebuild)
            debounce_timer.start()

    # Wait for pending rebuild to complete
    if debounce_timer is not None:
        debounce_timer.cancel()

    log("Watcher stopped")


if __name__ == "__main__":
    try:
        watch()
    except KeyboardInterrupt:
        log("Watcher interrupted")
        sys.exit(0)
    except Exception as e:
        log(f"Watcher fatal error: {e}")
        sys.exit(1)
