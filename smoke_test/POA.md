# POA — TODO API Smoke Test

## Scope

Build a TODO API as a smoke test for the Phase 4 factory integration.

## Files

- [ ] CREATE smoke_test/SPEC.md — specification document
- [ ] CREATE smoke_test/todo_api/main.py — FastAPI application
- [ ] CREATE smoke_test/requirements.txt — dependencies
- [ ] CREATE smoke_test/tests/test_main.py — pytest test suite

## Commands to Run

1. `pip install -r requirements.txt`
2. `pytest tests/ -v`
3. `python -c "from todo_api.main import app; print('app loads OK')"`

## Success Criteria

- pytest: all 11 tests pass (0 failures)
- app loads without ImportError or syntax errors
- All 4 endpoints respond correctly (POST /tasks, GET /tasks, PUT /tasks/{id}, DELETE /tasks/{id})
- Edge cases handled: empty list, 404 on missing ID, 422 on validation failure

## Verification

Run `pytest tests/ -v` and confirm all pass.

Run `python -c "from todo_api.main import app; print('app loads OK')"` and confirm output.