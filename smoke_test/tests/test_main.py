"""
pytest tests for TODO API.
Follows: testing-standards skill (AAA pattern, descriptive names)
"""
import pytest
from fastapi.testclient import TestClient


@pytest.fixture(autouse=True)
def reset_app_state():
    """Reset in-memory task store before each test."""
    from todo_api import main
    main.tasks.clear()
    yield
    main.tasks.clear()


@pytest.fixture
def client():
    """Fresh TestClient for each test."""
    from todo_api.main import app
    return TestClient(app)


def test_create_task_with_valid_title(client):
    """Should create task and return 201 with task data."""
    response = client.post("/tasks?title=Buy groceries")
    assert response.status_code == 201
    data = response.json()["data"]
    assert data["title"] == "Buy groceries"
    assert data["completed"] is False
    assert "id" in data
    assert "created_at" in data


def test_create_task_with_empty_title_returns_422(client):
    """Should reject empty title with 422."""
    response = client.post("/tasks?title=")
    assert response.status_code == 422


def test_create_task_with_title_too_long_returns_422(client):
    """Should reject title > 200 chars with 422."""
    long_title = "x" * 201
    response = client.post(f"/tasks?title={long_title}")
    assert response.status_code == 422


def test_list_tasks_when_empty(client):
    """Should return empty list with 200."""
    response = client.get("/tasks")
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["tasks"] == []
    assert data["count"] == 0


def test_list_tasks_with_multiple_tasks(client):
    """Should return all created tasks."""
    client.post("/tasks?title=Task 1")
    client.post("/tasks?title=Task 2")
    response = client.get("/tasks")
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["count"] == 2
    assert len(data["tasks"]) == 2


def test_update_task_success(client):
    """Should update task and return 200."""
    create_resp = client.post("/tasks?title=Original")
    task_id = create_resp.json()["data"]["id"]
    response = client.put(f"/tasks/{task_id}?completed=true")
    assert response.status_code == 200
    assert response.json()["data"]["completed"] is True
    assert response.json()["data"]["title"] == "Original"


def test_update_task_title(client):
    """Should update task title."""
    create_resp = client.post("/tasks?title=Original title")
    task_id = create_resp.json()["data"]["id"]
    response = client.put(f"/tasks/{task_id}?title=Updated title")
    assert response.status_code == 200
    assert response.json()["data"]["title"] == "Updated title"


def test_update_nonexistent_task_returns_404(client):
    """Should return 404 when task ID doesn't exist."""
    response = client.put("/tasks/nonexistent-id?completed=true")
    assert response.status_code == 404


def test_delete_task_success(client):
    """Should delete task and return 204."""
    create_resp = client.post("/tasks?title=To delete")
    task_id = create_resp.json()["data"]["id"]
    response = client.delete(f"/tasks/{task_id}")
    assert response.status_code == 204


def test_delete_nonexistent_task_returns_404(client):
    """Should return 404 when deleting non-existent task."""
    response = client.delete("/tasks/nonexistent-id")
    assert response.status_code == 404


def test_create_and_list_integration(client):
    """Full flow: create multiple tasks, verify all returned."""
    for i in range(3):
        client.post(f"/tasks?title=Task number {i}")
    response = client.get("/tasks")
    assert response.status_code == 200
    assert response.json()["data"]["count"] == 3


def test_update_then_delete_flow(client):
    """Complete flow: create, update, verify, delete, verify gone."""
    create_resp = client.post("/tasks?title=Temp task")
    task_id = create_resp.json()["data"]["id"]

    update_resp = client.put(f"/tasks/{task_id}?completed=true")
    assert update_resp.status_code == 200
    assert update_resp.json()["data"]["completed"] is True

    delete_resp = client.delete(f"/tasks/{task_id}")
    assert delete_resp.status_code == 204

    get_resp = client.get("/tasks")
    assert get_resp.json()["data"]["count"] == 0