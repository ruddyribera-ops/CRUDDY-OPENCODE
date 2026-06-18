---
name: memory-retrieval
description: Hybrid BM25+cosine+graph memory search over the memory/ directory. Used on SessionStart and when UserPromptSubmit triggers "remember" / "last time" / "we did".
triggers: remember, last time, previously, we did, recall, what did we
auto_load: code-builder, code-analyzer, main-coordinator
---

## When to Use

Invoke the memory retrieval system when the user:
- Asks about past decisions, sessions, or projects
- References something they did before ("last time we...")
- Uses trigger words: remember, recall, previously, what did we
- Starts a new session (auto-load recent context)

## How to Invoke

```bash
# From the opencode root directory
cd <INSTALL_DIR>/.config\opencode

# Query the memory store
python -m memory_retrieval query "your question here" --k 3

# Re-index after adding new memory files
python -m memory_retrieval index --source-dir memory --db .opencode/memory.db
```

## How It Works

The retrieval system uses a hybrid approach:
1. **BM25** — keyword matching via SQLite FTS5
2. **Cosine similarity** — semantic matching via sentence-transformers/all-MiniLM-L6-v2
3. **Graph boosting** — related memories boosted via NetworkX graph (future)

Results are ranked by combined score with a 0.3 confidence threshold.

## Disable Memory

Set the environment variable `OPENCODE_MEMORY=off` to disable retrieval:

```powershell
$env:OPENCODE_MEMORY = "off"
python -m memory_retrieval query "anything" --k 3
# Returns: [memory disabled]
```

## Model Download

First run downloads the embedding model (~80MB). Subsequent runs use cached model.

## Edge Cases

- **Idempotent indexing** — re-running index uses content SHA as ID, so duplicates are replaced not duplicated
- **Empty files** — skipped with warning
- **No match** — returns empty list `[]` when confidence < 0.3
