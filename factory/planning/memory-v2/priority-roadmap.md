# Memory v2 — Priority Roadmap

## Recommended Implementation Order

| Phase | Gaps | Total Time | Impact |
|-------|------|------------|--------|
| **Phase 1 (this week)** | G3 Importance + G2 Recency | 4-6 hours | 9/10 |
| **Phase 2 (next sprint)** | G5 Proactive surfacing + G6 Auto-linking | 3-4 days | 7/10 |
| **Phase 3 (eventual)** | G1, G4, G7, G8 | 1-2 weeks | 6/10 |

---

## Phase 1: Importance + Recency (THIS WEEK)

**Why these first:**
- G3 (Importance) is what makes Mem0 feel "smart" — 20 lines, 2 hours
- G3 enables G5 (proactive surfacing) since surfacing weights by importance
- G2 (Recency) is what users notice most on "what changed since last session?"
- Combined: ~1 day of work, closes the biggest perception gap

### G3: Importance Scoring

**Concrete step:** Add `importance` column to SQLite, update `models.py`, set auto-values based on `source_file`.

**Estimated time:** 2 hours

**Implementation:**
1. Add nullable `importance REAL DEFAULT 0.5` column via `ALTER TABLE`
2. Update `model_to_row()` / `row_to_model()` in `models.py`
3. Add auto-assignment logic in `indexer.py` based on filename patterns:
   - `user_preferences.md` → importance = 0.9
   - `project_active.md` → importance = 0.8
   - `session_log.md` → importance = 0.3
   - All others → importance = 0.5

**Verify:**
```bash
python -c "from memory_retrieval.store import MemoryStore; s = MemoryStore('.opencode/memory.db'); ms = s.get_all(); print(f'Avg importance: {sum(m.importance for m in ms)/len(ms):.2f}')"
```

Expected output: Avg importance ~0.55 (weighted toward session_log=0.3)

---

### G2: Recency Boost

**Concrete step:** Add recency_score function and integrate into `retriever.py:retrieve()`.

**Estimated time:** 1 hour

**Prerequisites:** None (independent of G3)

**Implementation:**
1. Add `recency_score()` function to `retriever.py`
2. Add `recency_vals` array after `cos_scores` calculation
3. Normalize and add 0.15 weight to combined formula
4. No schema changes needed

**Verify:**
```bash
python -c "
from memory_retrieval.retriever import MemoryRetriever
r = MemoryRetriever('.opencode/memory.db')
results = r.retrieve('project', k=5)
for res in results:
    print(f'{res.score:.3f} {res.memory.source_file.name}')
"
```

Expected: Memories from last 7 days should score higher than 6-month-old memories with similar content.

---

## Phase 2: Proactive Surfacing + Auto-Linking (NEXT SPRINT)

**Why these next:**
- G5 (Proactive surfacing) transforms session start from "dumb top-3" to "context-aware"
- G5 requires G3 (Importance) since surfacing should prioritize important memories
- G6 (Auto-linking) populates the graph that G5's surfacing will use
- Combined: ~3-4 days of work

---

### G5: Proactive Surfacing

**Concrete step:** Rewrite `on_session_start()` to accept optional `task_description` parameter and surface relevant memories.

**Estimated time:** 2 days

**Prerequisites:** G3 (Importance field must exist for weighted surfacing)

**Implementation:**
1. Add `task_description: str | None = None` param to `on_session_start()` in `hook_integration.py`
2. When `task_description` provided, do targeted retrieval weighted by importance
3. Add `recent_context` return field for today/yesterday memories
4. Update call sites (OpenCode hook system) to pass task context if available

**Verify:**
```python
result = on_session_start(task_description="working on authentication")
assert "recent_context" in result
assert len(result["recent_context"]) <= 5
assert result["memories"][0]["score"] >= result["recent_context"][0]["score"]  # task-relevant prioritized
```

---

### G6: Cross-Memory Auto-Linking

**Concrete step:** Add `_compute_auto_links()` method to `MemoryStore`, call from `insert()`.

**Estimated time:** 2 days

**Prerequisites:** G3 (Importance for link scoring), G2 (Recency for time-window matching)

**Implementation:**
1. Add `_compute_auto_links()` to `store.py` (see blueprint.md Section D)
2. Call from `insert()` only when `record.links` is empty
3. Batch test: re-index all 87 memories, verify links are populated

**Verify:**
```bash
python -c "
from memory_retrieval.store import MemoryStore
s = MemoryStore('.opencode/memory.db')
ms = s.get_all()
linked = sum(1 for m in ms if m.links)
print(f'Memories with auto-links: {linked}/{len(ms)}')
print(f'Avg links per memory: {sum(len(m.links) for m in ms)/len(ms):.1f}')
"
```

Expected: >50% of memories should have at least 1 auto-link

---

## Phase 3: Eventual (G1, G4, G7, G8)

### G1: Automatic Extraction
- **When:** After OpenCode produces structured conversation logs
- **Effort:** 3-4 days
- **Depends on:** Upstream conversation capture in OpenCode core

### G4: Memory Decay
- **When:** After Phase 1 complete, integrate into daily cron
- **Effort:** 2-3 days
- **Depends on:** G3 (importance field to decay)

### G7: Update Semantics (Versioning)
- **When:** Solo dev audit trail needed
- **Effort:** 3-4 days
- **Depends on:** None (independent)

### G8: Session Summaries
- **When:** After G1 (extraction) is implemented
- **Effort:** 2 days
- **Depends on:** G1 for conversation capture

---

## Quick-Reference Implementation Checklist

| Gap | Status | Hours | Verified |
|-----|--------|-------|----------|
| G3 Importance | TODO | 2h | Query avg importance |
| G2 Recency | TODO | 1h | Recent memories score higher |
| G5 Proactive | TODO | 2d | Task context surfacing works |
| G6 Auto-linking | TODO | 2d | >50% memories linked |
| G1 Extraction | Blocked | 3-4d | - |
| G4 Decay | TODO | 2-3d | Low-importance decays |
| G7 Versioning | TODO | 3-4d | Old versions archived |
| G8 Sessions | Blocked | 2d | - |
