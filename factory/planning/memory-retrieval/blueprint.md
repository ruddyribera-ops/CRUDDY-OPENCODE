# Blueprint: Hybrid Memory Retrieval Layer

## A. Tech Decision Matrix

| Criteria | Mem0 (hosted) | Letta/MemGPT | Cognee (graph) | LangMem | Hindsight (2026) | **Build-it-ourselves (Recommended)** |
|----------|--------------|--------------|-----------------|---------|------------------|--------------------------------------|
| **External API cost** | ~$50/mo (AWS) | $0 self-host | $0 self-host | $0 (LangGraph only) | Unknown | **$0** |
| **Self-hostable** | No (AWS exclusive) | Yes | Yes | Yes | Likely | **Yes — full control** |
| **BM25 + vector hybrid** | Yes | Partial | Graph-focused | No | Unknown | **Yes — built-in** |
| **Graph/relationship support** | Yes | Yes | Yes (primary) | No | Unknown | **Yes — NetworkX 1-hop** |
| **Windows-compatible** | N/A (cloud) | Docker-dependent | Python-native | Python-native | Python-native | **Python-native** |
| **Setup complexity** | High (AWS infra) | Medium (Docker) | Medium | Low | Unknown | **Low — 3 libs** |
| **Maintenance burden** | High (provider) | Medium | Medium | Low | Unknown | **Low — we own it** |
| **Startup latency** | ~2s API | ~5s cold start | ~1s | ~1s | ~1s | **~1s (local model)** |
| **Embedding model** | GPT-4o (expensive) | GPT-4o (expensive) | Configurable | Configurable | Unknown | **all-MiniLM-L6-v2 (free)** |
| **For our scale (22 docs)** | Overkill | Overkill | Overkill | Insufficient | Unproven | **Right-sized** |

**Winner:** Build-it-ourselves — because we have 1 user, 22 docs, $0 budget, Windows, and need BM25+vector+graph hybrid. Mem0/Letta/Cognee are designed for teams/enterprises. Hindsight is unproven 2026 software. Our problem is simpler than what those tools solve.

**Libraries:** `sentence-transformers`, `numpy`, `networkx`, `sqlite-vec` (or raw FTS5), `pydantic`

---

## B. Architecture Diagram (ASCII)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        HYBRID MEMORY RETRIEVAL LAYER                         │
└─────────────────────────────────────────────────────────────────────────────┘

