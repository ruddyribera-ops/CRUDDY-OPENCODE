# Risks: Hybrid Memory Retrieval Layer

## 1. Embedding Drift Over Time

**Risk:** The `all-MiniLM-L6-v2` model (or any embedding model) may drift from the corpus it was trained on. As OpenCode memory content evolves, embeddings computed at different times may occupy different regions of the vector space, degrading retrieval quality.

**Severity:** MEDIUM — degrades silently over months.

**Mitigation:**
- Re-embed all memories quarterly via `python -m retrieval.reembed --force`
- Log embedding timestamps; flag memories with age > 90 days for re-embed
- Version the embedding model: store `model_version` in DB; re-embed if model changes

**Verification:**
```python
# Check embedding age
memories = load_all_memories()
old_memories = [m for m in memories if (datetime.now() - m.timestamp).days > 90]
print(f"Found {len(old_memories)} memories older than 90 days — re-embed recommended")
```

---

## 2. Retrieval Hallucination (Semantic Match But Wrong Context)

**Risk:** A memory retrieved by cosine similarity may semantically match the query but be contextually wrong — e.g., retrieving "use PostgreSQL" from a 6-month-old project when the current project uses SQLite. The user sees a confident-looking result with a source_file they can't verify.

**Severity:** HIGH — leads to wrong code/generated context.

**Mitigation:**
- **Always include `source_file` in returned `RetrievalResult`** — non-negotiable
- Display `source_file` + `timestamp` alongside every retrieved memory in the session context
- User must be able to open the source .md file to verify
- Add a confidence threshold: if `combined_score < 0.3`, return empty rather than a low-confidence match
- Consider LLM-as-judge: for ambiguous queries, show top-3 candidates and let user pick

**Verification:**
```python
# Every RetrievalResult must have source_file
results = retrieve("gate failures last week", k=5)
for r in results:
    assert r.memory.source_file, f"Missing source_file for memory {r.memory.id}"
    print(f"content={r.memory.content[:60]}... source={r.memory.source_file}")
```

---

## 3. Privacy — All Local, No API

**Risk:** NONE for external privacy — all data stays on the Windows machine.

**Mitigation:** Document this explicitly. The retrieval layer reads `memory/*.md` files and stores embeddings locally. No external API calls. No telemetry. No network egress.

**Verification:**
```bash
# Confirm no external API calls in retrieval layer
grep -r "openai\|anthropic\|cohere\|azure\|google" retrieval/ --include="*.py"
# Expected: no matches
```

**Privacy note:** The `memory/` files themselves may contain sensitive information (e.g., user_preferences.md, session_log.md). Since the retrieval layer is local-only, there is no additional privacy risk beyond what already exists from the files themselves.

---

## 4. Cost — $0 External API

**Risk:** NONE. sentence-transformers `all-MiniLM-L6-v2` is free, local, 80MB.

**Mitigation:** N/A — this is a feature, not a risk.

**Verification:**
```bash
# Confirm no paid dependencies
pip freeze | grep -i "openai\|anthropic\|cohere"
# Expected: no matches
```

---

## 5. FTS5 Index Corruption

**Risk:** SQLite FTS5 index may corrupt if the process is interrupted during write (e.g., power loss, Ctrl+C during consolidation). This would make BM25 retrieval fail silently or return wrong results.

**Severity:** MEDIUM — BM25 fails, cosine still works (graceful degradation).

**Mitigation:**
- Always run consolidation in a transaction: `BEGIN IMMEDIATE` → write → `COMMIT`
- Keep WAL mode enabled: `PRAGMA journal_mode=WAL`
- Weekly integrity check: `PRAGMA integrity_check` run as part of maintenance
- Maintain FTS5 rebuild script: `python -m retrieval.rebuild_fts --force`

**Verification:**
```python
# Weekly integrity check
conn = sqlite3.connect(str(DB_PATH))
cursor = conn.cursor()
cursor.execute("PRAGMA integrity_check")
result = cursor.fetchone()
print(f"Integrity check: {result[0]}")
assert result[0] == "ok", "FTS5 index corrupted — rebuild required"
```

---

## 6. Embedding Model Unavailable

**Risk:** The `all-MiniLM-L6-v2` model download may fail, the model file may be corrupted, or disk space may be insufficient (80MB model + ~22 docs embeddings).

**Severity:** LOW — graceful degradation to BM25-only mode.

**Mitigation:**
- Cache model at `~/.cache/opencode/embedder/` with SHA256 verification
- If model unavailable, fall back to BM25-only retrieval with a warning log
- Check disk space before downloading: require > 500MB free

**Verification:**
```python
from pathlib import Path
cache_dir = Path.home() / ".cache" / "opencode" / "embedder"
model_path = cache_dir / "all-MiniLM-L6-v2"
if model_path.exists():
    print(f"Model cached at {model_path}")
else:
    print("Model not cached — will download on first use")
```

---

## 7. Failure Modes Summary

| Failure Mode | Severity | Detection | Mitigation |
|-------------|----------|-----------|------------|
| Embedding drift | MEDIUM | Re-embed quarterly | Log timestamps, re-embed if age > 90 days |
| Retrieval hallucination | HIGH | Low confidence threshold | Always include source_file; threshold 0.3 |
| FTS5 corruption | MEDIUM | Weekly integrity_check | WAL mode, rebuild script |
| Model unavailable | LOW | Graceful fallback | BM25-only fallback, cache with SHA256 |
| Disk full | LOW | Pre-check | Require > 500MB free before write |
| Session start slow | LOW | Latency monitoring | Async load, lazy embed |

---

## 8. Reversibility — Disable via Env Var

**Risk:** If the retrieval layer causes problems (wrong context injection, performance issues), users need a one-line way to disable it.

**Mitigation:**
- `OPENCODE_MEMORY=off` disables all retrieval operations
- When disabled: retrieval returns empty list, consolidation skips, no embeddings computed
- Implementation: single env var check at top of `retrieval/__init__.py`

**Verification:**
```bash
# Should return empty when disabled
OPENCODE_MEMORY=off python -c "from retrieval import retrieve; print(retrieve('test'))"
# Expected: []
```

---

## 9. Graph Sparsity at Scale

**Risk:** With only ~22 memory files, the graph will be sparse. 1-hop neighbor expansion may not add signal — in fact, it may add noise.

**Severity:** LOW — hybrid scoring weights account for this (graph weight = 0.2).

**Mitigation:**
- Graph expansion is the weakest signal by design (0.2 weight)
- If `links` are empty for all memories, graph_norm = 0 and combined = 0.4*BM25 + 0.4*cosine
- This degrades gracefully to BM25+cosine hybrid, which is still effective

---

## 10. Maintenance Burden

**Risk:** The nightly consolidation script requires a cron job or manual trigger. If it fails silently, the retrieval layer becomes stale.

**Severity:** MEDIUM — stale memories are worse than no memories (misleading context).

**Mitigation:**
- Consolidation logs to `memory/consolidation.log` with timestamps
- On retrieval, check if last consolidation was > 48 hours ago → warn user
- Add `OPENCODE_MEMORY_CONSOLIDATE=1` to force consolidation on next retrieval

**Verification:**
```python
from datetime import datetime, timedelta
last_run = Path("memory/consolidation.log").stat().st_mtime
last_run_dt = datetime.fromtimestamp(last_run)
if datetime.now() - last_run_dt > timedelta(hours=48):
    print("WARNING: consolidation last ran > 48 hours ago — run manually or via cron")
```
