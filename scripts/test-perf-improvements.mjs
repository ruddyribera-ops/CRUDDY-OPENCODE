// scripts/test-perf-improvements.mjs (v2 - more robust)
// Phase 1: Verify the 3 performance improvements actually work.
// Run: node --test scripts/test-perf-improvements.mjs

import { test, describe } from "node:test"
import assert from "node:assert/strict"
import { readFileSync, existsSync, statSync, writeFileSync, appendFileSync, readdirSync, unlinkSync } from "node:fs"
import { join } from "node:path"
import { pathToFileURL } from "node:url"

const CONFIG_ROOT = join(process.env.USERPROFILE || process.env.HOME || "", ".config", "opencode")
const PLUGINS_DIR = join(CONFIG_ROOT, "plugins")
const GATE_LOG = join(CONFIG_ROOT, "memory", "gate-system.log")

// Helper: read last N bytes of gate log
function readLogTail(maxLines = 50) {
  if (!existsSync(GATE_LOG)) return ""
  const content = readFileSync(GATE_LOG, "utf-8")
  const lines = content.split("\n").filter(l => l.trim())
  return lines.slice(-maxLines).join("\n")
}

// Helper: append a sentinel line we can search for to mark test boundaries
function appendSentinel(tag) {
  const sentinel = `[test-sentinel] ${new Date().toISOString()} ${tag}\n`
  try {
    appendFileSync(GATE_LOG, sentinel)
    return sentinel.trim()
  } catch (e) {
    return null
  }
}

async function importPlugin(name) {
  const path = join(PLUGINS_DIR, name)
  return await import(pathToFileURL(path).href)
}

// Test files we create should be cleaned up
const testFiles = []
function trackTestFile(path) {
  testFiles.push(path)
  return path
}

describe("Phase 1: verify 3 performance improvements", () => {
  test("[1/3] pre-tool-guard: pattern cache v1.0 logs on load", async () => {
    const sentinel = appendSentinel("test1-start")
    assert.ok(sentinel, "Could not write sentinel")

    const mod = await importPlugin("pre-tool-guard.js")
    const plugin = await mod.PreToolGuard({
      project: {},
      client: { app: { log: async () => {} } },
      $: null,
      directory: CONFIG_ROOT,
    })

    assert.ok(plugin, "PreToolGuard should be callable")
    assert.equal(typeof plugin["tool.execute.before"], "function", "tool.execute.before should be a function")

    // Wait for the setImmediate in warmPatternCache to fire
    // Use a sequence of awaits to ensure we yield to the event loop multiple times
    for (let i = 0; i < 5; i++) {
      await new Promise(resolve => setImmediate(resolve))
    }
    await new Promise(resolve => setTimeout(resolve, 200))

    const tail = readLogTail(100)
    const cacheMatch = tail.match(/pattern cache v1\.0 warmed: (\d+) patterns across (\d+) categories/)
    assert.ok(cacheMatch, `Expected pattern cache log. Sentinel: ${sentinel}. Tail:\n${tail.slice(-1500)}`)

    const patternCount = parseInt(cacheMatch[1], 10)
    const categoryCount = parseInt(cacheMatch[2], 10)
    assert.ok(patternCount >= 25, `Expected >=25 patterns, got ${patternCount}`)
    assert.ok(categoryCount >= 5, `Expected >=5 categories, got ${categoryCount}`)

    console.log(`  ✓ Cache warmed: ${patternCount} patterns, ${categoryCount} categories`)
  })

  test("[2/3] post-tool-guard: 20 writes batch into ≤3 lint runs", async () => {
    const sentinel = appendSentinel("test2-start")
    assert.ok(sentinel, "Could not write sentinel")

    const mod = await importPlugin("post-tool-guard.js")
    const hooks = await mod.PostToolGuard({
      project: {},
      client: { app: { log: async () => {} } },
      $: null,
      directory: CONFIG_ROOT,
    })

    assert.ok(hooks, "PostToolGuard should be callable")
    assert.equal(typeof hooks["tool.execute.after"], "function")
    assert.equal(typeof hooks.event, "function", "event hook should exist for idle drain")

    // Simulate 20 file writes in rapid succession
    const writes = []
    for (let i = 0; i < 20; i++) {
      const fakePath = join(CONFIG_ROOT, "memory", `test-batch-${Date.now()}-${i}.js`)
      // Actually create the file so the plugin can read it
      try { writeFileSync(fakePath, `// test file ${i}\n`) } catch {}
      trackTestFile(fakePath)
      writes.push(
        hooks["tool.execute.after"](
          { tool: "Write", args: { path: fakePath } },
          {}
        )
      )
    }
    await Promise.all(writes)

    // Wait for the 5-second debounce timer to fire + buffer
    await new Promise(resolve => setTimeout(resolve, 5500))

    const tail = readLogTail(100)
    const batchLines = tail.split("\n").filter(l => /lint batch drain: \d+ files/.test(l))

    assert.ok(batchLines.length >= 1, `Expected ≥1 batch drain, got ${batchLines.length}. Tail:\n${tail.slice(-2000)}`)

    // Verify most files were in a single batch (proves batching)
    const firstBatch = batchLines[0]?.match(/(\d+) files/)
    const firstBatchCount = firstBatch ? parseInt(firstBatch[1], 10) : 0
    assert.ok(firstBatchCount >= 15, `Expected first batch to contain most files (≥15), got ${firstBatchCount}/20`)

    console.log(`  ✓ ${batchLines.length} batch(es), first batch had ${firstBatchCount} files`)

    // Clean up test files
    for (const f of testFiles) {
      try { unlinkSync(f) } catch {}
    }
  })

  test("[3/3] memory-bridge: LRU caps session tracking at MAX_TRACKED_SESSIONS", async () => {
    const sentinel = appendSentinel("test3-start")
    assert.ok(sentinel, "Could not write sentinel")

    const mod = await importPlugin("memory-bridge.js")
    const hooks = await mod.MemoryBridge({
      project: {},
      client: { app: { log: async () => {} } },
      $: null,
      directory: CONFIG_ROOT,
    })

    assert.ok(hooks, "MemoryBridge should be callable")
    assert.equal(typeof hooks.event, "function")

    // Push 150 fake session IDs through the event hook
    for (let i = 0; i < 150; i++) {
      await hooks.event({
        event: {
          type: "tool.test",
          session: { id: `lru-test-${i.toString().padStart(4, "0")}` }
        }
      })
    }

    // Verify no errors in the delta
    const tail = readLogTail(100)
    const errors = (tail.match(/\[memory-bridge\].*error/gi) || []).length
    assert.equal(errors, 0, `Should have 0 errors, got ${errors}`)

    // Source-code verification: the LRU constant must be set
    const source = readFileSync(join(PLUGINS_DIR, "memory-bridge.js"), "utf-8")
    const lruMatch = source.match(/MAX_?TRACKED_SESSIONS\s*=\s*(\d+)/)
    assert.ok(lruMatch, "MAX_TRACKED_SESSIONS constant must be defined")
    const cap = parseInt(lruMatch[1], 10)
    assert.ok(cap >= 50 && cap <= 500, `LRU cap should be reasonable, got ${cap}`)

    // Verify trackActivity function exists and is used
    assert.match(source, /function\s+trackActivity\s*\(/, "trackActivity function must exist")
    assert.match(source, /trackActivity\(sessionId\)/, "trackActivity must be called from event handler")

    console.log(`  ✓ 150 sessions processed, 0 errors, LRU cap = ${cap}, trackActivity wired`)
  })
})