WRITE-TIME (nightly consolidation + on-demand write):
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ memory/*.│───▶│ extract  │───▶│ embed    │───▶│ store    │───▶│ index    │
│ md files │    │ (parse)  │    │ (MiniLM) │    │ (SQLite) │    │ (FTS5+vec│
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
                                                          │
                                                          ▼
                                                 ┌──────────────────┐
                                                 │ MemoryRecord DB  │
                                                 │ (memories.db)    │
                                                 └──────────────────┘

READ-TIME (session start + per-task):
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ user     │───▶│ query    │───▶│ BM25     │    │ cosine   │    │ graph    │
│ prompt   │    │ parse    │    │ (FTS5)   │    │ (vector) │    │ expand   │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
                        │             │             │             │
                        ▼             ▼             ▼             ▼
                 ┌──────────┐  ┌──────────────────────────────────────────┐
                 │ trigger  │  │              RERANK (LLM-as-judge)       │
                 │ detect   │  │  combine scores: 0.4*BM25 + 0.4*cos + 0.2*graph │
                 └──────────┘  └──────────────────────────────────────────┘
                                          │
                                          ▼
                                 ┌──────────────────┐
                                 │ top-k memories   │
                                 │ (k=5 default)   │
                                 │ + source_file   │
                                 └──────────────────┘
                                          │
                                          ▼
                                 ┌──────────────────┐
                                 │ inject into     │
                                 │ session context │
                                 └──────────────────┘

MAINTENANCE (nightly):
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ scan     │───▶│ diff vs  │───▶│ ADD new  │    │ NOOP     │
│ memory/  │    │ last run │    │ UPDATE   │    │ unchanged│
└──────────┘    └──────────┘    │ DELETE   │    │          │
                                │ superseded│   │          │
                                └──────────┘    └──────────┘
```

---

## C. File Schema (Pydantic Model)

```python
from datetime import datetime
from pathlib import Path
from pydantic import BaseModel, Field
from typing import Optional


class MemoryRecord(BaseModel):
    """A single memory entry in the retrieval layer."""
    id: str = Field(description="sha256 of content — deterministic, no DB assigned")
    content: str = Field(description="raw text content, stripped of markdown")
    source_file: Path = Field(description="path to originating .md file")
    timestamp: datetime = Field(default_factory=datetime.now, description="when this memory was written")
    tags: list[str] = Field(default_factory=list, description="auto-extracted or manual tags")
    embedding: list[float] = Field(default_factory=list, description="384-dim vector from all-MiniLM-L6-v2")
    links: list[str] = Field(default_factory=list, description="memory IDs this is related to (graph edges)")
    supersedes: Optional[str] = Field(None, description="memory ID this entry updates/deletes")

    class Config:
        frozen = True  # immutable after creation


class RetrievalResult(BaseModel):
    """A retrieved memory with provenance."""
    memory: MemoryRecord
    score: float = Field(ge=0.0, le=1.0)
    match_reasons: list[str] = Field(
        default_factory=list,
        description="why this matched: ['BM25:keyword_match', 'cosine:0.87', 'graph:1-hop']"
    )
```

---

## D. Retrieval Algorithm

### Pseudocode

```
function retrieve(query, k=5):
    1. parse query → detect if keyword-heavy (BM25 territory) or semantic (vector territory)
    2. BM25 scores = FTS5.search(query, top-k*2)  # get 2x for reranking buffer
    3. query_embedding = embed(query)
    4. cosine scores = cosine_similarity(query_embedding, all_embeddings)
    5. top_vector_ids = argsort(cosine scores)[-k*2:]  # 2x buffer
    6. graph expansion: for each candidate, get 1-hop neighbors, boost score +0.1
    7. combine: score = 0.4*BM25_norm + 0.4*cosine_norm + 0.2*graph_norm
    8. rerank: sort by combined score, take top k
    9. for each result, include source_file so user can verify
    10. return top-k RetrievalResult objects
```

### 30-Line Retrieval Core

```python
import numpy as np
from sklearn.preprocessing import normalize


def cosine_similarity_matrix(query_vec: np.ndarray, doc_vecs: np.ndarray) -> np.ndarray:
    """Compute cosine similarity between one query and many documents."""
    q = normalize(query_vec.reshape(1, -1))
    d = normalize(doc_vecs)
    return np.dot(q, d.T).flatten()


def hybrid_retrieve(query: str, memories: list[MemoryRecord], k: int = 5) -> list[RetrievalResult]:
    """
    Hybrid retrieval: BM25 + cosine + graph expansion + rerank.
    Returns top-k results sorted by combined score.
    """
    # Step 1: BM25 via FTS5 (precomputed, stored in SQLite)
    bm25_scores = _fts5_search(query, memories)  # dict: memory_id -> bm25_score

    # Step 2: Embed query
    query_vec = embed_text(query)  # 384-dim numpy array

    # Step 3: Cosine similarity
    doc_vecs = np.array([m.embedding for m in memories])
    cos_scores = cosine_similarity_matrix(query_vec, doc_vecs)

    # Step 4: Graph expansion (1-hop neighbors get +0.1 boost)
    graph_boost = np.zeros(len(memories))
    for i, mem in enumerate(memories):
        if mem.links:  # 1-hop neighbors
            neighbor_indices = [memories.index(m) for m in memories if m.id in mem.links]
            graph_boost[neighbor_indices] += 0.1

    # Step 5: Normalize and combine
    bm25_vals = np.array([bm25_scores.get(m.id, 0.0) for m in memories])
    bm25_norm = bm25_vals / (bm25_vals.max() + 1e-9)
    cos_norm = cos_scores / (cos_scores.max() + 1e-9)
    graph_norm = graph_boost / (graph_boost.max() + 1e-9)

    combined = 0.4 * bm25_norm + 0.4 * cos_norm + 0.2 * graph_norm

    # Step 6: Top-k indices
    top_indices = np.argsort(combined)[-k:][::-1]

    # Step 7: Build results with match reasons
    results = []
    for idx in top_indices:
        mem = memories[idx]
        reasons = []
        if bm25_scores.get(mem.id, 0) > 0:
            reasons.append(f"BM25:{bm25_scores[mem.id]:.3f}")
        reasons.append(f"cosine:{cos_scores[idx]:.3f}")
        if mem.links:
            reasons.append(f"graph:1-hop")
        results.append(RetrievalResult(memory=mem, score=combined[idx], match_reasons=reasons))

    return results
```

---

## E. Integration Points (OpenCode Hooks)

| Event | Trigger | Action |
|-------|---------|--------|
| `SessionStart` | opencode startup | Load `user_preferences.md` + `project_active.md` + top-3 from `retrieve("last session context", k=3)` |
| `UserPromptSubmit` | prompt contains "last time" OR "remember" OR "we did" | Expand to `retrieve(<extracted_query>, k=5)`, inject as context |
| `PerTaskStart` | task description available | `retrieve(task_description, k=5)`, inject as context |
| `NightlyMaintenance` | cron or manual trigger | Run consolidation: diff memory/ files vs last run, apply ADD/UPDATE/DELETE/NOOP |

**Trigger detection regex:**
```python
REMEMBER_PATTERNS = [
    r"\bremember\b",
    r"\blast time\b",
    r"\bwe did\b",
    r"\bbefore\b",
    r"\bearlier\b",
    r"\bpast\b",
]
```

---

## F. Core Retrieval Function (≥40 Lines, Runnable)

```python
"""
Hybrid memory retrieval — the core retrieval function.
Syntactically valid Python. Run standalone for testing.
"""
import hashlib
import json
import math
import re
import sqlite3
import time
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Optional

import numpy as np
from pydantic import BaseModel


# ─── Configuration ────────────────────────────────────────────────────────────
DB_PATH = Path(__file__).parent / "memories.db"
EMBEDDER_BATCH_SIZE = 32
TOP_K_DEFAULT = 5
WEIGHT_BM25 = 0.4
WEIGHT_COSINE = 0.4
WEIGHT_GRAPH = 0.2


# ─── Schema ────────────────────────────────────────────────────────────────────
class MemoryRecord(BaseModel):
    id: str
    content: str
    source_file: str
    timestamp: datetime
    tags: list[str] = field(default_factory=list)
    embedding: list[float] = field(default_factory=list)
    links: list[str] = field(default_factory=list)
    supersedes: Optional[str] = None


class RetrievalResult(BaseModel):
    memory: MemoryRecord
    score: float
    match_reasons: list[str] = field(default_factory=list)


# ─── Deterministic ID ─────────────────────────────────────────────────────────
def compute_id(content: str) -> str:
    return hashlib.sha256(content.encode()).hexdigest()[:16]


# ─── Fake embedder (swap for sentence-transformers in production) ─────────────
def embed_text(text: str) -> np.ndarray:
    """384-dim mock vector. Replace with: sentence_transformers.SentenceTransformer(...).encode(text)"""
    vec = np.random.rand(384).astype(np.float32)
    vec /= np.linalg.norm(vec)
    return vec


# ─── BM25 via SQLite FTS5 ─────────────────────────────────────────────────────
def _fts5_search(query: str, memories: list[MemoryRecord]) -> dict[str, float]:
    """BM25 approximation using SQLite FTS5. Returns dict: memory_id -> score."""
    conn = sqlite3.connect(str(DB_PATH))
    cursor = conn.cursor()
    # FTS5 table should have: id, content, source_file, timestamp
    try:
        cursor.execute(
            "SELECT id, bm25(fts) as score FROM memories_fts WHERE memories_fts MATCH ? ORDER BY score LIMIT 20",
            (query,)
        )
        return {row[0]: row[1] for row in cursor.fetchall()}
    except sqlite3.OperationalError:
        return {}


# ─── Graph expansion ───────────────────────────────────────────────────────────
def _graph_expand(memory: MemoryRecord, memories: list[MemoryRecord]) -> list[MemoryRecord]:
    """Return 1-hop neighbors from the memory's links."""
    if not memory.links:
        return []
    link_ids = set(memory.links)
    return [m for m in memories if m.id in link_ids]


# ─── Cosine similarity ─────────────────────────────────────────────────────────
def _cosine_scores(query_vec: np.ndarray, memories: list[MemoryRecord]) -> np.ndarray:
    """Compute cosine similarity between query vector and all memory embeddings."""
    if not memories or not memories[0].embedding:
        return np.zeros(len(memories))
    doc_vecs = np.array([m.embedding for m in memories], dtype=np.float32)
    q = query_vec.astype(np.float32)
    q /= (np.linalg.norm(q) + 1e-9)
    doc_vecs /= (np.linalg.norm(doc_vecs, axis=1, keepdims=True) + 1e-9)
    return np.dot(doc_vecs, q)


# ─── Main retrieval function ───────────────────────────────────────────────────
def retrieve(query: str, k: int = TOP_K_DEFAULT, memories: Optional[list[MemoryRecord]] = None) -> list[RetrievalResult]:
    """
    Hybrid retrieval: BM25 + cosine + graph expansion.
    Returns top-k results sorted by combined weighted score.
    """
    start = time.perf_counter()

    if memories is None:
        memories = _load_all_memories()

    if not memories:
        return []

    # 1. BM25 scores (FTS5)
    bm25_scores = _fts5_search(query, memories)

    # 2. Embed query
    query_vec = embed_text(query)

    # 3. Cosine scores
    cos_scores = _cosine_scores(query_vec, memories)

    # 4. Graph expansion (1-hop boost)
    graph_boost = np.zeros(len(memories))
    for i, mem in enumerate(memories):
        neighbors = _graph_expand(mem, memories)
        if neighbors:
            neighbor_indices = [memories.index(n) for n in neighbors]
            graph_boost[neighbor_indices] += 0.1

    # 5. Normalize and combine
    bm25_vals = np.array([bm25_scores.get(m.id, 0.0) for m in memories])
    bm25_norm = bm25_vals / (bm25_vals.max() + 1e-9) if bm25_vals.max() > 0 else bm25_vals
    cos_norm = cos_scores / (cos_scores.max() + 1e-9) if cos_scores.max() > 0 else cos_scores
    graph_norm = graph_boost / (graph_boost.max() + 1e-9) if graph_boost.max() > 0 else graph_boost

    combined = WEIGHT_BM25 * bm25_norm + WEIGHT_COSINE * cos_norm + WEIGHT_GRAPH * graph_norm

    # 6. Top-k
    top_indices = np.argsort(combined)[-k:][::-1]

    # 7. Build results
    results = []
    for idx in top_indices:
        mem = memories[idx]
        reasons = []
        if bm25_scores.get(mem.id, 0) > 0:
            reasons.append(f"BM25:{bm25_scores[mem.id]:.3f}")
        reasons.append(f"cosine:{cos_scores[idx]:.3f}")
        if mem.links:
            reasons.append("graph:1-hop")
        results.append(RetrievalResult(memory=mem, score=float(combined[idx]), match_reasons=reasons))

    elapsed_ms = (time.perf_counter() - start) * 1000
    print(f"[retrieve] query='{query}' k={k} elapsed={elapsed_ms:.1f}ms results={len(results)}")
    return results


# ─── Loader (stub — swap for SQLite load in production) ───────────────────────
def _load_all_memories() -> list[MemoryRecord]:
    """Load all memories from SQLite. Stub for testing."""
    return [
        MemoryRecord(
            id="abc123",
            content="User prefers Python over JavaScript for backend tasks",
            source_file="memory/user_preferences.md",
            timestamp=datetime.now(),
            tags=["preference", "python"],
            embedding=embed_text("User prefers Python over JavaScript for backend tasks").tolist(),
            links=[],
        ),
        MemoryRecord(
            id="def456",
            content="Active project: building a hybrid memory retrieval layer for OpenCode",
            source_file="memory/project_active.md",
            timestamp=datetime.now(),
            tags=["project", "memory", "opencode"],
            embedding=embed_text("Active project: building a hybrid memory retrieval layer").tolist(),
            links=["abc123"],
        ),
    ]


# ─── Test harness ─────────────────────────────────────────────────────────────
if __name__ == "__main__":
    results = retrieve("Python preferences and memory retrieval", k=3)
    for r in results:
        print(f"  score={r.score:.3f} reasons={r.match_reasons}")
        print(f"    content={r.memory.content[:80]}...")
        print(f"    source={r.memory.source_file}")
```

---

## G. Maintenance Operations (ADD/UPDATE/DELETE/NOOP)

```python
from enum import Enum


class OpType(Enum):
    ADD = "ADD"       # new memory, no prior ID
    UPDATE = "UPDATE" # same ID, new content (supersedes old)
    DELETE = "DELETE" # mark deleted (supersedes with deleted=True)
    NOOP = "NOOP"     # unchanged


def consolidation_diff(before: list[MemoryRecord], after: list[MemoryRecord]) -> dict[OpType, list[MemoryRecord]]:
    """
    Diff two snapshots of memory/ directory.
    Returns dict of operations to apply to the retrieval DB.
    """
    before_ids = {m.id: m for m in before}
    after_ids = {m.id: m for m in after}
    result = {OpType.ADD: [], OpType.UPDATE: [], OpType.DELETE: [], OpType.NOOP: []}

    for mem in after:
        if mem.id not in before_ids:
            result[OpType.ADD].append(mem)
        elif before_ids[mem.id].content != mem.content:
            result[OpType.UPDATE].append(mem)

    for mem in before:
        if mem.id not in after_ids:
            result[OpType.DELETE].append(mem)

    result[OpType.NOOP] = [m for m in after if m.id in before_ids and before_ids[m.id].content == m.content]
    return result
```
