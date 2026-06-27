# Memory v2 — Architecture Blueprint

## A. Schema Changes (MemoryRecord v1 → v2)

### Diff from `models.py:10-23`

```python
# CURRENT (v1)
class MemoryRecord(BaseModel):
    id: str = Field(description="SHA256 of content — deterministic")
    content: str = Field(description="raw text content, stripped of markdown")
    source_file: Path = Field(description="path to originating .md file")
    timestamp: datetime = Field(default_factory=datetime.now)
    tags: list[str] = Field(default_factory=list)
    embedding: list[float] = Field(default_factory=list)  # 384-dim
    links: list[str] = Field(default_factory=list)  # memory IDs
    superseded_by: Optional[str] = Field(None)  # [NEW] inverse of supersedes
    importance: float = Field(default=0.5, ge=0.0, le=1.0)  # [NEW] 0-1 scale
    expires_at: Optional[datetime] = Field(None)  # [NEW] TTL, nullable
    version: int = Field(default=1)  # [NEW] monotonic version counter
    session_id: Optional[str] = Field(None)  # [NEW] links to conversation session
```

### SQL Migration (backwards-compatible ALTER)

```sql
ALTER TABLE memories ADD COLUMN superseded_by TEXT;
ALTER TABLE memories ADD COLUMN importance REAL DEFAULT 0.5;
ALTER TABLE memories ADD COLUMN expires_at TEXT;  -- ISO datetime, nullable
ALTER TABLE memories ADD COLUMN version INTEGER DEFAULT 1;
ALTER TABLE memories ADD COLUMN session_id TEXT;
```

### `model_to_row()` changes (`models.py:50-62`)

```python
def model_to_row(model: MemoryRecordV2) -> dict:
    import json
    return {
        "id": model.id,
        "content": model.content,
        "source_file": str(model.source_file),
        "timestamp": model.timestamp.isoformat(),
        "tags": json.dumps(model.tags),
        "embedding": _embeddings_to_blob(model.embedding),
        "links": json.dumps(model.links),
        "supersedes": model.supersedes,  # [UNCHANGED]
        # [NEW FIELDS]
        "superseded_by": model.superseded_by,
        "importance": model.importance,
        "expires_at": model.expires_at.isoformat() if model.expires_at else None,
        "version": model.version,
        "session_id": model.session_id,
    }
```

### `row_to_model()` changes (`models.py:65-80`)

```python
def row_to_model(row: dict) -> MemoryRecordV2:
    import json
    from datetime import datetime
    embedding_list = _blob_to_embeddings(row["embedding"])
    return MemoryRecordV2(
        id=row["id"],
        content=row["content"],
        source_file=Path(row["source_file"]),
        timestamp=datetime.fromisoformat(row["timestamp"]),
        tags=json.loads(row["tags"]) if row["tags"] else [],
        embedding=embedding_list,
        links=json.loads(row["links"]) if row["links"] else [],
        superseded_by=row["superseded_by"],  # [NEW]
        importance=row.get("importance", 0.5),  # [NEW] default 0.5 for old rows
        expires_at=datetime.fromisoformat(row["expires_at"]) if row.get("expires_at") else None,  # [NEW]
        version=row.get("version", 1),  # [NEW]
        session_id=row.get("session_id"),  # [NEW]
    )
```

---

## B. New Retrieval Scoring Formula

### Current (`retriever.py:112`)

```python
combined = WEIGHT_BM25 * bm25_norm + WEIGHT_COSINE * cos_norm + WEIGHT_GRAPH * graph_norm
```

### Proposed v2 Formula

```
combined = w_bm25*BM25_norm + w_cosine*cos_norm + w_recency*recency_norm + w_importance*importance_norm + w_graph*graph_norm

Where:
- w_bm25 = 0.25
- w_cosine = 0.25
- w_recency = 0.15
- w_importance = 0.20
- w_graph = 0.15
- Total = 1.0
```

### Recency Score Formula

```python
def recency_score(timestamp: datetime, now: datetime | None = None) -> float:
    """1.0 for today, decays ~0.5 after 7 days, ~0.1 after 30 days."""
    from datetime import timedelta
    if now is None:
        now = datetime.now()
    days_since = (now - timestamp).total_seconds() / 86400
    # Half-life of ~7 days
    return 1.0 / (1.0 + days_since / 7.0)
```

### Importance Score (direct)

```python
# Already 0-1, use directly
importance_norm = memory.importance
```

### Integration into `retrieve()` (`retriever.py:99-112`)

```python
# After graph boost computation (existing code), add:
recency_vals = np.array([
    recency_score(m.timestamp) for m in memories
], dtype=np.float32)
importance_vals = np.array([m.importance for m in memories], dtype=np.float32)

# Normalize
recency_norm = recency_vals / recency_vals.max() if recency_vals.max() > 0 else recency_vals
importance_norm = importance_vals / importance_vals.max() if importance_vals.max() > 0 else importance_vals

# Combine with new weights
combined = (
    0.25 * bm25_norm +
    0.25 * cos_norm +
    0.15 * recency_norm +
    0.20 * importance_norm +
    0.15 * graph_norm
)
```

