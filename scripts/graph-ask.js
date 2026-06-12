#!/usr/bin/env node
/**
 * graph-ask.js - Human-facing graph query interface
 *
 * Natural language to graph-query.js commands
 * No LLM, keyword extraction only
 *
 * Usage:
 *   node graph-ask.js "any decisions about deploy in the last 30 days?"
 *   node graph-ask.js "what agents have we used most?"
 *   node graph-ask.js "any blockers for palma-coin?"
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const CONFIG_DIR = path.resolve(__dirname, '..');
const GQ = path.join(CONFIG_DIR, 'scripts', 'graph-query.js');
const GM = path.join(CONFIG_DIR, 'scripts', 'graph-memory.js');
const NODES_DIR = path.join(CONFIG_DIR, 'memory', 'graph', 'nodes');
const EDGES_DIR = path.join(CONFIG_DIR, 'memory', 'graph', 'edges');

/**
 * Run graph-query.js and parse JSON output
 */
function runGQ(cmd, args) {
  try {
    const argStr = args.map(a => `"${a}"`).join(' ');
    const out = execSync(`node "${GQ}" ${cmd} ${argStr}`, { encoding: 'utf8', timeout: 10000 });
    const trimmed = (out || '').trim();
    if (!trimmed || trimmed === '[]' || trimmed.startsWith('[')) {
      try { return JSON.parse(trimmed || '[]'); }
      catch { return []; }
    }
    return [];
  } catch {
    return [];
  }
}

/**
 * Run graph-memory.js query and parse JSON output
 */
function runGM(args) {
  try {
    const out = execSync(`node "${GM}" query ${args}`, { encoding: 'utf8', timeout: 10000 });
    const trimmed = (out || '').trim();
    if (!trimmed || trimmed === '[]') return [];
    return JSON.parse(trimmed);
  } catch {
    return [];
  }
}

/**
 * Extract keywords from question (words >3 chars, lowercased)
 */
function extractKeywords(question) {
  return question
    .toLowerCase()
    .replace(/[^\w\s]/g, ' ')
    .split(/\s+/)
    .filter(w => w.length > 3);
}

/**
 * Match keywords against pattern table
 */
function matchPattern(keywords) {
  const patterns = {
    decision: ['decision', 'decided', 'choice', 'chose', 'picked', 'opted'],
    lesson: ['lesson', 'learned', 'discovered', 'found', 'realized', 'learnt'],
    blocker: ['blocker', 'blocked', 'stuck', 'hanging', 'waiting', 'issue'],
    agentUsage: ['agent', 'used', 'frequent', 'most', 'often', 'work'],
    projectHistory: ['project', 'history', 'timeline', 'sessions', 'worked'],
    patternFrequency: ['pattern', 'frequency', 'edge', 'edges', 'relationships', 'connections']
  };

  const scores = {};
  for (const [type, terms] of Object.entries(patterns)) {
    scores[type] = keywords.filter(kw => terms.some(t => t.includes(kw) || kw.includes(t))).length;
  }

  const max = Math.max(...Object.values(scores), 0);
  if (max === 0) return 'help';

  const match = Object.entries(scores).find(([, s]) => s === max);
  return match ? match[0] : 'help';
}

/**
 * Format decisions into human-readable output
 */
function formatDecisions(results) {
  if (!results.length) return '  (no decisions found)';
  return results.map(d => {
    const date = d.created ? d.created.slice(0, 10) : 'unknown';
    const name = d.name || 'Untitled';
    const context = d.data && d.data.context ? ` - "${d.data.context}"` : '';
    return `  - ${date} - "${name}"${context}`;
  }).join('\n');
}

/**
 * Format lessons into human-readable output
 */
function formatLessons(results) {
  if (!results.length) return '  (no lessons found)';
  return results.map(l => {
    const date = l.created ? l.created.slice(0, 10) : 'unknown';
    const name = l.name || 'Untitled';
    const cat = l.data && l.data.category ? `[${l.data.category}]` : '';
    return `  - ${date} ${cat} "${name}"`;
  }).join('\n');
}

/**
 * Format blockers into human-readable output
 */
function formatBlockers(results) {
  if (!results.length) return '  (no blockers found)';
  return results.map(b => {
    const date = b.created ? b.created.slice(0, 10) : 'unknown';
    const name = b.name || 'Untitled';
    const note = b.data && b.data.note ? ` - ${b.data.note}` : '';
    return `  - ${date} - "${name}"${note}`;
  }).join('\n');
}

/**
 * Agent usage histogram from task nodes
 */
function agentUsage() {
  const results = runGM('--type task --limit 200');
  if (!results.length) {
    console.log('  (no task nodes found)');
    return;
  }

  const counts = {};
  for (const r of results) {
    const agent = (r.data && r.data.agent) || 'unknown';
    counts[agent] = (counts[agent] || 0) + 1;
  }

  const total = Object.values(counts).reduce((a, b) => a + b, 0);
  const sorted = Object.entries(counts).sort((a, b) => b[1] - a[1]);

  const maxBar = 20;
  for (const [agent, count] of sorted) {
    const pct = total > 0 ? Math.round(count / total * 100) : 0;
    const barLen = Math.round(count / total * maxBar);
    const bar = '\u2588'.repeat(barLen);
    console.log(`  ${agent.padEnd(20)} ${bar} ${count} (${pct}%)`);
  }
}

