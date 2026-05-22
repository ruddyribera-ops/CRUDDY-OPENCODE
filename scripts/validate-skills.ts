/**
 * OpenCode Skill Validation Script
 * Verifies all SKILL.md files have valid structure
 * Run: node --experimental-strip-types scripts/validate-skills.ts
 */

import { readdirSync, readFileSync, writeFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';

interface ValidationResult {
  skill: string;
  valid: boolean;
  errors: string[];
}

const SKILLS_DIR = join(process.env.USERPROFILE || '', '.config', 'opencode', 'skills');

function validateSkill(skillName: string, content: string): ValidationResult {
  const errors: string[] = [];
  
  // Check for frontmatter
  if (!content.startsWith('---')) {
    errors.push('Missing frontmatter (---)');
  }
  
  // Check for required sections
  const requiredSections = ['Description', 'Trigger', 'Use when'];
  for (const section of requiredSections) {
    if (!content.includes(section)) {
      errors.push(`Missing section: "${section}"`);
    }
  }
  
  // Check for empty description
  const descMatch = content.match(/Description[:\s]*([^\n]+)/i);
  if (!descMatch || !descMatch[1].trim()) {
    errors.push('Empty or missing description');
  }
  
  // Check for triggers
  if (!content.includes('Trigger') && !content.includes('trigger')) {
    errors.push('Missing trigger keywords');
  }
  
  return {
    skill: skillName,
    valid: errors.length === 0,
    errors,
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
              valid: false,
              errors: [`Could not read: ${e instanceof Error ? e.message : 'Unknown error'}`],
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
  console.log('  OpenCode Skill Validation');
  console.log('============================================================');
  console.log();
  console.log(`Scanning: ${SKILLS_DIR}`);
  console.log();

  const results: ValidationResult[] = [];
  scanSkillsDir(SKILLS_DIR, results);

  const validCount = results.filter(r => r.valid).length;
  const invalidCount = results.filter(r => !r.valid).length;

  // Show invalid first
  const invalid = results.filter(r => !r.valid);
  const valid = results.filter(r => r.valid);

  if (invalid.length > 0) {
    console.log('ISSUES FOUND:');
    console.log('-'.repeat(60));
    for (const r of invalid) {
      console.log(`\n[FAIL] ${r.skill}`);
      for (const err of r.errors) {
        console.log(`    - ${err}`);
      }
    }
    console.log();
  }

  console.log('VALID SKILLS:');
  console.log('-'.repeat(60));
  for (const r of valid) {
    console.log(`[OK] ${r.skill}`);
  }

  console.log();
  console.log('============================================================');
  console.log(`Total: ${results.length} | Valid: ${validCount} | Invalid: ${invalidCount}`);
  console.log('============================================================');

  // Write report
  const reportPath = join(dirname(SKILLS_DIR), 'memory', 'skill_validation_report.md');
  const report = `# Skill Validation Report
  
Generated: ${new Date().toISOString()}

## Summary
- Total: ${results.length}
- Valid: ${validCount}  
- Invalid: ${invalidCount}

## Invalid Skills
${invalid.map(r => `- ${r.skill}: ${r.errors.join(', ')}`).join('\n') || 'None'}

## Valid Skills
${valid.map(r => `- ${r.skill}`).join('\n')}
`;
  
  try {
    writeFileSync(reportPath, report, 'utf-8');
    console.log(`\nReport written to: ${reportPath}`);
  } catch (e) {
    console.log(`\n(Note: Could not write report file)`);
  }

  return invalidCount === 0;
}

const success = runValidation();
process.exit(success ? 0 : 1);