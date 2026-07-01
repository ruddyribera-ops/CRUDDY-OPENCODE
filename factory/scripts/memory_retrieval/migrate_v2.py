"""Phase 1 migration script for memory v2 — add importance, version, superseded_by columns.

Run once after deploying updated code:
    python -m memory_retrieval.migrate_v2

Idempotent: safe to run multiple times. Skips if columns already exist.
"""
import sys
from pathlib import Path

# Ensure memory_retrieval package is importable
_SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(_SCRIPT_DIR.parent))

DEFAULT_ROOT = _SCRIPT_DIR.parent.parent
DEFAULT_DB = DEFAULT_ROOT / ".opencode" / "memory.db"


def main() -> int:
    import argparse
    parser = argparse.ArgumentParser(description="Migrate memory.db to v2 schema")
    parser.add_argument(
        "--db",
        default=str(DEFAULT_DB),
        help=f"SQLite database path (default: {DEFAULT_DB})",
    )
    args = parser.parse_args()

    db_path = Path(args.db)
    if not db_path.exists():
        print(f"ERROR: Database not found: {db_path}", file=sys.stderr)
        return 1

    from memory_retrieval.store import run_migration
    result = run_migration(db_path)
    print(f"Migrated {result['count']} memories, avg importance {result['avg_importance']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())