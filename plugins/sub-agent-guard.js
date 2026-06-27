// sub-agent-guard.js
// Wraps the `task` tool with timeout tracking + empty-result detection.
// Addresses opencode issues:
//   #15080 - task tool has no built-in timeout (sub-agents can hang)
//   #18108 - task tool sometimes returns empty task_result (JSON truncation)
//
// What this does:
//   - Logs every task dispatch with its timeout budget (TASK_START)
//   - Tracks elapsed wall-clock time per task (start time stashed on input)
//   - On success: logs TASK_OK with result length + elapsed ms
//   - On empty result: replaces output with a structured, actionable error
//     and logs TASK_EMPTY (or TASK_TIMEOUT if the budget was exceeded)
//
// What this does NOT do (intentional, by OpenCode plugin API design):
//   - Cannot abort a running sub-agent from a hook. OpenCode has no abort
//     handle exposed to plugins. The dispatcher / orchestrator (main-coordinator)
//     is responsible for the actual retry-with-simpler-prompt loop. This plugin
//     only signals that a retry is needed via the structured output.
//
// Helpers exported for dispatcher-level retry:
//   - simplifyPrompt(prompt)  strips code blocks, truncates to <300 chars
//   - DEFAULT_TIMEOUT_MS      the 5-minute budget constant
//   - EMPTY_RESULT_MESSAGE    the canonical error string injected on failure

import { gateLog } from "./_shared.js"

const DEFAULT_TIMEOUT_MS = 300000  // 5 minutes
// MAX_PROMPT_LEN: generous limit prevents legitimate task descriptions from being
// truncated mid-word. 300 was too aggressive — real sub-agent prompts (with file
// paths, requirements, context) exceed it easily. 1500 gives headroom for complex tasks.
const MAX_PROMPT_LEN = 1500

const EMPTY_RESULT_MESSAGE =
  "[SUB-AGENT-GUARD] Task returned empty result. " +
  "Likely causes: (1) JSON truncation - the task was too large, " +
  "(2) sub-agent exceeded its timeout budget, " +
  "(3) sub-agent crashed mid-execution. " +
  "Suggested fix: re-dispatch with smaller scope, or run the prompt through " +
  "simplifyPrompt() to strip code blocks before retry."

// Start time is stashed on the input object itself. OpenCode passes the same
// input reference to both before- and after-hooks for a given tool call, and
// the input is GC'd once the call completes — no separate map needed.

/**
 * Strip fenced code blocks and truncate a prompt for safer retry.
 * Exported so a future dispatcher-level retry can reuse it.
 *
 * @param {string|undefined|null} prompt
 * @returns {string}
 */
function simplifyPrompt(prompt) {
  if (prompt == null) return ""
  let simplified = String(prompt).replace(/```[\s\S]*?```/g, "[code stripped]")
  if (simplified.length > MAX_PROMPT_LEN) {
    simplified = simplified.slice(0, MAX_PROMPT_LEN - 3) + "..."
  }
  return simplified
}

/**
 * OpenCode plugin entry. Returns hook handlers for the task tool.
 * @returns {Promise<{ "tool.execute.before": Function, "tool.execute.after": Function }>}
 */
export const SubAgentGuard = async () => {
  return {
    "tool.execute.before": async (input, _output) => {
      if (input.tool !== "task") return

      // Stamp a default timeout if the caller didn't set one. We don't
      // enforce it directly (no abort handle in the plugin API), but we
      // use it as the budget against which we measure elapsed time in after.
      if (!input.timeout) {
        input.timeout = DEFAULT_TIMEOUT_MS
      }

      const start = Date.now()
      input._subAgentGuardStart = start

      const agent = input.tool_call?.subagent_type || "unknown"
      gateLog("sub-agent-guard", `TASK_START agent=${agent} timeout=${input.timeout}ms`)
    },

    "tool.execute.after": async (input, output) => {
      if (input.tool !== "task") return

      const start = input._subAgentGuardStart
      const elapsed = start != null ? Date.now() - start : null

      const result = output?.output ?? output?.result ?? ""
      const resultStr = String(result)
      const hasContent = resultStr.trim().length > 0

      if (hasContent) {
        gateLog(
          "sub-agent-guard",
          `TASK_OK length=${resultStr.length} elapsed=${elapsed}ms`
        )
        return
      }

      // Empty result. Distinguish timeout-exceeded vs plain empty so the
      // dispatcher (or human reading the log) can tell which failure mode hit.
      const budget = input.timeout || DEFAULT_TIMEOUT_MS
      const exceeded = elapsed != null && elapsed >= budget
      const event = exceeded ? "TASK_TIMEOUT" : "TASK_EMPTY"
      gateLog(
        "sub-agent-guard",
        `${event} elapsed=${elapsed}ms budget=${budget}ms`
      )

      // Replace the empty output with a structured, actionable error.
      // The calling agent sees this in its tool result and can decide to retry.
      if (output && typeof output === "object") {
        output.output = EMPTY_RESULT_MESSAGE
      }
    },
  }
}

// Exported helpers (consumed by future dispatcher-level retry logic)
export { simplifyPrompt, DEFAULT_TIMEOUT_MS, EMPTY_RESULT_MESSAGE, MAX_PROMPT_LEN }
