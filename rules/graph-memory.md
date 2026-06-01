# Graph Memory — Context Graph Architecture

**Purpose:** Decision framework for agent routing and memory retrieval
using JSON-LD file-based graph storage.

## Schema

### Node Types
| Type | Created By | Example |
|------|-----------|---------|
| `session` | T1 (session start) | Session-2026-06-01-feat-auth |
| `task` | T2 (task complete) | Task-42-refactor-db |
| `decision` | T6 (decision made) | Decision-choose-sqlite-over-neo4j |
| `lesson` | T5 (lesson discovered) | Lesson-no-mutable-defaults |
| `project` | T1 (on project load) | Project-opencode-config |

### Edge Types
| Type | Direction | Meaning |
|------|-----------|---------|
| `touches` | Session → Project | Session worked on project |
| `makes` | Session → Decision | Session made this decision |
| `discovers` | Session → Lesson | Session learned this |
| `completes` | Session → Task | Session finished this task |
| `triggers` | Decision → Gene | Decision triggered a gene |

## Query Patterns

### Before routing (Moderate+ tasks):
```
Query: "relevant decisions about {domain} from last 7 days"
Query: "lessons matching {task keywords}"
Query: "blockers in {project}"
```

### Before session start (T1):
```
Query: "most recent session for {project}"
Query: "open decisions affecting {project}"
```

## File Structure
- `memory/graph/nodes/` — one JSON-LD file per node
- `memory/graph/edges/` — one JSON-LD file per edge
- `memory/graph/schema.yaml` — full schema definition
- Files named: `{type}-{timestamp}-{shortid}.jsonld`

## When NOT to Consult Graph
- Trivial tasks (score 0)
- User explicitly said "don't check history"
- Graph engine not installed (scripts/graph-memory.js missing)
