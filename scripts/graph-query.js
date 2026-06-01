#!/usr/bin/env node
/**
 * graph-query.js — Higher-level query helpers wrapping graph-memory.js
 *
 * CLI:
 *   node graph-query.js past-decisions --domain <domain> [--days <N>]
 *   node graph-query.js lessons --keywords <kw1,kw2> [--days <N>]
 *   node graph-query.js blockers --project <name>
 *   node graph-query.js session --project <name>
 *
 * Calls graph-memory.js under the hood, filters results by context.
 */

const { execSync } = require('child_process');
const path = require('path');

const CONFIG_DIR = path.resolve(__dirname);
const GM = path.join(CONFIG_DIR, 'graph-memory.js');

function runGM(args) {
  try {
    const out = execSync(`node "${GM}" ${args}`, { encoding: 'utf8', timeout: 5000 });
    return JSON.parse(out.trim() || '[]');
  } catch { return []; }
}

function pastDecisions(domain, days) {
  const results = runGM(`query --type decision --days ${days || 30} --limit 10`);
  if (!domain) { console.log(JSON.stringify(results, null, 2)); return; }
  const filtered = results.filter(d =>
    (d.name && d.name.toLowerCase().includes(domain.toLowerCase())) ||
    (d.data && d.data.context && d.data.context.toLowerCase().includes(domain.toLowerCase()))
  );
  console.log(JSON.stringify(filtered, null, 2));
}

function lessons(keywords, days) {
  const results = runGM(`query --type lesson --days ${days || 30} --limit 10`);
  if (!keywords) { console.log(JSON.stringify(results, null, 2)); return; }
  const kwList = keywords.split(',').map(k => k.trim().toLowerCase());
  const filtered = results.filter(l => {
    const text = `${l.name || ''} ${JSON.stringify(l.data || '')}`.toLowerCase();
    return kwList.some(kw => text.includes(kw));
  });
  console.log(JSON.stringify(filtered, null, 2));
}

function blockers(project) {
  const results = runGM(`query --type lesson --days 90 --limit 20`);
  const filtered = results.filter(l =>
    l.data && l.data.category === 'blocker' &&
    (!project || (l.name && l.name.toLowerCase().includes(project.toLowerCase())))
  );
  console.log(JSON.stringify(filtered, null, 2));
}

function recentSession(project) {
  const results = runGM(`query --type session --days 7 --limit 5`);
  if (!project) { console.log(JSON.stringify(results, null, 2)); return; }
  const filtered = results.filter(s =>
    s.data && s.data.projects_touched &&
    JSON.stringify(s.data.projects_touched).toLowerCase().includes(project.toLowerCase())
  );
  console.log(JSON.stringify(filtered, null, 2));
}

// ── CLI ──
const cmd = process.argv[2];

if (cmd === 'past-decisions') {
  const domainIdx = process.argv.indexOf('--domain');
  const daysIdx = process.argv.indexOf('--days');
  pastDecisions(
    domainIdx !== -1 ? process.argv[domainIdx + 1] : null,
    daysIdx !== -1 ? parseInt(process.argv[daysIdx + 1], 10) : null
  );
} else if (cmd === 'lessons') {
  const kwIdx = process.argv.indexOf('--keywords');
  const daysIdx = process.argv.indexOf('--days');
  lessons(
    kwIdx !== -1 ? process.argv[kwIdx + 1] : null,
    daysIdx !== -1 ? parseInt(process.argv[daysIdx + 1], 10) : null
  );
} else if (cmd === 'blockers') {
  const projIdx = process.argv.indexOf('--project');
  blockers(projIdx !== -1 ? process.argv[projIdx + 1] : null);
} else if (cmd === 'session') {
  const projIdx = process.argv.indexOf('--project');
  recentSession(projIdx !== -1 ? process.argv[projIdx + 1] : null);
} else {
  console.error('Usage:');
  console.error('  node graph-query.js past-decisions [--domain <name>] [--days <N>]');
  console.error('  node graph-query.js lessons [--keywords <kw,kw>] [--days <N>]');
  console.error('  node graph-query.js blockers [--project <name>]');
  console.error('  node graph-query.js session [--project <name>]');
  process.exit(1);
}
