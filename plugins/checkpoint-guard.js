// checkpoint-guard.js
// OpenCode plugin: auto-save task state to survive laptop crashes and long sessions.
//
// Triggers:
//   - tool.execute.before on `task`           -> checkpoint pre-state
//   - tool.execute.after  on `task`           -> checkpoint post-state with result
//   - tool.execute.before on `bash`           -> checkpoint if command modifies state
//   - Every 5 minutes of activity (interval)  -> checkpoint current session
//
// Storage: delegates to scripts/checkpoint.ps1 via execFile.
// Logs to memory/gate-system.log via `[checkpoint-guard] HH:MM:SS <event>` lines.
//
// Runtime notes:
//   - The 5-minute "interval" is checked lazily inside tool.execute.before
//     (no setInterval), so it survives plugin reloading and never fires when idle.
//   - `tool.execute.after` is a documented OpenCode hook; in some runtimes it has
//     historically not fired (see gate-system.js). Pre-task checkpoints still
//     cover survival even when post-task does not fire.
//   - The `Files` list passed to checkpoint.ps1 is currently always empty;
//     a "last-3-modifications" tracker can be added later by reading mtimes
//     from a small JSON ledger on disk.

import { execFile } from "node:child_process"
import { promisify } from "node:util"
import { appendFile, mkdir } from "node:fs/promises"
import path from "node:path"

const execFileP = promisify(execFile)

const CONFIG_ROOT = process.env.OPENCODE_CONFIG_HOME
  || process.env.OPENCODE_CONFIG
  || path.join(process.env.USERPROFILE || process.env.HOME || "", ".config", "opencode")

const MEMORY_DIR = path.join(CONFIG_ROOT, "memory")
const GATE_LOG = path.join(MEMORY_DIR, "gate-system.log")
const CHECKPOINT_SCRIPT = path.join(CONFIG_ROOT, "scripts", "checkpoint.ps1")

const CHECKPOINT_INTERVAL_MS = 5 * 60 * 1000

// Bash commands / PowerShell cmdlets / redirection operators that change filesystem state.
const MODIFYING_BASH_PATTERNS = /\b(rm|mv|cp|write|edit|delete|move|copy|Set-Content|Remove-Item|Move-Item|Copy-Item|New-Item)\b|>>?|<\s*</i

let lastCheckpoint = 0

async function log(msg) {
  try {
    await mkdir(MEMORY_DIR, { recursive: true })
    await appendFile(
      GATE_LOG,
      `[checkpoint-guard] ${new Date().toISOString().slice(11, 19)} ${msg}\n`,
      "utf8",
    )
  } catch {
    // Logging failure is non-fatal — do not crash the plugin.
  }
}

async function doCheckpoint(taskId, description, files, nextAction, progress) {
  try {
    await execFileP(
      "powershell.exe",
      [
        "-NoProfile",
        "-File",
        CHECKPOINT_SCRIPT,
        "-TaskId", taskId,
        "-Description", description,
        "-Files", files.join(","),
        "-NextAction", nextAction,
        "-ProgressPercent", String(progress),
      ],
      { timeout: 10000, windowsHide: true },
    )
    await log(`CHECKPOINT taskId=${taskId} progress=${progress}%`)
  } catch (e) {
    await log(`CHECKPOINT_FAIL ${(e && e.message ? e.message : String(e)).slice(0, 60)}`)
  }
}

export const CheckpointGuard = async () => {
  return {
    "tool.execute.before": async (input, _output) => {
      const now = Date.now()

      if (now - lastCheckpoint >= CHECKPOINT_INTERVAL_MS) {
        await doCheckpoint("interval", "5min auto-checkpoint", [], "continue", 50)
        lastCheckpoint = now
      }

      if (input.tool === "task") {
        const prompt = input.tool_call?.args?.prompt
          || input.tool_call?.args?.description
          || "task"
        await doCheckpoint("pre-task", `Starting: ${String(prompt).slice(0, 80)}`, [], "task in progress", 30)
      }

      if (input.tool === "bash") {
        const cmd = String(
          input.tool_call?.args?.command
          || input.tool_call?.args?.cmd
          || "",
        )
        if (MODIFYING_BASH_PATTERNS.test(cmd)) {
          await doCheckpoint("pre-bash-modify", `Bash will modify: ${cmd.slice(0, 60)}`, [], "bash modifying", 40)
        }
      }
    },

    "tool.execute.after": async (input, output) => {
      if (input.tool === "task") {
        const result = String(output?.output || "").slice(0, 60)
        await doCheckpoint("post-task", `Completed: ${result}`, [], "awaiting next", 70)
      }
    },
  }
}