/**
 * Project history timeline from session nodes
 */
function projectHistory(projectKw) {
  const results = runGM('--type session --days 90 --limit 50');
  if (!results.length) {
    console.log('  (no session nodes found)');
    return;
  }

  let filtered = results;
  if (projectKw) {
    filtered = results.filter(s => {
      const name = (s.name || '').toLowerCase();
      const projects = s.data && s.data.projects_touched ? JSON.stringify(s.data.projects_touched) : '';
      return name.includes(projectKw.toLowerCase()) || projects.includes(projectKw.toLowerCase());
    });
  }

  if (!filtered.length) {
    console.log(`  (no sessions found for project: ${projectKw})`);
    return;
  }

  const sorted = filtered.sort((a, b) => new Date(b.created) - new Date(a.created));
  for (const s of sorted.slice(0, 15)) {
    const date = s.created ? s.created.slice(0, 10) : 'unknown';
    const name = s.name || 'Untitled';
    const activity = s.data && s.data.activity_count ? ` [${s.data.activity_count} actions]` : '';
    console.log(`  - ${date} - ${name}${activity}`);
  }
}

/**
 * Pattern frequency histogram from edge types
 */
function patternFrequency() {
  if (!fs.existsSync(EDGES_DIR)) {
    console.log('  (edges directory not found)');
    return;
  }

  const files = fs.readdirSync(EDGES_DIR).filter(f => f.endsWith('.jsonld'));
  const counts = {};

  for (const file of files) {
    try {
      const content = JSON.parse(fs.readFileSync(path.join(EDGES_DIR, file), 'utf8'));
      const type = content.edgeType || 'unknown';
      counts[type] = (counts[type] || 0) + 1;
    } catch { /* skip malformed */ }
  }

  if (!Object.keys(counts).length) {
    console.log('  (no edges found)');
    return;
  }

  const total = Object.values(counts).reduce((a, b) => a + b, 0);
  const sorted = Object.entries(counts).sort((a, b) => b[1] - a[1]);
  const maxBar = 20;

  for (const [type, count] of sorted) {
    const pct = total > 0 ? Math.round(count / total * 100) : 0;
    const barLen = Math.round(count / total * maxBar);
    const bar = '\u2588'.repeat(barLen);
    console.log(`  ${type.padEnd(20)} ${bar} ${count} (${pct}%)`);
  }
}

/**
 * Show help with examples
 */
function showHelp() {
  console.log('Graph Query Interface');
  console.log('');
  console.log('Usage: node graph-ask.js "<question>"');
  console.log('');
  console.log('Examples:');
  console.log('  "any decisions about railway deploy?"');
  console.log('  "lessons learned about authentication?"');
  console.log('  "blockers for palma-coin project"');
  console.log('  "what agents have we used most?"');
  console.log('  "project history for NEW-SIS"');
  console.log('  "edge pattern frequency"');
  console.log('');
  console.log('Detected patterns: decision, lesson, blocker, agent-usage, project-history, pattern-frequency');
}

// === Main ===
const question = process.argv[2] || '';

if (!question || question === '--help' || question === '-h') {
  showHelp();
  process.exit(0);
}

const keywords = extractKeywords(question);
const pattern = matchPattern(keywords);

switch (pattern) {
  case 'decision': {
    const domain = keywords.filter(k => !['decision', 'decided', 'choice', 'about', 'any'].includes(k)).join(' ');
    console.log(`=== Decisions: ${domain || 'All'} ===`);
    const results = runGQ('past-decisions', domain ? [`--domain`, domain, `--days`, `30`] : [`--days`, `30`]);
    console.log(formatDecisions(results));
    break;
  }
  case 'lesson': {
    const kw = keywords.filter(k => !['lesson', 'learned', 'discovered', 'about', 'any'].includes(k)).join(',');
    console.log(`=== Lessons: ${kw || 'All'} ===`);
    const results = runGQ('lessons', kw ? [`--keywords`, kw, `--days`, `30`] : [`--days`, `30`]);
    console.log(formatLessons(results));
    break;
  }
  case 'blocker': {
    const proj = keywords.filter(k => !['blocker', 'blocked', 'stuck', 'for', 'any', 'about'].includes(k)).join(' ');
    console.log(`=== Blockers: ${proj || 'All'} ===`);
    const results = runGQ('blockers', proj ? [`--project`, proj] : []);
    console.log(formatBlockers(results));
    break;
  }
  case 'agentUsage': {
    console.log('=== Agent Usage (task distribution) ===');
    agentUsage();
    break;
  }
  case 'projectHistory': {
    const proj = keywords.filter(k => !['project', 'history', 'timeline', 'sessions', 'for', 'about'].includes(k)).join(' ');
    console.log(`=== Project History: ${proj || 'All Projects'} ===`);
    projectHistory(proj);
    break;
  }
  case 'patternFrequency': {
    console.log('=== Edge Pattern Frequency ===');
    patternFrequency();
    break;
  }
  default:
    showHelp();
}