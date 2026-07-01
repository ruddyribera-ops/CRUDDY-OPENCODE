---
name: tracing
description: "Distributed tracing for AI agent systems — nested spans, agent-to-tool-call hierarchy, MCP integration, failure attribution. Use when debugging multi-step agent failures or building observability. Triggers: trace, span, agent invocation, tool call, MCP, distributed tracing, latency, debug."
---

# Distributed Tracing Skill

Distributed tracing is the practice of tracking a request as it flows through multiple agents, sub-tasks, and tool calls. It is essential for debugging failures in multi-step AI workflows where a user request spawns dozens of sub-agent dispatches.

## Core Model: Spans

A **span** is the fundamental unit of a trace. It represents a single unit of work with a start time, duration, and metadata.

```
Span {
  trace_id:        string   // Unique ID linking all spans in one end-to-end request
  parent_id:       string|null  // ID of the parent span (null for root)
  span_id:         string   // Unique ID for this span
  name:            string   // Human-readable: "code-builder.write" / "bug-fixer.debug"
  service:         string   // Which agent or system handled this
  start_ms:        number   // Wall-clock start timestamp
  duration_ms:     number   // End - start
  status:          "ok" | "error" | "timeout"
  error_message?:  string
  tags: {
    agent?:        string   // e.g. "code-builder"
    tool?:         string   // e.g. "task", "bash", "edit"
    file?:         string   // File touched (if applicable)
    model?:        string   // Model used (if LLM call)
    tokens_in?:    number
    tokens_out?:   number
  }
}
```

## Hierarchy: Agent → Sub-Task → Tool Call

Every user request creates a trace tree:

```
[Root Span: user request]
  │
  ├── [Span: main-coordinator route]
  │     │
  │     ├── [Span: task dispatch to code-builder]
  │     │     ├── [Span: tool.call — read project structure]
  │     │     ├── [Span: tool.call — write new file]
  │     │     └── [Span: tool.call — run tests]
  │     │
  │     └── [Span: task dispatch to bug-fixer]
  │           ├── [Span: tool.call — grep error logs]
  │           └── [Span: tool.call — edit fix]
  │
  └── [Span: response aggregation]
```

### Span Naming Convention

```
agent-name.operation

Examples:
  code-builder.implement
  bug-fixer.debug
  main-coordinator.route
  delivery-engineer.deploy
  observability-sre.monitor
  expert-tester.test
```

## Trace Context Propagation

Trace context must propagate across agent boundaries. When main-coordinator dispatches to a sub-agent:

1. **Inject** trace context into the dispatch prompt:
   ```
   === TRACE CONTEXT ===
   trace_id: abc123
   parent_span_id: span456
   =====================
   ```

2. **Extract** at the sub-agent's entry point and include in all child spans

3. **Propagate** to any further sub-dispatches within that agent

### Correlation Log

For every dispatch, write a correlation record:
```json
{
  "ts": "2026-06-24T12:00:00.000Z",
  "trace_id": "abc123",
  "parent_span": "span456",
  "dispatched_agent": "code-builder",
  "dispatch_reason": "implement login feature"
}
```

## MCP Server Span Attachment

When an agent calls an MCP server tool (e.g., context7, sequential-thinking, codebase-memory):

```javascript
// Wrap every MCP tool call with a child span
const mcpSpan = {
  trace_id:  parentTraceId,
  parent_id: parentSpanId,
  span_id:   generateSpanId(),
  name:      `mcp.${serverName}.${toolName}`,
  service:   `mcp:${serverName}`,
  start_ms:  Date.now(),
  tags: {
    mcp_server: serverName,
    tool:       toolName,
    duration_ms: elapsed
  }
}
```

This lets you answer: "Was the slowdown in my agent logic or in the MCP server?"

## Failure Attribution

When a span fails, attribute it to the correct layer:

| Symptom | Likely Root Cause | Which Span Gets the Error |
|---------|-------------------|--------------------------|
| Timeout | Agent took too long OR upstream blocked | The span that hit the timeout |
| Empty result | Sub-agent returned nothing, prompt too large | The `task.after` span with `error: "empty"` |
| 4xx/5xx | External API failure | The tool call span to that API |
| Crash | Agent process died | The `task.after` span with crash error |
| MCP timeout | MCP server unresponsive | The MCP span with `status: timeout` |

