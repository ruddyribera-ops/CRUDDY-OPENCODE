"""Hybrid memory retrieval layer for OpenCode.

BM25 (SQLite FTS5) + Cosine (all-MiniLM-L6-v2) + Graph (NetworkX 1-hop).

Usage:
    from memory_retrieval import MemoryRetriever
    retriever = MemoryRetriever(".opencode/memory.db")
    results = retriever.retrieve("query text", k=5)

CLI:
    python -m memory_retrieval index --source-dir memory/ --db .opencode/memory.db
    python -m memory_retrieval query "query text" --k 5
"""
import sys
from pathlib import Path

# Ensure the package can be run as a module
__version__ = "1.0.0"

from .models import MemoryRecord, MemoryQuery, RetrievalResult, compute_memory_id
from .store import MemoryStore
from .embedder import embed_text, embed_batch, cosine_similarity
from .graph import MemoryGraph
from .indexer import index_directory, extract_text_from_markdown
from .retriever import MemoryRetriever

__all__ = [
    "MemoryRecord",
    "MemoryQuery",
    "RetrievalResult",
    "compute_memory_id",
    "MemoryStore",
    "embed_text",
    "embed_batch",
    "cosine_similarity",
    "MemoryGraph",
    "index_directory",
    "extract_text_from_markdown",
    "MemoryRetriever",
]