---

## C. New extract Command

### CLI Addition (`cli.py`)

```python
# In main(), add:
extract_parser = subparsers.add_parser("extract", help="Extract facts from markdown/transcript")
extract_parser.add_argument("file", help="Markdown file or transcript to extract from")
extract_parser.add_argument("--session-id", default=None, help="Optional session ID to tag memories")
extract_parser.add_argument("--importance", type=float, default=0.5, help="Base importance 0-1")
```

### LLM Extraction Prompt Template

```python
EXTRACT_PROMPT = """You are a memory extraction system. Given input text, extract discrete facts
as JSON array of memory objects. Each memory object has:
- content: the fact (max 200 chars, be specific)
- tags: 2-4 keywords for retrieval
- importance: 0.0-1.0 (0.5 is normal, 0.8+ for decisions/lessons, 0.3 for notes)

Rules:
- Extract ONLY facts, not opinions or filler
- Each fact should be independently retrievable
- Merge related info into single facts (do not fragment)
- Tag with specific tech names, project names, patterns

Input: {input_text}

Output JSON array:"""

def extract_facts(text: str, importance: float = 0.5) -> list[MemoryRecordV2]:
    """Use LLM to extract facts from raw text."""
    import json, hashlib
    response = call_llm(EXTRACT_PROMPT.format(input_text=text))
    facts = json.loads(response)
    
    records = []
    for fact in facts:
        content = fact["content"][:200]
        record = MemoryRecordV2(
            id=hashlib.sha256(content.encode()).hexdigest()[:16],
            content=content,
            source_file=Path("extracted"),
            tags=fact.get("tags", []),
            importance=fact.get("importance", importance),
            session_id=session_id,
        )
        records.append(record)
    return records
```

### `cmd_extract()` Implementation

```python
def cmd_extract(args: argparse.Namespace) -> int:
    """Extract facts from a markdown file or transcript."""
    from memory_retrieval.store import MemoryStore
    from memory_retrieval.embedder import embed_text
    
    path = Path(args.file)
    if not path.exists():
        print(f"ERROR: File not found: {path}", file=sys.stderr)
        return 1
    
    text = path.read_text(encoding="utf-8")
    records = extract_facts(text, importance=args.importance, session_id=args.session_id)
    
    # Generate embeddings
    for record in records:
        record.embedding = embed_text(record.content)
    
    store = MemoryStore(_resolve_db_path(args.db))
    count = store.upsert_batch(records)
    print(f"Extracted {count} facts from {path.name}")
    return 0
```

---

## D. Cross-Memory Linking Algorithm

### Pseudocode

```
On store.insert(record):
  1. Find candidates: memories sharing same source_file OR same tags OR timestamp within 7 days
  2. For each candidate, compute link_score = overlap_count / total_unique_keys
  3. If link_score > 0.3, add candidate.id to record.links
  4. If record.id in candidate.links already, skip (avoid duplicate edges)
  5. Insert record with computed links
```

### 20-line Python Implementation (`store.py`, new method)

```python
from datetime import timedelta

def _compute_auto_links(self, record: MemoryRecordV2, all_memories: list[MemoryRecordV2]) -> list[str]:
    """Auto-link a new record to related existing memories."""
    links = []
    record_tags = set(record.tags)
    record_date = record.timestamp
    link_threshold = 0.3
    
    for candidate in all_memories:
        if candidate.id == record.id:
            continue
        
        score = 0.0
        # Same source_file: +0.4
        if candidate.source_file == record.source_file:
            score += 0.4
        # Shared tags: +0.3 per shared tag (max 0.3)
        shared = record_tags & set(candidate.tags)
        score += min(0.3, len(shared) * 0.15)
        # Within 7 days: +0.3
        if abs((candidate.timestamp - record_date).total_seconds()) < 7 * 86400:
            score += 0.3
        
        if score >= link_threshold:
            links.append(candidate.id)
    
    return links
```

### Integration into `insert()` (`store.py:55`)

```python
def insert(self, record: MemoryRecordV2) -> None:
    # ... existing rowid check code ...
    
    # Auto-link new record to related memories
    if not record.links:  # Only if not manually set
        all_memories = self.get_all()
        record.links = self._compute_auto_links(record, all_memories)
    
    # ... rest of existing insert code ...
```

---

## E. Proactive Surfacing (on_session_start v2)

### Current (`hook_integration.py:60-102`)

```python
def on_session_start() -> dict:
    # Retrieve by 3 queries, take top-3 each
    # Then add top-3 most recent
    # Return top-10 total
```

### Proposed v2 (`hook_integration.py:60-102`)