### Attribution Pattern

```javascript
function attributeError(span, error, toolOutput) {
  if (toolOutput?.includes("[SUB-AGENT-GUARD]")) {
    span.status = "error"
    span.error_message = "SUB-AGENT-GUARD: empty result — prompt likely too large"
    span.tags.failure_layer = "dispatcher"
  } else if (error?.message?.includes("timeout")) {
    span.status = "timeout"
    span.tags.failure_layer = "agent" // could be agent or upstream
  } else if (toolOutput?.includes("enoent") || toolOutput?.includes("not found")) {
    span.status = "error"
    span.error_message = toolOutput
    span.tags.failure_layer = "filesystem"
  }
  return span
}
```

## Example: Instrumenting a code-reviewer → expert-tester Handoff

This is the highest-value trace pattern — the evaluator-optimizer loop:

```
[Span: code-reviewer.review]
  │
  └── [Span: task dispatch to expert-tester]
        │
        ├── [Span: expert-tester.adversarial-test]
        │     ├── [Span: tool.call — fuzz inputs]
        │     ├── [Span: tool.call — race condition check]
        │     └── [Span: tool.call — prompt injection test]
        │
        └── [Span: aggregate results → verdict]
```

### Implementation

In `main-coordinator-tracing.js` (already created in Sprint 006):

```javascript
// On tool.execute.before for "task" tool:
if (input.tool === "task") {
  const agent = input.tool_call?.subagent_type || "unknown"
  const span = {
    trace_id:  input._traceId || generateTraceId(),
    parent_id: input._parentSpanId || null,
    span_id:   generateSpanId(),
    name:      `task.dispatch.${agent}`,
    service:   "main-coordinator",
    start_ms:  Date.now(),
    tags:      { agent }
  }
  input._currentSpanId = span.span_id
}

// On tool.execute.after:
if (input.tool === "task") {
  const duration = Date.now() - input._tracingStart
  appendLog({
    event: "agent_dispatch",
    trace_id:    input._traceId,
    parent_span: input._parentSpanId,
    span_id:     input._currentSpanId,
    target_agent: input.tool_call?.subagent_type,
    duration_ms: duration,
    success:     !output?.output?.includes("[SUB-AGENT-GUARD]"),
    error:       output?.output?.includes("[SUB-AGENT-GUARD]") ? "empty" : null
  })
}
```

## Augment 2026 Patterns: Nested Spans + MCP-Aware Context

The Augment 2026 AI engineering survey found that the top 3 production issues in agent systems were:

1. **Silent failures** (200 OK but no work done) — detected by span status = "ok" but `tags.work_done = false`
2. **Latency regressions** (p99 creeping up) — detected by comparing span duration histograms week-over-week
3. **MCP server degradation** — detected by per-MCP-server span success rate

### Histogram Buckets for Latency

Track span durations in these buckets:
```
0-100ms   ████████████████  (fast)
100-500ms ███████████       (acceptable)
500-1000ms █████            (slow)
1-5s      ███               (concerning)
>5s       █                 (critical)
```

Alert when >10% of spans fall into the >1s bucket for the same operation.

## Reading Traces

When debugging, query the coordination log:

```bash
# Find all failed dispatches in the last hour
cat ~/.config/opencode/memory/coordination-log.jsonl \
  | jq 'select(.event == "agent_dispatch" and .success == false)' \
  | tail -20

# Find all spans for a specific trace
cat ~/.config/opencode/memory/coordination-log.jsonl \
  | jq 'select(.trace_id == "abc123")'

# Aggregate by agent — average duration and failure rate
cat ~/.config/opencode/memory/coordination-log.jsonl \
  | jq -r 'select(.event == "agent_dispatch") | .target_agent' \
  | sort | uniq -c | sort -rn

# Find p95 duration per agent
# (use jq -s for full dataset aggregation)
```

## Relationship to Other Skills

- **`cost-tracking`**: Each span should record `tokens_in` and `tokens_out` from the model response — this lets you attribute cost to specific traces
- **`performance-optimization`**: Span duration data feeds into the p50/p95/p99 latency tracking in that skill
- **`karpathy-guidelines`**: Apply the "jagged intelligence" principle — spans that are surprisingly slow reveal where the agent model is weak
