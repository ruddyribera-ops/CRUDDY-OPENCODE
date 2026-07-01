"""CLI for memory retrieval: index and query commands."""
import argparse
import json
import os
import sys
from datetime import datetime
from pathlib import Path

# Ensure memory_retrieval package is importable when run as `python cli.py`
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from memory_retrieval.indexer import index_directory
from memory_retrieval.retriever import MemoryRetriever, TOP_K_DEFAULT, TOP_K_MAX

# Stable anchor: OPENCODE_ROOT env var if set, else package parent
DEFAULT_ROOT = Path(os.environ.get("OPENCODE_ROOT") or Path(__file__).resolve().parent.parent.parent.parent)


def _resolve_db_path(db_arg: str | None) -> Path:
    """Resolve --db path: absolute unchanged, relative to DEFAULT_ROOT."""
    if not db_arg:
        return DEFAULT_ROOT / ".opencode" / "memory.db"
    p = Path(db_arg)
    if p.is_absolute():
        return p
    return DEFAULT_ROOT / p


def _resolve_source_dir(source_dir_arg: str) -> Path:
    """Resolve --source-dir: absolute unchanged, relative to DEFAULT_ROOT."""
    p = Path(source_dir_arg)
    if p.is_absolute():
        return p
    return DEFAULT_ROOT / p


def cmd_index(args: argparse.Namespace) -> int:
    """Index markdown files into the memory store."""
    source_dir = _resolve_source_dir(args.source_dir)
    db_path = _resolve_db_path(args.db)

    if not source_dir.exists():
        print(f"ERROR: Source directory does not exist: {source_dir}", file=sys.stderr)
        return 1

    print(f"Indexing markdown files from: {source_dir}")
    print(f"Database: {db_path}")

    from memory_retrieval.store import MemoryStore
    store = MemoryStore(db_path)

    files_processed, memories_indexed = index_directory(
        source_dir=source_dir,
        store=store,
        rebuild=args.rebuild,
        verbose=args.verbose,
    )

    print(f"Indexed {memories_indexed} memories from {files_processed} files")
    return 0


def cmd_query(args: argparse.Namespace) -> int:
    """Query the memory store."""
    db_path = _resolve_db_path(args.db)

    if not db_path.exists():
        print(f"ERROR: Database does not exist. Run 'index' first.", file=sys.stderr)
        return 1

    retriever = MemoryRetriever(db_path)
    k = min(args.k or TOP_K_DEFAULT, TOP_K_MAX)

    results = retriever.retrieve(args.query, k=k, now=datetime.now())

    if not results:
        disabled = os.getenv("OPENCODE_MEMORY", "").lower() in ("off", "0", "false", "no")
        print("[memory disabled]" if disabled else "No results found")
        return 0

    if args.json:
        output = [
            {
                "score": r.score,
                "importance": r.memory.importance,
                "source_file": str(r.memory.source_file),
                "match_reasons": r.match_reasons,
                "content": r.memory.content[:200] + "..." if len(r.memory.content) > 200 else r.memory.content,
                "tags": r.memory.tags,
            }
            for r in results
        ]
        print(json.dumps(output, indent=2, default=str))
    else:
        print(f"Found {len(results)} results for: {args.query}")
        print("-" * 60)
        for i, result in enumerate(results, 1):
            print(f"[{i}] Score: {result.score:.3f} | importance: {result.memory.importance:.2f}")
            print(f"    Source: {result.memory.source_file}")
            print(f"    Reasons: {', '.join(result.match_reasons)}")
            content = result.memory.content
            snippet = content[:150] + "..." if len(content) > 150 else content
            print(f"    Snippet: {snippet}")
            if result.memory.tags:
                print(f"    Tags: {', '.join(result.memory.tags)}")
            print()

    return 0


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Hybrid memory retrieval: BM25 + cosine + graph",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    subparsers = parser.add_subparsers(dest="command", help="Commands")

    # Index command
    index_parser = subparsers.add_parser("index", help="Index markdown files")
    index_parser.add_argument(
        "--source-dir",
        required=True,
        help="Directory containing markdown files to index",
    )
    index_parser.add_argument(
        "--db",
        default=".opencode/memory.db",
        help="SQLite database path (default: .opencode/memory.db)",
    )
    index_parser.add_argument(
        "--rebuild",
        action="store_true",
        help="Clear existing index before indexing",
    )
    index_parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Verbose output",
    )

    # Query command
    query_parser = subparsers.add_parser("query", help="Query the memory store")
    query_parser.add_argument("query", help="Search query string")
    query_parser.add_argument(
        "--k",
        type=int,
        default=TOP_K_DEFAULT,
        help=f"Number of results to return (default: {TOP_K_DEFAULT}, max: {TOP_K_MAX})",
    )
    query_parser.add_argument(
        "--db",
        default=".opencode/memory.db",
        help="SQLite database path (default: .opencode/memory.db)",
    )
    query_parser.add_argument(
        "--json",
        action="store_true",
        help="Output results as JSON",
    )

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return 1

    if args.command == "index":
        return cmd_index(args)
    elif args.command == "query":
        return cmd_query(args)
    else:
        parser.print_help()
        return 1


if __name__ == "__main__":
    sys.exit(main())
