// memory-bridge.js
// Session event â†’ auto-memory bridge
// Replaces gate-system.js tool.execute.after (which never fired)
//
// What this does:
// - session.idle (2+ activity) â†’ auto-memory.ps1
// - session.deleted â†’ auto-memory.ps1 (final flush)
// - Every 10 idle events â†’ retro-analyze.ps1
// - All events â†’ session_events.jsonl (always worked, keep it)

import { appendFile, mkdir, readFile, openSync, closeSync, unlinkSync } from "node:fs/promises"
import { execFile } from "node:child_process"
import { promisify } from "node:util"
import path from "node:path"
import { gateLog } from "./_shared.js"

const execFileP = promisify(execFile)

const CONFIG_ROOT = path.resolve(process.env.OPENCODE_CONFIG_HOME || process.env.OPENCODE_CONFIG || path.join(process.env.USERPROFILE || "", ".config", "opencode"))
const MEMORY_DIR  = path.join(CONFIG_ROOT, "memory")
const GATE_ROOT   = path.join(CONFIG_ROOT, "gates")
const SESSION_LOG = path.join(MEMORY_DIR, "session_log.md")

const AUTO_MEMORY  = path.join(CONFIG_ROOT, "scripts", "auto-memory.ps1")
const RETRO_SCRIPT = path.join(CONFIG_ROOT, "scripts", "gate", "retro-analyze.ps1")
const COUNTER_PATH = path.join(GATE_ROOT, ".task-counter.json")
const GATE_LOG     = path.join(MEMORY_DIR, "gate-system.log")

const TASK_THRESHOLD = 10
let lastRotationCheck = 0
const ROTATION_THROTTLE_MS = 60000  // 1 minute
const SESSION_EVENTS_MAX_LINES = 2000  // was 10K; with 84% noise filtered, 2K ≈ 3 days useful events

// â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
async function appendJsonl(name, payload) {
  await mkdir(MEMORY_DIR, { recursive: true })
  await appendFile(path.join(MEMORY_DIR, name), JSON.stringify({ ts: new Date().toISOString(), ...payload }) + "\n")
}

const log = (msg) => gateLog("memory-bridge", msg)

// â”€â”€ Session Events Rotation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
async function rotateSessionEvents() {
  const now = Date.now()
  if (now - lastRotationCheck < ROTATION_THROTTLE_MS) return
  lastRotationCheck = now
  const eventsPath = path.join(MEMORY_DIR, "session_events.jsonl")
  try {
    const fs = await import("node:fs")
    const stat = fs.statSync(eventsPath)
    if (!stat.size) return

    // Read all lines
    const content = fs.readFileSync(eventsPath, "utf8")
    const lines = content.split("\n").filter(l => l.trim())
    
    if (lines.length <= SESSION_EVENTS_MAX_LINES) return  // nothing to do

    // Keep last N lines (most recent)
    const kept = lines.slice(-SESSION_EVENTS_MAX_LINES)
    const removed = lines.length - kept.length
    
    fs.writeFileSync(eventsPath, kept.join("\n") + "\n", "utf8")
    await log(`rotated session_events: ${lines.length} â†’ ${kept.length} (removed ${removed} old lines)`)
  } catch (e) {
    await log(`rotate_session_events failed: ${e.message.slice(0, 60)}`)
  }
}

// â”€â”€ Counter (shared with gate-system.js for retro threshold) â”€â”€â”€â”€
async function readCounter() {
  try {
    const data = await readFile(COUNTER_PATH, "utf8")
    return JSON.parse(data)
  } catch { return { count: 0, last: null } }
}

async function writeCounter(data) {
  await mkdir(GATE_ROOT, { recursive: true })
  const tmp = COUNTER_PATH + ".tmp"
  const fs = await import("node:fs/promises")
  await fs.writeFile(tmp, JSON.stringify(data))
  await fs.rename(tmp, COUNTER_PATH)
}

async function incrementCounter() {
  const c = await readCounter()
  const next = { count: c.count + 1, last: new Date().toISOString() }
  await writeCounter(next)
  return next.count
}

// â”€â”€ Auto-memory (calls PowerShell script) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// M-10: File-based mutex replaces in-memory Map (survives plugin reload)
function acquireFlushLock(sessionId) {
  const lockPath = path.join(MEMORY_DIR, ".flush-" + sessionId + ".lock")
  try {
    const fd = openSync(lockPath, "wx")
    closeSync(fd)
    return lockPath
  } catch (e) {
    return null  // Already locked
  }
}

