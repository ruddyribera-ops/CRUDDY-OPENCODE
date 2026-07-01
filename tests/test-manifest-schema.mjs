// D:\Users\Windows\.config\opencode\tests\test-manifest-schema.mjs
// Schema conformance tests for agent manifests.
// Uses node:test (built-in Node 18+) and js-yaml (already in package.json).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import yaml from 'js-yaml';

const AGENTS_DIR = 'C:/Users/Windows/.config/opencode/agents';
const SCHEMA_PATH = 'C:/Users/Windows/.config/opencode/agents/agent.schema.json';

// Load schema once
const schema = JSON.parse(readFileSync(SCHEMA_PATH, 'utf-8'));

// Load all manifest files (exclude schema files)
const manifestFiles = readdirSync(AGENTS_DIR)
  .filter(f => f.endsWith('.yaml') && !f.includes('-schema') && f !== 'agent-schema.yaml')
  .map(f => join(AGENTS_DIR, f));

const manifests = manifestFiles.map(path => {
  const content = readFileSync(path, 'utf-8');
  const data = yaml.load(content);
  const fname = path.split(/[/\\]/).pop().replace('.yaml', '');
  return { path, name: fname, data };
});

test('all manifests parse as valid YAML', () => {
  for (const m of manifests) {
    assert.ok(m.data, `${m.path} should parse as YAML object`);
    assert.strictEqual(typeof m.data, 'object', `${m.path} should be an object`);
  }
});

test('all manifests have required fields (name, description)', () => {
  for (const m of manifests) {
    assert.ok(m.data.name, `${m.path} missing name`);
    assert.ok(m.data.description, `${m.path} missing description`);
    const desc = String(m.data.description || '');
    assert.ok(desc.length >= 10, `${m.path} description too short (${desc.length} chars)`);
  }
});

test('manifest name matches filename', () => {
  for (const m of manifests) {
    const expected = m.path.split(/[/\\]/).pop().replace('.yaml', '');
    assert.strictEqual(m.data.name, expected, `${m.path} name="${m.data.name}" does not match filename "${expected}"`);
  }
});

test('name field matches lowercase-kebab pattern', () => {
  for (const m of manifests) {
    if (m.data.name) {
      assert.ok(/^[a-z][a-z0-9-]*$/.test(m.data.name), `${m.path} name="${m.data.name}" does not match pattern ^[a-z][a-z0-9-]*$`);
    }
  }
});

test('no duplicate model_tier keys (YAML silently uses last)', () => {
  for (const m of manifests) {
    const content = readFileSync(m.path, 'utf-8');
    const matches = content.match(/^model_tier:/gm) || [];
    assert.ok(matches.length <= 1, `${m.path} has ${matches.length} model_tier keys (silent overwrite bug)`);
  }
});

test('mode is primary or subagent if specified', () => {
  for (const m of manifests) {
    if (m.data.mode !== undefined) {
      assert.ok(['primary', 'subagent'].includes(m.data.mode), `${m.path} mode="${m.data.mode}" not in {primary, subagent}`);
    }
  }
});

test('no duplicate agent names across all manifests', () => {
  const names = manifests.map(m => m.data.name);
  const seen = new Set();
  for (const name of names) {
    assert.ok(!seen.has(name), `duplicate agent name: ${name}`);
    seen.add(name);
  }
});

test('validate against JSON Schema required fields', () => {
  const required = schema.required || [];
  for (const m of manifests) {
    for (const req of required) {
      assert.ok(m.data[req] !== undefined && m.data[req] !== null, `${m.path} missing required field: ${req}`);
    }
  }
});

test('validate field types against JSON Schema', () => {
  for (const m of manifests) {
    for (const [key, prop] of Object.entries(schema.properties || {})) {
      if (m.data[key] === undefined || m.data[key] === null) continue;
      if (!prop.type) continue;

      if (prop.type === 'string') {
        assert.strictEqual(typeof m.data[key], 'string', `${m.path} ${key} should be string`);
      } else if (prop.type === 'array') {
        assert.ok(Array.isArray(m.data[key]), `${m.path} ${key} should be array`);
      } else if (prop.type === 'integer') {
        assert.strictEqual(typeof m.data[key], 'number', `${m.path} ${key} should be number/integer`);
      } else if (prop.type === 'object') {
        assert.strictEqual(typeof m.data[key], 'object', `${m.path} ${key} should be object`);
        assert.ok(!Array.isArray(m.data[key]), `${m.path} ${key} should be object not array`);
      }
    }
  }
});

test('version field matches semver pattern if present', () => {
  for (const m of manifests) {
    if (m.data.version !== undefined) {
      assert.ok(/^\d+\.\d+\.\d+$/.test(m.data.version), `${m.path} version="${m.data.version}" does not match semver pattern`);
    }
  }
});
