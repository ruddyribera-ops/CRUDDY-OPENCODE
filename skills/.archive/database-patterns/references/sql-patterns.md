# SQL Patterns & Utilities

## SQLite / sql.js — Table Creation
```javascript
db.run(`CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT UNIQUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)`);
```

## Idempotent Column Migration
```javascript
try { db.run("ALTER TABLE users ADD COLUMN phone TEXT"); }
catch (e) { /* Column already exists — ignore */ }
```

## Seed Data (Only When Empty)
```javascript
const count = db.exec("SELECT COUNT(*) FROM users")[0]?.values[0][0] || 0;
if (count === 0) {
  db.run('INSERT INTO users (name, email) VALUES (?, ?)', ['Admin', 'admin@example.com']);
}
```

## Query Utilities
```javascript
function getAll(sql, params = []) {
  const stmt = db.prepare(sql);
  if (params.length) stmt.bind(params);
  const results = [];
  while (stmt.step()) results.push(stmt.getAsObject());
  stmt.free(); return results;
}
function getOne(sql, params = []) { return getAll(sql, params)[0] || null; }
```

## SQLite ↔ PostgreSQL Type Drift
SQLite is permissive with types; PostgreSQL is strict. Common dev→prod bugs:
- **Booleans:** SQLite accepts 0/1/'true'/'false'/True/False interchangeably. PostgreSQL is strict — `BOOLEAN` rejects integers, `INTEGER` rejects True/False. Fix: declare BOOLEAN in both or always write integers from Python.
- **Dev-vs-prod parity:** Use Docker postgres locally if possible. Write integration tests against PG in CI. Never store Python True/False into INTEGER — cast to `int(bool_value)`. On first PG deploy, run `SELECT column_name, data_type FROM information_schema.columns WHERE table_name='X'`.

## PostgreSQL Bulk Operations

**Bulk Insert with `executemany`:**
```python
conn = psycopg2.connect(os.environ['DATABASE_URL'])
cur = conn.cursor()
cur.executemany("INSERT INTO orders (date, status, customer, amount) VALUES (%s, %s, %s, %s)", data_list)
conn.commit()
```

**Skip duplicates with `ON CONFLICT DO NOTHING`:**
```python
cur.executemany("INSERT INTO products (sku, name, price) VALUES (%s, %s, %s) ON CONFLICT (sku) DO NOTHING", data_list)
```

**JSON Backup & Restore:**
```python
def backup_table(cur, table_name):
    cur.execute(f"SELECT * FROM {table_name}")
    rows = cur.fetchall()
    columns = [desc[0] for desc in cur.description]
    return json.dumps({'columns': columns, 'rows': rows}, default=str)

def restore_table(conn, cur, table_name, json_data):
    data = json.loads(json_data)
    rows = data['rows']
    placeholders = ','.join(['%s'] * len(data['columns']))
    cur.executemany(f"INSERT INTO {table_name} VALUES ({placeholders})", rows)
    conn.commit()
```

## Data Migration Workflow (CRITICAL)
1. CREATE BACKUP first — never skip
2. Verify backup exists with correct row count
3. Inform user: "About to delete X rows and insert Y rows" → wait for confirmation
4. Execute operation
5. Verify: `SELECT COUNT(*) FROM table`
6. Spot-check: `SELECT * FROM table LIMIT 5`

**Backup template:**
```python
def backup_before_import(conn, table_name, backup_dir="backups"):
    cur = conn.cursor(); cur.execute(f"SELECT * FROM {table_name}")
    rows = cur.fetchall(); columns = [desc[0] for desc in cur.description]
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"{backup_dir}/backup_{table_name}_{timestamp}.json"
    with open(filename, 'w') as f: json.dump({'columns': columns, 'rows': rows}, f, default=str)
    print(f"Backup created: {filename} ({len(rows)} rows)"); return filename
```

## Verification Queries
```sql
SELECT COUNT(*) FROM products;
SELECT DISTINCT category FROM products ORDER BY category;
SELECT * FROM products WHERE sku = 'ABC123' LIMIT 5;
SELECT sku, COUNT(*) FROM products GROUP BY sku HAVING COUNT(*) > 1;
```

## PostgreSQL / MySQL Notes
- Use migration tools (knex, prisma, sequelize) for schema changes
- Never ALTER TABLE in production without backup
- Use connection pooling for high traffic
