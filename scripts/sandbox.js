#!/usr/bin/env node
/**
 * OpenCode Sandbox Manager
 * 
 * Run OpenCode in isolated Docker containers with network/filesystem isolation
 * 
 * Usage:
 *   node sandbox.js run <command>        # Run command in sandbox
 *   node sandbox.js status              # Show sandbox status
 *   node sandbox.js logs <container>    # Show container logs
 *   node sandbox.js stop                # Stop all sandboxes
 *   node sandbox.js install             # Install jailoc for OpenCode
 */

const { spawn, execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const SANDBOX_DIR = path.join(process.env.HOME || '', '.config', 'opencode', 'sandbox');
const COMPOSE_FILE = path.join(SANDBOX_DIR, 'docker-compose.yaml');

// Ensure sandbox directory exists
if (!fs.existsSync(SANDBOX_DIR)) {
  fs.mkdirSync(SANDBOX_DIR, { recursive: true });
}

const dockerCompose = `
version: '3.8'

services:
  opencode-sandbox:
    image: ubuntu:22.04
    container_name: opencode-sandbox
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    networks:
      - sandbox-net
    
  # Jailoc integration (OpenCode-specific sandboxing)
  jailoc:
    build: 
      context: https://github.com/seznam/jailoc.git
      dockerfile: Dockerfile
    container_name: opencode-jailoc
    volumes:
      - ./work:/work
    cap_add:
      - SYS_ADMIN
    security_opt:
      - seccomp:unconfined
    networks:
      - sandbox-net

networks:
  sandbox-net:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.name: opencode-sandbox
`;

async function installJailoc() {
  console.log('Installing jailoc (OpenCode sandbox)...');
  
  try {
    execSync('docker build -t jailoc https://github.com/seznam/jailoc.git', {
      stdio: 'inherit'
    });
    console.log('✓ jailoc installed');
  } catch (e) {
    console.error('✗ Failed to install jailoc:', e.message);
  }
}

async function runInSandbox(command, args = []) {
  console.log(`Running in sandbox: ${command} ${args.join(' ')}`);
  
  // Create work directory for this session
  const sessionDir = path.join(SANDBOX_DIR, `session-${Date.now()}`);
  fs.mkdirSync(sessionDir, { recursive: true });
  
  // Run the command in Docker with isolation
  const dockerArgs = [
    'run', '--rm',
    '--cap-drop', 'ALL',
    '--security-opt', 'no-new-privileges:true',
    '-v', `${sessionDir}:/workspace`,
    '-v', `${process.env.HOME || ''}/.config/opencode:/opencode-config:ro`,
    'ubuntu:22.04',
    'sh', '-c', `cd /workspace && ${command} ${args.join(' ')}`
  ];
  
  return new Promise((resolve, reject) => {
    const proc = spawn('docker', dockerArgs, {
      stdio: 'inherit',
      env: { ...process.env }
    });
    
    proc.on('close', (code) => {
      resolve(code);
    });
    
    proc.on('error', reject);
  });
}

async function showStatus() {
  console.log('\n=== OpenCode Sandbox Status ===\n');
  
  try {
    const containers = execSync('docker ps -a --filter "name=opencode" --format "{{.Names}}\t{{.Status}}"')
      .toString()
      .trim();
    
    if (containers) {
      console.log('Active containers:');
      console.log(containers);
    } else {
      console.log('No sandbox containers running');
    }
  } catch (e) {
    console.log('Docker not available or no containers');
  }
  
  console.log('\nSandbox options available:');
  console.log('  - jailoc:     https://github.com/seznam/jailoc (OpenCode-specific)');
  console.log('  - porta:      https://github.com/almide/porta (WASM isolation, no Docker)');
  console.log('  - rustyolo:   https://github.com/brooksomics/llm-rustyolo (filesystem/network isolation)');
}

async function stopSandboxes() {
  console.log('Stopping sandbox containers...');
  
  try {
    execSync('docker stop $(docker ps -aq --filter "name=opencode") 2>/dev/null || true');
    execSync('docker rm $(docker ps -aq --filter "name=opencode") 2>/dev/null || true');
    console.log('✓ Sandboxes stopped');
  } catch (e) {
    console.log('No containers to stop');
  }
}

const args = process.argv.slice(2);
const command = args[0];

switch (command) {
  case 'run':
    const runArgs = args.slice(2);
    await runInSandbox(args[1], runArgs);
    break;
    
  case 'status':
    await showStatus();
    break;
    
  case 'install':
    await installJailoc();
    break;
    
  case 'stop':
    await stopSandboxes();
    break;
    
  case 'logs':
    const containerName = args[1] || 'opencode-sandbox';
    execSync(`docker logs ${containerName}`, { stdio: 'inherit' });
    break;
    
  default:
    console.log(`
OpenCode Sandbox Manager

Usage:
  node sandbox.js run <command>     Run command in sandbox
  node sandbox.js status           Show sandbox status
  node sandbox.js install          Install jailoc
  node sandbox.js logs [container] Show container logs
  node sandbox.js stop            Stop all sandboxes

More info:
  https://github.com/seznam/jailoc - OpenCode-specific Docker sandbox
  https://github.com/almide/porta - WASM isolation (no Docker needed)
`);
}