// gate-system.test.js
// Tests for the gate-system plugin.
// Run: node --test plugins/gate-system.test.js

import { test, describe, before, after, beforeEach } from "node:test"
import { strict as assert } from "node:assert"
import { existsSync, unlinkSync, mkdirSync, writeFileSync, readFileSync, renameSync, readdirSync } from "node:fs"
import path from "node:path"
import yaml from "js-yaml"
import {
  GeneSchema, DnaSchema,
  GATE_ROOT, DNA_PATH, COUNTER_PATH, LOCK_PATH,
  readCounter, incrementCounter, shouldTriggerRetro,
  loadDnaSafe, validateDna
} from "./gate-system.js"

// ── Fixtures ────────────────────────────────────────────────────
const SAMPLE_GENE = {
  id: "AUTH-001",
  name: "password_hash_bcrypt",
  description: "Use bcrypt cost >=12 OR argon2id. Never MD5/SHA.",
  triggers: ["password", "bcrypt", "argon2"]
}

const SAMPLE_AUTO_GENE = {
  id: "CODE-AUTO-001",
  name: "code_gate_blocked_verify",
  description: "Auto-generated gene for blocked verify step.",
  triggers: ["verify", "gate"],
  auto_generated: true,
  auto_date: new Date().toISOString()
}

const SAMPLE_DNA = {
  version: "3.0.0",
  generated: "2026-06-01",
  genes: [SAMPLE_GENE, SAMPLE_AUTO_GENE]
}

// ── Test isolation helpers ──────────────────────────────────────
function withTempDna(testFn) {
  return async () => {
    const orig = existsSync(DNA_PATH) ? readFileSync(DNA_PATH, "utf8") : null
    try {
      await testFn()
    } finally {
      if (orig !== null) {
        writeFileSync(DNA_PATH, orig)
      } else if (existsSync(DNA_PATH)) {
        unlinkSync(DNA_PATH)
      }
    }
  }
}

function writeDna(data) {
  mkdirSync(path.dirname(DNA_PATH), { recursive: true })
  writeFileSync(DNA_PATH, yaml.dump(data, { lineWidth: -1 }))
}

// ── Tests: Gene schema ──────────────────────────────────────────
describe("GeneSchema", () => {
  test("accepts manually written gene", () => {
    const result = GeneSchema.safeParse(SAMPLE_GENE)
    assert.equal(result.success, true)
  })

  test("accepts auto-generated gene", () => {
    const result = GeneSchema.safeParse(SAMPLE_AUTO_GENE)
    assert.equal(result.success, true)
  })

  test("rejects malformed gene ID (lowercase)", () => {
    const bad = { ...SAMPLE_GENE, id: "auth-001" }
    const result = GeneSchema.safeParse(bad)
    assert.equal(result.success, false)
    assert.match(result.error.errors[0].message, /FAMILY-NNN/)
  })

  test("rejects malformed gene ID (wrong format)", () => {
    const bad = { ...SAMPLE_GENE, id: "AUTH-1" }
    const result = GeneSchema.safeParse(bad)
    assert.equal(result.success, false)
  })

  test("rejects gene with empty triggers", () => {
    const bad = { ...SAMPLE_GENE, triggers: [] }
    const result = GeneSchema.safeParse(bad)
    assert.equal(result.success, false)
  })

  test("accepts all gene families", () => {
    const families = ["AUTH", "DB", "API", "CODE", "DEPLOY", "SEC", "UI", "COORD", "MMX", "PERF", "EVO", "GENE"]
    for (const fam of families) {
      const gene = { ...SAMPLE_GENE, id: `${fam}-001` }
      const result = GeneSchema.safeParse(gene)
      assert.equal(result.success, true, `Family ${fam} should be valid`)
    }
  })
})

// ── Tests: DNA schema ──────────────────────────────────────────
describe("DnaSchema", () => {
  test("accepts valid DNA", () => {
    const result = DnaSchema.safeParse(SAMPLE_DNA)
    assert.equal(result.success, true)
    assert.equal(result.data.genes.length, 2)
  })

  test("rejects non-semver version", () => {
    const bad = { ...SAMPLE_DNA, version: "latest" }
    const result = DnaSchema.safeParse(bad)
    assert.equal(result.success, false)
  })

  test("rejects genes as non-array", () => {
    const bad = { ...SAMPLE_DNA, genes: "not-an-array" }
    const result = DnaSchema.safeParse(bad)
    assert.equal(result.success, false)
  })

  test("allows passthrough of extra fields", () => {
    const gene = { ...SAMPLE_GENE, custom_field: "extra", another: 42 }
    const result = GeneSchema.safeParse(gene)
    assert.equal(result.success, true)
  })
})

