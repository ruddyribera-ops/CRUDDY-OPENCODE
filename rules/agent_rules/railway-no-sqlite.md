---
description: No SQLite on Railway — use PostgreSQL
condition: sqlite|\.db\b|sqlite3|aiosqlite
scope: "tool:edit(**/*.{py,ts,js,toml,txt})"
severity: error
triggered_by: SQLite on Railway backend
---

# No SQLite on Railway

Railway filesystem is ephemeral. SQLite data will be lost on restart or deploy. Use PostgreSQL.

## Fix
```python
import psycopg2
conn = psycopg2.connect(os.environ["DATABASE_URL"])
```
