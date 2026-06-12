// post-tool-guard.js
// Plugin-based post-tool enforcement (replaces scripts/hooks/post-tool-check.ps1)
//
// Hooks: tool.execute.after
// Runs: eslint/biome on file edits, format verification, injection detection
//
// Usage: OpenCode auto-loads this plugin via opencode.json plugin array.
// No manual wiring needed — runs on every tool call automatically.
//
// Research sources:
// - Dwarves Foundation PostToolUse hook for injection scanning
// - Steve Kinney "Guardrails" (Apr 2026)

import { existsSync } from "node:fs"
import { execSync } from "node:child_process"
import path from "node:path"
import { gateLog } from "./_shared.js"

const CONFIG_ROOT = process.env.OPENCODE_CONFIG_HOME
  || process.env.OPENCODE_CONFIG
  || path.join(process.env.USERPROFILE || process.env.HOME || "", ".config", "opencode")

const log = (msg) => gateLog("post-tool-guard", msg)

function runSilent(cmd, timeout = 15000) {
  try {
    return execSync(cmd, { encoding: "utf8", timeout, windowsHide: true })
  } catch (e) {
    // Non-fatal: lint tools may not be installed. Return null, caller handles.
    return null
  }
}

function getFileExt(filepath) {
  const match = filepath.match(/\.[^.]+$/)
  return match ? match[0].toLowerCase() : ""
}

// ── Linters ─────────────────────────────────────────────────────────────────
// BiomesFirst pattern: if biome.json exists, defer formatting/linting to post-turn-biome.js
// (it's 20-50x faster and handles both lint + format in one tool).
// Legacy linters (eslint/prettier/ruff/black) only run when biome is NOT configured.
// This preserves project-specific eslint rules while letting fast projects use biome.
function biomeHasPriority(workDir) {
  return !!(findUp("biome.json", workDir))
}

function lintJSFile(filepath, workDir) {
  // If biome is configured, skip legacy linters (biome handles it faster)
  if (biomeHasPriority(workDir)) return null

  // eslint (if configured)
  const eslint = findUp(".eslintrc", workDir) || findUp(".eslintrc.js", workDir)
  if (eslint) {
    const out = runSilent(`npx eslint "${filepath}" --max-warnings 0`, 20000)
    if (out && out.includes("error")) {
      log(`lint error: ${filepath}`)
      return { level: "warn", msg: out.slice(0, 300) }
    }
  }

  // prettier check
  const prettier = findUp(".prettierrc", workDir) || findUp(".prettierrc.js", workDir)
  if (prettier) {
    const out = runSilent(`npx prettier --check "${filepath}"`)
    if (out && out.includes("fails")) {
      log(`format warning: ${filepath}`)
      return { level: "warn", msg: `Format check failed. Run: npx prettier --write "${filepath}"` }
    }
  }
  return null
}

function lintPythonFile(filepath, workDir) {
  // If biome is configured, skip legacy linters
  if (workDir && biomeHasPriority(workDir)) return null

  // ruff (if installed)
  try {
    const out = execSync(`ruff check "${filepath}"`, { encoding: "utf8", timeout: 10000, windowsHide: true })
    if (out && out.trim()) {
      log(`ruff warning: ${filepath}`)
      return { level: "warn", msg: out.slice(0, 300) }
    }
  } catch (e) {
    // Non-fatal: ruff may not be installed. Return null, caller handles.
  }

  // black check
  try {
    const out = execSync(`python -m black --check "${filepath}"`, { encoding: "utf8", timeout: 10000, windowsHide: true })
    if (out && out.includes("would reformat")) {
      log(`black warning: ${filepath}`)
      return { level: "warn", msg: `Format check failed. Run: python -m black "${filepath}"` }
    }
  } catch (e) {
    // Non-fatal: black may not be installed. Return null, caller handles.
  }
  return null
}

// Find file in parent directories (simplified)
function findUp(filename, startDir) {
  let dir = startDir
  for (let i = 0; i < 5; i++) {
    const candidate = path.join(dir, filename)
    if (existsSync(candidate)) return candidate
    const parent = path.dirname(dir)
    if (parent === dir) break
    dir = parent
  }
  return null
}

// ── Debounced lint queue (batch operations) ───────────────────────────────────
// Instead of running lint subprocesses on every Write/Edit (which is expensive
// when the user creates many files), we accumulate paths in a queue and run
// lint on the entire batch when:
//   (a) 5 seconds have passed since the last Write (idle debounce), OR
//   (b) session.idle fires (clean drain trigger)
// This can reduce 400 lint subprocesses per 100-file session to ~20-40.
const LINT_DEBOUNCE_MS = 5000
const pendingLintQueue = new Map()  // key=filepath, value={ext, workDir}

let lintDebounceTimer = null

function scheduleLint(filepath, workDir, ext) {
  // Dedupe — if same path is queued, just refresh its ext/workDir
  pendingLintQueue.set(filepath, { ext, workDir })

  // Reset debounce timer
  if (lintDebounceTimer) clearTimeout(lintDebounceTimer)
  lintDebounceTimer = setTimeout(() => {
    drainLintQueue("debounce-timer")
  }, LINT_DEBOUNCE_MS)
}