```python
def on_session_start(task_description: str | None = None) -> dict:
    """Return context-aware memories at session start.
    
    Args:
        task_description: Optional task context to match against.
                          If provided, weights towards relevant memories.
    """
    retriever = _get_retriever()
    if not retriever:
        return {"memories": [], "context_block": "", "recent_context": []}
    
    seen_ids: set[str] = set()
    memories: list[dict] = []
    recent_context: list[dict] = []
    
    # 1. Today and yesterday memories (recency bucket)
    from datetime import datetime, timedelta
    now = datetime.now()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    yesterday_start = today_start - timedelta(days=1)
    
    all_memories = retriever.store.get_all()
    for m in all_memories:
        if m.timestamp >= yesterday_start:
            if m.id not in seen_ids:
                seen_ids.add(m.id)
                recent_context.append({...})  # format same as memories
    
    # 2. If task_description provided, do targeted retrieval
    if task_description:
        for r in retriever.retrieve(task_description, k=5):
            if r.memory.id not in seen_ids:
                seen_ids.add(r.memory.id)
                memories.append({...})
    
    # 3. Fallback: user_preferences + project_active
    for q in ["user preferences", "project active current"]:
        for r in retriever.retrieve(q, k=2):
            if r.memory.id not in seen_ids:
                seen_ids.add(r.memory.id)
                memories.append({...})
    
    return {
        "memories": memories[:10],
        "recent_context": recent_context[:5],  # [NEW] Today memories
        "context_block": _format_context_block(memories[:10]),
    }
```

### Key Changes

| Field | v1 | v2 |
|-------|----|----|
| `memories` | top-3 by queries + top-3 by recency | task-relevant + user_prefs + project_active |
| `recent_context` | (none) | memories from today/yesterday |
| `context_block` | includes all 10 | unchanged |

---

## F. Memory Decay

### Where Decay Lives

Decay is **not** applied on retrieval (that would slow down every query). Instead:

1. **On retrieval return** — track which memories were returned in a session
2. **On session end OR on a timer** — apply decay to memories not retrieved in N days

### Implementation Location

New file: `decay.py`

```python
"""Memory decay — run periodically or on session end."""
from datetime import datetime, timedelta
from pathlib import Path

DECAY_RATE = 0.02  # importance -= 0.02 per day of no retrieval
DECAY_THRESHOLD = 0.1  # below this, exclude from top-k
RETRIEVAL_HISTORY_DAYS = 30  # look-back window

class DecayManager:
    def __init__(self, db_path: Path):
        self.store = MemoryStore(db_path)
        self._retrieved_ids: set[str] = set()  # IDs returned this session
    
    def record_retrieval(self, memory_ids: list[str]) -> None:
        """Track which memories were returned (call from retriever)."""
        self._retrieved_ids.update(memory_ids)
    
    def apply_decay(self) -> int:
        """Apply decay to all memories not retrieved recently.
        
        Returns count of decayed memories.
        """
        all_memories = self.store.get_all()
        decayed = 0
        
        for mem in all_memories:
            if mem.importance <= DECAY_THRESHOLD:
                continue  # Already at floor
            
            # Check if expires_at passed
            if mem.expires_at and datetime.now() > mem.expires_at:
                mem.importance = DECAY_THRESHOLD
                decayed += 1
            elif mem.importance > DECAY_THRESHOLD:
                # Simple time-based decay for memories > 90 days old
                age_days = (datetime.now() - mem.timestamp).days
                if age_days > 90:
                    days_over = age_days - 90
                    decayed_amount = DECAY_RATE * days_over
                    mem.importance = max(DECAY_THRESHOLD, mem.importance - decayed_amount)
                    decayed += 1
        
        if decayed > 0:
            self.store.upsert_batch([m for m in all_memories if m.importance <= DECAY_THRESHOLD])
        
        return decayed
    
    def get_decay_report(self) -> dict:
        """Return stats about decay state."""
        all_memories = self.store.get_all()
        below_threshold = sum(1 for m in all_memories if m.importance <= DECAY_THRESHOLD)
        return {
            "total_memories": len(all_memories),
            "below_threshold": below_threshold,
            "average_importance": sum(m.importance for m in all_memories) / max(1, len(all_memories)),
        }
```

### Integration into `retriever.py`

At end of `retrieve()` method, after building results:

```python
# After line 143 (return results)
# [NEW] Notify decay manager of retrieved IDs
if hasattr(self, "_decay_manager") and self._decay_manager:
    self._decay_manager.record_retrieval([r.memory.id for r in results])
```

### Threshold Check in Retrieval

At top of `retrieve()` method, after loading memories:

```python
# [NEW] Filter out decayed memories unless explicitly querying
memories = [m for m in memories if m.importance > DECAY_THRESHOLD or query.lower().__contains__(m.content.lower())]
```

---

## Implementation File Map

| File | Changes | Lines Added |
|------|---------|-------------|
| `models.py` | Add V2 model, update converters | +25 |
| `store.py` | ALTER TABLE compat, `_compute_auto_links()` | +40 |
| `retriever.py` | New formula, decay filter, decay manager integration | +30 |
| `hook_integration.py` | `on_session_start(task_description)` | +25 |
| `cli.py` | `extract` command | +35 |
| `decay.py` | NEW — DecayManager class | +75 |
| **Total** | | **~230 lines** |

---

## Backwards Compatibility

- All existing 87 memories survive: new columns nullable with defaults
- `MemoryRecord` v1 still usable via `MemoryRecordV2(..., importance=0.5)` coercion
- No FTS5 schema changes (BM25 unchanged)
- No embedding dimension changes
