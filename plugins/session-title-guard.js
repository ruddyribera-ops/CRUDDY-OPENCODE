// session-title-guard.js
// T0 Session Auto-Naming Plugin
//
// Hooks message.updated events to detect the first meaningful exchange.
// When user sends first task → capture content
// When assistant responds → derive session name via session_machine.ps1 T0
//
// Runs once per session. Uses session.yaml marker to prevent re-runs.

import { existsSync, readFileSync, writeFileSync, appendFileSync, mkdirSync } from "node:fs"
import path from "node:path"

const CONFIG_ROOT = process.env.OPENCODE_CONFIG_HOME
  || process.env.OPENCODE_CONFIG
  || path.join(process.env.USERPROFILE || process.env.HOME || "", ".config", "opencode")

const MEMORY_DIR  = path.join(CONFIG_ROOT, "memory")
const SESSION_YAML = path.join(MEMORY_DIR, "session.yaml")
const SM_SCRIPT   = path.join(CONFIG_ROOT, "scripts", "session_machine.ps1")
const MARKER_FILE = path.join(CONFIG_ROOT, "gates", ".session-title-guard.done")

const TITLE_MAX = 48

function safeReadFile(p) {
  try { return readFileSync(p, "utf8") } catch { return null }
}

function safeWriteFile(p, content) {
  try {
    mkdirSync(path.dirname(p), { recursive: true })
    writeFileSync(p, content, "utf8")
    return true
  } catch { return false }
}

// Escape for YAML string value
function yamlEscape(str) {
  return str.replace(/"/g, '\\"').slice(0, TITLE_MAX)
}

// Derive a clean session name from first user message
function deriveTitle(firstMessage) {
  if (!firstMessage) return null

  // Strip common prefixes
  let text = firstMessage
    .replace(/^(Load and execute:|Run:|Execute:|Start:|Begin:)\s*/i, "")
    .replace(/^[\s\-\*]+/, "")
    .trim()

  // Remove file paths, URLs, code blocks
  text = text.replace(/`[^`]*`/g, "").replace(/\$[^ ]*/g, "").replace(/https?:\/\/\S+/g, "").trim()

  if (!text || text.length < 4) return null
  if (text.length > TITLE_MAX) text = text.slice(0, TITLE_MAX - 3) + "..."

  return text
}

// Call session_machine.ps1 T0 with the derived name
// H5 fix: use execFile with args array — no string concatenation = no command injection
function invokeT0(sessionName) {
  try {
    const { execFileSync: exec } = require("child_process")
    const ps1Path = SM_SCRIPT
    const args = [
      "-NoProfile",
      "-ExecutionPolicy", "Bypass",
      "-File", ps1Path,
      "-Trigger", "T0",
      "-TaskName", sessionName
    ]
    exec("powershell.exe", args, { encoding: "utf8", timeout: 10000, windowsHide: true })
    return true
  } catch { return false }
}

// Check if session already has a descriptive name (not default "Session YYYY-MM-DD")
function isSessionAlreadyNamed() {
  try {
    const content = safeReadFile(SESSION_YAML)
    if (!content) return false
    // If session_name exists and is NOT the default pattern, it's named
    return /session_name:\s*"Session \d{4}-\d{2}-\d{2}/.test(content) === false
      && /session_name:\s*"/.test(content)
  } catch { return false }
}

export const SessionTitleGuard = async () => {
  let firstUserMessage = null
  let guardActive = false

  // Read session.yaml to see if this session already has a name
  const alreadyNamed = isSessionAlreadyNamed()

  if (!alreadyNamed && !existsSync(MARKER_FILE)) {
    guardActive = true
  }

  return {
    // Track session start
    "event": async ({ event }) => {
      if (!guardActive) return

      if (event?.type === "session.status") {
        // Session just started — record that we're tracking
        return
      }

      // First user message → capture the task
      if (event?.type === "message.updated" && guardActive) {
        const props = event.properties || event
        const info = props?.info || {}

        // User role = first task content
        if (info?.role === "user" && !firstUserMessage) {
          const content = info?.content || info?.message?.content || ""
          if (content && content.trim().length > 3) {
            firstUserMessage = content.trim()
          }
        }

        // Assistant role after user message → derive name and fire T0
        if (info?.role === "assistant" && firstUserMessage && !existsSync(MARKER_FILE)) {
          const derived = deriveTitle(firstUserMessage)
          if (derived) {
            const ok = invokeT0(derived)
            if (ok) {
              // Write marker so we don't re-run
              safeWriteFile(MARKER_FILE, `session named: ${derived}\n`)
            }
          }
          guardActive = false  // done
        }
      }
    }
  }
}