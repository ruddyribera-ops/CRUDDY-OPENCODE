"""
Dev Agency Agent Factory — OpenCode Integration
CrewAI-based multi-agent team for Ruddy's EdTech projects

Usage:
    from crew_factory import DevAgency
    agency = DevAgency()
    result = agency.execute_requirement("Add login to PRIA")

Note: Model defaults to user's configured OpenCode model (minimax/minimax-m2.7)
"""

import os
import json
import subprocess
from crewai import Agent, Crew, Task, Process
from crewai.tools import BaseTool
from typing import Optional


# ────────────────────────────────────────────────────────────────
# Model Config — read from OpenCode's config to use the same model
# ────────────────────────────────────────────────────────────────
def _get_opencode_model() -> str:
    """Read the model from OpenCode's config to keep the crew aligned."""
    try:
        config_path = os.path.expanduser("~/.config/opencode/opencode.json")
        with open(config_path) as f:
            cfg = json.load(f)
        model = cfg.get("model", "minimax/minimax-m2.7")
        return model
    except Exception:
        return "minimax/minimax-m2.7"


def _build_llm(model: str):
    """Build a CrewAI LLM object. Handles custom OpenAI-compatible providers
    like 'minimax' that aren't in CrewAI's native provider list.

    For known providers (openai, anthropic, etc.), returns the model string.
    For unknown providers, uses openai-compatible with custom base_url.
    """
    from crewai import LLM

    KNOWN_PROVIDERS = {
        "openai", "anthropic", "claude", "azure", "azure_openai",
        "google", "gemini", "bedrock", "aws", "openrouter",
        "deepseek", "ollama", "ollama_chat", "hosted_vllm",
        "cerebras", "dashscope"
    }

    if "/" in model:
        provider, model_name = model.split("/", 1)
        if provider in KNOWN_PROVIDERS:
            return model  # CrewAI handles natively

        # Custom OpenAI-compatible provider (e.g. minimax)
        if provider == "minimax":
            # MINIMAX_API_HOST is the bare host (e.g. https://api.minimax.io)
            # OpenAI client appends /chat/completions — need /v1 prefix
            api_host = os.environ.get("MINIMAX_API_HOST", "https://api.minimax.io")
            # Ensure /v1 suffix — OpenAI-compatible APIs need this
            if not api_host.rstrip("/").endswith("/v1"):
                api_host = api_host.rstrip("/") + "/v1"
            api_key = os.environ.get("MINIMAX_API_KEY", "")
            return LLM(
                model=model_name,
                provider="openai",
                base_url=api_host,
                api_key=api_key
            )

    # Fallback: just pass the model string and let CrewAI decide
    return model


# ────────────────────────────────────────────────────────────────
# Tool Wrappers (CrewAI compatible)
# ────────────────────────────────────────────────────────────────

class OpenCodeRunTool(BaseTool):
    """Run a one-shot OpenCode command and return result."""
    name: str = "opencode_run"
    description: str = "Execute OpenCode CLI for a one-shot coding task. Use for: add feature, fix bug, refactor, create file, run tests. Returns stdout/stderr."

    def _run(self, task: str, workdir: Optional[str] = None, model: Optional[str] = None) -> str:
        workdir = workdir or os.getcwd()
        model = model or _get_opencode_model()
        # Windows: opencode is a .ps1/.cmd shim, not a binary.
        # Use cmd.exe wrapper so subprocess can find it.
        try:
            cmd_parts = ["opencode.cmd", "run", task]
            if model:
                cmd_parts.extend(["--model", model])
            result = subprocess.run(
                cmd_parts,
                capture_output=True, text=True, timeout=300, cwd=workdir,
                shell=True  # Windows needs shell to resolve .cmd
            )
            return f"[OPENCODE] Exit {result.returncode}\nSTDOUT:\n{result.stdout[:2000]}\nSTDERR:\n{result.stderr[:500]}"
        except subprocess.TimeoutExpired:
            return f"[OPENCODE] TIMEOUT after 300s for task: {task[:100]}"
        except FileNotFoundError:
            return "[OPENCODE] ERROR: opencode CLI not found in PATH"
        except Exception as e:
            return f"[OPENCODE] ERROR: {e}"


