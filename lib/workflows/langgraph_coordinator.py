"""
LangGraph Coordinator — Advanced Workflow Control for Dev Agency

Provides:
- Conditional routing (test gate, approval gate, retry loop)
- Error recovery (if backend fails → reassign, if tests fail → loop back)
- State machine with typed state
- Human-in-the-loop checkpoints

Usage:
    from langgraph_coordinator import DevWorkflow
    workflow = DevWorkflow()
    app = workflow.compile()
    result = app.invoke({"requirement": "Add login to PRIA"})
"""

from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import MemorySaver
from typing import TypedDict, Annotated
import operator


# ────────────────────────────────────────────────────────────────
# State Definition
# ────────────────────────────────────────────────────────────────

class WorkflowState(TypedDict, total=False):
    """State passed through the Dev Agency workflow graph."""

    requirement: str
    spec: str
    backend_impl: str
    frontend_impl: str
    backend_tests: str
    frontend_tests: str
    qa_report: str
    deployment_status: str
    errors: list[str]
    retry_count: int
    needs_approval: bool
    approvalGranted: bool
    test_results: str  # aggregated test results

    # Parallel task tracking
    parallel_results: dict


# ────────────────────────────────────────────────────────────────
# Node Functions
# ────────────────────────────────────────────────────────────────

def write_spec(state: WorkflowState) -> WorkflowState:
    """Node: PM creates specification."""
    # In production, this calls the PM agent via CrewAI
    spec = f"Spec for: {state.get('requirement', 'unknown')}\n- User stories\n- Acceptance criteria\n- API contract"
    return {**state, "spec": spec}


def implement_backend(state: WorkflowState) -> WorkflowState:
    """Node: Backend dev implements API."""
    # In production, calls backend agent
    impl = f"Backend implementation for spec:\n{state.get('spec', '')}"
    return {**state, "backend_impl": impl}


def implement_frontend(state: WorkflowState) -> WorkflowState:
    """Node: Frontend dev implements UI."""
    # In production, calls frontend agent
    impl = f"Frontend implementation for spec:\n{state.get('spec', '')}"
    return {**state, "frontend_impl": impl}


def run_tests(state: WorkflowState) -> WorkflowState:
    """Node: QA runs tests."""
    # In production, runs pytest/playwright and aggregates results
    tests = f"Test results for backend + frontend"
    return {**state, "qa_report": tests, "test_results": tests}


def deploy(state: WorkflowState) -> WorkflowState:
    """Node: DevOps deploys to Railway."""
    # In production, runs Verify-Deploy.ps1
    status = f"Deployed to Railway. URL: https://example.up.railway.app"
    return {**state, "deployment_status": status}


def approval_gate(state: WorkflowState) -> WorkflowState:
    """Node: Human approval gate — set needs_approval=True to pause for user."""
    return {**state, "needs_approval": False, "approvalGranted": True}


# ────────────────────────────────────────────────────────────────
# Conditional Edge Functions
# ────────────────────────────────────────────────────────────────

def should_deploy(state: WorkflowState) -> str:
    """
    Conditional edge: Can we deploy?
    - If tests passed → deploy
    - If tests failed → retry backend (max 3 retries)
    - If errors → fail
    """
    errors = state.get("errors", [])
    retry_count = state.get("retry_count", 0)

    if errors and retry_count >= 3:
        return "fail"

    test_results = state.get("qa_report", "")
    if "PASSED" in test_results or "pass" in test_results.lower():
        return "deploy"

    if retry_count < 3:
        return "retry_backend"

    return "fail"


def should_retry(state: WorkflowState) -> str:
    """Conditional edge: After retry, re-run tests or fail."""
    retry_count = state.get("retry_count", 0)
    if retry_count >= 3:
        return "fail"
    return "run_tests"


def approval_needed(state: WorkflowState) -> str:
    """Conditional edge: Check if approval gate required."""
    if state.get("needs_approval", False) and not state.get("approvalGranted", False):
        return "wait_for_approval"
    return "deploy"


# ────────────────────────────────────────────────────────────────
# Build Graph
# ────────────────────────────────────────────────────────────────

def build_dev_workflow() -> StateGraph:
    """Build the Dev Agency workflow graph."""

    workflow = StateGraph(WorkflowState)

    # Add nodes
    workflow.add_node("spec", write_spec)
    workflow.add_node("backend", implement_backend)
    workflow.add_node("frontend", implement_frontend)
    workflow.add_node("tests", run_tests)
    workflow.add_node("deploy", deploy)
    workflow.add_node("approval", approval_gate)
    workflow.add_node("retry_backend", implement_backend)  # Reuse backend node
    workflow.add_node("fail", lambda state: state)  # Pass-through fail node

    # Start → spec
    workflow.add_edge(START, "spec")

    # spec → backend AND frontend (parallel)
    workflow.add_edge("spec", "backend")
    workflow.add_edge("spec", "frontend")

    # backend + frontend → tests
    workflow.add_edge("backend", "tests")
    workflow.add_edge("frontend", "tests")

    # tests → conditional (deploy / retry / fail)
    workflow.add_conditional_edges(
        "tests",
        should_deploy,
        {
            "deploy": "approval",
            "retry_backend": "retry_backend",
            "fail": "fail"
        }
    )

    # retry count tracking
    def increment_retry_and_test(state: WorkflowState) -> WorkflowState:
        current = state.get("retry_count", 0)
        return {**state, "retry_count": current + 1}

    workflow.add_node("increment_retry", increment_retry_and_test)
    workflow.add_edge("retry_backend", "increment_retry")
    workflow.add_edge("increment_retry", "tests")

    # approval → deploy (or wait)
    workflow.add_conditional_edges(
        "approval",
        approval_needed,
        {
            "deploy": "deploy",
            "wait_for_approval": END  # Pauses here — resumes when user approves
        }
    )

    # deploy → END
    workflow.add_edge("deploy", END)
    workflow.add_edge("fail", END)

    return workflow


# ────────────────────────────────────────────────────────────────
# Compiled App
# ────────────────────────────────────────────────────────────────

def create_dev_workflow():
    """Create and compile the Dev Agency workflow."""
    graph = build_dev_workflow()

    # MemorySaver enables state persistence across sessions
    checkpointer = MemorySaver()

    return graph.compile(
        checkpointer=checkpointer,
        interrupt_before=["approval"],  # Pause at approval gate
    )


# ────────────────────────────────────────────────────────────────
# Usage Example
# ────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    app = create_dev_workflow()

    # Initial state
    initial_state = {
        "requirement": "Add OAuth login to PRIA",
        "errors": [],
        "retry_count": 0,
        "needs_approval": False,
        "approvalGranted": False,
    }

    # Run workflow
    print("🚀 Starting Dev Agency workflow...")
    result = app.invoke(initial_state)

    print("\n✅ Workflow complete!")
    print(f"   Spec: {result.get('spec', 'N/A')[:50]}...")
    print(f"   Deployment: {result.get('deployment_status', 'N/A')}")
    print(f"   Retries: {result.get('retry_count', 0)}")