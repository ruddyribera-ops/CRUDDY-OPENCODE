/**
 * OpenCode Skill Validator — Tiered Validation
 *
 * Tier 1 (FAIL): Hard errors per Anthropic SKILL.md spec
 *   - Missing or unparseable YAML frontmatter
 *   - Missing required `name` field
 *   - Missing required `description` field (must be 30+ chars)
 *
 * Tier 2 (WARN): Recommended fields per OpenCode routing
 *   - Missing `triggers` field (less discoverable)
 *   - Description under 100 chars (weak trigger matching)
 *
 * Tier 3 (INFO): Style suggestions
 *   - No `## When to use` markdown section
 *   - No `version` in frontmatter
 *   - Body under 1000 chars
 *
 * Run: node --experimental-strip-types scripts/validate-skills.ts
 */

import { readdirSync, readFileSync, writeFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import * as yaml from 'js-yaml';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

interface ValidationResult {
  skill: string;
  tier1Errors: string[];   // FAIL — must fix
  tier2Warnings: string[];  // WARN — should fix
  tier3Info: string[];      // INFO — nice to have
  valid: boolean;            // true if no tier1 errors
}

const SKILLS_DIR = join(__dirname, '..', 'skills');
const MIN_DESCRIPTION_LENGTH = 30;
const MIN_BODY_LENGTH = 500;

function validateSkill(skillName: string, content: string): ValidationResult {
  const tier1Errors: string[] = [];
  const tier2Warnings: string[] = [];
  const tier3Info: string[] = [];

  // ── TIER 1: Hard errors (per Anthropic SKILL.md spec) ──
  if (!content.startsWith('---')) {
    tier1Errors.push('Missing YAML frontmatter (file must start with ---)');
    return { skill: skillName, tier1Errors, tier2Warnings, tier3Info, valid: false };
  }

  const fmMatch = content.match(/^---\s*\n(.*?)\n---/s);
  if (!fmMatch) {
    tier1Errors.push('YAML frontmatter not properly delimited (--- not closed)');
    return { skill: skillName, tier1Errors, tier2Warnings, tier3Info, valid: false };
  }

  let fm: any;
  try {
    fm = yaml.load(fmMatch[1]);
  } catch (e) {
    tier1Errors.push(`YAML frontmatter parse error: ${e instanceof Error ? e.message : String(e)}`);
    return { skill: skillName, tier1Errors, tier2Warnings, tier3Info, valid: false };
  }

  if (!fm || typeof fm !== 'object') {
    tier1Errors.push('YAML frontmatter parsed to non-object (likely malformed)');
    return { skill: skillName, tier1Errors, tier2Warnings, tier3Info, valid: false };
  }

  // Required: name (string, lowercase-kebab-case per Anthropic spec)
  if (!fm.name || typeof fm.name !== 'string') {
    tier1Errors.push('Missing required field: `name`');
  } else if (!/^[a-z0-9-]+$/.test(fm.name)) {
    tier1Errors.push(`Field \`name\` must be lowercase-kebab-case: "${fm.name}"`);
  }

  // Required: description (string, 30+ chars per Anthropic spec)
  if (!fm.description || typeof fm.description !== 'string') {
    tier1Errors.push('Missing required field: `description`');
  } else if (fm.description.length < MIN_DESCRIPTION_LENGTH) {
    tier1Errors.push(`Field \`description\` too short (${fm.description.length} chars, min ${MIN_DESCRIPTION_LENGTH})`);
  }

  // ── TIER 2: Warnings (per OpenCode routing) ──
  if (!fm.triggers || !Array.isArray(fm.triggers) || fm.triggers.length === 0) {
    tier2Warnings.push('Missing or empty `triggers` field (skill less discoverable)');
  }

  if (fm.description && fm.description.length < 100) {
    tier2Warnings.push(`Description under 100 chars (${fm.description.length}) — trigger matching may be weak`);
  }

  if (!fm['applies_to']) {
    tier2Warnings.push('Missing `applies_to` field (which agents should load this skill)');
  }

  // ── TIER 3: Info (style suggestions) ──
  const body = content.slice(fmMatch[0].length).trim();
  if (body.length < MIN_BODY_LENGTH) {
    tier3Info.push(`Body short (${body.length} chars, suggest ${MIN_BODY_LENGTH}+ for usefulness)`);
  }

  if (!fm.version) {
    tier3Info.push('No `version` field in frontmatter');
  }

  // Note: `## When to use` markdown section is recommended but not required.
  // Per Anthropic spec, only YAML frontmatter is required.
  if (!/^##\s+(when to use|usage)/im.test(body)) {
    tier3Info.push('No "## When to use" markdown section (recommended for clarity)');
  }

  return {
    skill: skillName,
    tier1Errors,
    tier2Warnings,
    tier3Info,
    valid: tier1Errors.length === 0,
  };
}

function scanSkillsDir(dir: string, results: ValidationResult[]): void {
  try {
    const entries = readdirSync(dir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = join(dir, entry.name);

      if (entry.isDirectory()) {
        const skillFile = join(fullPath, 'SKILL.md');
        if (existsSync(skillFile)) {
          try {
            const content = readFileSync(skillFile, 'utf-8');
            const result = validateSkill(entry.name, content);
            results.push(result);
          } catch (e) {
            results.push({
              skill: entry.name,
              tier1Errors: [`Could not read: ${e instanceof Error ? e.message : 'Unknown error'}`],
              tier2Warnings: [],
              tier3Info: [],
              valid: false,
            });
          }
        }
      }
    }
  } catch (e) {
    console.error(`Error scanning directory: ${e}`);
  }
}

function runValidation() {
  console.log('============================================================');
  console.log('  OpenCode Skill Validator — Tiered (Anthropic SKILL.md spec)');
  console.log('============================================================');
  console.log();
  console.log(`Scanning: ${SKILLS_DIR}`);
  console.log();

  const results: ValidationResult[] = [];
  scanSkillsDir(SKILLS_DIR, results);

  // Categorize by tier
  const tier1Failures = results.filter(r => r.tier1Errors.length > 0);
  const tier2Only = results.filter(r => r.tier1Errors.length === 0 && r.tier2Warnings.length > 0);
  const tier3Only = results.filter(r => r.tier1Errors.length === 0 && r.tier2Warnings.length === 0 && r.tier3Info.length > 0);
  const clean = results.filter(r => r.tier1Errors.length === 0 && r.tier2Warnings.length === 0 && r.tier3Info.length === 0);

  // Output
  if (tier1Failures.length > 0) {
    console.log(`[TIER 1 FAIL] ${tier1Failures.length} skill(s) with hard errors (per Anthropic SKILL.md spec):`);
    console.log('-'.repeat(70));
    for (const r of tier1Failures) {
      console.log(`\n  ${r.skill}:`);
      for (const err of r.tier1Errors) {
        console.log(`    - ${err}`);
      }
    }
    console.log();
  }

  if (tier2Only.length > 0) {
    console.log(`[TIER 2 WARN] ${tier2Only.length} skill(s) with warnings:`);
    console.log('-'.repeat(70));
    for (const r of tier2Only) {
      console.log(`\n  ${r.skill}:`);
      for (const w of r.tier2Warnings) {
        console.log(`    - ${w}`);
      }
    }
    console.log();
  }

  if (tier3Only.length > 0) {
    console.log(`[TIER 3 INFO] ${tier3Only.length} skill(s) with style suggestions:`);
    console.log('-'.repeat(70));
    for (const r of tier3Only) {
      console.log(`  ${r.skill}: ${r.tier3Info.length} suggestion(s)`);
    }
    console.log();
  }

  console.log(`[CLEAN] ${clean.length} skill(s) passing all tiers`);
  console.log();

  console.log('============================================================');
  console.log(`Total: ${results.length} | T1 fail: ${tier1Failures.length} | T2 warn: ${tier2Only.length} | T3 info: ${tier3Only.length} | Clean: ${clean.length}`);
  console.log('============================================================');

  // Write report
  const reportPath = join(dirname(SKILLS_DIR), 'memory', 'skill_validation_report.md');
  const report = `# Skill Validation Report (Tiered)

Generated: ${new Date().toISOString()}

## Summary
- Total skills: ${results.length}
- TIER 1 FAIL (hard errors): ${tier1Failures.length}
- TIER 2 WARN (should fix): ${tier2Only.length}
- TIER 3 INFO (style): ${tier3Only.length}
- Clean: ${clean.length}

## Tier Definitions
- **TIER 1 FAIL**: Hard errors per Anthropic SKILL.md spec (unparseable YAML, missing name or description)
- **TIER 2 WARN**: Recommended fields per OpenCode routing (triggers, applies_to)
- **TIER 3 INFO**: Style suggestions (version field, When to use section, body length)

## Tier 1 Failures
${tier1Failures.map(r => `- ${r.skill}: ${r.tier1Errors.join('; ')}`).join('\n') || 'None'}

## Tier 2 Warnings
${tier2Only.map(r => `- ${r.skill}: ${r.tier2Warnings.join('; ')}`).join('\n') || 'None'}

## Tier 3 Info (summary)
${tier3Only.map(r => `- ${r.skill}: ${r.tier3Info.length} suggestions`).join('\n') || 'None'}

## Clean Skills (all tiers pass)
${clean.map(r => `- ${r.skill}`).join('\n') || 'None'}
`;

  try {
    writeFileSync(reportPath, report, 'utf-8');
    console.log(`\nReport written to: ${reportPath}`);
  } catch (e) {
    console.log(`\n(Note: Could not write report file: ${e instanceof Error ? e.message : String(e)})`);
  }

  // Exit code: non-zero ONLY if tier 1 failures exist
  process.exit(tier1Failures.length === 0 ? 0 : 1);
}

runValidation();