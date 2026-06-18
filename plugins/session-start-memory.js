import { execFile } from "node:child_process"
import { promisify } from "node:util"
import { appendFile, mkdir, access, writeFile } from "node:fs/promises"
import path from "node:path"

const execFileP = promisify(execFile)

const CONFIG_ROOT = process.env.OPENCODE_CONFIG_HOME
  || process.env.OPENCODE_CONFIG
  || path.join(process.env.USERPROFILE || process.env.HOME || "", ".config", "opencode")

const PYTHON_SCRIPT = path.join(CONFIG_ROOT, "factory", "hooks", "session_start.py")
const MEMORY_DIR    = path.join(CONFIG_ROOT, "memory")
const LOG_FILE      = path.join(MEMORY_DIR, "session-start-memory.log")
const MARKER_FILE   = path.join(CONFIG_ROOT, ".opencode", "gates", ".session-start-memory.done")
const GATE_ROOT     = path.join(CONFIG_ROOT, ".opencode", "gates")

async function log(msg) {
  try {
    await mkdir(MEMORY_DIR, { recursive: true })
    await appendFile(LOG_FILE, `${new Date().toISOString()} [ssm] ${msg}\n`, "utf8")
  } catch {}
}

async function markerExists() {
  try {
    await access(MARKER_FILE)
    return true
  } catch {
    return false
  }
}

async function createMarker() {
  try {
    await mkdir(path.dirname(MARKER_FILE), { recursive: true })
    await writeFile(MARKER_FILE, new Date().toISOString(), "utf8")
  } catch {}
}

async function runSessionStart() {
  if (await markerExists()) {
    await log("skipping: marker exists")
    return
  }

  await createMarker()
  await log("session.idle detected, launching session_start.py")

  const PYTHON_CMDS = ["python", "python3", "python.exe"]
  for (const pythonCmd of PYTHON_CMDS) {
    try {
      const { stdout, stderr } = await execFileP(pythonCmd, [PYTHON_SCRIPT], {
        timeout: 30000,
        windowsHide: true,
      })
      await log(`OK stdout=${stdout.slice(0, 80)} stderr=${stderr.slice(0, 80)}`)
      return
    } catch (e) {
      await log(`try ${pythonCmd} failed: ${e.message.slice(0, 80)}`)
    }
  }
  await log("ERROR: no python found")
}

let lastActivityMs = Date.now()
const FORCE_IDLE_MS = 90000
const CHECK_INTERVAL_MS = 30000

export const SessionStartMemory = async () => {
  await log("SessionStartMemory plugin loaded")

  // Forced-idle fallback: if no event activity for 90s, fire anyway
  setInterval(async () => {
    const idleMs = Date.now() - lastActivityMs
    if (idleMs >= FORCE_IDLE_MS) {
      lastActivityMs = Date.now()
      await log(`forced-idle fallback (${idleMs}ms since last activity)`)
      try {
        await runSessionStart()
      } catch (e) {
        await log(`ERROR forced-idle: ${e.message.slice(0, 80)}`)
      }
    }
  }, CHECK_INTERVAL_MS).unref()

  return {
    event: async ({ event }) => {
      // Reset activity timer on ANY event
      lastActivityMs = Date.now()
      if (event?.type !== "session.idle") return
      try {
        await runSessionStart()
      } catch (e) {
        await log(`ERROR: ${e.message.slice(0, 80)}`)
      }
    },
  }
}
