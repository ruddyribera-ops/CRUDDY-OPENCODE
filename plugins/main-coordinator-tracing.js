// main-coordinator-tracing.js
// Routing decision tracer — logs every agent dispatch to coordination-log.jsonl
//
// What this does:
//   - Intercepts every `task` tool call (the dispatch mechanism for sub-agents)
//   - Logs: timestamp, target agent, prompt length, duration, success/failure
//   - Appends one JSON object per line to memory/coordination-log.jsonl
//   - Non-blocking: never fails routing if logging fails
//   - Rotates log at MAX_LOG_BYTES to prevent unbounded growth
//
// References:
//   - memory-bridge.js for event hook patterns
//   - sub-agent-guard.js for task tool instrumentation
//   - _shared.js for gateLog utility

import { appendFile, mkdir, stat, rename, unlink } from "node:fs/promises"
import { join } from "node:path"
import { gateLog } from "./_shared.js"

const CONFIG_ROOT = process.env.OPENCODE_CONFIG_HOME
  || process.env.OPENCODE_CONFIG
  || join(process.env.USERPROFILE || process.env.HOME || "", ".config", "opencode")

const MEMORY_DIR  = join(CONFIG_ROOT, "memory")
const COORD_LOG   = join(MEMORY_DIR, "coordination-log.jsonl")
const COORD_LOG_1 = join(MEMORY_DIR, "coordination-log.jsonl.1")
const COORD_LOG_2 = join(MEMORY_DIR, "coordination-log.jsonl.2")

// Rotation config — keep the log small enough to never fill disk
const MAX_LOG_BYTES = 5 * 1024 * 1024    // 5 MB
const CHECK_EVERY_N_WRITES = 50           // stat the file every 50 writes

// In-flight tracker: maps start timestamp to dispatch metadata
// Used to compute duration on tool.execute.after
const inFlight = new Map()

// Write counter for periodic rotation checks
let writeCount = 0

/**
 * Rotate the coordination log if it has grown beyond MAX_LOG_BYTES.
 * Keeps at most 2 archived files (coordination-log.jsonl.1, .2).
 * Oldest (.2) is deleted before rotation. Fire-and-forget errors.
 */
async function rotateIfNeeded() {
  try {
    const s = await stat(COORD_LOG).catch(() => null)
    if (!s || s.size < MAX_LOG_BYTES) return

    // Drop the oldest if it exists
    await unlink(COORD_LOG_2).catch(() => null)
    // Shift .1 to .2 if it exists
    await rename(COORD_LOG_1, COORD_LOG_2).catch(() => null)
    // Move current to .1
    await rename(COORD_LOG, COORD_LOG_1).catch(() => null)

    gateLog(
      "main-coordinator-tracing",
      `ROTATED log=${COORD_LOG} size=${s.size}`
    )
  } catch (err) {
    // Never throw — just log
    console.error("[tracing] rotation failed:", err.message)
  }
}

/**
 * Append a JSON line to the coordination log.
 * Fire-and-forget: errors are logged to gate-system.log, never thrown.
 * Periodically checks log size and rotates if needed.
 *
 * @param {object} entry - The log entry object
 */
async function appendLog(entry) {
  try {
    await mkdir(MEMORY_DIR, { recursive: true })

    // Periodic rotation check (cheap; avoids stat on every write)
    writeCount++
    if (writeCount % CHECK_EVERY_N_WRITES === 0) {
      await rotateIfNeeded()
    }

    const line = JSON.stringify({
      ts: new Date().toISOString(),
      ...entry
    })
    await appendFile(COORD_LOG, line + "\n", "utf8")
  } catch (err) {
    // Never throw — log to stderr and gate log only
    console.error("[tracing] log append failed:", err.message)
    gateLog("main-coordinator-tracing", `append failed: ${err.message.slice(0, 80)}`)
  }
}

/**
 * Trim a string for safe logging — removes excessive length, code blocks,
 * and other content that shouldn't appear in a coordination log.
 *
 * @param {string|undefined} str
 * @param {number} maxLen
 * @returns {string}
 */
