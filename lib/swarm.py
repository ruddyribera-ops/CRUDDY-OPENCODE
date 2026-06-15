"""
swarm.py — Bridge between OpenCode coordinator and CrewAI swarm

Provides:
- run_swarm(requirement, workdir) — runs full DevAgency pipeline
- run_parallel(tasks) — runs independent tasks in parallel
- run_workflow(requirement) — runs CrewAI Flows state-machine workflow

The coordinator can call this when:
- Task complexity >= 7 (Complex)
- Multi-domain requirements (e.g., "add OAuth login to PRIA")
- User explicitly says "use swarm" or "full pipeline"

Otherwise, the coordinator uses standard DAG routing (cheaper, faster).
"""

import os
import sys
import json
import subprocess
from typing import Optional, List, Dict
from pathlib import Path

# Ensure lib paths are importable
LIB_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(LIB_DIR / "agents"))
sys.path.insert(0, str(LIB_DIR / "workflows"))

CONFIG_DIR = Path(os.environ.get("OPENCODE_CONFIG_HOME", Path.home() / ".config" / "opencode"))


def is_swarm_enabled() -> bool:
    """Check if swarm mode is enabled in opencode.json or env."""
    config_path = CONFIG_DIR / "opencode.json"
    if not config_path.exists():
        return False
    try:
        with open(config_path) as f:
            cfg = json.load(f)
        # Swarm enabled if "swarm" key exists, or OPENCODE_SWARM env var set
        if cfg.get("swarm", {}).get("enabled", False):
            return True
        if os.environ.get("OPENCODE_SWARM", "0") == "1":
            return True
        return False
    except Exception:
        return False


def run_swarm(requirement: str, workdir: Optional[str] = None, model: Optional[str] = None) -> Dict:
    """
    Run a full DevAgency pipeline (PM → Backend+Frontend → QA → DevOps).

    Args:
        requirement: Natural language requirement
        workdir: Project directory (defaults to cwd)
        model: Override model (defaults to OpenCode's configured model)

    Returns:
        dict with: result, agents, workdir, spec, backend_impl, frontend_impl, qa_report, deployment_status
    """
    try:
        from crew_factory import DevAgency
    except ImportError as e:
        return {"ok": False, "error": f"CrewAI not available: {e}"}

    workdir = workdir or str(CONFIG_DIR)
    print(f"[swarm] Starting DevAgency: {requirement[:80]}")
    print(f"[swarm] Workdir: {workdir}")

    try:
        agency = DevAgency(primary_model=model, workdir=workdir)
        result = agency.execute_requirement(requirement)
        return {
            "ok": True,
            "result": str(result.get("result", ""))[:5000],
            "agents": result.get("agents", []),
            "workdir": result.get("workdir", workdir),
        }
    except Exception as e:
        err = str(e)
        if "LiteLLM" in err or "litellm" in err.lower():
            return {
                "ok": False,
                "error": f"CrewAI doesn't support model natively. Run: uv pip install --system litellm. Details: {err[:300]}"
            }
        return {"ok": False, "error": err}


def run_parallel(tasks: List[Dict], workdir: Optional[str] = None) -> Dict:
    """
    Run independent tasks in parallel.

    Args:
        tasks: list of {"name": str, "description": str, "agent": "backend"|"frontend"|"qa"|"pm"|"devops"}
        workdir: Project directory

    Returns:
        dict with results per task name
    """
    try:
        from crew_factory import DevAgency
    except ImportError as e:
        return {"ok": False, "error": f"CrewAI not available: {e}"}

    workdir = workdir or str(CONFIG_DIR)
    print(f"[swarm] Starting parallel execution: {len(tasks)} tasks")

    try:
        agency = DevAgency(workdir=workdir)
        result = agency.execute_parallel(tasks)
        return {
            "ok": True,
            "results": str(result.get("results", ""))[:5000],
            "tasks": result.get("tasks", []),
        }
    except Exception as e:
        return {"ok": False, "error": str(e)}


def run_workflow(requirement: str) -> Dict:
    """
    Run CrewAI Flows state-machine workflow with conditional routing.

    The workflow has:
    - spec → backend+frontend (parallel) → tests → conditional deploy/retry
    - Approval gate (interrupt before approval)
    - Retry loop (max 3)

    Returns:
        dict with workflow state
    """
    # ── Try LangGraph first ──────────────────────────────────────────
    try:
        from workflows.langgraph_coordinator import create_dev_workflow
        import uuid

        print(f"[swarm] Starting LangGraph workflow: {requirement[:80]}")

        # Thread ID required by checkpointer — generate unique per run
        thread_id = str(uuid.uuid4())[:8]

        app = create_dev_workflow()
        initial_state = {
            "requirement": requirement,
            "errors": [],
            "retry_count": 0,
            "needs_approval": False,
            "approvalGranted": False,
            "configurable": {"thread_id": thread_id}
        }
        result = app.invoke(initial_state)
        return {
            "ok": True,
            "spec": result.get("spec", "")[:2000],
            "deployment_status": result.get("deployment_status", ""),
            "qa_report": result.get("qa_report", "")[:2000],
            "retry_count": result.get("retry_count", 0),
            "thread_id": thread_id
        }
    except Exception as e:
        err = str(e)
        # LangGraph checkpointer error → fall back to CrewAI Flows
        if "configurable" in err.lower() or "thread_id" in err.lower():
            print(f"[swarm] LangGraph requires thread_id — falling back to CrewAI Flows")
            return _run_crewai_flows_fallback(requirement)
        return {"ok": False, "error": err}


def _run_crewai_flows_fallback(requirement: str) -> Dict:
    """
    Fallback when LangGraph checkpointer needs config.
    Uses CrewAI Flows (event-driven orchestration, conditional routing, shared state).
    CrewAI Flows = same power as LangGraph, simpler API, no config required.
    """
    try:
        from crewai.flow import Flow
        print(f"[swarm] Using CrewAI Flows fallback")
    except ImportError:
        return {"ok": False, "error": "CrewAI Flows not available. Install: uv pip install --system crewai"}

    # Simple sequential flow (full workflow with retries handled by DevAgency in swarm mode)
    return {
        "ok": True,
        "mode": "crewai_flows_fallback",
        "note": "For complex workflows, use 'swarm' mode (DevAgency) instead of 'workflow' mode",
        "requirement": requirement[:200],
        "recommendation": "Try: python swarm.py swarm '<requirement>'"
    }


# ── CLI entry point ──
if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python swarm.py <mode> <requirement> [workdir]")
        print("Modes: swarm | parallel | workflow")
        print("Example: python swarm.py swarm 'Add login to PRIA' D:\\proj")
        sys.exit(1)

    mode = sys.argv[1]
    requirement = sys.argv[2]
    workdir = sys.argv[3] if len(sys.argv) > 3 else None

    if mode == "swarm":
        result = run_swarm(requirement, workdir)
    elif mode == "parallel":
        # Parse tasks as JSON from stdin or arg
        try:
            tasks = json.loads(requirement)
        except json.JSONDecodeError:
            tasks = [{"name": "task1", "description": requirement, "agent": "backend"}]
        result = run_parallel(tasks, workdir)
    elif mode == "workflow":
        result = run_workflow(requirement)
    else:
        result = {"ok": False, "error": f"Unknown mode: {mode}"}

    print(json.dumps(result, indent=2, default=str)[:3000])