function drainLintQueue(trigger) {
  if (lintDebounceTimer) {
    clearTimeout(lintDebounceTimer)
    lintDebounceTimer = null
  }
  if (pendingLintQueue.size === 0) return

  // Snapshot the queue and clear it (drain semantics)
  const batch = Array.from(pendingLintQueue.entries())
  pendingLintQueue.clear()

  log(`lint batch drain: ${batch.length} files (trigger=${trigger})`)

  for (const [filepath, { ext, workDir }] of batch) {
    try {
      if (/^\.(ts|tsx|js|jsx)$/.test(ext)) {
        const result = lintJSFile(filepath, workDir)
        if (result?.level === "warn") {
          log(`post-tool warn: ${filepath}: ${result.msg.slice(0, 80)}`)
        }
      } else if (ext === ".py") {
        const result = lintPythonFile(filepath, workDir)
        if (result?.level === "warn") {
          log(`post-tool warn: ${filepath}: ${result.msg.slice(0, 80)}`)
        }
      }
    } catch (e) {
      // Per-file lint failure is non-fatal — log and continue with next file
      log(`lint error: ${filepath}: ${(e.message || "").slice(0, 80)}`)
    }
  }

  // check-rules.py: run agent rules on modified files (advisory, non-blocking)
  const codeFiles = batch.filter(([f, { ext }]) => /\.(py|ts|tsx|js|jsx|go|php)$/.test(ext))
  if (codeFiles.length > 0) {
    const filesArg = codeFiles.map(([f]) => f).join(" ")
    const rulesOut = runSilent(
      "python " + CONFIG_ROOT + "/scripts/check-rules.py check . --files " + filesArg,
      30000
    )
    if (rulesOut && rulesOut.includes("error")) {
      log("check-rules errors: " + rulesOut.slice(0, 200))
    }
  }
}

// ── Injection Detection (Dwarves Foundation approach) ─────────────────────────
// Scans file content for hidden instructions, encoded payloads, HTML smuggling
const INJECTION_PATTERNS = [
  // HTML comment smuggling (<!-- --> used to hide instructions)
  /<!--[\s\S]{50,}?-->/,
  // Zero-width / invisible unicode characters (steganography) — use literal chars
  /\u200b|\u200c|\u200d|\ufeff/i,
  // URL-encoded injection payloads
  /%3Cscript|%3Ciframe|%3Csvg|onerror\s*=|onload\s*=/i,
  // Hidden elements (CSS display:none, visibility:hidden)
  /display\s*:\s*none|visibility\s*:\s*hidden|opacity\s*:\s*0/i,
  // Base64 encoded command strings (eval(atob(...)) style)
  /eval\s*\(\s*atob\s*\(|fromCharCode\s*\(\s*\d+.*\d+/i,
  // Prompt injection in file content
  /(?:ignore\s+(?:previous|above|all)\s+(?:instructions?|rules?))/i,
  /(?:disregard\s+(?:previous|above|all)\s+(?:instructions?|rules?))/i,
  /(?:you\s+are\s+(?:now\s+)?(?:free\s+to|allowed\s+to))\s+(?:ignore|bypass|skip)/i,
  // Encoded PowerShell/cmd payloads
  /powershell\s+-enc\s+[A-Za-z0-9+/=]{50,}/i,
  /cmd\s+\/c\s+[A-Za-z0-9+/=]{50,}/i,
]

function scanForInjection(content) {
  if (!content || typeof content !== "string") return false
  return INJECTION_PATTERNS.some(p => p.test(content))
}

function readFileContent(filepath) {
  try {
    const { readFileSync } = require("node:fs")
    return readFileSync(filepath, "utf8")
  } catch (e) {
    // Non-fatal: file may not be readable during scan. Return null.
    return null
  }
}

// ── Main guard ────────────────────────────────────────────────────────────────
export const PostToolGuard = async () => {
  return {
    "tool.execute.after": async (input, output) => {
      const { tool, args } = input
      const exitCode = output?.exit_code ?? 0

      // Only run on file modifications
      if (!["Write", "Edit"].includes(tool)) return
      const filepath = args?.path || args?.filePath || ""
      if (!filepath) return

      const ext = getFileExt(filepath)
      const workDir = process.cwd()

      // Injection scan on file content — ALWAYS runs immediately (cheap regex)
      // because this is the security gate, not the perf bottleneck.
      const content = readFileContent(filepath)
      if (content && scanForInjection(content)) {
        log(`INJECTION DETECTED: ${filepath} contains hidden instruction pattern`)
        // Warn but don't block — could be legitimate code with string patterns
      }

      // Lint — DEBOUNCED. Schedule instead of running synchronously.
      // This batches multiple writes in a burst into a single lint pass.
      // Injection scan stays synchronous because security > performance.
      if (/^\.(ts|tsx|js|jsx)$/.test(ext) || ext === ".py") {
        scheduleLint(filepath, workDir, ext)
      }
    },

    // Drain lint queue when session goes idle (best-effort clean shutdown)
    "event": async ({ event }) => {
      if (event?.type === "session.idle" || event?.type === "session.deleted") {
        drainLintQueue(event.type)
      }
    },
  }
}