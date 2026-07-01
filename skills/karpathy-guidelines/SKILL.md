---
name: karpathy-guidelines
description: "Andrej Karpathy's software engineering principles — augmented LLM, simple patterns first, focused evaluation, transparency in agent reasoning. Use when designing agentic systems or making architectural decisions. Triggers: Karpathy, augmented LLM, agent design, simple first, transparent reasoning, intern model, jagged intelligence."
---

# Karpathy Guidelines

## When to use this

Load this skill when designing agentic AI systems, making architectural decisions about how to use LLMs, choosing between simple and complex patterns, or debugging unexpected AI behavior. This skill grounds AI engineering in practical software craftsmanship.

---

## Core Principles

1. **Augmented LLMs are the basic building block** — The foundation of AI engineering is combining an LLM with retrieval (context), tools (actions), and memory (state). Do not think of the LLM as an isolated component.

2. **Simple patterns first (Anthropic canonical)** — The progression is: single LLM call → prompt chaining → routing → parallelization → orchestrator-workers → evaluator-optimizer → agents. Do not jump to agents when a single call suffices.

3. **Treat AI agents as brilliant interns** — An intern can execute complex tasks correctly but their judgment needs oversight. They will confidently produce wrong answers. You must verify their work.

4. **Jagged intelligence is real** — AI is superhuman in some domains (code synthesis, pattern matching) and surprisingly dumb in others (simple math, counting, spatial reasoning). Verify the simple things the model should "obviously" know.

5. **Software 3.0: not everything needs code** — Sometimes a well-crafted prompt + neural net replaces a traditional program. When the problem is ambiguous, fuzzy, or rule-heavy, consider if a prompt is the right solution.

6. **Outsource thinking, not understanding** — You can offload the execution of a known process to an LLM. You cannot offload understanding of a domain you yourself do not understand.

7. **Transparency in agent reasoning** — When an agent makes a decision, the reasoning should be visible (in logs, in outputs, in traces). Opaque chains of reasoning make debugging impossible.

---

## Patterns

### Pattern Progression (Simple to Complex)

```
Level 1: Single LLM Call
  - One prompt in, one response out
  - Use for: classification, extraction, transformation

Level 2: Prompt Chaining
  - Output of one LLM call is input to the next
  - Use for: first draft → revision → final polish

Level 3: Routing
  - Classify input, dispatch to specialized handler
  - Use for: different types of requests need different prompts

Level 4: Parallelization
  - Same input to multiple LLMs, aggregate responses
  - Use for: synthesis from multiple sources, redundancy

Level 5: Orchestrator-Workers
  - Central LLM decomposes task, dispatches to workers, synthesizes
  - Use for: complex tasks with multiple sub-problems

Level 6: Evaluator-Optimizer
  - LLM generates response, another LLM evaluates and critiques, iterate
  - Use for: code review, writing refinement, adversarial testing

Level 7: Agents
  - LLM drives its own tool use and sub-task progression
  - Use for: open-ended goals where the path is unknown
```

### Augmented LLM: The Four Components

```python
from dataclasses import dataclass, field
from typing import Optional
import json

@dataclass
class AugmentedLLM:
    """
    The four building blocks of an augmented LLM system.
    """
    # 1. Base model (the LLM itself)
    model: str = "gpt-4o"

    # 2. Retrieval: context injected into each prompt
    context: list[str] = field(default_factory=list)

    # 3. Tools: actions the LLM can invoke
    tools: list[dict] = field(default_factory=list)

    # 4. Memory: conversation history and state
    memory: list[dict] = field(default_factory=list)

    def prompt(self, user_message: str) -> str:
        """
        Build the augmented prompt:
        1. System prompt with role and instructions
        2. Retrieved context documents
        3. Conversation history
        4. Current user message
        """
        parts = []

        # System + context
        if self.context:
            parts.append(f"=== CONTEXT ===\n" + "\n".join(self.context))

        # Memory (last N turns)
        if self.memory:
            history = "\n".join(
                f"{m['role']}: {m['content']}"
                for m in self.memory[-10:]
            )
            parts.append(f"=== HISTORY ===\n{history}")

        # Current message
        parts.append(f"=== USER ===\n{user_message}")

        return "\n\n".join(parts)

    def call(self, user_message: str, tools: bool = False) -> dict:
        """
        Execute the augmented LLM call.
        In production, this calls the actual API.
        """
        prompt = self.prompt(user_message)
        # API call here...
        return {"response": "...", "tool_calls": []}
```

