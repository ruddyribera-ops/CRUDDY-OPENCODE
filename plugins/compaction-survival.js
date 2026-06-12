// compaction-survival.js
// OpenCode plugin: injects checkpoint state + learned patterns into session compaction
// Hooks: experimental.session.compacting (fires BEFORE LLM generates continuation summary)
//
// Research: https://opencode.ai/docs/plugins/
//   "The experimental.session.compacting hook fires before the LLM generates a
//    continuation summary. Use it to inject domain-specific context that the
//    default [compaction prompt] doesn't include."
//
// v2 change (2026-06-05): Switched from session.compacted (post-event, never fired
//   in our config) to experimental.session.compacting (pre-event, the documented
//   hook for injecting context into the compaction prompt itself).
//
// v2 change: Also added session.compacted as a SECONDARY hook to log when
//   compaction completes (for telemetry only).

import { existsSync, readFileSync, mkdirSync, appendFileSync } from "node:fs"
import path from "node:path"
import { formatPatternsList, loadCheckpointIndex, loadCheckpointFile } from "./_shared.js"

// ── Paths ────────────────────────────────────────────────────────
const CONFIG_ROOT = process.env.OPENCODE_CONFIG_HOME
  || process.env.OPENCODE_CONFIG
  || path.join(process.env.USERPROFILE || process.env.HOME || "", ".config", "opencode")

const CHECKPOINT_DIR = path.join(CONFIG_ROOT, "memory", "checkpoints")
const INDEX_FILE = path.join(CHECKPOINT_DIR, "checkpoint_index.jsonl")
const PATTERNS_FILE = path.join(CONFIG_ROOT, "memory", "outcomes", "patterns.jsonl")
const MATURITY_FILE = path.join(CONFIG_ROOT, "memory", "outcomes", "pattern_maturity.yaml")

// ── File-only logging ─────────────────────────────────────────────
// All output goes to memory/compaction-survival.log only — never to CLI
const LOG_FILE = path.join(CONFIG_ROOT, "memory", "compaction-survival.log")

function log(msg) {
  const line = `[compaction-survival] ${new Date().toISOString().slice(11,19)} ${msg}`
  try {
    mkdirSync(path.dirname(LOG_FILE), { recursive: true })
    appendFileSync(LOG_FILE, line + "\n")
  } catch {}
}

function loadMaturityPatterns() {
  try {
    if (!existsSync(MATURITY_FILE)) return []
    const content = readFileSync(MATURITY_FILE, "utf8")
    // Simple YAML parse — look for patterns: section
    const patterns = []
    const lines = content.split("\n")
    let inPatterns = false
    for (const line of lines) {
      if (line.trim() === "patterns:") { inPatterns = true; continue }
      if (inPatterns && line.match(/^\s+(\w+):/)) {
        const match = line.match(/^\s+(\w+):/)
        if (match && match[1] !== "generated") {
          patterns.push(match[1])
        }
      }
    }
    return patterns
  } catch (e) {
    return []
  }
}

// loadCheckpointIndex, loadCheckpointFile, formatPatternsList are now imported from ./_shared.js
// (see imports at top of file) — they take paths as arguments for testability.

// ── Plugin ────────────────────────────────────────────────────────
export const CompactionSurvival = async ({ project, client, $, directory }) => {
  log("Initialized.")

  return {
    // PRIMARY: fires BEFORE the LLM generates the continuation summary
    // This is the documented hook for injecting context into compaction
    "experimental.session.compacting": async (input, output) => {
      log("experimental.session.compacting fired — injecting context")

      // Load most recent checkpoint (shared helpers take paths as args)
      const latest = loadCheckpointIndex(CHECKPOINT_DIR, INDEX_FILE)
      const checkpoint = latest ? loadCheckpointFile(CHECKPOINT_DIR, latest.file) : null

      // Build recovery context
      let recoveryContext = ""
      if (checkpoint) {
        const pendingStr = checkpoint.pending_tasks && checkpoint.pending_tasks.length > 0
          ? checkpoint.pending_tasks.join("; ")
          : "none"

        const agentsStr = checkpoint.active_agents && checkpoint.active_agents.length > 0
          ? checkpoint.active_agents.join(", ")
          : "none"

        const filesStr = checkpoint.files_modified && checkpoint.files_modified.length > 0
          ? checkpoint.files_modified.join(", ")
          : "none"

        recoveryContext = `
## Session Recovery State
A checkpoint was saved at ${checkpoint.progress_percent}% completion.
- Project: ${checkpoint.project_path || directory || "unknown"}
- Strategy used: ${checkpoint.strategy || "unknown"}
- Files in flight: ${filesStr}
- Active agents: ${agentsStr}
- Pending tasks: ${pendingStr}
- Next action: ${checkpoint.next_action || "unknown"}
${checkpoint.error_context ? `- Error context: ${checkpoint.error_context}` : ""}

When resuming, prioritize:
1. Complete the pending tasks listed above
2. Use proven patterns for similar task types
3. Avoid anti-patterns (marked ANTI-PATTERN)

If there were errors before compaction, address them first before proceeding.
`.trim()
      }

      const patternsList = formatPatternsList(MATURITY_FILE)
      const patternsContext = `
## Learned Patterns
This coordinator has learned from past task outcomes:
${patternsList}
`.trim()

      // Inject into output.context (additive — recommended approach)
      if (Array.isArray(output.context)) {
        if (recoveryContext) {
          output.context.push({ type: "text", text: recoveryContext })
        }
        output.context.push({ type: "text", text: patternsContext })
        log(`Injected ${recoveryContext ? "checkpoint + " : ""}patterns into compaction context.`)
      } else if (typeof output.context === "string") {
        // Build a combined string
        const combined = [recoveryContext, patternsContext].filter(Boolean).join("\n\n")
        output.context = combined + "\n\n" + output.context
        log("Injected recovery context via output.context string concatenation")
      } else if (output.prompt !== undefined) {
        const combined = [recoveryContext, patternsContext].filter(Boolean).join("\n\n")
        output.prompt = combined + "\n\n" + (output.prompt || "")
        log("Injected recovery context via output.prompt (fallback)")
      } else {
        log("WARNING: Could not inject recovery context — output.format unknown")
      }
    },

    // SECONDARY: post-compaction telemetry (fires AFTER compaction completes)
    // Not used for context injection — just for log accounting
    "session.compacted": async (input, output) => {
      log("session.compacted fired (post-compaction telemetry)")
    },
  }
}