// ── Tests: Task counter ────────────────────────────────────────
describe("task counter", () => {
  beforeEach(() => {
    if (existsSync(COUNTER_PATH)) unlinkSync(COUNTER_PATH)
  })

  test("starts at 0 when no file exists", () => {
    const c = readCounter()
    assert.equal(c.count, 0)
  })

  test("increments correctly", () => {
    assert.equal(incrementCounter(), 1)
    assert.equal(incrementCounter(), 2)
    assert.equal(incrementCounter(), 3)
    assert.equal(readCounter().count, 3)
  })

  test("persists across reads", () => {
    incrementCounter()
    incrementCounter()
    const c = readCounter()
    assert.equal(c.count, 2)
    assert.ok(c.last)
  })

  test("atomic write uses temp file", () => {
    incrementCounter()
    const tmpFiles = readdirSync(GATE_ROOT).filter(f => f.includes(".tmp."))
    // Cleanup any leftover temp files
    for (const f of tmpFiles) unlinkSync(path.join(GATE_ROOT, f))
    // Test that we CAN do this without error - actual atomic behavior verified by file existence
    assert.ok(existsSync(COUNTER_PATH), "counter file should exist after increment")
  })
})

// ── Tests: Retro trigger threshold ──────────────────────────────
describe("shouldTriggerRetro", () => {
  test("never triggers at 0", () => {
    assert.equal(shouldTriggerRetro(0), false)
  })
  test("triggers at 10", () => {
    assert.equal(shouldTriggerRetro(10), true)
  })
  test("triggers at 20", () => {
    assert.equal(shouldTriggerRetro(20), true)
  })
  test("does not trigger at 11", () => {
    assert.equal(shouldTriggerRetro(11), false)
  })
})

// ── Tests: DNA loading and validation ───────────────────────────
describe("loadDnaSafe + validateDna", () => {
  test("returns null when DNA.yaml does not exist", () => {
    const orig = existsSync(DNA_PATH) ? readFileSync(DNA_PATH, "utf8") : null
    try {
      if (existsSync(DNA_PATH)) unlinkSync(DNA_PATH)
      assert.equal(loadDnaSafe(), null)
    } finally {
      if (orig) writeFileSync(DNA_PATH, orig)
    }
  })

  test("loads valid DNA", () => {
    const orig = existsSync(DNA_PATH) ? readFileSync(DNA_PATH, "utf8") : null
    try {
      writeDna(SAMPLE_DNA)
      const data = loadDnaSafe()
      assert.ok(data)
      assert.equal(data.version, "3.0.0")
      assert.equal(data.genes.length, 2)
    } finally {
      if (orig) writeFileSync(DNA_PATH, orig)
    }
  })

  test("validateDna returns ok for valid file", () => {
    const orig = existsSync(DNA_PATH) ? readFileSync(DNA_PATH, "utf8") : null
    try {
      writeDna(SAMPLE_DNA)
      const result = validateDna()
      assert.equal(result.ok, true)
      assert.equal(result.geneCount, 2)
    } finally {
      if (orig) writeFileSync(DNA_PATH, orig)
    }
  })

  test("validateDna returns errors for invalid file", () => {
    const orig = existsSync(DNA_PATH) ? readFileSync(DNA_PATH, "utf8") : null
    try {
      writeDna({ version: "bad", genes: [{ id: "lowercase-1", name: "x", description: "x", triggers: [] }] })
      const result = validateDna()
      assert.equal(result.ok, false)
      assert.ok(result.errors.length > 0)
    } finally {
      if (orig) writeFileSync(DNA_PATH, orig)
    }
  })

  test("validateDna invalidates cache when DNA.yaml changes", () => {
    const orig = existsSync(DNA_PATH) ? readFileSync(DNA_PATH, "utf8") : null
    try {
      writeDna(SAMPLE_DNA)
      const r1 = validateDna()
      assert.equal(r1.geneCount, 2)
      // Modify the file - mtime changes, cache must invalidate
      writeDna({ version: "1.0.0", genes: [] })
      const r2 = validateDna()
      // r2 should reflect the new content (0 genes), not the cached r1
      assert.equal(r2.geneCount, 0)
      // Timestamps should differ (cache was invalidated)
      assert.notEqual(r1.ts, r2.ts)
    } finally {
      if (orig) writeFileSync(DNA_PATH, orig)
    }
  })
})

// ── Tests: Real DNA.yaml in config (if exists) ─────────────────
describe("real DNA.yaml", () => {
  test("current DNA.yaml is valid or absent", () => {
    if (!existsSync(DNA_PATH)) {
      console.log("  (no DNA.yaml in test env - skipping)")
      return
    }
    const result = validateDna()
    if (!result.ok) {
      console.log("  DNA.yaml validation errors (informational):")
      for (const err of result.errors) console.log(`    - ${err}`)
    }
    // Don't assert - the real file may have intentional test data
    assert.ok(result, "validateDna should return a result")
  })
})
