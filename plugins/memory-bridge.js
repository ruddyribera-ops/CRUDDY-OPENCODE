import { appendFile, mkdir, readFile } from "node:fs/promises"
import path from "node:path"

const CONFIG_ROOT = path.resolve(process.env.OPENCODE_CONFIG_HOME || process.env.OPENCODE_CONFIG || path.join(process.env.USERPROFILE || "", ".config", "opencode"))
const MEMORY_DIR = path.join(CONFIG_ROOT, "memory")
const SESSION_LOG = path.join(MEMORY_DIR, "session_log.md")

async function appendJsonl(name, payload) {
  await mkdir(MEMORY_DIR, { recursive: true })
  await appendFile(path.join(MEMORY_DIR, name), JSON.stringify({ ts: new Date().toISOString(), ...payload }) + "\n")
}

async function appendSessionLog(format, ...args) {
  await mkdir(MEMORY_DIR, { recursive: true })
  const ts = new Date().toISOString().split('T')[0]
  let entry = `[${ts}] ` + format
  for (let i = 0; i < args.length; i++) {
    entry = entry.replace(`{${i}}`, String(args[i]))
  }
  entry = entry + "\n"
  try {
    await appendFile(SESSION_LOG, entry)
  } catch {}
}

async function readIfExists(file) {
  try {
    return await readFile(path.join(MEMORY_DIR, file), "utf8")
  } catch {
    return ""
  }
}

export const MemoryBridge = async () => {
  return {
    "shell.env": async (_input, output) => {
      output.env.OPENCODE_CONFIG_HOME = CONFIG_ROOT
      output.env.OPENCODE_MEMORY_DIR = MEMORY_DIR
      output.env.OPENCODE_EXPERIMENTAL_LSP_TOOL = "true"
    },

    event: async ({ event }) => {
      if (!event?.type) return
      
      // Log session start/end to session_log.md
      const session = event.session || event.properties?.session || {}
      const title = session?.title || "untitled"
      
      if (event.type === "session.created") {
        await appendSessionLog("NEW SESSION: {0}", title)
      }
      else if (event.type === "session.idle") {
        const id = session?.id || event.sessionID || "?"
        await appendSessionLog("SESSION IDLE: {0} ({1})", title, id)
      }
      else if (event.type === "session.error") {
        await appendSessionLog("SESSION ERROR: {0}", title)
      }
      
      // Capture all events to session_events.jsonl
      if (event.type.startsWith("message.") || event.type.startsWith("session.") || event.type.startsWith("permission.") || event.type === "file.edited") {
        await appendJsonl("session_events.jsonl", { type: event.type, sessionID: event.sessionID || event.session?.id, file: event.file || event.path })
      }
    },

    "experimental.session.compacting": async (_input, output) => {
      const memory = await readIfExists("MEMORY.md")
      const active = await readIfExists("project_active.md")
      const lessons = await readIfExists("lessons_learned.md")
      output.context.push(`## Persistent OpenCode Memory\n\n${memory.slice(0, 4000)}\n\n## Active Project Memory\n\n${active.slice(0, 3000)}\n\n## Recent Lessons\n\n${lessons.slice(-3000)}`)
    },
  }
}
