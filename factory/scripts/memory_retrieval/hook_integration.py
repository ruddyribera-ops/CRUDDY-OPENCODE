"""Hook integration for OpenCode — called by the hook system at session start, user prompt, and task start."""
from pathlib import Path
from typing import Optional

from memory_retrieval.retriever import MemoryRetriever

# Stable anchor for DB path
DEFAULT_ROOT = Path(__file__).resolve().parent.parent.parent.parent
DEFAULT_DB = DEFAULT_ROOT / ".opencode" / "memory.db"

# Trigger words that activate memory retrieval on user prompt
TRIGGER_WORDS = frozenset({"remember", "last time", "we did", "previously", "recall"})


def _get_retriever() -> Optional[MemoryRetriever]:
    """Return a retriever if DB exists, else None."""
    if not DEFAULT_DB.exists():
        return None
    try:
        return MemoryRetriever(DEFAULT_DB)
    except Exception:
        return None


def _format_context_block(memories: list[dict]) -> str:
    """Format memories into an HTML comment + markdown block for OpenCode injection."""
    if not memories:
        return ""

    lines = ["<!-- injected by memory-retrieval -->"]
    lines.append("<details>")
    lines.append("<summary>Relevant memories</summary>")
    lines.append("")
    for mem in memories:
        source = Path(mem["source_file"]).name
        lines.append(f"- [{source}] {mem['snippet']}")
    lines.append("</details>")
    return "\n".join(lines)


def _retrieve_memories(query: str, k: int) -> list[dict]:
    """Retrieve memories and format as list of dicts."""
    retriever = _get_retriever()
    if not retriever:
        return []
    try:
        results = retriever.retrieve(query, k=k)
        return [
            {
                "source_file": str(r.memory.source_file),
                "score": round(r.score, 2),
                "snippet": r.memory.content[:200] + "..." if len(r.memory.content) > 200 else r.memory.content,
            }
            for r in results
        ]
    except Exception:
        return []


def on_session_start() -> dict:
    """Return top memories at session start.

    Filters: user_preferences, project_active, plus top-3 most recent.
    """
    retriever = _get_retriever()
    if not retriever:
        return {"memories": [], "context_block": ""}

    # Retrieve by common session-start queries
    queries = ["user preferences settings", "project active current", "recent session"]
    seen_ids: set[str] = set()
    memories: list[dict] = []

    for q in queries:
        for r in retriever.retrieve(q, k=3):
            if r.memory.id not in seen_ids:
                seen_ids.add(r.memory.id)
                memories.append({
                    "source_file": str(r.memory.source_file),
                    "score": round(r.score, 2),
                    "snippet": r.memory.content[:200] + "..." if len(r.memory.content) > 200 else r.memory.content,
                })

    # Top-3 most recent
    try:
        all_memories = retriever.store.get_all()
        all_memories.sort(key=lambda m: m.timestamp, reverse=True)
        for m in all_memories[:3]:
            if m.id not in seen_ids:
                seen_ids.add(m.id)
                memories.append({
                    "source_file": str(m.source_file),
                    "score": 0.0,
                    "snippet": m.content[:200] + "..." if len(m.content) > 200 else m.content,
                })
    except Exception:
        pass

    return {
        "memories": memories[:10],
        "context_block": _format_context_block(memories[:10]),
    }


def on_user_prompt(prompt: str) -> dict:
    """Called when UserPromptSubmit fires.

    If prompt contains trigger words ('remember', 'last time', 'we did',
    'previously', 'recall'), return top-5; else return {}.
    """
    lower = prompt.lower()
    if not any(tw in lower for tw in TRIGGER_WORDS):
        return {"memories": [], "context_block": ""}

    memories = _retrieve_memories(prompt, k=5)
    return {
        "memories": memories,
        "context_block": _format_context_block(memories),
    }


def on_task_start(task_description: str) -> dict:
    """Return top-3 memories matching task description."""
    memories = _retrieve_memories(task_description, k=3)
    return {
        "memories": memories,
        "context_block": _format_context_block(memories),
    }