function releaseFlushLock(lockPath) {
  if (lockPath) {
    try { unlinkSync(lockPath) } catch (e) {}
  }
}

async function flushMemory(taskName, result) {
  // M-10: Coalesce rapid-fire calls: if same taskName is in-flight, skip
  const lockPath = acquireFlushLock(taskName)
  if (!lockPath) return
  try {
    // M3 fix: escape metacharacters before passing to PowerShell
 // Escape $, `, and " to prevent param injection via -Result or -TaskName
    const psEscape = (s) => String(s).replace(/[`$"']/g, "`$&")
    await execFileP("powershell.exe", [
      "-NoProfile", "-File", AUTO_MEMORY,
      "-TaskName", psEscape(taskName.slice(0, 80)),
      "-Agent", "main-coordinator",
      "-Result", psEscape(String(result).slice(0, 200)),
      "-TokensEst", "~N"
    ], { timeout: 20000, windowsHide: true })
    await log(`auto-memory OK: ${taskName}`)
  } catch (e) {
    // Capture full stderr + exit code (not just 60-char truncation)
    const stderr = (e.stderr ? e.stderr.toString().trim() : "").slice(0, 300)
    const code   = e.code || e.signal || "?"
    await log(`auto-memory FAILED: code=${code} stderr="${stderr}"`)
} finally {
    releaseFlushLock(lockPath)
  }
}

// â”€â”€ Graph memory write (fire-and-forget) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Mem0 citation pattern: every fact stores source + validity window (MinnsDB pattern)
// Citation fields: source (file), line, session, valid_from, valid_until, confidence
const CITATION_TTL_DAYS = 28  // Auto-expire facts after 28 days (Mem0 default)
async function writeGraphNode(type, name, data) {
  try {
    const GM = path.join(CONFIG_ROOT, "scripts", "graph-memory.js")
    // Add citation + validity window to data (additive â€” existing fields preserved)
    const now = new Date()
    const validUntil = new Date(now.getTime() + CITATION_TTL_DAYS * 86400000)
    const enriched = {
      ...data,
      citation: {
        ...(data.citation || {}),
        valid_from: data.citation?.valid_from || now.toISOString(),
        valid_until: data.citation?.valid_until || validUntil.toISOString(),
        confidence: data.citation?.confidence ?? 1.0
      }
    }
    // Use spawn + stdin to avoid Windows CLI quoting issues with nested JSON quotes
    const { spawn } = await import("node:child_process")
    await new Promise((resolve, reject) => {
      const child = spawn("node", [GM, "create-node", type, "--name", name, "--stdin"], {
        timeout: 5000, windowsHide: true
      })
      child.on("close", (code) => code === 0 ? resolve() : reject(new Error("exit " + code)))
      child.on("error", reject)
      child.stdin.write(JSON.stringify(enriched))
      child.stdin.end()
    })
  } catch (e) {
    // Graph writes are advisory â€” never block. Log silently.
  }
}

async function writeGraphEdge(fromNode, toNode, relationship) {
  try {
    const GM = path.join(CONFIG_ROOT, "scripts", "graph-memory.js")
    // Add validity window to edge (edges also need temporal tracking)
    const now = new Date()
    const validUntil = new Date(now.getTime() + CITATION_TTL_DAYS * 86400000)
    const enrichedRel = typeof relationship === "string"
      ? { type: relationship, valid_from: now.toISOString(), valid_until: validUntil.toISOString() }
      : { ...relationship, valid_from: relationship.valid_from || now.toISOString(), valid_until: relationship.valid_until || validUntil.toISOString() }
    await execFileP("node", [GM, "create-edge", "--from", fromNode, "--to", toNode, "--relationship", JSON.stringify(enrichedRel)], {
      timeout: 5000, windowsHide: true
    })
  } catch (e) {
    // Graph writes are advisory â€” never block
  }
}

// â”€â”€ Retro-analyze (every N idle events) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
async function runRetroAnalyze(count) {
  if (!TASK_THRESHOLD || count % TASK_THRESHOLD !== 0) return
  try {
    const { stdout } = await execFileP("powershell.exe", [
      "-NoProfile", "-File", RETRO_SCRIPT,
      "-TaskCount", String(TASK_THRESHOLD), "-WriteGenes"
    ], { timeout: 30000 })
    await log(`retro-analyze: ${stdout.includes("[GENES WRITTEN]") ? "genes written" : "done"}`)
  } catch (e) {
    await log(`retro-analyze error: ${e.message.slice(0, 60)}`)
  }
}

// â”€â”€ Session tracking â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const sessionActivity = new Map()
const fileEditCount = new Map()  // tracks file.edited events per session
const lastActivityMs = new Map()
const IDLE_THRESHOLD = 1  // minimum events before we log idle (1 = fire on first idle after any activity)
const MAX_TRACKED_SESSIONS = 100  // LRU cap - prevents unbounded Map growth

// ES6 Maps preserve insertion order - re-set moves to end, first key is oldest
function trackActivity(sessionId, isFileEdit) {
  sessionActivity.set(sessionId, (sessionActivity.get(sessionId) || 0) + 1)
  if (isFileEdit) fileEditCount.set(sessionId, (fileEditCount.get(sessionId) || 0) + 1)
  lastActivityMs.set(sessionId, Date.now())
  while (sessionActivity.size > MAX_TRACKED_SESSIONS) {
    const oldest = sessionActivity.keys().next().value
    if (oldest === undefined) break
    sessionActivity.delete(oldest)
    lastActivityMs.delete(oldest)
    fileEditCount.delete(oldest)  // also evict file edit count to prevent leak
  }
}
const FORCE_IDLE_MS = 90000  // 90s of no activity â†’ forced auto-memory flush (fallback when session.idle doesn't fire)

export const MemoryBridge = async () => {
  await mkdir(MEMORY_DIR, { recursive: true })
  await log(`memory-bridge STARTED pid=${process.pid}`)

  return {
    "shell.env": async (_input, output) => {
      output.env.OPENCODE_CONFIG_HOME = CONFIG_ROOT
      output.env.OPENCODE_MEMORY_DIR  = MEMORY_DIR
      output.env.OPENCODE_EXPERIMENTAL_LSP_TOOL = "true"
    },

    event: async ({ event }) => {
      if (!event?.type) return

      const session = event.session || event.properties?.session || {}
      const sessionId = session?.id || event.sessionID || "unknown"
      const title = session?.title || "untitled"

      // â”€â”€ Track activity â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      // Note: session.idle fires with sessionID="unknown" in OpenCode Go.
      // We track ALL sessions including "unknown" so idle detection works.
      if (sessionId) {
        const isWork = (
          event.type === "file.edited" ||
          event.type.startsWith("tool.") ||
          (event.type === "message.updated" && event.properties?.info?.role === "user")
        )
        if (isWork) {
          // trackActivity() handles LRU eviction automatically
          trackActivity(sessionId, event.type === "file.edited")
        }
      }

      // â”€â”€ Force-idle fallback: if no activity for 90s+, flush anyway â”€
      // This handles cases where session.idle doesn't fire for continuous conversations
      const lastActive = lastActivityMs.get(sessionId) || 0
      const idleMs = Date.now() - lastActive
if (lastActive > 0 && idleMs >= FORCE_IDLE_MS) {
        // Skip noise: untitled sessions with no real file work
        if (title === "untitled" && (fileEditCount.get(sessionId) || 0) === 0) {
          lastActivityMs.set(sessionId, Date.now())
          sessionActivity.delete(sessionId)
          return
        }
        // Reset activity to avoid repeated flushes
        lastActivityMs.set(sessionId, Date.now())
        const activity = sessionActivity.get(sessionId) || 0
        if (activity > 0) {
          const count = await incrementCounter()
          const taskName = `forced-idle:${title}`.slice(0, 80)
          await flushMemory(taskName, "forced-idle")
          await runRetroAnalyze(count)
          await log(`forced-idle: ${title} [${idleMs}ms, count=${count}]`)
          sessionActivity.delete(sessionId)
        }
      }

      // â”€â”€ session.idle â†’ auto-memory â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
if (event.type === "session.idle") {
        // M-7: Skip unknown+untitled sessions that flood logs
        if (sessionId === "unknown" && (title === undefined || title === "untitled")) {
          return
        }
        const activity = sessionActivity.get(sessionId) || 0

        if (activity >= IDLE_THRESHOLD) {
          // Skip noise: untitled sessions with no real work
          if (title === "untitled" && (fileEditCount.get(sessionId) || 0) === 0) {
            sessionActivity.delete(sessionId)
            return
          }
          const count = await incrementCounter()
          const taskName = `idle:${title}`.slice(0, 80)
          await flushMemory(taskName, "idle")

          // Write to graph memory (advisory)
          const sessionNode = `Session-${title.replace(/[^a-zA-Z0-9-]/g, '-')}`
          await writeGraphNode("session", sessionNode, {
            title: title,
            activity_count: activity,
            last_idle: new Date().toISOString()
          })

          await runRetroAnalyze(count)
          await log(`idle logged: ${title} [count=${count}]`)
        }

        sessionActivity.delete(sessionId)
      }

      // â”€â”€ session.deleted â†’ final flush â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      else if (event.type === "session.deleted") {
        const activity = sessionActivity.get(sessionId) || 0
        if (activity > 0 || sessionId !== "unknown") {
          await flushMemory(`session-close:${title}`.slice(0, 80), "session-deleted")
          await log(`session-deleted flush: ${title}`)
        }
        sessionActivity.delete(sessionId)
        // Rotate session_events after session end (keep last 10K lines)
        await rotateSessionEvents()
        // Clean old session-env directories (14+ days) â€” use array args to avoid path truncation
        const cleanupPath = AUTO_MEMORY.replace("auto-memory.ps1", "cleanup-session-env.ps1")
        execFileP("powershell.exe", ["-NoProfile", "-File", cleanupPath, "-MaxAgeDays", "14"], {
          timeout: 15000, windowsHide: true
        }).catch(() => {})
      }

      // â”€â”€ session.error â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      else if (event.type === "session.error") {
        await flushMemory(`session-error:${title}`.slice(0, 80), "error")
        await log(`session-error: ${title}`)
        sessionActivity.delete(sessionId)
      }

      // Skip high-frequency streaming noise (84% - message.part.*)
      if (event.type === "message.part.delta" || event.type === "message.part.updated") return

      // â”€â”€ Always: capture to session_events.jsonl â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      if (
        event.type.startsWith("message.") ||
        event.type.startsWith("session.") ||
        event.type.startsWith("permission.") ||
        event.type === "file.edited"
      ) {
        await appendJsonl("session_events.jsonl", {
          type: event.type,
          sessionID: sessionId,
          file: event.file || event.path
        })
        // Rotate if over threshold
        await rotateSessionEvents()
      }
    },

    "session.compacted": async (_input, output) => {
      // Rotate session_events BEFORE injecting memory (keeps context lean for compaction)
      await rotateSessionEvents()

      // Inject memory into compacted session context
      const fs = await import("node:fs/promises")
      const path2 = await import("node:path")
      const CONFIG = CONFIG_ROOT
      
      async function readIfExists(name) {
        try {
          const p = path2.join(MEMORY_DIR, name)
          const stat = await fs.stat(p)
          if (!stat.size) return ""
          return await fs.readFile(p, "utf8")
        } catch { return "" }
      }

      const memory = await readIfExists("MEMORY.md")
      const active = await readIfExists("project_active.md")
      const lessons = await readIfExists("lessons_learned.md")

      if (Array.isArray(output.context)) {
        output.context.push(
          `## Persistent OpenCode Memory\n\n${(memory || "").slice(0, 4000)}\n` +
          `## Active Project Memory\n\n${(active || "").slice(0, 3000)}\n` +
          `## Recent Lessons\n\n${(lessons || "").slice(-3000)}`
        )
      } else if (typeof output.context === "string") {
        output.context += "\n" +
          `## Persistent OpenCode Memory\n\n${(memory || "").slice(0, 4000)}\n` +
          `## Active Project Memory\n\n${(active || "").slice(0, 3000)}\n` +
          `## Recent Lessons\n\n${(lessons || "").slice(-3000)}`
      }
      // If neither array nor string, skip silently
      await log("session.compacted: injected memory + rotated events")
    },
  }
}

// â”€â”€ Module-level check â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const _MOD_CHECK = path.join(GATE_ROOT, ".memory-bridge-load.txt")
try { appendFile(_MOD_CHECK, `memory-bridge loaded ${new Date().toISOString()}\n`) } catch {}