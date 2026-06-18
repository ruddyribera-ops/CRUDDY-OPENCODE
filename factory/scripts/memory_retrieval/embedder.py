"""Sentence-transformers wrapper for embedding generation."""
import os
import threading
from typing import Optional

import numpy as np

# Global model instance (lazy-loaded, thread-safe)
_model: Optional["SentenceTransformer"] = None
_model_lock = threading.Lock()

# Model identifier
EMBEDDING_MODEL = "sentence-transformers/all-MiniLM-L6-v2"
EMBEDDING_DIM = 384  # all-MiniLM-L6-v2 outputs 384-dim vectors


def _get_model() -> "SentenceTransformer":
    """Get or create the singleton SentenceTransformer instance."""
    global _model
    if _model is not None:
        return _model

    with _model_lock:
        if _model is not None:
            return _model

        from sentence_transformers import SentenceTransformer
        _model = SentenceTransformer(EMBEDDING_MODEL)
        return _model


def embed_text(text: str) -> np.ndarray:
    """Generate a 384-dim embedding vector for the given text.

    Uses all-MiniLM-L6-v2. First call downloads the model (~80MB).
    Subsequent calls use cached model.
    """
    model = _get_model()
    embedding = model.encode(text, normalize_embeddings=True, show_progress_bar=False)
    return embedding.astype(np.float32)


def embed_batch(texts: list[str], batch_size: int = 32) -> list[np.ndarray]:
    """Generate embeddings for a batch of texts.

    Args:
        texts: List of strings to embed
        batch_size: Batch size for encoding (default 32)

    Returns:
        List of 384-dim numpy arrays
    """
    if not texts:
        return []

    model = _get_model()
    embeddings = model.encode(
        texts,
        batch_size=batch_size,
        normalize_embeddings=True,
        show_progress_bar=False,
        convert_to_numpy=True,
    )
    return [emb.astype(np.float32) for emb in embeddings]


def cosine_similarity(query_vec: np.ndarray, doc_vecs: np.ndarray) -> np.ndarray:
    """Compute cosine similarity between one query and many document vectors.

    Assumes both query and doc vectors are already L2-normalized.
    """
    if doc_vecs.ndim == 1:
        doc_vecs = doc_vecs.reshape(1, -1)
    return np.dot(doc_vecs, query_vec).flatten()


def check_model_available() -> bool:
    """Check if the embedding model can be loaded (tests network + disk)."""
    try:
        _get_model()
        return True
    except Exception as e:
        import warnings
        warnings.warn(f"Embedding model unavailable: {e}")
        return False
