#!/usr/bin/env node
/**
 * graph-memory.js — JSON-LD file-based graph engine
 *
 * CLI:
 *   node graph-memory.js create-node <type> --name <name> [--data '{"key":"val"}']
 *   node graph-memory.js get-node <filename>
 *   node graph-memory.js create-edge --from <node> --to <node> --type <edgeType>
 *   node graph-memory.js query --type <nodeType> [--days <N>] [--limit <N>]
 *   node graph-memory.js init   — ensure directories exist
 *
 * Fire-and-forget writes. Graceful fallback if directories missing.
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const CONFIG_DIR = path.resolve(__dirname, '..');
const LOCAL_CONFIG = path.join(CONFIG_DIR, 'opencode.local.json');

function loadStoragePaths() {
  try {
    const cfg = JSON.parse(fs.readFileSync(LOCAL_CONFIG, 'utf8'));
    const g = cfg.graph_memory || {};
    return {
      nodes: path.resolve(CONFIG_DIR, g.storage?.nodes || 'memory/graph/nodes'),
      edges: path.resolve(CONFIG_DIR, g.storage?.edges || 'memory/graph/edges')
    };
  } catch {
    return {
      nodes: path.join(CONFIG_DIR, 'memory/graph/nodes'),
      edges: path.join(CONFIG_DIR, 'memory/graph/edges')
    };
  }
}

const paths = loadStoragePaths();

function ensureDir(dir) {
  try { fs.mkdirSync(dir, { recursive: true }); return true; }
  catch { return false; }
}

function safeTimestamp() {
  return new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
}

function shortId() {
  return crypto.randomBytes(4).toString('hex');
}

// ── Commands ──

function createNode(type, name, data) {
  if (!ensureDir(paths.nodes)) { console.error('Cannot create nodes directory'); process.exit(1); }
  const ts = safeTimestamp();
  const filename = `${type}-${ts}-${shortId()}.jsonld`;
  const filepath = path.join(paths.nodes, filename);
  const node = {
    '@context': { schema: 'https://schema.org/' },
    '@type': type,
    name: name || `${type}-${shortId()}`,
    created: new Date().toISOString(),
    data: data || {}
  };
  fs.writeFileSync(filepath, JSON.stringify(node, null, 2), 'utf8');
  console.log(filename);
  return filename;
}

function getNode(filename) {
  // Try nodes dir first, then edges dir
  for (const dir of [paths.nodes, paths.edges]) {
    const filepath = path.join(dir, filename);
    if (fs.existsSync(filepath)) {
      console.log(fs.readFileSync(filepath, 'utf8'));
      return;
    }
  }
  console.error(`Node not found: ${filename}`);
  process.exit(1);
}

function createEdge(fromNode, toNode, edgeType) {
  if (!ensureDir(paths.edges)) { console.error('Cannot create edges directory'); process.exit(1); }
  const ts = safeTimestamp();
  const filename = `edge-${ts}-${shortId()}.jsonld`;
  const filepath = path.join(paths.edges, filename);
  const edge = {
    '@context': { schema: 'https://schema.org/' },
    '@type': 'Edge',
    edgeType: edgeType,
    from: fromNode,
    to: toNode,
    created: new Date().toISOString()
  };
  fs.writeFileSync(filepath, JSON.stringify(edge, null, 2), 'utf8');
  console.log(filename);
  return filename;
}

function queryByType(nodeType, days, limit) {
  const dir = paths.nodes;
  if (!fs.existsSync(dir)) { console.log('[]'); return; }

  const cutoff = days ? Date.now() - days * 86400000 : 0;
  const files = fs.readdirSync(dir)
    .filter(f => f.startsWith(`${nodeType}-`) && f.endsWith('.jsonld'))
    .map(f => {
      const fp = path.join(dir, f);
      try {
        const content = JSON.parse(fs.readFileSync(fp, 'utf8'));
        return { file: f, ...content };
      } catch { return null; }
    })
    .filter(Boolean)
    .filter(n => !cutoff || new Date(n.created).getTime() >= cutoff)
    .sort((a, b) => new Date(b.created) - new Date(a.created));

  const results = limit ? files.slice(0, limit) : files;
  console.log(JSON.stringify(results, null, 2));
}

function init() {
  ensureDir(paths.nodes);
  ensureDir(paths.edges);
  console.error(`✅ Graph dirs ready:
  nodes: ${paths.nodes}
  edges: ${paths.edges}`);
}

// ── CLI ──
const cmd = process.argv[2];

if (cmd === 'init') {
  init();
  process.exit(0);
} else if (cmd === 'create-node') {
  const type = process.argv[3] === '--type' ? process.argv[4] : process.argv[3];
  const nameIdx = process.argv.indexOf('--name');
  const dataIdx = process.argv.indexOf('--data');
  const stdinIdx = process.argv.indexOf('--stdin');
  if (!type) { console.error('Usage: create-node <type> --name <name> [--data \'{"key":"val"}\'] [--stdin]'); process.exit(1); }
  const name = nameIdx !== -1 ? process.argv[nameIdx + 1] : null;
  if (stdinIdx !== -1) {
    // Read JSON from stdin (avoids Windows CLI quoting issues with nested quotes)
    let stdinData = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', chunk => stdinData += chunk);
    process.stdin.on('end', () => {
      try {
        const data = JSON.parse(stdinData);
        createNode(type, name, data);
        process.exit(0);
      } catch (e) {
        console.error('Invalid JSON from stdin: ' + e.message);
        process.exit(1);
      }
    });
    return; // Don't exit - wait for stdin
  }
  const data = dataIdx !== -1 ? JSON.parse(process.argv[dataIdx + 1]) : null;
  createNode(type, name, data);
  process.exit(0);
} else if (cmd === 'get-node') {
  const filename = process.argv[3];
  if (!filename) { console.error('Usage: get-node <filename>'); process.exit(1); }
  getNode(filename);
  process.exit(0);
} else if (cmd === 'create-edge') {
  const fromIdx = process.argv.indexOf('--from');
  const toIdx = process.argv.indexOf('--to');
  const typeIdx = process.argv.indexOf('--type');
  const relIdx = process.argv.indexOf('--relationship');
  const from = fromIdx !== -1 ? process.argv[fromIdx + 1] : null;
  const to = toIdx !== -1 ? process.argv[toIdx + 1] : null;
  const edgeType = typeIdx !== -1 ? process.argv[typeIdx + 1] : (relIdx !== -1 ? process.argv[relIdx + 1] : null);
  if (!from || !to || !edgeType) { console.error('Usage: create-edge --from <node> --to <node> --type <edgeType>'); process.exit(1); }
  createEdge(from, to, edgeType);
  process.exit(0);
} else if (cmd === 'query') {
  const typeIdx = process.argv.indexOf('--type');
  const daysIdx = process.argv.indexOf('--days');
  const limitIdx = process.argv.indexOf('--limit');
  const nodeType = typeIdx !== -1 ? process.argv[typeIdx + 1] : null;
  const days = daysIdx !== -1 ? parseInt(process.argv[daysIdx + 1], 10) : null;
  const limit = limitIdx !== -1 ? parseInt(process.argv[limitIdx + 1], 10) : null;
  if (!nodeType) { console.error('Usage: query --type <nodeType> [--days <N>] [--limit <N>]'); process.exit(1); }
  queryByType(nodeType, days, limit);
  process.exit(0);
} else {
  console.error('Usage:');
  console.error('  node graph-memory.js init');
  console.error('  node graph-memory.js create-node [--type] <type> --name <name> [--data \'{"k":"v"}\']');
  console.error('  node graph-memory.js get-node <filename>');
  console.error('  node graph-memory.js create-edge --from <node> --to <node> --type|--relationship <t>');
  console.error('  node graph-memory.js query --type <nodeType> [--days <N>] [--limit <N>]');
  process.exit(1);
}