class OpenCodeSessionTool(BaseTool):
    """Start an interactive OpenCode background session."""
    name: str = "opencode_session"
    description: str = "Start an OpenCode interactive TUI session in background. Use for multi-turn tasks needing iteration. Returns session_id."

    def _run(self, task: str, workdir: Optional[str] = None) -> str:
        # Sessions are not supported in this Windows env — return guidance
        return f"[OPENCODE] Interactive session not available in Windows env. Use opencode_run for: {task[:80]}"


# ────────────────────────────────────────────────────────────────
# Agent Factory
# ────────────────────────────────────────────────────────────────

class DevAgency:
    """
    Multi-agent Dev Agency for Ruddy's projects.
    
    Agents:
        - pm: Product Manager — breaks down requirements
        - backend: Backend dev — FastAPI, Node.js, PostgreSQL
        - frontend: Frontend dev — React, Streamlit, Next.js
        - qa: QA Engineer — testing, edge cases
        - devops: DevOps — Railway deploy, Docker
        - coordinator: Orchestrator — delegates, tracks
    """

    def __init__(
        self,
        primary_model: Optional[str] = None,
        fallback_model: str = "groq/llama-3.3-70b-versatile",
        workdir: Optional[str] = None
    ):
        # Use OpenCode's configured model by default
        self.primary = primary_model or _get_opencode_model()
        self.fallback = fallback_model
        self.workdir = workdir or os.getcwd()
        self.agents = {}
        self.tools = {
            "opencode_run": OpenCodeRunTool(),
            "opencode_session": OpenCodeSessionTool(),
        }
        self._setup_agents()

    def _resolve_model(self, model: str) -> str:
        """Resolve a model string to one CrewAI supports natively.

        For unsupported providers (e.g. 'minimax/minimax-m2.7'), we attempt
        to fall back to openai-compatible mode with the underlying URL.
        """
        if "/" in model:
            provider = model.split("/", 1)[0]
            known = {"openai", "anthropic", "claude", "azure", "azure_openai",
                     "google", "gemini", "bedrock", "aws", "openrouter",
                     "deepseek", "ollama", "ollama_chat", "hosted_vllm",
                     "cerebras", "dashscope"}
            if provider in known:
                return model
        return model

    def _setup_agents(self):
        """Initialize all 6 agents using modern CrewAI LLM format."""

        # ── Product Manager ──────────────────────────────────
        self.agents["pm"] = Agent(
            role="Product Manager",
            goal="Transform requirements into detailed specifications and user stories",
            backstory=(
                "Expert PM with 15 years experience in EdTech. "
                "Breaks down complex requirements into actionable tasks. "
                "Always considers neuro-inclusive design and K-12 pedagogy. "
                "Works with Ruddy's 7 active projects: PRIA, Palma Coin, Math Platform, EduFlow, BDM App."
            ),
            tools=list(self.tools.values()),
            verbose=True,
            allow_delegation=False,
            llm=_build_llm(self.primary),
            temperature=0.3
        )

        # ── Backend Developer ─────────────────────────────────
        self.agents["backend"] = Agent(
            role="Backend Developer",
            goal="Implement robust, scalable server-side logic and APIs",
            backstory=(
                "Senior backend engineer. Expertise: Python (FastAPI, Streamlit, SQLAlchemy async), "
                "Node.js (Express, pg), PostgreSQL, Redis, Docker Compose, Railway deployment. "
                "Knows Ruddy's patterns: ephemeral fs on Railway, WebSocket TCP proxy config, "
                "ON CONFLICT DO NOTHING for seeds, RETURNING * not last_insert_rowid()."
            ),
            tools=list(self.tools.values()),
            verbose=True,
            allow_delegation=False,
            llm=_build_llm(self.primary),
            temperature=0.1
        )

        # ── Frontend Developer ─────────────────────────────────
        self.agents["frontend"] = Agent(
            role="Frontend Developer",
            goal="Build responsive, accessible user interfaces",
            backstory=(
                "Expert frontend engineer. Expertise: React 19, Vite, Next.js 14, "
                "Streamlit, TailwindCSS, TypeScript, shadcn/ui, Framer Motion. "
                "Knows Ruddy's design principles: neuro-inclusive, clear visual scaffolding, "
                "gamification for classroom use."
            ),
            tools=list(self.tools.values()),
            verbose=True,
            allow_delegation=False,
            llm=_build_llm(self.primary),
            temperature=0.1
        )

        # ── QA Engineer ────────────────────────────────────────
        self.agents["qa"] = Agent(
            role="QA Engineer",
            goal="Ensure quality through comprehensive testing and validation",
            backstory=(
                "Meticulous QA engineer focused on edge cases, performance, and security. "
                "Expert in pytest, Vitest, Playwright E2E, security scanning (OWASP Top 10). "
                "Always tests the empty input case — agents forget to handle it. "
                "Verifies against acceptance criteria before declaring done."
            ),
            tools=list(self.tools.values()),
            verbose=True,
            allow_delegation=False,
            llm=_build_llm(self.primary),
            temperature=0.2
        )

        # ── DevOps Engineer ────────────────────────────────────
        self.agents["devops"] = Agent(
            role="DevOps Engineer",
            goal="Deploy reliably to Railway, manage infrastructure, optimize performance",
            backstory=(
                "DevOps expert. Expertise: Railway (postgresql plugin, TCP proxy for WebSocket), "
                "Docker, Docker Compose, GitHub Actions CI/CD, PostgreSQL, Redis. "
                "Knows: pink 404 = container not serving, check railway logs. "
                "Always runs Verify-Deploy.ps1 before declaring deploy done."
            ),
            tools=list(self.tools.values()),
            verbose=True,
            allow_delegation=False,
            llm=_build_llm(self.primary),
            temperature=0.1
        )

        # ── Coordinator ────────────────────────────────────────
        self.agents["coordinator"] = Agent(
            role="Project Coordinator",
            goal="Orchestrate team, delegate tasks, track progress, unblock issues",
            backstory=(
                "Experienced coordinator. Manages dependencies between agents. "
                "Detects when agents should run in parallel vs. sequential. "
                "Escalates blockers to user in one sentence. "
                "Tracks token budget per agent. "
                "Speaks Spanish-first for Ruddy."
            ),
            tools=list(self.tools.values()),
            verbose=True,
            allow_delegation=True,
            llm=_build_llm(self.primary),
            temperature=0.2
        )

    def execute_requirement(self, requirement: str) -> dict:
        """
        Execute a full requirement through the Dev Agency pipeline.
        
        Pipeline:
            1. PM creates specification
            2. Backend + Frontend implement in parallel
            3. QA validates
            4. DevOps deploys
        
        Args:
            requirement: Natural language requirement (e.g., "Add OAuth login to PRIA")
        
        Returns:
            dict with keys: spec, backend_impl, frontend_impl, tests, deployment_status
        """

        # Task 1: PM creates specification
        task_spec = Task(
            description=f"Create detailed specification for: {requirement}\n\n"
                        "Include: user stories, acceptance criteria, API contract, "
                        "database schema changes if any, edge cases to handle.",
            agent=self.agents["pm"],
            expected_output=(
                "Complete spec with: user stories (Given/When/Then format), "
                "acceptance criteria (numbered), API endpoints (method + path + body), "
                "DB schema changes, error handling approach."
            )
        )

        # Task 2: Backend implements API
        task_backend = Task(
            description=f"Implement backend for feature spec.\n\n"
                        f"Project context: {self.workdir}\n"
                        "Use FastAPI for Python projects, Express for Node.js. "
                        "Always: parameterized SQL, bcrypt passwords, ON CONFLICT DO NOTHING seeds. "
                        "PostgreSQL: RETURNING * not last_insert_rowid().",
            agent=self.agents["backend"],
            expected_output="Working API endpoints with docstring, routes, models, migrations.",
            context=[task_spec]
        )

        # Task 3: Frontend implements UI (parallel with backend)
        task_frontend = Task(
            description=f"Implement frontend for feature spec.\n\n"
                        f"Project context: {self.workdir}\n"
                        "Use React 19 + Vite + TypeScript for new projects. "
                        "Streamlit for Python-heavy projects. "
                        "Always: responsive mobile-first, accessibility (a11y).",
            agent=self.agents["frontend"],
            expected_output="Working UI components with integration to backend API.",
            context=[task_spec]
        )

        # Task 4: QA validates
        task_qa = Task(
            description=f"Test all acceptance criteria and edge cases.\n\n"
                        f"Project context: {self.workdir}\n"
                        "Write tests BEFORE declaring fix done. "
                        "Edge case to always test: empty input. "
                        "Security: check for SQL injection, XSS, auth bypass.",
            agent=self.agents["qa"],
            expected_output="Test report with coverage metrics, list of edge cases tested, "
                           "any bugs found (with severity).",
            context=[task_spec, task_backend, task_frontend]
        )

        # Task 5: DevOps deploys
        task_devops = Task(
            description=f"Deploy to Railway and verify.\n\n"
                        f"Project context: {self.workdir}\n"
                        "1. Run Verify-Deploy.ps1 — MUST exit 0 before declaring done. "
                        "2. Check railway logs if pink 404. "
                        "3. Verify seed-on-startup ran (fresh deploy = empty DB otherwise). "
                        "4. Test WebSocket connectivity if applicable.",
            agent=self.agents["devops"],
            expected_output="Deployment confirmation with Railway URL, verification results.",
            context=[task_spec, task_backend, task_frontend, task_qa]
        )

        # Build crew with sequential pipeline
        crew = Crew(
            agents=list(self.agents.values()),
            tasks=[task_spec, task_backend, task_frontend, task_qa, task_devops],
            process=Process.sequential,  # PM → Backend+Frontend (in parallel) → QA → DevOps
            verbose=True,
        )

        result = crew.kickoff()
        return {
            "result": result,
            "agents": list(self.agents.keys()),
            "workdir": self.workdir,
        }

    def execute_parallel(self, tasks: list[dict]) -> dict:
        """
        Execute multiple independent tasks in parallel using worktrees.
        
        Args:
            tasks: list of {"name": str, "description": str, "agent": "backend"|"frontend"|"qa"}
        
        Returns:
            dict of results per task name
        """
        crew_tasks = []
        for t in tasks:
            agent = self.agents.get(t["agent"], self.agents["backend"])
            crew_task = Task(
                description=t["description"],
                agent=agent,
                expected_output=f"Completed: {t['name']}"
            )
            crew_tasks.append(crew_task)

        crew = Crew(
            agents=[self.agents["coordinator"]],
            tasks=crew_tasks,
            process=Process.hierarchical,  # Coordinator delegates to each
            verbose=True,
        )

        result = crew.kickoff()
        return {"results": result, "tasks": [t["name"] for t in tasks]}


# ────────────────────────────────────────────────────────────────
# CLI Entry Point
# ────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: python crew_factory.py '<requirement>'")
        print("Example: python crew_factory.py 'Add dark mode to PRIA'")
        sys.exit(1)

    requirement = sys.argv[1]
    workdir = sys.argv[2] if len(sys.argv) > 2 else os.getcwd()

    print(f"🚀 Dev Agency — Starting requirement: {requirement}")
    print(f"   Workdir: {workdir}")

    agency = DevAgency(workdir=workdir)
    result = agency.execute_requirement(requirement)

    print("\n✅ Dev Agency complete!")
    print(f"   Result: {result['result']}")
