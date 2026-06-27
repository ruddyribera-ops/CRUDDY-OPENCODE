// _shared.js
// Internal utilities shared across OpenCode plugins.
// NOT a plugin — does not export a default `X = async () => { return { hooks } }`.
// OpenCode ignores files without that export, so this is safe to keep here.
//
// Source of truth for: gateLog, configRoot, formatPatternsList, checkpoint helpers.
// If you need a utility in 2+ plugins, add it here and import it.

import { appendFileSync, existsSync, readFileSync, mkdirSync } from "node:fs"
import { join } from "node:path"

const CONFIG_ROOT = process.env.OPENCODE_CONFIG_HOME
  || process.env.OPENCODE_CONFIG
  || join(process.env.USERPROFILE || process.env.HOME || "", ".config", "opencode")

const GATE_LOG = join(CONFIG_ROOT, "memory", "gate-system.log")
const MEMORY_DIR = join(CONFIG_ROOT, "memory")

// Unified gate logging. Writes a timestamped line to gate-system.log.
// Fire-and-forget; never throws. Safe to call from hot paths.
function gateLog(pluginName, msg) {
  try {
    const line = `[${pluginName}] ${new Date().toISOString().slice(11, 19)} ${msg}\n`
    appendFileSync(GATE_LOG, line)
  } catch (e) {
    // Logging failure is non-fatal — do not crash the plugin
  }
}

// formatPatternsList — read pattern_maturity.yaml, return human-readable list.
// Used by compaction-survival and memory-bridge.
function formatPatternsList(maturityFile) {
  try {
    if (!existsSync(maturityFile)) return "No patterns learned yet."
    const content = readFileSync(maturityFile, "utf8")
    const lines = content.split("\n")
    const results = []
    let currentPattern = ""
    let currentMaturity = ""
    let currentScore = ""

    for (const line of lines) {
      const indentMatch = line.match(/^(\s*)(\w+):/)
      if (indentMatch && indentMatch[1].length === 2 && indentMatch[2] !== "generated") {
        if (currentPattern) {
          results.push(`- ${currentPattern}: ${currentMaturity.toUpperCase()} (score ${currentScore})`)
        }
        currentPattern = indentMatch[2]
        currentMaturity = ""
        currentScore = ""
      } else if (line.includes("maturity:")) {
        currentMaturity = line.split(":")[1].trim()
      } else if (line.includes("score:")) {
        currentScore = line.split(":")[1].trim()
      }
    }
    if (currentPattern) {
      results.push(`- ${currentPattern}: ${currentMaturity.toUpperCase()} (score ${currentScore})`)
    }
    return results.length > 0 ? results.join("\n") : "No patterns learned yet."
  } catch (e) {
    return "No patterns learned yet."
  }
}

// loadCheckpointIndex — return most recent checkpoint metadata, or null
function loadCheckpointIndex(checkpointDir, indexFile) {
  try {
    if (!existsSync(indexFile)) return null
    const content = readFileSync(indexFile, "utf8")
    const lines = content.split("\n").filter(l => l.trim())
    const checkpoints = lines.map(l => {
      try { return JSON.parse(l) } catch { return null }
    }).filter(x => x && x.type === "checkpoint")
    if (checkpoints.length === 0) return null
    checkpoints.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
    return checkpoints[0]
  } catch (e) {
    return null
  }
}

// loadCheckpointFile — load the full checkpoint JSON by filename
function loadCheckpointFile(checkpointDir, filename) {
  try {
    const filePath = join(checkpointDir, filename)
    if (!existsSync(filePath)) return null
    return JSON.parse(readFileSync(filePath, "utf8"))
  } catch (e) {
    return null
  }
}

export {
  CONFIG_ROOT,
  GATE_LOG,
  MEMORY_DIR,
  gateLog,
  formatPatternsList,
  loadCheckpointIndex,
  loadCheckpointFile,
}
