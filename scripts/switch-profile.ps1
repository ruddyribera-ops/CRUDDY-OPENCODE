#!/usr/bin/env node
/**
 * OpenCode Profile Switcher
 * Usage: node switch-profile.js <profile-name>
 * Examples: 
 *   node switch-profile.js work
 *   node switch-profile.js personal  
 *   node switch-profile.js minimal
 *   node switch-profile.js list
 */

const fs = require('fs');
const path = require('path');

const CONFIG_DIR = process.env.OPENCODE_CONFIG_DIR || path.join(process.env.HOME || '', '.config', 'opencode');
const PROFILES_DIR = path.join(CONFIG_DIR, 'profiles');
const ACTIVE_PROFILE_FILE = path.join(CONFIG_DIR, '.active-profile');

function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function listProfiles() {
  const profiles = fs.readdirSync(PROFILES_DIR).filter(f => {
    const stat = fs.statSync(path.join(PROFILES_DIR, f));
    return stat.isDirectory();
  });
  
  const active = fs.existsSync(ACTIVE_PROFILE_FILE) 
    ? fs.readFileSync(ACTIVE_PROFILE_FILE, 'utf8').trim() 
    : 'default';
  
  console.log('\nAvailable profiles:');
  profiles.forEach(p => {
    const marker = p === active ? ' *' : '';
    console.log(`  - ${p}${marker}`);
  });
  console.log(`\nActive: ${active}\n`);
}

function switchProfile(name) {
  const profileDir = path.join(PROFILES_DIR, name);
  if (!fs.existsSync(profileDir)) {
    console.error(`Profile '${name}' not found. Run 'list' to see available profiles.`);
    process.exit(1);
  }
  
  const sourceConfig = path.join(profileDir, 'opencode.jsonc');
  const targetConfig = path.join(CONFIG_DIR, 'opencode.jsonc');
  
  if (!fs.existsSync(sourceConfig)) {
    console.error(`Profile '${name}' has no opencode.jsonc file.`);
    process.exit(1);
  }
  
  // Backup current config
  const backupConfig = targetConfig + '.backup';
  if (fs.existsSync(targetConfig)) {
    fs.copyFileSync(targetConfig, backupConfig);
    console.log(`Backed up current config to ${backupConfig}`);
  }
  
  // Copy new config
  fs.copyFileSync(sourceConfig, targetConfig);
  fs.writeFileSync(ACTIVE_PROFILE_FILE, name);
  
  console.log(`✓ Switched to profile: ${name}`);
}

const args = process.argv.slice(2);
const command = args[0];

if (!command || command === 'list' || command === 'ls') {
  listProfiles();
} else if (command === 'switch') {
  switchProfile(args[1]);
} else {
  // Direct profile switch
  switchProfile(command);
}