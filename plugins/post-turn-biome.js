// post-turn-biome.js
// OpenCode Go plugin: runs Biome on modified files after agent completes a turn
// Hooks: tool.execute.after (track edits) + session.idle (run biome)
//
// All logging goes to memory/biome-check.log only — never to CLI stdout
// to avoid cluttering the interactive interface.

import { existsSync, readFileSync, writeFileSync, mkdirSync, appendFileSync } from "node:fs"
import { execFile } from "node:child_process"
import path from "node:path"

const execFileP = (cmd, args) => new Promise((resolve, reject) => {
  execFile(cmd, args, { timeout: 30000, windowsHide: true }, (err, stdout, stderr) => {
    if (err) reject(err)
    else resolve({ stdout, stderr })
  })
})

// ── Paths ────────────────────────────────────────────────────────
const CONFIG_ROOT = process.env.OPENCODE_CONFIG_HOME
  || process.env.OPENCODE_CONFIG
  || path.join(process.env.USERPROFILE || process.env.HOME || "", ".config", "opencode")

const BIOME_JSON = path.join(CONFIG_ROOT, "biome.json")
const CHECK_LOG = path.join(CONFIG_ROOT, "memory", "biome-check.log")

// ── Config ────────────────────────────────────────────────────────
const EDIT_TOOLS = new Set([
  "write", "edit", "replace_content", "replace_symbol_body",
  "insert_after_symbol", "insert_before_symbol", "rename_symbol",
  "create_text_file"
])

const COOLDOWN_MS = 20_000  // 20 seconds between biome runs
const MAX_FILES_PER_RUN = 50

// ── State ─────────────────────────────────────────────────────────
let editedFiles = new Set()
let lastRunAt = 0
let pendingCheck = false

// ── Helpers ──────────────────────────────────────────────────────
// All output goes to CHECK_LOG only — silent on CLI
function log(msg) {
  const line = `[post-turn-biome] ${new Date().toISOString().slice(11,19)} ${msg}`
  try {
    mkdirSync(path.dirname(CHECK_LOG), { recursive: true })
    appendFileSync(CHECK_LOG, line + "\n")
  } catch {}
}

// Deduplicate + filter non-code files
function extractFiles(args) {
  if (!args) return []

  const files = []
  if (args.filePath && typeof args.filePath === "string") {
    files.push(args.filePath)
  }
  if (args.path && typeof args.path === "string") {
    files.push(args.path)
  }
  if (Array.isArray(args.files)) {
    for (const f of args.files) {
      if (typeof f === "string") files.push(f)
    }
  }

  // Deduplicate then filter out non-code files
  return [...new Set(files)].filter(f =>
    f.length > 0 &&
    !f.includes(".md") &&
    !f.includes("package-lock")
  )
}

async function runBiomeCheck(projectDir) {
  const now = Date.now()
  if (now - lastRunAt < COOLDOWN_MS) {
    log("Cooldown active, skipping.")
    return null
  }
  if (editedFiles.size === 0) {
    log("No files tracked, skipping.")
    return null
  }

  lastRunAt = now
  const files = Array.from(editedFiles).slice(0, MAX_FILES_PER_RUN)
  editedFiles.clear()

  log(`Running biome on ${files.length} file(s)`)

  try {
    const result = await execFileP("pwsh.exe", [
      "-NoProfile", "-Command",
      `& biome check --write --config-path "${BIOME_JSON}" ${files.map(f => `"${f}"`).join(" ")}`
    ])

    const output = [result.stdout, result.stderr].filter(Boolean).join("\n").trim()
    if (output) {
      log(`Biome output: ${output.slice(0, 200)}`)
      return output
    }
    log("Biome: no issues found.")
    return null
  } catch (err) {
    // Biome exits non-zero when lint errors found — that's expected
    if (err.code === 1 || err.code === 2) {
      const output = err.stdout || err.stderr || ""
      log(`Biome found issues (exit ${err.code}): ${output.slice(0, 200)}`)
      return output
    }
    log(`Biome error: ${err.message.slice(0, 100)}`)
    return null
  }
}

// ── Plugin ────────────────────────────────────────────────────────
export const PostTurnBiome = async ({ project, client, $, directory }) => {
  log(`Initialized. Project: ${directory || "unknown"}`)

  return {
    // Track file modifications
    "tool.execute.after": async (input, output) => {
      if (!EDIT_TOOLS.has(input.tool)) return

      const files = extractFiles(input.args)
      for (const f of files) {
        editedFiles.add(f)
      }

      if (files.length > 0) {
        log(`Tracked ${files.length} file(s) from ${input.tool}`)
      }
    },

    // Run biome when session goes idle
    "session.idle": async ({ properties }) => {
      if (editedFiles.size === 0) return

      const sessionId = properties?.sessionID || "unknown"
      log(`Session idle. Running biome check for session ${sessionId}...`)

      const output = await runBiomeCheck(directory)

      if (output && client?.session?.prompt) {
        const message = `
Post-turn biome check completed.

--- BEGIN BIOME OUTPUT ---
${output.slice(0, 1500)}
--- END BIOME OUTPUT ---

If there are errors, fix them. If something's unclear, ask.
`.trim()

        try {
          await client.session.prompt({
            path: { id: sessionId },
            body: { parts: [{ type: "text", text: message }] }
          })
          log("Biome output sent to agent.")
        } catch (e) {
          log(`Failed to send biome output to agent: ${e.message.slice(0, 100)}`)
        }
      }

      pendingCheck = false
    }
  }
}
