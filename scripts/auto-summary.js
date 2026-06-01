#!/usr/bin/env node
/**
 * auto-summary.js — T1 session-start graph summary injector
 *
 * Combines past decisions + lessons from the context graph into a single
 * JSON blob, capped at max-tokens (rough estimate: 1 token ~= 4 chars).
 * Fire-and-forget: never blocks session start, never throws.
 *
 * CLI:
 *   node auto-summary.js --project <name> [--days <N>] [--max-tokens <N>]
 *
 * Output: JSON to stdout, shape:
 *   { project, days, tokens_est, decisions: [...], lessons: [...] }
 *
 * Exit codes:
 *   0 — success (may have empty arrays if no graph data)
 *   1 — usage error (no args)
 */

const { execSync } = require('child_process');
const path = require('path');

const CONFIG_DIR = path.resolve(__dirname);
const GQ = path.join(CONFIG_DIR, 'graph-query.js');

// ── Flag parsing ──
function parseArgs(argv) {
  const args = { project: 'default', days: 30, maxTokens: 2000 };
  for (let i = 2; i < argv.length; i++) {
    if (argv[i] === '--project')  args.project = argv[++i];
    else if (argv[i] === '--days')     args.days = parseInt(argv[++i], 10) || 30;
    else if (argv[i] === '--max-tokens') args.maxTokens = parseInt(argv[++i], 10) || 2000;
  }
  return args;
}

function usage() {
  console.error('Usage: node auto-summary.js --project <name> [--days <N>] [--max-tokens <N>]');
  process.exit(1);
}

// ── Graph queries (always return arrays, never throw) ──
function safeExec(cli) {
  try {
    const out = execSync(`node "${GQ}" ${cli}`, { encoding: 'utf8', timeout: 5000 });
    const trimmed = (out || '').trim();
    if (!trimmed || trimmed === '[]') return [];
    const parsed = JSON.parse(trimmed);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

// ── Token estimation ──
function estTokens(obj) {
  return Math.ceil(JSON.stringify(obj).length / 4);
}

// ── Cap by tokens (truncate lessons first, keep all decisions) ──
function capByTokens(decisions, lessons, maxTokens) {
  let result = { decisions, lessons };
  let tokens = estTokens(result);
  if (tokens <= maxTokens) return { ...result, tokens_est: tokens };
  // Truncate lessons from the end until under cap
  while (result.lessons.length > 0 && estTokens(result) > maxTokens) {
    result.lessons = result.lessons.slice(0, -1);
  }
  // If still over cap, truncate decisions
  while (result.decisions.length > 0 && estTokens(result) > maxTokens) {
    result.decisions = result.decisions.slice(0, -1);
  }
  return { ...result, tokens_est: estTokens(result), truncated: true };
}

// ── Main ──
if (process.argv.length < 3) usage();

const args = parseArgs(process.argv);

const decisions = safeExec(`past-decisions --days ${args.days}`);
const lessons   = safeExec(`lessons --keywords ${args.project} --days ${args.days}`);

const out = capByTokens(decisions, lessons, args.maxTokens);
out.project = args.project;
out.days = args.days;

console.log(JSON.stringify(out, null, 2));
process.exit(0);
