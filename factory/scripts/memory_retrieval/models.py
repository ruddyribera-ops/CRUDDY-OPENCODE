"""Pydantic models for the memory retrieval layer."""
import hashlib
from datetime import datetime
from pathlib import Path
from typing import Optional

from pydantic import BaseModel, Field


class MemoryRecord(BaseModel):
    """A single memory entry in the retrieval layer."""

    id: str = Field(description="SHA256 of content — deterministic, no DB assigned")
    content: str = Field(description="raw text content, stripped of markdown")
    source_file: Path = Field(description="path to originating .md file")
    timestamp: datetime = Field(default_factory=datetime.now, description="when this memory was written")
    tags: list[str] = Field(default_factory=list, description="auto-extracted or manual tags")
    embedding: list[float] = Field(default_factory=list, description="384-dim vector from all-MiniLM-L6-v2")
    links: list[str] = Field(default_factory=list, description="memory IDs this is related to (graph edges)")
    supersedes: Optional[str] = Field(None, description="memory ID this entry updates/deletes")
    importance: float = Field(default=0.5, description="0.0 to 1.0, higher = more important", ge=0.0, le=1.0)
    version: int = Field(default=1, description="monotonic version counter")
    superseded_by: Optional[str] = Field(None, description="memory ID that updated this entry")

    class Config:
        frozen = True  # immutable after creation


class MemoryQuery(BaseModel):
    """A query to the memory retrieval system."""

    query: str = Field(description="the search query text")
    k: int = Field(default=5, description="number of results to return", ge=1, le=10)
    threshold: float = Field(default=0.3, description="minimum score threshold", ge=0.0, le=1.0)


class RetrievalResult(BaseModel):
    """A retrieved memory with provenance."""

    memory: MemoryRecord
    score: float = Field(ge=0.0, le=1.0)
    match_reasons: list[str] = Field(
        default_factory=list,
        description="why this matched: ['BM25:keyword_match', 'cosine:0.87', 'graph:1-hop']"
    )


def compute_memory_id(content: str) -> str:
    """Compute a deterministic ID from content using SHA256 truncated to 16 chars."""
    return hashlib.sha256(content.encode()).hexdigest()[:16]


def model_to_row(model: MemoryRecord) -> dict:
    """Convert a MemoryRecord to a dict suitable for SQLite insertion."""
    import json
    return {
        "id": model.id,
        "content": model.content,
        "source_file": str(model.source_file),
        "timestamp": model.timestamp.isoformat(),
        "tags": json.dumps(model.tags),
        "embedding": _embeddings_to_blob(model.embedding),
        "links": json.dumps(model.links),
        "supersedes": model.supersedes,
        "importance": model.importance,
        "version": model.version,
        "superseded_by": model.superseded_by,
    }


def row_to_model(row: dict) -> MemoryRecord:
    """Convert a SQLite row back to a MemoryRecord."""
    import json
    from datetime import datetime

    embedding_list = _blob_to_embeddings(row["embedding"])
    return MemoryRecord(
        id=row["id"],
        content=row["content"],
        source_file=Path(row["source_file"]),
        timestamp=datetime.fromisoformat(row["timestamp"]),
        tags=json.loads(row["tags"]) if row["tags"] else [],
        embedding=embedding_list,
        links=json.loads(row["links"]) if row["links"] else [],
        supersedes=row["supersedes"],
        importance=row.get("importance", 0.5),
        version=row.get("version", 1),
        superseded_by=row.get("superseded_by"),
    )


def _embeddings_to_blob(embedding: list[float]) -> bytes:
    """Convert float list to packed bytes for SQLite BLOB storage."""
    import struct
    return struct.pack(f"{len(embedding)}f", *embedding)


def _blob_to_embeddings(blob: bytes) -> list[float]:
    """Convert packed bytes back to float list."""
    import struct
    if not blob:
        return []
    num_floats = len(blob) // 4
    return list(struct.unpack(f"{num_floats}f", blob))
