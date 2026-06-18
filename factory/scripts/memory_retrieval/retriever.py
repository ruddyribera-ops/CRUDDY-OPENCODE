"""Hybrid retriever: BM25 + cosine + graph expansion."""
import os
import time
from datetime import datetime
from pathlib import Path
from typing import Optional

import numpy as np

from .embedder import cosine_similarity, embed_text
from .graph import MemoryGraph
from .models import MemoryRecord, RetrievalResult
from .store import MemoryStore

# Weights for score combination (Phase 1: G3 + G2)
WEIGHT_BM25 = 0.25
WEIGHT_COSINE = 0.25
WEIGHT_RECENCY = 0.15
WEIGHT_IMPORTANCE = 0.20
WEIGHT_GRAPH = 0.15

# Graph boost value
GRAPH_BOOST = 0.1

# Default and max k
TOP_K_DEFAULT = 5
TOP_K_MAX = 10

# Low-confidence threshold
CONFIDENCE_THRESHOLD = 0.3

# Environment variable to disable memory
ENV_DISABLE = "OPENCODE_MEMORY"


def recency_score(memory: MemoryRecord, now: datetime | None = None) -> float:
    """0.0 to 1.0, 1.0 = retrieved just now. Half-life of 7 days."""
    if now is None:
        now = datetime.now()
    days = (now - memory.timestamp).total_seconds() / 86400
    # half-life of 7 days: after 7 days, score = 0.5
    return 1.0 / (1.0 + days / 7.0)


class MemoryRetriever:
    """Hybrid memory retriever combining BM25, cosine, and graph signals."""

    def __init__(self, db_path: Path):
        self.store = MemoryStore(db_path)
        self._graph: Optional[MemoryGraph] = None

    def _ensure_graph(self) -> MemoryGraph:
        """Lazy-load the memory graph."""
        if self._graph is None:
            memories = self.store.get_all()
            self._graph = MemoryGraph()
            self._graph.build_from_memories(memories)
        return self._graph

    def retrieve(
        self,
        query: str,
        k: int = TOP_K_DEFAULT,
        threshold: float = CONFIDENCE_THRESHOLD,
        now: datetime | None = None,
    ) -> list[RetrievalResult]:
        """Hybrid retrieval: BM25 + cosine + recency + importance + graph expansion.

        Args:
            query: Search query string
            k: Number of results to return (default 5, max 10)
            threshold: Minimum score threshold (default 0.3)
            now: Optional reference time for recency scoring (default: datetime.now())

        Returns:
            List of RetrievalResult objects, sorted by combined score
        """
        # Check if memory is disabled
        if os.getenv(ENV_DISABLE, "").lower() in ("off", "0", "false", "no"):
            return []

        # Validate k
        k = min(k, TOP_K_MAX)

        # Load all memories
        memories = self.store.get_all()
        if not memories:
            return []

        start = time.perf_counter()

        # 1. BM25 via FTS5
        bm25_scores = self.store.fts5_search(query, top_k=k * 2)

        # 2. Embed query
        query_embedding = embed_text(query)

        # 3. Get all embeddings
        _, all_embeddings = self.store.get_embeddings_matrix()
        if not all_embeddings:
            return []

        all_embeddings = np.array(all_embeddings, dtype=np.float32)

        # 4. Cosine similarity
        cos_scores = cosine_similarity(query_embedding, all_embeddings)

        # 5. Graph expansion (1-hop neighbors get +0.1 boost)
        graph = self._ensure_graph()
        memory_ids = [m.id for m in memories]
        graph_boost_scores = graph.compute_boost_scores(memory_ids, boost=GRAPH_BOOST)

        # 6. Normalize and combine
        bm25_vals = np.array([bm25_scores.get(m.id, 0.0) for m in memories], dtype=np.float32)
        graph_vals = np.array([graph_boost_scores.get(m.id, 0.0) for m in memories], dtype=np.float32)

        # Compute recency and importance scores
        recency_vals = np.array([recency_score(m, now) for m in memories], dtype=np.float32)
        importance_vals = np.array([m.importance for m in memories], dtype=np.float32)

        # Normalize (avoid division by zero)
        bm25_max = bm25_vals.max()
        cos_max = cos_scores.max()
        graph_max = graph_vals.max()
        recency_max = recency_vals.max()
        importance_max = importance_vals.max()

        bm25_norm = bm25_vals / bm25_max if bm25_max > 0 else bm25_vals
        cos_norm = cos_scores / cos_max if cos_max > 0 else cos_scores
        graph_norm = graph_vals / graph_max if graph_max > 0 else graph_vals
        recency_norm = recency_vals / recency_max if recency_max > 0 else recency_vals
        importance_norm = importance_vals / importance_max if importance_max > 0 else importance_vals

        # Phase 1: combined = 0.25*BM25 + 0.25*cosine + 0.15*recency + 0.20*importance + 0.15*graph
        combined = (
            WEIGHT_BM25 * bm25_norm +
            WEIGHT_COSINE * cos_norm +
            WEIGHT_RECENCY * recency_norm +
            WEIGHT_IMPORTANCE * importance_norm +
            WEIGHT_GRAPH * graph_norm
        )

        # 7. Top-k indices (descending)
        if len(combined) < k:
            top_indices = np.argsort(combined)[::-1]
        else:
            top_indices = np.argsort(combined)[-k:][::-1]

        # 8. Build results with match reasons
        results: list[RetrievalResult] = []
        for idx in top_indices:
            mem = memories[idx]
            score = float(combined[idx])

            # Skip below threshold
            if score < threshold:
                continue

            reasons = []
            if bm25_scores.get(mem.id, 0) > 0:
                reasons.append(f"BM25:{bm25_scores[mem.id]:.3f}")
            reasons.append(f"cosine:{cos_scores[idx]:.3f}")
            if mem.links:
                reasons.append("graph:1-hop")

            results.append(RetrievalResult(
                memory=mem,
                score=score,
                match_reasons=reasons,
            ))

        elapsed_ms = (time.perf_counter() - start) * 1000
        return results

    def retrieve_with_context(
        self,
        query: str,
        k: int = TOP_K_DEFAULT,
    ) -> dict:
        """Retrieve with additional context (for OpenCode integration).

        Returns dict with results and metadata.
        """
        results = self.retrieve(query, k=k)

        if not results:
            disabled = os.getenv(ENV_DISABLE, "").lower() in ("off", "0", "false", "no")
            return {
                "results": [],
                "count": 0,
                "query": query,
                "disabled": disabled,
                "message": "[memory disabled]" if disabled else "no results",
            }

        return {
            "results": results,
            "count": len(results),
            "query": query,
            "disabled": False,
            "message": f"found {len(results)} results",
        }

    def clear_cache(self) -> None:
        """Clear the graph cache to force rebuild on next retrieve."""
        self._graph = None
