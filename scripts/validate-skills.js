#!/usr/bin/env node
/**
 * SKILL.md Validator - validates skill files have required fields
 * Usage: node validate-skills.js <file1> <file2> ...
 */

const fs = require('fs');
const path = require('path');

function validateSkill(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    
    // Check for required sections
    const hasDescription = content.includes('description') || content.includes('Description');
    const hasTriggers = content.includes('Trigger') || content.includes('trigger');
    
    // Check for empty file
    if (content.trim().length < 50) {
      console.error(`✗ ${filePath}: File too small (likely empty template)`);
      return false;
    }
    
    // Check for required frontmatter or key sections
    const valid = hasDescription && hasTriggers;
    
    if (valid) {
      console.log(`✓ ${filePath}`);
    } else {
      console.error(`✗ ${filePath}: Missing required fields (description, triggers)`);
    }
    return valid;
  } catch (e) {
    console.error(`✗ ${filePath}: ${e.message}`);
    return false;
  }
}

const args = process.argv.slice(2);
if (args.length === 0) {
  console.error('Usage: node validate-skills.js <file1> <file2> ...');
  process.exit(1);
}

let allValid = true;
for (const file of args) {
  if (!validateSkill(file)) {
    allValid = false;
  }
}

process.exit(allValid ? 0 : 1);