### The Intern Model: Verification Pattern

```python
"""
Treat every LLM output as if it came from a brilliant but unverified intern.
Always verify before committing to irreversible actions.
"""

async def execute_with_verification(task: str, llm: AugmentedLLM) -> dict:
    """
    LLM generates a plan, a separate verifier checks it,
    execution only proceeds if verification passes.
    """
    # Step 1: Generate
    plan = llm.call(
        f"""You are a software engineer. Create a plan for this task:
        {task}

        Break it into numbered steps. For each step, specify:
        - What file to modify
        - What the change is
        - What could go wrong (risks)
        """
    )

    # Step 2: Verify (a different LLM or a rule-based check)
    verification = llm.call(
        f"""Review this plan for safety and correctness:
        {plan}

        Check for:
        - Destructive operations (deletes, drops)
        - Security vulnerabilities
        - Breaking changes to existing APIs
        - Data loss risks

        Respond: APPROVED, REJECTED, or NEEDS_CHANGES
        """
    )

    if "REJECTED" in verification:
        raise SafetyError(f"Plan rejected: {verification}")

    if "NEEDS_CHANGES" in verification:
        # Re-generate with feedback
        plan = llm.call(f"Revise this plan based on feedback: {verification}\n\nOriginal: {plan}")

    return plan
```

### Jagged Intelligence: Guardrails for Simple Things

```python
"""
Jagged intelligence: AI is great at complex synthesis but can fail at simple things.
Verify the simple things that should be obvious.
"""

def verify_simple_math(expression: str) -> float:
    """
    AI can confidently give wrong answers to "simple" math.
    Always verify arithmetic with a calculator, not an LLM.
    """
    import ast
    import operator

    # Parse and evaluate mathematically — not via LLM
    ops = {'+': operator.add, '-': operator.sub, '*': operator.mul, '/': operator.truediv}
    try:
        # Safely parse a simple math expression (whitelist allowed chars)
        allowed = set('0123456789+-*/(). ')
        if set(expression) - allowed:
            raise ValueError("Invalid characters")
        return eval(expression)  # In production, use a safe evaluator
    except Exception:
        # Fall back to LLM only if parsing fails
        return llm.call(f"Calculate: {expression}")

def verify_count(items: list) -> int:
    """
    AI can miscount. For critical counts, always verify programmatically.
    """
    return len(items)  # Don't ask LLM to count a list
```

### Software 3.0: When to Use a Prompt Instead of Code

```python
"""
Software 3.0: Some problems are better solved with prompts than programs.
Use this decision framework:
"""

def should_use_llm(problem_type: str) -> bool:
    """
    Heuristics for when to reach for an LLM vs traditional code.
    """
    llm_better = [
        "classify with nuanced categories",      # Fuzzy categorization
        "extract from unstructured text",       # Information extraction
        "rewrite in a different style",         # Transformation with judgment
        "answer questions from context",        # QA over documents
        "generate code from natural language",  # Synthesis
        "detect sentiment or intent",            # Fuzzy classification
    ]
    code_better = [
        "exact calculation (use math)",
        "deterministic transformation (use regex)",
        "enforcing strict format (use parser)",
        "high-performance computation (use C)",
        "enforcing business rules (use validation)",
    ]
    # When in doubt, start with code. Add LLM only when code proves insufficient.
```

### Transparent Reasoning: Structured Output with Thought Process

