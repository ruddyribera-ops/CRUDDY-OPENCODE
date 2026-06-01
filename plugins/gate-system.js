// gate-system.js
// OpenCode v1.15.13 plugin: retro-analyze trigger + DNA.yaml validation
// Wires gate scripts into OpenCode's hook system, replacing manual triggers.
//
// Hooks:
//   shell.env              - inject GATE_ROOT, DNA_PATH into subshells
//   command.execute.before - count bash commands, trigger retro-analyze every 10
//   tool.execute.before    - validate DNA.yaml on read/edit access
//
// Exports: GateSystem plugin (matches @opencode-ai/plugin pattern)

import { existsSync, readFileSync, writeFileSync, renameSync, mkdirSync, unlinkSync, openSync, closeSync, statSync, appendFileSync } from "node:fs"
import { promisify } from "node:util"
import { execFile } from "node:child_process"
import path from "node:path"
import { fileURLToPath } from "node:url"
import yaml from "js-yaml"
import { z } from "zod"

const execFileP = promisify(execFile)

// ── Paths ────────────────────────────────────────────────────────
const CONFIG_ROOT = process.env.OPENCODE_CONFIG_HOME
  || process.env.OPENCODE_CONFIG
  || path.join(process.env.USERPROFILE || process.env.HOME || "", ".config", "opencode")

const GATE_ROOT = path.join(CONFIG_ROOT, "gates")
const DNA_PATH = path.join(CONFIG_ROOT, "skills", "DNA.yaml")
const COUNTER_PATH = path.join(GATE_ROOT, ".task-counter.json")
const LOCK_PATH = `${DNA_PATH}.lock`
const RETRO_SCRIPT = path.join(CONFIG_ROOT, "scripts", "gate", "retro-analyze.ps1")
const AUTO_MEMORY_SCRIPT = path.join(CONFIG_ROOT, "scripts", "auto-memory.ps1")
const TASK_BUFFER_PATH = path.join(GATE_ROOT, ".task-buffer.jsonl")
const TASK_THRESHOLD = 10  // trigger retro-analyze every N tasks
const AUTO_MEMORY_EVERY = 3  // flush auto-memory every N commands

// ── Auto-memory task buffer ──────────────────────────────────────
let taskBuffer = []
let flushInProgress = false

