#!/usr/bin/env python3
"""
preflight-snapshot.py
Creates timestamped backup snapshots before batch file modifications.
Uses SHA256 for verification (more thorough than size-only checks).
Created after 2026-06-17 PDC destruction incident.
"""

import os
import sys
import shutil
import hashlib
import datetime
import argparse
from pathlib import Path

BASE_DIR = Path("D:/Temp/opencode")
FALLBACK_DIR = Path("C:/Temp")
LOG_FILE = BASE_DIR / "BEFORE_LOG.txt"
AGENT_ROOT = Path("C:/Users/Windows/.config/opencode")
BACKUP_ROOT = BASE_DIR

TOLERANCE = 0.01  # 1% size tolerance


def get_default_backup_dir():
    if BASE_DIR.exists() and BASE_DIR.is_dir():
        try:
            test_file = BASE_DIR / ".write_test"
            test_file.write_text("test")
            test_file.unlink()
            return BASE_DIR
        except (OSError, PermissionError):
            pass
    if FALLBACK_DIR.exists() and FALLBACK_DIR.is_dir():
        return FALLBACK_DIR
    return None


def is_path_under_restricted(path: Path) -> bool:
    try:
        resolved = path.resolve()
        resolved_str = str(resolved).rstrip('\\')
        agent_str = str(AGENT_ROOT.resolve()).rstrip('\\')
        backup_str = str(BACKUP_ROOT.resolve()).rstrip('\\')
        if resolved_str.startswith(agent_str):
            return True
        if resolved_str.startswith(backup_str):
            return True
    except (OSError, RuntimeError):
        pass
    return False


def compute_sha256(path: Path) -> str:
    h = hashlib.sha256()
    try:
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(8192), b""):
                h.update(chunk)
        return h.hexdigest()
    except (OSError, PermissionError):
        return ""


def get_dir_size(path: Path) -> int:
    total = 0
    try:
        for entry in path.rglob("*"):
            if entry.is_file():
                total += entry.stat().st_size
    except (OSError, PermissionError):
        pass
    return total


def copy_with_verify(src: Path, dest: Path) -> bool:
    try:
        if src.is_dir():
            dest.mkdir(parents=True, exist_ok=True)
            shutil.copytree(src, dest, dirs_exist_ok=True)
        else:
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dest)

        if not dest.exists():
            print(f"FAILED: {src} -> {dest} (copy failed)", file=sys.stderr)
            return False

        if src.is_file():
            src_size = src.stat().st_size
            dest_size = dest.stat().st_size
            if src_size > 0:
                pct = abs(src_size - dest_size) / src_size
                if pct > TOLERANCE:
                    print(f"FAILED: {src} -> {dest} (size mismatch: {src_size} vs {dest_size})", file=sys.stderr)
                    return False

            src_hash = compute_sha256(src)
            dest_hash = compute_sha256(dest)
            if src_hash and src_hash != dest_hash:
                print(f"FAILED: {src} -> {dest} (SHA256 mismatch)", file=sys.stderr)
                return False

        return True
    except Exception as e:
        print(f"FAILED: {src} -> {dest} ({e})", file=sys.stderr)
        return False


def main():
    parser = argparse.ArgumentParser(description="Create preflight snapshot backup")
    parser.add_argument("--paths", required=True, help="Comma-separated source paths")
    parser.add_argument("--operation", required=True, help="Operation label for snapshot")
    args = parser.parse_args()

    paths = [Path(p.strip()) for p in args.paths.split(",") if p.strip()]

    backup_dir = get_default_backup_dir()
    if not backup_dir:
        print("CRITICAL: Neither D:\\Temp\\opencode nor C:\\Temp is writable", file=sys.stderr)
        return 1

    for p in paths:
        if is_path_under_restricted(p):
            print(f"REFUSED: Cannot backup agent files or backup location: {p}", file=sys.stderr)
            return 1
        if not p.exists():
            print(f"REFUSED: Source path does not exist: {p}", file=sys.stderr)
            return 1

    timestamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    snapshot_dir = backup_dir / f"BEFORE_{timestamp}_{args.operation}"
    snapshot_dir.mkdir(parents=True, exist_ok=True)

    file_count = 0
    total_size = 0
    failures = []

    for src_path in paths:
        try:
            resolved = src_path.resolve()
        except (OSError, RuntimeError):
            print(f"REFUSED: Cannot resolve path: {src_path}", file=sys.stderr)
            return 1

        if resolved.is_dir():
            src_size = get_dir_size(resolved)
        else:
            src_size = resolved.stat().st_size
        total_size += src_size

        item_name = resolved.name
        dest_path = snapshot_dir / item_name

        if copy_with_verify(resolved, dest_path):
            file_count += 1
        else:
            failures.append(str(src_path))

    if failures:
        for f in failures:
            print(f"VERIFY FAILED: {f}", file=sys.stderr)
        return 1

    timestamp_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = f"{timestamp_str} | {args.operation} | {snapshot_dir} | {file_count} | {total_size}"
    try:
        with open(LOG_FILE, "a") as log:
            log.write(log_entry + "\n")
    except (OSError, PermissionError):
        pass

    print(f"OK: {file_count} files/dirs backed up to {snapshot_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
