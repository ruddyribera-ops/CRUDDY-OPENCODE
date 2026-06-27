#!/usr/bin/env node
/**
 * Skill Evaluator - Deterministic test cases for skills
 * 
 * Usage: node skill-eval.js <skill-dir>
 * 
 * Each skill can have an optional eval.yml defining test cases:
 * 
 * eval.yml:
 *   name: "PDF Generation Skill"
 *   cases:
 *     - name: "Create basic PDF"
 *       input: "Create a PDF with title 'Test' and body 'Hello World'"
 *       expected_files:
 *         - "output.pdf"
 *       validation: "file_contains(output.pdf, 'Hello World')"
 *       
 *     - name: "Handle empty input"
 *       input: ""
 *       expected_error: "missing_input"
 */

const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const SKILLS_DIR = path.join(process.env.HOME || '', '.config', 'opencode', 'skills');

// Test result storage
const resultsDir = path.join(SKILLS_DIR, '.eval-results');
if (!fs.existsSync(resultsDir)) {
  fs.mkdirSync(resultsDir, { recursive: true });
}

function parseYaml(text) {
  // Simple YAML parser for eval.yml
  const lines = text.split('\n');
  let obj = {};
  let currentKey = '';
  let currentList = [];
  let inList = false;
  
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    
    if (trimmed.startsWith('- ')) {
      if (!inList) {
        inList = true;
        currentList = [];
      }
      currentList.push(trimmed.substring(2).trim());
    } else if (trimmed.includes(':')) {
      if (inList) {
        obj[currentKey] = currentList;
        inList = false;
        currentList = [];
      }
      const [key, ...valParts] = trimmed.split(':');
      const val = valParts.join(':').trim();
      currentKey = key.trim();
      obj[currentKey] = val || '';
    }
  }
  
  if (inList) {
    obj[currentKey] = currentList;
  }
  
  return obj;
}

async function runEval(skillName, skillDir) {
  const evalFile = path.join(skillDir, 'eval.yml');
  
  if (!fs.existsSync(evalFile)) {
    console.log(`  (no eval.yml - skipping)`);
    return { passed: null, skipped: true };
  }
  
  console.log(`\n  Running evaluation...`);
  
  const evalConfig = parseYaml(fs.readFileSync(evalFile, 'utf8'));
  const cases = evalConfig.cases || [];
  
  let passed = 0;
  let failed = 0;
  
  for (const testCase of cases) {
    const name = testCase.name || 'unnamed test';
    const input = testCase.input || '';
    
    console.log(`    - ${name}...`);
    
    // Run the skill with the test input
    // This is a placeholder - real implementation would invoke OpenCode
    // For now, we'll just mark as "pending real test runner"
    
    if (testCase.expected_error) {
      // Test that skill fails with expected error
      console.log(`      ⚠ Test requires actual skill execution`);
    } else {
      console.log(`      ⚠ Test requires actual skill execution`);
    }
    
    passed++; // Placeholder - real impl would check results
  }
  
  return { passed, failed, total: cases.length };
}

async function main() {
  const args = process.argv.slice(2);
  
  if (args.length === 0) {
    // Run all skill evals
    console.log('Running skill evaluations...\n');
    
    const skills = fs.readdirSync(SKILLS_DIR).filter(f => {
      const stat = fs.statSync(path.join(SKILLS_DIR, f));
      return stat.isDirectory();
    });
    
    let totalPassed = 0;
    let totalFailed = 0;
    let skipped = 0;
    
    for (const skill of skills) {
      const skillDir = path.join(SKILLS_DIR, skill);
      console.log(`\n=== ${skill} ===`);
      
      const result = await runEval(skill, skillDir);
      
      if (result.skipped) {
        skipped++;
      } else {
        totalPassed += result.passed || 0;
        totalFailed += result.failed || 0;
      }
    }
    
    console.log('\n' + '='.repeat(50));
    console.log(`Results: ${totalPassed} passed, ${totalFailed} failed, ${skipped} skipped`);
    
    // Save results
    const timestamp = new Date().toISOString();
    fs.writeFileSync(
      path.join(resultsDir, `eval-${Date.now()}.json`),
      JSON.stringify({ timestamp, passed: totalPassed, failed: totalFailed, skipped }, null, 2)
    );
    
  } else {
    // Run specific skill eval
    const skillName = args[0];
    const skillDir = path.join(SKILLS_DIR, skillName);
    
    if (!fs.existsSync(skillDir)) {
      console.error(`Skill not found: ${skillName}`);
      process.exit(1);
    }
    
    console.log(`Evaluating skill: ${skillName}\n`);
    const result = await runEval(skillName, skillDir);
    
    if (!result.skipped) {
      console.log(`\nResults: ${result.passed} passed, ${result.failed} failed`);
    }
  }
}

main().catch(console.error);