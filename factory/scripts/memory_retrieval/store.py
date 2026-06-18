"""SQLite store with FTS5 and BLOB vector storage."""
import json
import sqlite3
import struct
from pathlib import Path
from typing import Optional

from .models import MemoryRecord, compute_memory_id


class MemoryStore:
    """SQLite-backed memory store with FTS5 full-text search and vector BLOB storage."""

    def __init__(self, db_path: Path):
        self.db_path = Path(db_path)
        self._ensure_db()

    def _ensure_db(self) -> None:
        """Create tables if they don't exist."""
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        conn = sqlite3.connect(str(self.db_path))
        cursor = conn.cursor()

        # Main memories table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS memories (
                id TEXT PRIMARY KEY,
                content TEXT NOT NULL,
                source_file TEXT NOT NULL,
                timestamp TEXT NOT NULL,
                tags TEXT DEFAULT '[]',
                embedding BLOB,
                links TEXT DEFAULT '[]',
                supersedes TEXT,
                importance REAL DEFAULT 0.5,
                version INTEGER DEFAULT 1,
                superseded_by TEXT
            )
        """)

        # FTS5 virtual table for BM25
        cursor.execute("""
            CREATE VIRTUAL TABLE IF NOT EXISTS memories_fts USING fts5(
                id UNINDEXED,
                content,
                content=memories,
                content_rowid=rowid
            )
        """)

        # FTS5 sync is handled manually in insert() / upsert_batch() / delete()
        # Triggers were removed because INSERT OR REPLACE + content_rowid=rowid
        # causes rowid reuse that breaks the trigger-based sync pattern.

        conn.commit()
        conn.close()

    def insert(self, record: MemoryRecord) -> None:
        """Insert or replace a memory record. Manually syncs FTS5 to avoid rowid reuse bugs."""
        conn = sqlite3.connect(str(self.db_path))
        cursor = conn.cursor()

        # Check if record with this ID already exists (to know if we need to delete old FTS5 entry)
        cursor.execute("SELECT rowid FROM memories WHERE id = ?", (record.id,))
        existing = cursor.fetchone()

        if existing:
            # Delete old FTS5 entry BEFORE the content row changes
            old_rowid = existing[0]
            cursor.execute("DELETE FROM memories_fts WHERE rowid = ?", (old_rowid,))

        # Insert or replace the content row
        cursor.execute("""
            INSERT OR REPLACE INTO memories (id, content, source_file, timestamp, tags, embedding, links, supersedes)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            record.id,
            record.content,
            str(record.source_file),
            record.timestamp.isoformat(),
            json.dumps(record.tags),
            self._embeddings_to_blob(record.embedding),
            json.dumps(record.links),
            record.supersedes,
        ))

        # Get the rowid of the inserted/replaced row
        # For INSERT OR REPLACE, SQLite returns the rowid of the newly inserted row
        new_rowid = cursor.lastrowid

        # Insert new FTS5 entry with explicit rowid matching content table
        cursor.execute(
            "INSERT INTO memories_fts(rowid, id, content) VALUES (?, ?, ?)",
            (new_rowid, record.id, record.content)
        )

        conn.commit()
        conn.close()

    def upsert_batch(self, records: list[MemoryRecord]) -> int:
        """Insert or replace multiple records. Manually syncs FTS5. Returns count."""
        conn = sqlite3.connect(str(self.db_path))
        cursor = conn.cursor()
        count = 0
        for record in records:
            # Check if exists to determine if we need FTS5 delete
            cursor.execute("SELECT rowid FROM memories WHERE id = ?", (record.id,))
            existing = cursor.fetchone()

            if existing:
                old_rowid = existing[0]
                cursor.execute("DELETE FROM memories_fts WHERE rowid = ?", (old_rowid,))

            cursor.execute("""
                INSERT OR REPLACE INTO memories (id, content, source_file, timestamp, tags, embedding, links, supersedes)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                record.id,
                record.content,
                str(record.source_file),
                record.timestamp.isoformat(),
                json.dumps(record.tags),
                self._embeddings_to_blob(record.embedding),
                json.dumps(record.links),
                record.supersedes,
            ))

            new_rowid = cursor.lastrowid
            cursor.execute(
                "INSERT INTO memories_fts(rowid, id, content) VALUES (?, ?, ?)",
                (new_rowid, record.id, record.content)
            )
            count += 1
        conn.commit()
        conn.close()
        return count

    def get_all(self) -> list[MemoryRecord]:
        """Load all memories from the store."""
        conn = sqlite3.connect(str(self.db_path))
        cursor = conn.cursor()
        cursor.execute("SELECT id, content, source_file, timestamp, tags, embedding, links, supersedes, importance, version, superseded_by FROM memories")
        rows = cursor.fetchall()
        conn.close()
        return [self._row_to_model(row) for row in rows]

    def get_by_id(self, memory_id: str) -> Optional[MemoryRecord]:
        """Get a single memory by ID."""
        conn = sqlite3.connect(str(self.db_path))
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id, content, source_file, timestamp, tags, embedding, links, supersedes, importance, version, superseded_by FROM memories WHERE id=?",
            (memory_id,)
        )
        row = cursor.fetchone()
        conn.close()
        return self._row_to_model(row) if row else None

    def delete(self, memory_id: str) -> bool:
        """Delete a memory by ID and its FTS5 entry. Returns True if deleted."""
        conn = sqlite3.connect(str(self.db_path))
        cursor = conn.cursor()

        # Get rowid before deleting content (needed to delete FTS5 entry)
        cursor.execute("SELECT rowid FROM memories WHERE id=?", (memory_id,))
        row = cursor.fetchone()

        if not row:
            conn.close()
            return False

        old_rowid = row[0]

        # Delete content row
        cursor.execute("DELETE FROM memories WHERE id=?", (memory_id,))
        deleted = cursor.rowcount > 0

        # Delete corresponding FTS5 entry
        if deleted:
            cursor.execute("DELETE FROM memories_fts WHERE rowid=?", (old_rowid,))

        conn.commit()
        conn.close()
        return deleted

    def clear(self) -> None:
        """Delete all memories and FTS5 entries."""
        conn = sqlite3.connect(str(self.db_path))
        cursor = conn.cursor()
        cursor.execute("DELETE FROM memories")
        cursor.execute("DELETE FROM memories_fts")
        conn.commit()
        conn.close()

    def fts5_search(self, query: str, top_k: int = 20) -> dict[str, float]:
        """BM25 search via FTS5. Returns dict: memory_id -> bm25_score."""
        conn = sqlite3.connect(str(self.db_path))
        cursor = conn.cursor()
        try:
            cursor.execute(
                "SELECT id, bm25(memories_fts) as score FROM memories_fts WHERE memories_fts MATCH ? ORDER BY score LIMIT ?",
                (query, top_k)
            )
            return {row[0]: abs(row[1]) for row in cursor.fetchall()}
        except sqlite3.OperationalError:
            return {}
        finally:
            conn.close()

    def get_embeddings_matrix(self) -> tuple[list[str], list[list[float]]]:
        """Get all embeddings as (ids, vectors) for cosine computation."""
        conn = sqlite3.connect(str(self.db_path))
        cursor = conn.cursor()
        cursor.execute("SELECT id, embedding FROM memories WHERE embedding IS NOT NULL")
        rows = cursor.fetchall()
        conn.close()
        ids = []
        vectors = []
        for row in rows:
            ids.append(row[0])
            vectors.append(self._blob_to_embeddings(row[1]))
        return ids, vectors

    def _embeddings_to_blob(self, embedding: list[float]) -> bytes:
        """Convert float list to packed bytes for SQLite BLOB storage."""
        return struct.pack(f"{len(embedding)}f", *embedding)

    def _blob_to_embeddings(self, blob: bytes) -> list[float]:
        """Convert packed bytes back to float list."""
        if not blob:
            return []
        num_floats = len(blob) // 4
        return list(struct.unpack(f"{num_floats}f", blob))

    def _row_to_model(self, row: tuple) -> MemoryRecord:
        """Convert a SQLite row to a MemoryRecord."""
        from datetime import datetime
        return MemoryRecord(
            id=row[0],
            content=row[1],
            source_file=Path(row[2]),
            timestamp=datetime.fromisoformat(row[3]),
            tags=json.loads(row[4]) if row[4] else [],
            embedding=self._blob_to_embeddings(row[5]),
            links=json.loads(row[6]) if row[6] else [],
            supersedes=row[7],
            importance=row[8] if len(row) > 8 and row[8] is not None else 0.5,
            version=row[9] if len(row) > 9 and row[9] is not None else 1,
            superseded_by=row[10] if len(row) > 10 else None,
        )


# --- Migration helpers (used by migrate_v2.py) ---

def run_migration(db_path: Path) -> dict:
    """Run Phase 1 migration (idempotent): add importance, version, superseded_by.

    Returns dict with migration stats: count, avg_importance.
    """
    import logging
    logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
    logger = logging.getLogger(__name__)

    conn = sqlite3.connect(str(db_path))
    cursor = conn.cursor()

    # Check if already migrated (column exists)
    cursor.execute("PRAGMA table_info(memories)")
    columns = {row[1] for row in cursor.fetchall()}

    if "importance" in columns and "version" in columns:
        cursor.execute("SELECT COUNT(*), AVG(importance) FROM memories")
        row = cursor.fetchone()
        conn.close()
        logger.info("Migration already applied, skipping")
        return {"count": row[0], "avg_importance": round(row[1] or 0.5, 2)}

    # Add new columns (backwards-compatible: nullable with defaults)
    cursor.execute("ALTER TABLE memories ADD COLUMN importance REAL DEFAULT 0.5")
    cursor.execute("ALTER TABLE memories ADD COLUMN version INTEGER DEFAULT 1")
    cursor.execute("ALTER TABLE memories ADD COLUMN superseded_by TEXT")
    logger.info("Added columns: importance, version, superseded_by")

    # Pattern-based importance auto-assignment
    patterns = [
        ("user_preferences", 1.0),
        ("project_active", 0.9),
        ("session_log", 0.7),
        ("research_factory", 0.6),
        ("research_poa", 0.5),
        ("reference", 0.4),
        ("skill_", 0.5),
        ("poa_", 0.4),
        ("TRIGGERS", 0.6),
    ]

    for pattern, score in patterns:
        cursor.execute(
            "UPDATE memories SET importance = ? WHERE source_file LIKE ? AND importance = 0.5",
            (score, f"%{pattern}%")
        )

    cursor.execute("SELECT COUNT(*), AVG(importance) FROM memories")
    row = cursor.fetchone()
    count, avg = row
    logger.info(f"Migrated {count} memories, avg importance {round(avg or 0.5, 2)}")

    conn.commit()
    conn.close()

    return {"count": count, "avg_importance": round(avg or 0.5, 2)}