```python
"""
For important decisions, the LLM should output structured reasoning
so that humans (and other systems) can audit the chain of thought.
"""

def decision_with_rationale(task: str, llm: AugmentedLLM) -> dict:
    """
    Request structured output with explicit reasoning.
    """
    response = llm.call(
        f"""Task: {task}

        Respond with this JSON structure:
        {{
            "decision": "What you decided to do",
            "reasoning": [
                "Step 1: What you considered first...",
                "Step 2: What you considered next...",
                "Step 3: What you concluded..."
            ],
            "confidence": "high|medium|low",
            "risks": ["Risk 1", "Risk 2"],
            "alternatives_considered": ["Alt 1", "Alt 2"]
        }}
        """
    )
    return json.loads(response)


# Example output:
# {
#   "decision": "Rewrite the query function to use indexed columns",
#   "reasoning": [
#     "Step 1: Profile showed N+1 queries on the posts endpoint",
#     "Step 2: SQLAlchemy was using lazy loading for the user relationship",
#     "Step 3: Adding joinedload(User) to the query eliminates the N+1",
#     "Step 4: No change to the API contract or response format"
#   ],
#   "confidence": "high",
#   "risks": ["Slight increase in memory for large result sets"],
#   "alternatives_considered": ["Add Redis cache (overkill for this endpoint)"]
# }
```

### Evaluator-Optimizer: Two-Agent Pattern

```python
"""
Evaluator-Optimizer: One agent generates, another evaluates and provides feedback.
Iterate until the evaluator approves or max iterations reached.
"""

async def evaluate_optimizer_loop(
    initial_prompt: str,
    max_iterations: int = 3
) -> str:
    generator = AugmentedLLM(model="gpt-4o")  # Generates solutions
    evaluator = AugmentedLLM(model="gpt-4o")  # Evaluates and critiques

    current_output = generator.call(initial_prompt)

    for i in range(max_iterations):
        feedback = evaluator.call(
            f"""Evaluate this output for quality, correctness, and completeness:

            Output:
            {current_output}

            Original task:
            {initial_prompt}

            Provide specific, actionable feedback. If the output is good,
            say "APPROVED". Otherwise, explain what needs to be fixed.
            """
        )

        if "APPROVED" in feedback:
            return current_output

        # Regenerate with feedback
        current_output = generator.call(
            f"Original task: {initial_prompt}\n\nFeedback: {feedback}\n\n"
            "Rewrite the output addressing all feedback."
        )

    return current_output
```

---

## Anti-Patterns

- **Jumping to agents when a single LLM call suffices** — The most common AI engineering mistake. If the task is classification, extraction, or simple transformation, a single prompt is faster, cheaper, and more reliable than a multi-agent system.

- **Opaque reasoning chains** — When an agent makes a decision, if you cannot trace why it made that choice, you cannot debug when it goes wrong. Always log the agent's reasoning.

- **Treating AI as a magic box** — AI can fail in surprising ways. The "jagged intelligence" problem means AI can be confidently wrong about simple things. Always verify critical outputs.

- **No verification of AI-generated code** — AI-generated code can have security vulnerabilities, logical errors, and subtle bugs. Code review and tests are not optional for AI-generated code.

- **Over-reliance on AI for domain knowledge you lack** — You can outsource execution to an LLM, but not understanding. If you do not understand the domain, you cannot verify the AI's output.

- **Ignoring cost and latency at scale** — A single LLM call is fast and cheap. A multi-agent system with 10 turns and 5 agents per turn is expensive and slow. Always measure at scale.

---

## Quick Reference

| Pattern Level | When to Use | Example |
|-------------|-------------|---------|
| Single LLM call | Classification, extraction, simple transform | "Is this email spam?" |
| Prompt chaining | Multi-step refinement | Draft → edit → final |
| Routing | Different inputs need different prompts | Intent classification |
| Parallelization | Multiple perspectives, redundancy | User support triage |
| Orchestrator-workers | Complex task with sub-problems | Bug fix: find file → analyze → fix |
| Evaluator-optimizer | Code review, writing, adversarial | Code generation → critique → regenerate |
| Agents | Open-ended goals, unknown path | Research agent |

### Karpathy's Software Engineering Principles (Summary)

```
1. Build incrementally — don't over-engineer upfront
2. Simple patterns first — only add complexity when needed
3. Verify everything — AI outputs need human oversight
4. Be transparent — log reasoning, make decisions auditable
5. Jagged intelligence — verify simple things the AI should know
6. Outsourcing thinking vs. understanding — you can't verify what you don't understand
7. Software 3.0 — consider prompts for fuzzy problems, code for deterministic ones
```
