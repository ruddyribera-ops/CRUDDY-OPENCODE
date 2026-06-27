#!/usr/bin/env node
/**
 * JSONC Validator - validates JSON with Comments
 * Usage: node validate-jsonc.js <file1> <file2> ...
 */

const fs = require('fs');
const path = require('path');

function stripJsonComments(jsonString) {
  // Remove single-line comments //
  let result = jsonString.replace(/\/\/[^\n]*/g, '');
  // Remove multi-line comments /* */
  result = result.replace(/\/\*[\s\S]*?\*\//g, '');
  return result;
}

function validateJsonc(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const stripped = stripJsonComments(content);
    JSON.parse(stripped);
    console.log(`✓ ${filePath}`);
    return true;
  } catch (e) {
    console.error(`✗ ${filePath}: ${e.message}`);
    return false;
  }
}

const args = process.argv.slice(2);
if (args.length === 0) {
  console.error('Usage: node validate-jsonc.js <file1> <file2> ...');
  process.exit(1);
}

let allValid = true;
for (const file of args) {
  if (!validateJsonc(file)) {
    allValid = false;
  }
}

process.exit(allValid ? 0 : 1);