import { readFile, writeFile, mkdir, appendFile } from "node:fs/promises"
import path from "node:path"

const CONFIG_ROOT = path.resolve(process.env.OPENCODE_CONFIG_HOME || process.env.OPENCODE_CONFIG || path.join(process.env.USERPROFILE || "", ".config", "opencode"))
const MEMORY_DIR = path.join(CONFIG_ROOT, "memory")
const SESSION_YAML = path.join(MEMORY_DIR, "session.yaml")
const BAD_TITLE = /^(new session|untitled|session.*|opencode|fix auto-naming pipeline)$/i

function cleanTitle(text) {
  const raw = String(text || "")
    .replace(/```[\s\S]*?```/g, " ")
    .replace(/[^\p{L}\p{N}\s:_-]/gu, " ")
    .replace(/\s+/g, " ")
    .trim()
  if (!raw) return ""
  const words = raw.split(" ").slice(0, 8).join(" ")
  return words.length > 72 ? words.slice(0, 69).trim() + "..." : words
}

async function appendJsonl(name, payload) {
  await mkdir(MEMORY_DIR, { recursive: true })
  await appendFile(path.join(MEMORY_DIR, name), JSON.stringify({ ts: new Date().toISOString(), ...payload }) + "\n")
}

async function mirrorSessionTitle(title) {
  await mkdir(MEMORY_DIR, { recursive: true })
  let current = ""
  try {
    current = await readFile(SESSION_YAML, "utf8")
  } catch {}
  if (/^session_name:/m.test(current)) {
    current = current.replace(/^session_name:.*$/m, `session_name: "${title.replace(/"/g, "'")}"`)
  } else {
    current = `session_name: "${title.replace(/"/g, "'")}"\n` + current
  }
  await writeFile(SESSION_YAML, current)
}

async function listMessages(client, sessionID) {
  const candidates = [
    () => client.session.messages({ path: { id: sessionID }, query: { limit: 20 } }),
    () => client.session.message.list({ path: { id: sessionID }, query: { limit: 20 } }),
    () => client.session.message({ path: { id: sessionID }, query: { limit: 20 } }),
  ]
  for (const call of candidates) {
    try {
      const result = await call()
      if (Array.isArray(result)) return result
      if (Array.isArray(result?.data)) return result.data
    } catch {}
  }
  return []
}

function firstUserText(messages) {
  for (const msg of messages) {
    const role = msg?.info?.role || msg?.role
    if (role && role !== "user") continue
    const parts = msg?.parts || msg?.content || []
    if (typeof parts === "string") return parts
    for (const part of parts) {
      const text = part?.text || part?.content || part?.body
      if (text) return text
    }
  }
  return ""
}

async function patchTitle(client, sessionID, title) {
  const calls = [
    () => client.session.update({ path: { id: sessionID }, body: { title } }),
    () => client.session.patch({ path: { id: sessionID }, body: { title } }),
    () => client.session.update({ id: sessionID, title }),
  ]
  for (const call of calls) {
    try {
      await call()
      return true
    } catch {}
  }
  return false
}


async function fireT1() {
    // Trigger hook-startup.ps1 T1 to reset session.yaml
    const { execSync } = await import("node:child_process")
    const hookScript = path.join(CONFIG_ROOT, "scripts", "hooks", "hook-startup.ps1")
    try {
        execSync(`powershell -File "${hookScript}" 2>&1`, { timeout: 10000, windowsHide: true })
    } catch {}
}
export const SessionTitleGuard = async ({ client }) => {
  return {
    event: async ({ event }) => {
      if (!["session.created", "session.updated", "session.idle"].includes(event?.type)) return
      // Fire T1 on session.created to reset session.yaml
      if (event.type === "session.created") { await fireT1() }
      const session = event.session || event.properties?.session || event
      const sessionID = session.id || session.sessionID || event.sessionID
      const currentTitle = session.title || ""
      if (!sessionID || (currentTitle && !BAD_TITLE.test(currentTitle))) return

      const messages = await listMessages(client, sessionID)
      let fallback = cleanTitle(firstUserText(messages))
      if (!fallback) {
        const cwd = process.cwd() || "session"
        const project = cwd.split(/[/\\]/).pop() || "session"
        fallback = project
      }

      const patched = await patchTitle(client, sessionID, fallback)
      await mirrorSessionTitle(fallback)
      await appendJsonl("session_title_guard.jsonl", { sessionID, oldTitle: currentTitle, newTitle: fallback, patched })
    },
  }
}