function safeTruncate(str, maxLen = 300) {
  if (!str) return ""
  // Strip fenced code blocks
  let trimmed = String(str).replace(/```[\s\S]*?```/g, "[code]")
  // Strip inline code
  trimmed = trimmed.replace(/`[^`]*`/g, "[code]")
  // Strip URLs (security: don't log internal paths disclosed in prompts)
  trimmed = trimmed.replace(/https?:\/\/[^\s<>"{}|\\^`[\]]+/g, "[url]")
  // Collapse whitespace
  trimmed = trimmed.replace(/\s+/g, " ").trim()
  if (trimmed.length > maxLen) {
    return trimmed.slice(0, maxLen - 3) + "..."
  }
  return trimmed
}

/**
 * Determine if a tool result indicates success or failure.
 * @param {any} output - The tool output
 * @returns {{ success: boolean, error: string|null }}
 */
function classifyOutcome(output) {
  if (!output) return { success: false, error: "empty output" }

  const result = output.output ?? output.result ?? ""
  const resultStr = String(result)

  // Sub-agent guard sentinel = empty result
  if (resultStr.includes("[SUB-AGENT-GUARD]")) {
    return { success: false, error: "SUB-AGENT-GUARD: empty result" }
  }

  // Task cancelled or abandoned
  if (resultStr.includes("Task cancelled") || resultStr.includes("Task abandoned")) {
    return { success: false, error: "task cancelled" }
  }

  // Error patterns in output
  if (resultStr.includes("[ERROR]") || resultStr.includes('"status": "error"')) {
    return { success: false, error: "error in output" }
  }

  // Empty result after meaningful execution time
  if (!resultStr.trim()) {
    return { success: false, error: "empty result string" }
  }

  return { success: true, error: null }
}

// ─── Plugin Entry ─────────────────────────────────────────────────────────────

/**
 * OpenCode plugin entry point.
 * Instruments the `task` tool to capture every sub-agent dispatch.
 *
 * @returns {Promise<{ "tool.execute.before": Function, "tool.execute.after": Function }>}
 */
export const CoordinatorTracing = async () => {
  await mkdir(MEMORY_DIR, { recursive: true })
  gateLog(
    "main-coordinator-tracing",
    `STARTED pid=${process.pid} log=${COORD_LOG} max=${MAX_LOG_BYTES}B`
  )

  return {
    /**
     * Fires BEFORE a tool is executed.
     * For `task` tool: capture dispatch metadata and start the timer.
     */
    "tool.execute.before": async (input, _output) => {
      // Only instrument the task tool (dispatch mechanism)
      if (input.tool !== "task") return

      const agent     = input.tool_call?.subagent_type || input.agent || "unknown"
      const promptLen = (input.prompt?.length ?? 0) + (input.description?.length ?? 0)
      const startMs  = Date.now()

      // Store metadata keyed by start timestamp for correlation in after hook
      inFlight.set(startMs, {
        agent,
        promptLen,
        taskDescription: safeTruncate(input.description, 120),
      })

      // Stamp the start time on the input object so after hook can read it
      input._tracingStart = startMs

      gateLog("main-coordinator-tracing", `DISPATCH agent=${agent} promptLen=${promptLen}`)
    },

    /**
     * Fires AFTER a tool is executed.
     * For `task` tool: log the dispatch outcome to coordination-log.jsonl.
     */
    "tool.execute.after": async (input, output) => {
      if (input.tool !== "task") return

      const startMs = input._tracingStart
      if (!startMs) {
        gateLog("main-coordinator-tracing", "after: no _tracingStart found")
        return
      }

      const metadata = inFlight.get(startMs) || {
        agent: "unknown",
        promptLen: 0,
        taskDescription: "",
      }
      inFlight.delete(startMs)

      const durationMs = Date.now() - startMs
      const { success, error } = classifyOutcome(output)
      const resultLen = (output?.output?.length ?? output?.result?.length ?? 0)

      const logEntry = {
        event: "agent_dispatch",
        target_agent: metadata.agent,
        prompt_len: metadata.promptLen,
        task_description: metadata.taskDescription,
        duration_ms: durationMs,
        success,
        error: error || undefined,
        result_len: resultLen,
        // Atomic reference for correlation
        trace_id: startMs,
      }

      await appendLog(logEntry)

      gateLog(
        "main-coordinator-tracing",
        `RESULT agent=${metadata.agent} success=${success} duration=${durationMs}ms`
      )
    },
  }
}

// Default export (both named AND default work per customize-opencode skill)
export default CoordinatorTracing
