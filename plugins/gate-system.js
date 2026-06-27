// gate-system.js - FORK-BOMB PROTECTION ONLY
// tool.execute.after hook never fired in OpenCode Go plugin runtime.
// Auto-memory logic moved to memory-bridge.js (event-based session.idle).
// This file only handles: task agent depth tracking (fork-bomb protection).
//
// Counter, retro-analyze, auto-memory — all now in memory-bridge.js

import { existsSync, readFileSync, writeFileSync, renameSync, mkdirSync } from "node:fs"
import path from "node:path"

const CONFIG_ROOT = process.env.OPENCODE_CONFIG_HOME
  || process.env.OPENCODE_CONFIG
  || path.join(process.env.USERPROFILE || process.env.HOME || "", ".config", "opencode")

const GATE_ROOT  = path.join(CONFIG_ROOT, "gates")
const DEPTH_PATH = path.join(GATE_ROOT, ".agent-depth.json")
const MAX_AGENT_DEPTH = 3

// ── Agent Depth (fork-bomb protection) ────────────────────────────
function readDepth() {
  try {
    if (!existsSync(DEPTH_PATH)) return { depth: 0, maxDepth: 0 }
    return JSON.parse(readFileSync(DEPTH_PATH, "utf8"))
  } catch { return { depth: 0, maxDepth: 0 } }
}

function writeDepth(data) {
  mkdirSync(GATE_ROOT, { recursive: true })
  const tmp = DEPTH_PATH + ".tmp"
  writeFileSync(tmp, JSON.stringify(data))
  renameSync(tmp, DEPTH_PATH)
}

function incrementDepth() {
  const c = readDepth()
  writeDepth({ depth: c.depth + 1, maxDepth: Math.max(c.maxDepth, c.depth + 1) })
  return c.depth + 1
}

function decrementDepth() {
  const c = readDepth()
  writeDepth({ depth: Math.max(0, c.depth - 1), maxDepth: c.maxDepth })
  return Math.max(0, c.depth - 1)
}

// Module-level IIFE: write marker on import (runs even if GateSystem() never called)
const _INIT_MARKER = path.join(GATE_ROOT, ".gate-system-init.marker")
try {
  mkdirSync(GATE_ROOT, { recursive: true })
  writeFileSync(_INIT_MARKER, `gate-system.js loaded at ${new Date().toISOString()} pid=${process.pid}\n`, "utf8")
} catch (e) {
  process.stderr.write(`[gate-system] init marker write failed: ${e.message}\n`)
}

export const GateSystem = async () => {
  return {
    // Inject config paths into all subshells
    "shell.env": async (_input, output) => {
      output.env.OPENCODE_GATE_ROOT   = GATE_ROOT
      output.env.OPENCODE_CONFIG_HOME = CONFIG_ROOT
    },

    // Track task agent depth for fork-bomb protection
    "event": async ({ event }) => {
      if (event?.type === "session.status") {
        const d = readDepth()
        if (d.depth > MAX_AGENT_DEPTH * 2) {
          writeDepth({ depth: 0, maxDepth: d.maxDepth })
        }
      }
    }
  }
}

export { incrementDepth, decrementDepth, MAX_AGENT_DEPTH, readDepth }