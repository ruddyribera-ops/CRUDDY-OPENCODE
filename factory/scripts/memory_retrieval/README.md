# Hybrid Memory Retrieval Layer

BM25 + Cosine similarity + Graph expansion for OpenCode's 22 memory files.

## Architecture

```
memory/*.md → extract → embed (all-MiniLM-L6-v2) → store (SQLite FTS5 + BLOB)
                                                        ↓
Query → BM25 (FTS5) + cosine (vector) + graph (1-hop) → combine → top-k
```

## Scoring

```
final_score = 0.4 * BM25_norm + 0.4 * cosine_norm + 0.2 * graph_boost
```

- **BM25**: Keyword match via SQLite FTS5
- **Cosine**: Semantic similarity via 384-dim all-MiniLM-L6-v2 embeddings
- **Graph**: +0.1 boost for 1-hop neighbors via NetworkX

## Quick Start

```powershell
# Install dependencies
cd scripts/memory_retrieval
uv venv
uv pip install -r requirements.txt

# Index memory files
python -m memory_retrieval index --source-dir memory/ --db .opencode/memory.db

# Query
python -m memory_retrieval query "gate failures" --k 3
python -m memory_retrieval query "what should I do when the agent makes mistakes" --k 3
```

## CLI Commands

### `index`
```powershell
python -m memory_retrieval index --source-dir memory/ --db .opencode/memory.db [--rebuild] [-v]
```

Options:
- `--source-dir`: Directory containing .md files (required)
- `--db`: SQLite database path (default: .opencode/memory.db)
- `--rebuild`: Clear existing index before re-indexing
- `-v`: Verbose output

### `query`
```powershell
python -m memory_retrieval query "query text" [--k 3] [--db .opencode/memory.db] [--json]
```

Options:
- `--k`: Number of results (default: 5, max: 10)
- `--db`: SQLite database path
- `--json`: Output as JSON

## Configuration

| Env Variable | Values | Effect |
|--------------|--------|--------|
| `OPENCODE_MEMORY` | `off`, `0`, `false`, `no` | Disable memory retrieval (returns empty) |

## Dependencies

- `sentence-transformers>=2.2.0` — all-MiniLM-L6-v2 embeddings
- `numpy>=1.24.0` — cosine similarity
- `networkx>=3.1` — graph relationships
- `pydantic>=2.0.0` — data validation

## Files

```
scripts/memory_retrieval/
├── __init__.py      # Package init + exports
├── models.py        # Pydantic schemas (MemoryRecord, RetrievalResult)
├── store.py         # SQLite store (FTS5 + BLOB vectors)
├── embedder.py      # Sentence-transformers wrapper
├── graph.py         # NetworkX memory relationships
├── indexer.py       # Extract → embed → store pipeline
├── retriever.py     # Hybrid retrieval (BM25 + cosine + graph)
├── cli.py           # CLI entry point
├── requirements.txt # Dependencies
└── README.md        # This file
```
