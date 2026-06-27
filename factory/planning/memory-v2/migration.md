# Memory v2 — Migration Guide

## Overview

Migrate 87 existing memories from v1 schema to v2 schema without data loss. All new columns are nullable with defaults. No rows are deleted or modified — only new columns added.

---

## Pre-Migration Checklist

- [ ] Backup `.opencode/memory.db`
- [ ] Verify current count: `python -c "from memory_retrieval.store import MemoryStore; print(len(MemoryStore('.opencode/memory.db').get_all()))"`
- [ ] Expected: 87 memories

---

## Step 1: Schema Migration (SQLite)

Run these commands in order. All are backwards-compatible additions.

```sql
-- 1. Add superseded_by (inverse of supersedes)
ALTER TABLE memories ADD COLUMN superseded_by TEXT;

-- 2. Add importance (default 0.5 for all existing rows)
ALTER TABLE memories ADD COLUMN importance REAL DEFAULT 0.5;

-- 3. Add expires_at (nullable — no TTL by default)
ALTER TABLE memories ADD COLUMN expires_at TEXT;

-- 4. Add version (default 1 for all existing)
ALTER TABLE memories ADD COLUMN version INTEGER DEFAULT 1;

-- 5. Add session_id (nullable)
ALTER TABLE memories ADD COLUMN session_id TEXT;

-- 6. Verify schema
PRAGMA table_info(memories);
```

Expected output after PRAGMA:
```
cid  name           type    notnull  dflt_value  pk
0    id             TEXT    1        NULL        1
1    content        TEXT    1        NULL        0
2    source_file    TEXT    1        NULL        0
3    timestamp      TEXT    1        NULL        0
4    tags           TEXT    0        []          0
5    embedding      BLOB    0        NULL        0
6    links          TEXT    0        []          0
7    supersedes     TEXT    0        NULL        0
8    superseded_by  TEXT    0        NULL        0   [NEW]
9    importance     REAL    0        0.5         0   [NEW]
10   expires_at     TEXT    0        NULL        0   [NEW]
11   version        INTEGER 0        1           0   [NEW]
12   session_id     TEXT    0        NULL        0   [NEW]
```

---

## Step 2: Populate New Fields for Existing Memories

### Auto-Importance Based on Source File

```python
# Run this after schema migration to auto-set importance
import sqlite3
from pathlib import Path

DB = Path(".opencode/memory.db")
conn = sqlite3.connect(str(DB))
cursor = conn.cursor()

# Importance mapping by source_file pattern
IMPORTANCE_MAP = {
    "user_preferences": 0.9,
    "project_active": 0.8,
    "session_log": 0.3,
    "lessons_learned": 0.7,
    "feedback_": 0.5,
    "reference_": 0.6,
    "research_": 0.5,
    "gap-": 0.4,
    "ci_cd": 0.6,
    "current_sprint": 0.7,
    "master-plan": 0.8,
}

def get_importance(source_file: str) -> float:
    source = Path(source_file).name.lower()
    for pattern, importance in IMPORTANCE_MAP.items():
        if pattern.lower() in source:
            return importance
    return 0.5  # default

# Update all rows
cursor.execute("SELECT id, source_file FROM memories")
for row in cursor.fetchall():
    memory_id, source_file = row
    importance = get_importance(source_file)
    cursor.execute(
        "UPDATE memories SET importance = ? WHERE id = ?",
        (importance, memory_id)
    )

conn.commit()

# Verify
cursor.execute("SELECT AVG(importance), MIN(importance), MAX(importance) FROM memories")
avg, min_val, max_val = cursor.fetchone()
print(f"Importance stats: avg={avg:.3f}, min={min_val:.3f}, max={max_val:.3f}")

conn.close()
```

---

## Step 3: Verify Migration

### Count Check

```bash
python -c "
from memory_retrieval.store import MemoryStore
store = MemoryStore('.opencode/memory.db')
memories = store.get_all()
print(f'Total memories: {len(memories)}')

# Verify new fields
with_importance = sum(1 for m in memories if hasattr(m, 'importance'))
with_version = sum(1 for m in memories if hasattr(m, 'version'))
with_expires = sum(1 for m in memories if hasattr(m, 'expires_at') and m.expires_at)
with_session = sum(1 for m in memories if hasattr(m, 'session_id') and m.session_id)

print(f'With importance field: {with_importance}/{len(memories)}')
print(f'With version field: {with_version}/{len(memories)}')
print(f'With expires_at set: {with_expires}/{len(memories)}')
print(f'With session_id set: {with_session}/{len(memories)}')

# Importance distribution
importances = [m.importance for m in memories]
print(f'Avg importance: {sum(importances)/len(importances):.3f}')
"
```

Expected output:
```
Total memories: 87
With importance field: 87/87
With version field: 87/87
With expires_at set: 0/87
With session_id set: 0/87
Avg importance: 0.54
```

### Schema Diff

```bash
python -c "
import sqlite3
conn = sqlite3.connect('.opencode/memory.db')
cursor = conn.cursor()
cursor.execute('PRAGMA table_info(memories)')
cols = {row[1]: row[2] for row in cursor.fetchall()}
print('Columns in memories table:')
for name, type_ in cols.items():
    print(f'  {name}: {type_}')
conn.close()
"
```

Expected: 13 columns (was 8 before)

---

## Step 4: Code Updates (apply after schema verified)

### Update `models.py`

Add new fields to `row_to_model()` with `.get()` for backwards compatibility:

```python
# In row_to_model(), after existing fields:
importance=row.get("importance", 0.5),
expires_at=datetime.fromisoformat(row["expires_at"]) if row.get("expires_at") else None,
version=row.get("version", 1),
session_id=row.get("session_id"),
```

### Update `store.py`

Add new columns to INSERT/REPLACE and SELECT statements:

```python
# In insert() and upsert_batch(), add to VALUES:
superseded_by,
importance,
expires_at,
version,
session_id,

# Add to SELECT in get_all() and get_by_id():
superseded_by, importance, expires_at, version, session_id
```

---

## Rollback Plan

If migration fails:

```sql
-- Rollback: recreate table with old schema (requires backup)
CREATE TABLE memories_old AS SELECT * FROM memories;
DROP TABLE memories;
-- Recreate with v1 schema, repopulate from backup
```

**Note:** With backwards-compatible ALTER TABLE additions, rollback is only needed if code changes corrupt data. The schema additions themselves do not modify existing data.

---

## Post-Migration Tasks

1. Re-run indexer to ensure FTS5 is in sync
2. Test retrieval: `python -m memory_retrieval query "project"`
3. Verify importance-weighted results surface first
4. Update any hardcoded references to v1 schema

---

## Migration Summary

| Step | Action | Time |
|------|--------|------|
| 1 | Run 5 ALTER TABLE commands | 1 min |
| 2 | Run importance auto-assignment script | 30 sec |
| 3 | Verify 87 memories, avg importance ~0.54 | 1 min |
| 4 | Update models.py + store.py | 15 min |
| **Total** | | **~20 minutes** |
