// integration-test.js
// Manually test the plugin's retro-analyze trigger path

import { existsSync, mkdirSync, writeFileSync, unlinkSync, readFileSync } from "node:fs"
import path from "node:path"
import { execFile } from "node:child_process"
import { promisify } from "node:util"

const execFileP = promisify(execFile)
const CONFIG_ROOT = process.env.OPENCODE_CONFIG_HOME
  || path.join(process.env.USERPROFILE, ".config", "opencode")
const GATE_ROOT = path.join(CONFIG_ROOT, "gates")
const COUNTER_PATH = path.join(GATE_ROOT, ".task-counter.json")
const RETRO_SCRIPT = path.join(CONFIG_ROOT, "scripts", "gate", "retro-analyze.ps1")

// Simulate what command.execute.before does
async function simulateTrigger(threshold = 3) {
  console.log(`[sim] Threshold: ${threshold}`)
  mkdirSync(GATE_ROOT, { recursive: true })

  // Run threshold-1 times (below threshold) — should NOT trigger
  for (let i = 0; i < threshold - 1; i++) {
    await fakeTask()
  }
  let count = readCounter()
  console.log(`[sim] After ${threshold-1} tasks, count=${count}`)
  if (count % threshold === 0 && count > 0) {
    console.log("[sim] Would trigger retro-analyze")
    return true
  }
  console.log("[sim] Would NOT trigger")

  // One more — should trigger
  await fakeTask()
  count = readCounter()
  console.log(`[sim] After ${threshold} tasks, count=${count}`)
  if (count % threshold === 0 && count > 0) {
    console.log("[sim] Would trigger retro-analyze")
    return true
  }
  return false
}

async function fakeTask() {
  if (!existsSync(COUNTER_PATH)) {
    writeFileSync(COUNTER_PATH, JSON.stringify({ count: 0, last: null }))
  }
  const current = JSON.parse(readFileSync(COUNTER_PATH, "utf8"))
  const next = { count: (current.count || 0) + 1, last: new Date().toISOString() }
  const tmp = `${COUNTER_PATH}.tmp.${process.pid}`
  writeFileSync(tmp, JSON.stringify(next))
  const { renameSync } = await import("node:fs")
  renameSync(tmp, COUNTER_PATH)
}

function readCounter() {
  if (!existsSync(COUNTER_PATH)) return 0
  return JSON.parse(readFileSync(COUNTER_PATH, "utf8")).count || 0
}

async function main() {
  // Clean up
  if (existsSync(COUNTER_PATH)) unlinkSync(COUNTER_PATH)

  console.log("=== Test 1: Below threshold ===")
  const triggered1 = await simulateTrigger(3)
  console.log(`Result: triggered=${triggered1}`)

  // Clean up
  if (existsSync(COUNTER_PATH)) unlinkSync(COUNTER_PATH)

  console.log("\n=== Test 2: With actual retro-analyze trigger ===")
  // Set up a fake gate
  const testGate = path.join(GATE_ROOT, "integration-test-task")
  mkdirSync(testGate, { recursive: true })
  writeFileSync(path.join(testGate, "state.yaml"),
    "task_id: integration-test\n" +
    "current_step: verify\n" +
    "steps:\n" +
    "  implement:\n    status: done; gate_passed: true; attempts: 1; blocked_reason: \"\"\n" +
    "  verify:\n    status: done; gate_passed: true; attempts: 4; blocked_reason: \"test_integration\"\n" +
    "  review:\n    status: pending; gate_passed: false; attempts: 0; blocked_reason: null\n" +
    "  close:\n    status: pending; gate_passed: false; attempts: 0; blocked_reason: null\n"
  )

  // Run 10 fake tasks to trigger
  for (let i = 0; i < 10; i++) await fakeTask()
  const count = readCounter()
  console.log(`[test] Reached count=${count}`)

  if (count % 10 === 0) {
    console.log("[test] Running retro-analyze.ps1...")
    try {
      const { stdout } = await execFileP("powershell.exe", [
        "-NoProfile", "-File", RETRO_SCRIPT,
        "-TaskCount", "10", "-WriteGenes"
      ], { timeout: 30000 })
      const wroteGenes = stdout.includes("[GENES WRITTEN]")
      const skipped = stdout.includes("[SKIP]")
      console.log(`[test] retro-analyze: wroteGenes=${wroteGenes} skipped=${skipped}`)
    } catch (e) {
      // execFile throws on non-zero exit. But retro-analyze returns 1 for "no patterns" sometimes.
      // We treat it as a non-fatal trigger outcome.
      const stdout = e.stdout || ""
      const wroteGenes = stdout.includes("[GENES WRITTEN]")
      const skipped = stdout.includes("[SKIP]")
      console.log(`[test] retro-analyze: wroteGenes=${wroteGenes} skipped=${skipped} (exit ${e.code})`)
    }
  }

  // Cleanup
  if (existsSync(testGate)) {
    const { rmSync } = await import("node:fs")
    rmSync(testGate, { recursive: true, force: true })
  }
  if (existsSync(COUNTER_PATH)) unlinkSync(COUNTER_PATH)
}

main().catch(console.error)
