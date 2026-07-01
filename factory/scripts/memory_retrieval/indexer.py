"""Indexer: extract text from markdown files, embed, and store."""
import hashlib
import logging
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional

from .embedder import embed_batch, EMBEDDING_DIM
from .models import MemoryRecord, compute_memory_id
from .store import MemoryStore

logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)


# Importance auto-assignment patterns (order matters: first match wins)
IMPORTANCE_PATTERNS = [
    ("user_preferences", 1.0),
    ("project_active", 0.9),
    ("session_log", 0.7),
    ("research_factory", 0.6),
    ("TRIGGERS", 0.6),
    ("research_poa", 0.5),
    ("skill_", 0.5),
    ("poa_", 0.4),
    ("reference", 0.4),
]


def assign_importance(source_file: Path) -> float:
    """Auto-assign importance based on source_file path patterns.

    Returns a value in [0.0, 1.0]. Higher = more important.
    """
    path_str = str(source_file)
    for pattern, score in IMPORTANCE_PATTERNS:
        if pattern in path_str:
            return score
    return 0.5  # default


def extract_text_from_markdown(file_path: Path) -> Optional[str]:
    """Extract plain text from a markdown file.

    Strips:
    - YAML front matter (---...---)
    - Markdown syntax (**, __, *, `, #)
    - Extra whitespace

    Returns None for empty files or files that fail to read.
    """
    try:
        content = file_path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        try:
            content = file_path.read_text(encoding="utf-8-sig")
        except Exception as e:
            logger.warning(f"Failed to read {file_path}: {e}")
            return None

    # Strip YAML front matter
    content = re.sub(r"^---\s*\n.*?\n---\s*\n", "", content, flags=re.DOTALL)

    # Strip markdown syntax
    content = re.sub(r"\*\*(.+?)\*\*", r"\1", content)  # bold
    content = re.sub(r"__(.+?)__", r"\1", content)  # bold underscore
    content = re.sub(r"\*(.+?)\*", r"\1", content)  # italic
    content = re.sub(r"_(.+?)_", r"\1", content)  # italic underscore
    content = re.sub(r"`(.+?)`", r"\1", content)  # inline code
    content = re.sub(r"```.*?```", "", content, flags=re.DOTALL)  # code blocks
    content = re.sub(r"#+\s+", "", content)  # headers
    content = re.sub(r"\[([^\]]+)\]\([^\)]+\)", r"\1", content)  # links
    content = re.sub(r"!\[[^\]]*\]\([^\)]+\)", "", content)  # images
    content = re.sub(r"^\s*[-*+]\s+", "", content, flags=re.MULTILINE)  # list items
    content = re.sub(r"^\s*\d+\.\s+", "", content, flags=re.MULTILINE)  # numbered lists
    content = re.sub(r"^\s*>\s+", "", content, flags=re.MULTILINE)  # blockquotes
    content = re.sub(r"<[^>]+>", "", content)  # HTML tags

    # Normalize whitespace
    content = re.sub(r"\n{3,}", "\n\n", content)
    content = content.strip()

    if not content:
        return None

    return content


def extract_tags_from_content(content: str, source_file: Path) -> list[str]:
    """Extract tags from content and filename.

    Looks for:
    - Words after # in content
    - Filename-derived tags (e.g., session_log.md -> session, log)
    """
    tags = []

    # Tags from filename
    stem = source_file.stem.lower()
    for part in re.split(r"[_\-]", stem):
        if len(part) > 2 and part not in ("memory", "reference", "research", "active"):
            tags.append(part)

    # Tags from content (markdown headers)
    header_tags = re.findall(r"^#\s+(.+)$", content, re.MULTILINE)
    for header in header_tags[:3]:  # limit to first 3 headers
        words = re.findall(r"\b[a-z]{3,}\b", header.lower())
        tags.extend(words[:2])

    # Deduplicate and limit
    seen = set()
    unique_tags = []
    for tag in tags:
        if tag not in seen and len(tag) > 2:
            seen.add(tag)
            unique_tags.append(tag)
            if len(unique_tags) >= 5:
                break

    return unique_tags


def extract_links_from_content(content: str) -> list[str]:
    """Extract memory links from [[wiki-link]] style references."""
    return re.findall(r"\[\[([^\]]+)\]\]", content)


def index_directory(
    source_dir: Path,
    store: MemoryStore,
    rebuild: bool = False,
    verbose: bool = False,
) -> tuple[int, int]:
    """Index all markdown files in a directory.

    Args:
        source_dir: Directory containing .md files
        store: MemoryStore instance
        rebuild: If True, clear existing data first
        verbose: If True, log each file indexed

    Returns:
        Tuple of (files_processed, memories_indexed)
    """
    if not source_dir.exists():
        logger.error(f"Source directory does not exist: {source_dir}")
        return 0, 0

    if rebuild:
        store.clear()
        logger.info("Cleared existing index (rebuild mode)")

    # Find all markdown files
    md_files = list(source_dir.glob("**/*.md"))
    md_files = [f for f in md_files if f.is_file()]

    if not md_files:
        logger.warning(f"No markdown files found in {source_dir}")
        return 0, 0

    # Extract text from each file
    records: list[MemoryRecord] = []
    skipped_empty = 0

    for md_file in md_files:
        content = extract_text_from_markdown(md_file)

        if content is None:
            logger.warning(f"Skipping empty/unreadable file: {md_file}")
            skipped_empty += 1
            continue

        # Compute deterministic ID from content
        memory_id = compute_memory_id(content)

        # Extract metadata
        tags = extract_tags_from_content(content, md_file)
        links = extract_links_from_content(content)

        record = MemoryRecord(
            id=memory_id,
            content=content,
            source_file=md_file,
            timestamp=datetime.now(),
            tags=tags,
            embedding=[],  # Will be filled below
            links=links,
            supersedes=None,
            importance=assign_importance(md_file),
        )
        records.append(record)

        if verbose:
            logger.info(f"Extracted: {md_file.name} ({len(content)} chars)")

    if not records:
        logger.warning("No valid content extracted from markdown files")
        return len(md_files), 0

    # Batch embed all contents
    logger.info(f"Embedding {len(records)} memories (first run downloads model ~80MB)...")
    try:
        contents = [r.content for r in records]
        embeddings = embed_batch(contents, batch_size=32)
        # Recreate records with embeddings (frozen model prevents post-init assignment)
        records = [
            MemoryRecord(
                id=r.id,
                content=r.content,
                source_file=r.source_file,
                timestamp=r.timestamp,
                tags=r.tags,
                embedding=emb.tolist(),
                links=r.links,
                supersedes=r.supersedes,
                importance=r.importance,
            )
            for r, emb in zip(records, embeddings)
        ]
    except Exception as e:
        logger.error(f"Embedding failed: {e}")
        logger.error("Cannot proceed without embeddings. Check network connectivity.")
        sys.exit(1)

    # Store all records
    count = store.upsert_batch(records)

    files_processed = len(md_files) - skipped_empty
    logger.info(f"Indexed {count} memories from {files_processed} files")

    return files_processed, count