function bufferTask(command) {
  const taskName = command.slice(0, 80).replace(/["'`]/g, "").trim() || "unknown"
  const agent = command.match(/\.(ps1|py|js|ts)\b/) ? "script" : "bash"
  taskBuffer.push({
    ts: new Date().toISOString(),
    taskName,
    agent,
    command: command.slice(0, 200)
  })
}

async function flushAutoMemory() {
  if (flushInProgress || taskBuffer.length === 0) return
  flushInProgress = true
  const tasks = taskBuffer.splice(0)
  try {
    // Write buffer to disk for persistence
    mkdirSync(GATE_ROOT, { recursive: true })
    // Call auto-memory with a summary entry
    const summary = tasks.map(t => t.taskName).join("; ")
    await execFileP("powershell.exe", [
      "-NoProfile", "-File", AUTO_MEMORY_SCRIPT,
      "-TaskName", `"batch: ${summary.slice(0, 100)}"`,
      "-Agent", "gate-system",
      "-Result", "tracked",
      "-TokensEst", "~0"
    ], { timeout: 15000, windowsHide: true })
  } catch (e) {
    // Non-fatal: auto-memory failures shouldn't block commands
    console.warn(`[gate-system] auto-memory flush failed: ${e.message.slice(0, 100)}`)
  } finally {
    flushInProgress = false
  }
}

// ── Zod schema for DNA.yaml ──────────────────────────────────────
const GeneSchema = z.object({
  id: z.string().regex(/^[A-Z]+(-AUTO)?-\d{3}$/, "Gene ID must match FAMILY-NNN format"),
  name: z.string().min(1),
  description: z.string().min(1),
  triggers: z.array(z.string()).min(1),
  auto_generated: z.boolean().optional(),
  auto_approved: z.boolean().optional(),
  auto_rejected: z.boolean().optional(),
  auto_date: z.string().optional(),
  auto_reason: z.string().optional(),
  approved_date: z.string().optional(),
  rejected_date: z.string().optional(),
}).passthrough()

const DnaSchema = z.object({
  version: z.string().regex(/^\d+\.\d+\.\d+$/, "Version must be semver"),
  generated: z.union([z.string(), z.date()]).optional(),
  genes: z.array(GeneSchema),
}).passthrough()

// ── Task counter ────────────────────────────────────────────────
function readCounter() {
  try {
    if (!existsSync(COUNTER_PATH)) return { count: 0, last: null }
    return JSON.parse(readFileSync(COUNTER_PATH, "utf8"))
  } catch {
    return { count: 0, last: null }
  }
}

function incrementCounter() {
  mkdirSync(GATE_ROOT, { recursive: true })
  const current = readCounter()
  const next = {
    count: (current.count || 0) + 1,
    last: new Date().toISOString()
  }
  // Atomic write: write to temp, rename
  const tmp = `${COUNTER_PATH}.tmp.${process.pid}`
  writeFileSync(tmp, JSON.stringify(next))
  renameSync(tmp, COUNTER_PATH)
  return next.count
}

function shouldTriggerRetro(count) {
  return count > 0 && count % TASK_THRESHOLD === 0
}

// ── DNA.yaml validation ─────────────────────────────────────────
let lastValidation = { ok: true, errors: [], ts: 0, mtime: 0 }

function loadDnaSafe() {
  try {
    if (!existsSync(DNA_PATH)) return null
    return yaml.load(readFileSync(DNA_PATH, "utf8"))
  } catch (e) {
    return { __parseError: e.message }
  }
}

function getDnaMtime() {
  try {
    if (!existsSync(DNA_PATH)) return 0
    return statSync(DNA_PATH).mtimeMs
  } catch {
    return 0
  }
}

function validateDna() {
  // Cache invalidation: if file mtime changed, re-validate
  const currentMtime = getDnaMtime()
  const now = Date.now()
  if (lastValidation.mtime === currentMtime && (now - lastValidation.ts < 60000)) {
    return lastValidation
  }

  const data = loadDnaSafe()
  if (!data) {
    lastValidation = { ok: true, errors: [], ts: now, mtime: currentMtime, message: "DNA.yaml not found (skipped)" }
    return lastValidation
  }
  if (data.__parseError) {
    lastValidation = { ok: false, errors: [data.__parseError], ts: now, mtime: currentMtime }
    return lastValidation
  }
  const result = DnaSchema.safeParse(data)
  if (result.success) {
    lastValidation = { ok: true, errors: [], ts: now, mtime: currentMtime, geneCount: result.data.genes.length }
    return lastValidation
  }
  lastValidation = {
    ok: false,
    errors: result.error.errors.map(e => `${e.path.join(".")}: ${e.message}`),
    ts: now,
    mtime: currentMtime
  }
  return lastValidation
}

// ── Lockfile (advisory, cross-process) ───────────────────────────
async function withLock(fn, timeoutMs = 5000) {
  const start = Date.now()
  while (Date.now() - start < timeoutMs) {
    try {
      // wx flag = exclusive create, fails if exists
      const fd = openSync(LOCK_PATH, "wx")
      closeSync(fd)
      try {
        return await fn()
      } finally {
        try { unlinkSync(LOCK_PATH) } catch {}
      }
    } catch (e) {
      if (e.code === "EEXIST") {
        await new Promise(r => setTimeout(r, 100))
        continue
      }
      throw e
    }
  }
  throw new Error(`Lock acquisition timeout: ${LOCK_PATH}`)
}

// ── Retro-analyze trigger ───────────────────────────────────────
async function runRetroAnalyze() {
  if (!existsSync(RETRO_SCRIPT)) {
    console.warn(`[gate-system] retro-analyze.ps1 not found at ${RETRO_SCRIPT}`)
    return { code: -1, message: "script not found" }
  }
  try {
    const { stdout, stderr } = await execFileP("powershell.exe", [
      "-NoProfile", "-File", RETRO_SCRIPT,
      "-TaskCount", String(TASK_THRESHOLD),
      "-WriteGenes"
    ], { timeout: 30000 })
    const code = stdout.includes("[GENES WRITTEN]") ? 2 : 0
    if (code === 2) {
      console.log(`[gate-system] Genes written. Evolution-agent will review.`)
    }
    return { code, stdout, stderr }
  } catch (e) {
    // execFile throws on non-zero exit
    const code = e.code || 0
    const stdout = e.stdout || ""
    if (stdout.includes("[GENES WRITTEN]")) {
      console.log(`[gate-system] Genes written (exit ${code}). Evolution-agent will review.`)
      return { code: 2, stdout, stderr: e.stderr }
    }
    console.warn(`[gate-system] retro-analyze failed: ${e.message}`)
    return { code, message: e.message }
  }
}

// ── Plugin export ────────────────────────────────────────────────
export const GateSystem = async () => {
  return {
    // Inject CONFIG paths into every subshell
    "shell.env": async (_input, output) => {
      output.env.OPENCODE_GATE_ROOT = GATE_ROOT
      output.env.OPENCODE_DNA_PATH = DNA_PATH
      output.env.OPENCODE_CONFIG_HOME = CONFIG_ROOT
    },

    // Count bash commands as task proxy. Every 10 -> trigger retro-analyze.
    "command.execute.before": async (input, _output) => {
      // Skip self-trigger: don't count when retro-analyze.ps1 or auto-memory is running
      if (input.command && (
        input.command.includes("retro-analyze.ps1") ||
        input.command.includes("auto-memory.ps1") ||
        input.command.includes("gate-system") ||
        input.command.includes("track-tokens")
      )) return

      const count = incrementCounter()

      // Buffer task for auto-memory
      bufferTask(input.command || "unknown")

      // Flush auto-memory every AUTO_MEMORY_EVERY commands (async, non-blocking)
      if (count % AUTO_MEMORY_EVERY === 0) {
        flushAutoMemory().catch(() => {})
      }

      if (shouldTriggerRetro(count)) {
        console.log(`[gate-system] Task ${count} reached threshold. Triggering retro-analyze...`)
        // Run async, don't block the command
        runRetroAnalyze().catch(err => {
          console.warn(`[gate-system] retro-analyze async error: ${err.message}`)
        })
      }
    },

    // Validate DNA.yaml before any read/edit access
    "tool.execute.before": async (input, _output) => {
      if (input.tool !== "read" && input.tool !== "edit") return

      // Check if the file path is DNA.yaml
      const filePath = input.args?.filePath || input.args?.path || ""
      if (!filePath.endsWith("DNA.yaml")) return

      const result = validateDna()
      if (!result.ok) {
        console.warn(`[gate-system] DNA.yaml validation FAILED:`)
        for (const err of result.errors) {
          console.warn(`  - ${err}`)
        }
        // Don't block the read (user might be fixing the issue),
        // but warn loudly so they see it.
      } else if (result.geneCount) {
        console.log(`[gate-system] DNA.yaml valid: ${result.geneCount} genes`)
      }
    }
  }
}

// ── Exports for testing ─────────────────────────────────────────
export {
  CONFIG_ROOT, GATE_ROOT, DNA_PATH, COUNTER_PATH, LOCK_PATH,
  GeneSchema, DnaSchema,
  readCounter, incrementCounter, shouldTriggerRetro,
  loadDnaSafe, validateDna, withLock,
  runRetroAnalyze
}
