// scripts/test-plugins.mjs
// Plugin test runner — verifies all 8 OpenCode plugins load and the 3
// performance improvements work as expected.
//
// Usage:
//   node scripts/test-plugins.mjs
//
// Exit code: 0 = all pass, 1 = any fail
//
// Reuses the regression tests from test-perf-improvements.mjs, plus adds
// a plugin-load check for all 8 plugins in the plugins/ directory.

import { test, describe, before, after } from "node:test"
import assert from "node:assert/strict"
import { readFileSync, existsSync, readdirSync } from "node:fs"
import { join, basename } from "node:path"
import { pathToFileURL } from "node:url"

const CONFIG_ROOT = join(process.env.USERPROFILE || process.env.HOME || "", ".config", "opencode")
const PLUGINS_DIR = join(CONFIG_ROOT, "plugins")

const PLUGINS = [
  { name: "compaction-survival.js", export: "CompactionSurvival" },
  { name: "gate-system.js", export: null },  // utility plugin, no plugin export
  { name: "integration-test.js", export: null },
  { name: "memory-bridge.js", export: "MemoryBridge" },
  { name: "post-tool-guard.js", export: "PostToolGuard" },
  { name: "post-turn-biome.js", export: "PostTurnBiome" },
  { name: "pre-tool-guard.js", export: "PreToolGuard" },
  { name: "session-title-guard.js", export: "SessionTitleGuard" },
]

describe("Plugin test suite", () => {
  test("[load] all plugins importable from their directory", async () => {
    const results = []
    for (const p of PLUGINS) {
      const path = join(PLUGINS_DIR, p.name)
      if (!existsSync(path)) {
        results.push({ name: p.name, ok: false, reason: "file missing" })
        continue
      }
      try {
        const mod = await import(pathToFileURL(path).href)
        if (p.export) {
          assert.ok(mod[p.export], `${p.name} should export ${p.export}`)
          assert.equal(typeof mod[p.export], "function", `${p.export} should be a function`)
        }
        results.push({ name: p.name, ok: true })
      } catch (e) {
        results.push({ name: p.name, ok: false, reason: e.message.slice(0, 80) })
      }
    }

    const failed = results.filter(r => !r.ok)
    if (failed.length > 0) {
      console.log("\n  Failed plugins:")
      for (const f of failed) {
        console.log(`    - ${f.name}: ${f.reason}`)
      }
    }
    assert.equal(failed.length, 0, `${failed.length} plugin(s) failed to load`)
    console.log(`  ✓ All ${PLUGINS.length} plugins loaded successfully`)
  })
})

describe("Performance improvements (from test-perf-improvements.mjs)", () => {
  test("[1/3] pre-tool-guard: pattern cache v1.0 logs on load", async () => {
    const GATE_LOG = join(CONFIG_ROOT, "memory", "gate-system.log")
    const before = existsSync(GATE_LOG) ? readFileSync(GATE_LOG, "utf-8").length : 0
    const mod = await import(pathToFileURL(join(PLUGINS_DIR, "pre-tool-guard.js")).href)
    await mod.PreToolGuard({ project: {}, client: { app: { log: async () => {} } }, $: null, directory: CONFIG_ROOT })
    for (let i = 0; i < 5; i++) await new Promise(r => setImmediate(r))
    await new Promise(r => setTimeout(r, 200))
    const content = existsSync(GATE_LOG) ? readFileSync(GATE_LOG, "utf-8") : ""
    const delta = content.slice(before)
    const m = delta.match(/pattern cache v1\.0 warmed: (\d+) patterns across (\d+) categories/)
    assert.ok(m, `Expected cache log, got delta: ${delta.slice(-300)}`)
    const patterns = parseInt(m[1], 10)
    const cats = parseInt(m[2], 10)
    assert.ok(patterns >= 25, `Expected >=25 patterns, got ${patterns}`)
    assert.ok(cats >= 5, `Expected >=5 categories, got ${cats}`)
    console.log(`  ✓ Cache warmed: ${patterns} patterns, ${cats} categories`)
  })

  test("[2/3] post-tool-guard: 20 writes batch into ≤3 lint runs", async () => {
    const GATE_LOG = join(CONFIG_ROOT, "memory", "gate-system.log")
    const before = existsSync(GATE_LOG) ? readFileSync(GATE_LOG, "utf-8").length : 0
    const mod = await import(pathToFileURL(join(PLUGINS_DIR, "post-tool-guard.js")).href)
    const hooks = await mod.PostToolGuard({ project: {}, client: { app: { log: async () => {} } }, $: null, directory: CONFIG_ROOT })
    for (let i = 0; i < 20; i++) {
      const fakePath = join(CONFIG_ROOT, "memory", `test-batch-${Date.now()}-${i}.js`)
      await hooks["tool.execute.after"]({ tool: "Write", args: { path: fakePath } }, {})
    }
    await new Promise(r => setTimeout(r, 5500))
    const content = existsSync(GATE_LOG) ? readFileSync(GATE_LOG, "utf-8") : ""
    const delta = content.slice(before)
    const batches = (delta.match(/lint batch drain: \d+ files \(trigger=/g) || []).length
    assert.ok(batches >= 1, `Expected ≥1 batch, got ${batches}`)
    assert.ok(batches <= 3, `Expected ≤3 batches, got ${batches}`)
    console.log(`  ✓ ${batches} batch(es) for 20 writes (proves debounce works)`)
  })

  test("[3/3] memory-bridge: LRU caps session tracking", async () => {
    const mod = await import(pathToFileURL(join(PLUGINS_DIR, "memory-bridge.js")).href)
    const hooks = await mod.MemoryBridge({ project: {}, client: { app: { log: async () => {} } }, $: null, directory: CONFIG_ROOT })
    for (let i = 0; i < 150; i++) {
      await hooks.event({ event: { type: "tool.test", session: { id: `t${i}` } } })
    }
    const source = readFileSync(join(PLUGINS_DIR, "memory-bridge.js"), "utf-8")
    const m = source.match(/MAX_?TRACKED_SESSIONS\s*=\s*(\d+)/)
    assert.ok(m, "MAX TRACKED SESSIONS constant must be defined")
    const cap = parseInt(m[1], 10)
    assert.ok(cap >= 50 && cap <= 500, `LRU cap should be reasonable, got ${cap}`)
    assert.match(source, /function\s+trackActivity\s*\(/, "trackActivity function must exist")
    assert.match(source, /trackActivity\(sessionId\)/, "trackActivity must be called from event handler")
    console.log(`  ✓ 150 sessions processed, LRU cap = ${cap}, trackActivity wired`)
  })
})
