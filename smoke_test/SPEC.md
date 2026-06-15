# TODO API — Specification

## Functionality

Simple TODO API with in-memory storage.

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/tasks` | Create a new task |
| GET | `/tasks` | List all tasks |
| PUT | `/tasks/{id}` | Update a task by ID |
| DELETE | `/tasks/{id}` | Delete a task by ID |

### Task Model

```json
{
  "id": "string (UUID)",
  "title": "string (required, 1-200 chars)",
  "completed": "boolean (default: false)",
  "created_at": "ISO8601 timestamp"
}
```

### Response Format

**Success:**
```json
{
  "data": { ... },
  "meta": { "timestamp": "..." }
}
```

**Error:**
```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "Task not found",
    "field": "id"
  }
}
```

### HTTP Status Codes

- 200 OK — GET, PUT (success)
- 201 Created — POST (task created)
- 204 No Content — DELETE (success)
- 400 Bad Request — invalid input
- 404 Not Found — task ID doesn't exist
- 422 Unprocessable Entity — validation failed

### Validation Rules

- `title` is required, 1-200 characters
- `id` must be a valid UUID for PUT/DELETE
- `completed` must be boolean if provided

### Edge Cases

1. GET /tasks when empty → return empty list with 200
2. PUT /tasks/{id} with non-existent ID → 404
3. DELETE /tasks/{id} with non-existent ID → 404
4. POST with empty title → 400
5. POST with title > 200 chars → 422

---

## Tech Stack

- Python 3.11
- FastAPI
- In-memory storage (dict, no external DB)
- pytest for tests

## Success Criteria

- All 4 endpoints functional
- All edge cases handled with correct status codes
- pytest tests pass (all pass, 0 failures)
- Lint: flake8 passes (if configured)
- Build: FastAPI starts without error