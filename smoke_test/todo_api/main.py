"""
TODO API — FastAPI with in-memory storage.
Follows: api-patterns skill, python-patterns skill
"""
from datetime import datetime, timezone
from typing import Optional
from uuid import uuid4

from fastapi import FastAPI, HTTPException, Query, status
from fastapi.responses import JSONResponse

app = FastAPI(
    title="TODO API",
    version="1.0.0",
    description="Simple TODO API with in-memory storage"
)

# In-memory storage
tasks: dict[str, dict] = {}


def make_response(data: dict, status_code: int = 200) -> JSONResponse:
    """Standard response format with meta."""
    return JSONResponse(
        content={
            "data": data,
            "meta": {"timestamp": datetime.now(timezone.utc).isoformat()}
        },
        status_code=status_code
    )


def make_error(code: str, message: str, field: Optional[str] = None) -> dict:
    """Standard error format."""
    error = {"code": code, "message": message}
    if field:
        error["field"] = field
    return {"error": error}


@app.post("/tasks", status_code=status.HTTP_201_CREATED)
def create_task(title: str = Query(..., min_length=1, max_length=200)):
    """Create a new task."""
    task_id = str(uuid4())
    task = {
        "id": task_id,
        "title": title,
        "completed": False,
        "created_at": datetime.now(timezone.utc).isoformat()
    }
    tasks[task_id] = task
    return make_response(task, status_code=201)


@app.get("/tasks")
def list_tasks() -> JSONResponse:
    """List all tasks."""
    task_list = list(tasks.values())
    return make_response({"tasks": task_list, "count": len(task_list)})


@app.put("/tasks/{task_id}")
def update_task(task_id: str, completed: Optional[bool] = None, title: Optional[str] = None) -> JSONResponse:
    """Update a task by ID."""
    if task_id not in tasks:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=make_error("NOT_FOUND", "Task not found", "task_id")
        )

    task = tasks[task_id]
    if title is not None:
        task["title"] = title
    if completed is not None:
        task["completed"] = completed

    return make_response(task)


@app.delete("/tasks/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_task(task_id: str):
    """Delete a task by ID."""
    if task_id not in tasks:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=make_error("NOT_FOUND", "Task not found", "task_id")
        )
    del tasks[task_id]
    return None