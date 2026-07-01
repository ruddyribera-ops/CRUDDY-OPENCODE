#!/usr/bin/env python3
"""Generate a fast markdown codemap from a codebase.

Pure stdlib Python. No LLM calls, no network. Deterministic output.

Usage:
    python generate.py <repo_path> [--output-dir <dir>]

Outputs:
    codemap.md  - Languages, entry points, file type counts, largest files (cap 8 KiB)
    modules.md  - Top-level directory structure + agent cross-references

Stdout: JSON summary (languages detected, entry point count, file sizes)
Exit code: 0 on success, 1 on error

Skipped directories: node_modules, .venv, venv, __pycache__, .git,
                     dist, build, .next, target, .cache, .turbo
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

# ----- Configuration ----------------------------------------------------------

MAX_FILE_BYTES = 8 * 1024          # 8 KiB per output file
MAX_LISTING = 50                   # max items per list
MIN_LARGEST_FILE_BYTES = 1024      # skip files < 1KB from "largest" list

SKIP_DIRS = frozenset({
    "node_modules", ".venv", "venv", "__pycache__", ".git",
    "dist", "build", ".next", "target", ".cache", ".turbo",
    "vendor", ".pytest_cache", ".mypy_cache", ".tox",
})

# Manifest files that indicate language/framework
MANIFESTS = {
    "package.json": "node",
    "tsconfig.json": "node-typescript",
    "pyproject.toml": "python",
    "requirements.txt": "python",
    "setup.py": "python",
    "Pipfile": "python",
    "Cargo.toml": "rust",
    "go.mod": "go",
    "pom.xml": "java",
    "build.gradle": "java",
    "composer.json": "php",
    "Gemfile": "ruby",
}

# Entry point patterns by language (relative filenames)
ENTRY_POINTS = {
    "python": ["main.py", "app.py", "__main__.py", "manage.py", "wsgi.py", "asgi.py"],
    "node": ["index.js", "index.ts", "app.js", "app.ts", "server.js", "server.ts", "main.js", "main.ts"],
    "rust": ["main.rs", "lib.rs"],
    "go": ["main.go"],
    "java": ["Main.java", "Application.java"],
    "php": ["index.php", "artisan"],
}


# ----- Helpers ---------------------------------------------------------------

def _is_skipped(path: Path) -> bool:
    """Return True if any parent directory of path is in SKIP_DIRS."""
    return any(part in SKIP_DIRS for part in path.parts)


def find_manifests(root: Path) -> dict[str, list[str]]:
    """Find all manifest files indicating language. Returns {language: [paths]}."""
    found: dict[str, list[str]] = {}
    for manifest, lang in MANIFESTS.items():
        for path in root.rglob(manifest):
            if _is_skipped(path.relative_to(root)):
                continue
            found.setdefault(lang, []).append(str(path.relative_to(root)))
    # Sort each language's paths
    for lang in found:
        found[lang].sort()
    return found


def find_entry_points(root: Path) -> list[tuple[str, str]]:
    """Find likely entry points. Returns [(language, relative_path)]."""
    entries: list[tuple[str, str]] = []
    for lang, filenames in ENTRY_POINTS.items():
        for filename in filenames:
            for path in root.rglob(filename):
                if _is_skipped(path.relative_to(root)):
                    continue
                entries.append((lang, str(path.relative_to(root))))
    entries.sort(key=lambda x: x[1])
    return entries[:MAX_LISTING]


def get_top_level_dirs(root: Path) -> list[str]:
    """Get immediate subdirectories of root, sorted."""
    dirs: list[str] = []
    for item in sorted(root.iterdir()):
        if item.is_dir() and not item.name.startswith(".") and item.name not in SKIP_DIRS:
            dirs.append(item.name)
    return dirs[:MAX_LISTING]


def count_files_by_type(root: Path) -> list[tuple[str, int]]:
    """Count files by extension. Returns sorted [(ext, count), ...] top 10."""
    counts: dict[str, int] = {}
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        rel = path.relative_to(root)
        if _is_skipped(rel):
            continue
        ext = path.suffix.lower() or "(no ext)"
        # Normalize: ext from path.suffix always starts with '.', (no ext) does not
        counts[ext] = counts.get(ext, 0) + 1
    sorted_counts = sorted(counts.items(), key=lambda x: (-x[1], x[0]))[:10]
    return sorted_counts


def find_largest_files(root: Path, n: int = 10) -> list[tuple[str, int]]:
    """Find the n largest files (above MIN_LARGEST_FILE_BYTES)."""
    files: list[tuple[str, int]] = []
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        rel = path.relative_to(root)
        if _is_skipped(rel):
            continue
        try:
            size = path.stat().st_size
        except OSError:
            continue
        if size >= MIN_LARGEST_FILE_BYTES:
            files.append((str(rel), size))
    files.sort(key=lambda x: -x[1])
    return files[:n]


# ----- Output generation -----------------------------------------------------

def generate_codemap_md(root: Path, manifests: dict, entries: list, file_counts: list, largest: list) -> str:
    """Build codemap.md content with hard size cap."""
    lines: list[str] = []
    lines.append(f"# Codemap: {root.name}")
    lines.append("")
    lines.append(f"_Generated from `{root}`_")
    lines.append("")

    lines.append("## Languages Detected")
    lines.append("")
    if manifests:
        for lang, paths in manifests.items():
            shown = ", ".join(f"`{p}`" for p in paths[:3])
            if len(paths) > 3:
                shown += f" (+{len(paths) - 3} more)"
            lines.append(f"- **{lang}**: {shown}")
    else:
        lines.append("- No standard manifests detected")
    lines.append("")

    lines.append("## Entry Points (likely)")
    lines.append("")
    if entries:
        for lang, path in entries:
            lines.append(f"- `{path}` ({lang})")
    else:
        lines.append("- No standard entry points found")
    lines.append("")

    lines.append("## File Types (top 10)")
    lines.append("")
    if file_counts:
        for ext, count in file_counts:
            display = ext if ext == "(no ext)" else ext
            lines.append(f"- `{display}`: {count} files")
    else:
        lines.append("- No files found")
    lines.append("")

    lines.append("## Largest Files (top 10)")
    lines.append("")
    if largest:
        for path, size in largest:
            kb = size / 1024
            lines.append(f"- `{path}` ({kb:.1f} KB)")
    else:
        lines.append("- No files above 1KB found")
    lines.append("")

    content = "\n".join(lines)
    if len(content.encode("utf-8")) > MAX_FILE_BYTES:
        content = content[:MAX_FILE_BYTES] + "\n\n_(truncated at 8KiB)_\n"
    return content


def generate_modules_md(root: Path, top_dirs: list[str]) -> str:
    """Build modules.md content."""
    lines: list[str] = []
    lines.append(f"# Modules: {root.name}")
    lines.append("")
    lines.append("## Top-Level Directories")
    lines.append("")
    if top_dirs:
        for d in top_dirs:
            lines.append(f"- `{d}/`")
    else:
        lines.append("- No top-level directories")
    lines.append("")

    lines.append("## Cross-References")
    lines.append("")
    lines.append("After generating this codemap, decide what to do next:")
    lines.append("")
    lines.append("- **Symbol-level navigation** (find a function, trace a call) -> `codebase-memory` MCP tools")
    lines.append("- **Health or quality assessment** (test coverage, debt) -> dispatch `code-analyzer`")
    lines.append("- **Security review** (auth, secrets, injection) -> dispatch `cybersecurity`")
    lines.append("- **Architectural decisions** (refactor, patterns) -> dispatch `architecture-advisor`")
    lines.append("- **Deep semantic overview** -> `codebase-memory_get_architecture` (slower, richer)")
    lines.append("")
    return "\n".join(lines)


# ----- Main ------------------------------------------------------------------

def generate(root: Path, output_dir: Path) -> dict:
    """Run the full codemap generation. Returns summary dict."""
    output_dir.mkdir(parents=True, exist_ok=True)

    manifests = find_manifests(root)
    entries = find_entry_points(root)
    top_dirs = get_top_level_dirs(root)
    file_counts = count_files_by_type(root)
    largest = find_largest_files(root)

    codemap_md = generate_codemap_md(root, manifests, entries, file_counts, largest)
    modules_md = generate_modules_md(root, top_dirs)

    (output_dir / "codemap.md").write_text(codemap_md, encoding="utf-8")
    (output_dir / "modules.md").write_text(modules_md, encoding="utf-8")

    return {
        "repo": str(root),
        "output_dir": str(output_dir),
        "codemap_bytes": len(codemap_md.encode("utf-8")),
        "modules_bytes": len(modules_md.encode("utf-8")),
        "languages": sorted(manifests.keys()),
        "entry_points": len(entries),
        "top_level_dirs": len(top_dirs),
        "truncated": codemap_md.endswith("(truncated at 8KiB)\n"),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate a fast markdown codemap from a codebase.")
    parser.add_argument("path", help="Path to codebase root")
    parser.add_argument("--output-dir", default=".", help="Output directory for codemap files (default: current dir)")
    args = parser.parse_args()

    root = Path(args.path).resolve()
    if not root.exists():
        print(f"Error: path does not exist: {root}", file=sys.stderr)
        return 1
    if not root.is_dir():
        print(f"Error: not a directory: {root}", file=sys.stderr)
        return 1

    output_dir = Path(args.output_dir).resolve()
    try:
        summary = generate(root, output_dir)
    except Exception as e:
        print(f"Error: {type(e).__name__}: {e}", file=sys.stderr)
        return 1

    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())