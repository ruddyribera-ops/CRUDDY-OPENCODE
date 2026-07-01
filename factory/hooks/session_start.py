#!/usr/bin/env python3
"""OpenCode session-start hook — prints memory context_block to stdout.

This script is called by OpenCode's hook system at session start.
It imports hook_integration and outputs the context_block for OpenCode to capture.
"""
import sys
from pathlib import Path

# Ensure the memory_retrieval package is importable
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

from memory_retrieval.hook_integration import on_session_start

if __name__ == "__main__":
    try:
        result = on_session_start()
        if result.get("context_block"):
            # Write to binary stdout to avoid PowerShell charmap encoding issues
            sys.stdout.buffer.write(result["context_block"].encode("utf-8"))
        else:
            sys.stdout.buffer.write(b"<!-- memory-retrieval: no memories available -->")
    except Exception as e:
        sys.stderr.write(f"<!-- memory-retrieval hook error: {e} -->\n")
        sys.exit(0)  # Never fail a hook — exit 0 so OpenCode continues