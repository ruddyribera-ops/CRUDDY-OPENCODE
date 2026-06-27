#!/usr/bin/env node
/**
 * authmd-register.js — auth.md service registration CLI
 *
 * CLI:
 *   node authmd-register.js register --service <name>   — register a service
 *   node authmd-register.js discover --url <url>        — discover registration endpoint
 *   node authmd-register.js list                         — list all configured services
 *   node authmd-register.js revoke --service <name>     — revoke a service registration
 *   node authmd-register.js mcp-registry list           — list all registered MCP servers
 *   node authmd-register.js mcp-registry health         — health check all MCP servers
 *   node authmd-register.js mcp-registry add --service <name> --mcp-url <url> --capabilities <csv>
 *                                                      — manually add an MCP server
 *
 * Config: opencode.local.json with agent_identity.services
 * Keys:   .well-known/ec-private.pem (ES256)
 * Registry: memory/agent_mcp_registry.json
 */

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');
const { execSync } = require('child_process');

const CONFIG_DIR = path.resolve(__dirname, '..');
const LOCAL_CONFIG = path.join(CONFIG_DIR, 'opencode.local.json');
const MCP_REGISTRY_PATH = path.join(CONFIG_DIR, 'memory', 'agent_mcp_registry.json');

// ── Helpers ──────────────────────────────────────────────────────────────────

function loadConfig() {
  try {
    return JSON.parse(fs.readFileSync(LOCAL_CONFIG, 'utf8'));
  } catch (err) {
    console.error(`[authmd-register] Failed to load config: ${err.message}`);
    return null;
  }
}

function loadServiceConfig(config, serviceName) {
  const services = config?.agent_identity?.services;
  if (!services || typeof services !== 'object') {
    console.error('[authmd-register] No services configured in opencode.local.json');
    return null;
  }
  const svc = services[serviceName];
  if (!svc) {
    console.error(`[authmd-register] Service "${serviceName}" not found in configuration`);
    return null;
  }
  return svc;
}

function mintIdJag(sub, taskId) {
  try {
    const output = execSync(
      `node "${path.join(CONFIG_DIR, 'scripts', 'agent-identity.js')}" mint --sub "${sub}" --task-id "${taskId}"`,
      { encoding: 'utf8', timeout: 10000 }
    );
    return output.trim();
  } catch (err) {
    throw new Error(`ID-JAG minting failed: ${err.message}`);
  }
}

function httpRequest(url, options = {}) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const isHttps = urlObj.protocol === 'https:';
    const lib = isHttps ? https : http;

    const reqOptions = {
      hostname: urlObj.hostname,
      port: urlObj.port || (isHttps ? 443 : 80),
      path: urlObj.pathname + urlObj.search,
      method: options.method || 'GET',
      headers: options.headers || {}
    };

    const req = lib.request(reqOptions, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          resolve({ status: res.statusCode, body: json, raw: data });
        } catch {
          resolve({ status: res.statusCode, body: data, raw: data });
        }
      });
    });

    req.on('error', reject);
    req.setTimeout(10000, () => {
      req.destroy();
      reject(new Error(`Request timeout: ${url}`));
    });

    if (options.body) {
      req.write(typeof options.body === 'string' ? options.body : JSON.stringify(options.body));
    }
    req.end();
  });
}

function storeCredential(credentialPath, apiKey, expiresAt = null) {
  const dir = path.dirname(credentialPath);
  fs.mkdirSync(dir, { recursive: true });
  const cred = {
    api_key: apiKey,
    registered_at: new Date().toISOString(),
    expires_at: expiresAt
  };
  fs.writeFileSync(credentialPath, JSON.stringify(cred, null, 2), 'utf8');
}

function loadCredential(credentialPath) {
  if (!fs.existsSync(credentialPath)) return null;
  try {
    return JSON.parse(fs.readFileSync(credentialPath, 'utf8'));
  } catch {
    return null;
  }
}

function deleteCredential(credentialPath) {
  if (fs.existsSync(credentialPath)) {
    fs.unlinkSync(credentialPath);
    return true;
  }
  return false;
}

// ── MCP Registry Helpers ─────────────────────────────────────────────────────

function loadMcpRegistry() {
  try {
    if (fs.existsSync(MCP_REGISTRY_PATH)) {
      return JSON.parse(fs.readFileSync(MCP_REGISTRY_PATH, 'utf8'));
    }
  } catch (err) {
    console.error(`[authmd-register] Failed to load MCP registry: ${err.message}`);
  }
  return { version: '1.0', updated_at: new Date().toISOString(), servers: {} };
}

function saveMcpRegistry(registry) {
  registry.updated_at = new Date().toISOString();
  fs.writeFileSync(MCP_REGISTRY_PATH, JSON.stringify(registry, null, 2), 'utf8');
}

function addMcpServer(name, mcpUrl, capabilities = []) {
  const registry = loadMcpRegistry();
  const serverKey = `${name.toLowerCase().replace(/[^a-z0-9]/g, '-')}-mcp`;
  registry.servers[serverKey] = {
    name,
    mcp_url: mcpUrl,
    capabilities: capabilities,
    registered_at: new Date().toISOString(),
    status: 'active'
  };
  saveMcpRegistry(registry);
  return serverKey;
}

function removeMcpServer(serverKey) {
  const registry = loadMcpRegistry();
  if (registry.servers[serverKey]) {
    delete registry.servers[serverKey];
    saveMcpRegistry(registry);
    return true;
  }
  return false;
}

// ── Commands ─────────────────────────────────────────────────────────────────

async function cmdRegister(serviceName) {
  const config = loadConfig();
  if (!config) return 1;

  const svc = loadServiceConfig(config, serviceName);
  if (!svc) return 1;

  const privKeyPath = path.join(CONFIG_DIR, '.well-known', 'ec-private.pem');
  if (!fs.existsSync(privKeyPath)) {
    console.error('[authmd-register] Private key not found. Run: node scripts/agent-identity.js init');
    return 1;
  }

  const taskId = `register-${serviceName}-${Date.now()}`;
  let idJag;
  try {
    idJag = mintIdJag('opencode-agent', taskId);
  } catch (err) {
    console.error(`[authmd-register] ${err.message}`);
    return 1;
  }

  const registrationEndpoint = svc.registration_endpoint;
  if (!registrationEndpoint) {
    console.error(`[authmd-register] No registration_endpoint for ${serviceName}. Run discover first.`);
    return 1;
  }

  console.error(`[authmd-register] Registering ${serviceName} at ${registrationEndpoint}...`);

  try {
    const res = await httpRequest(registrationEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-ID-JAG': idJag
      },
      body: JSON.stringify({
        agent_name: serviceName,
        capabilities: svc.capabilities || ['read']
      })
    });

    if (res.status === 200 || res.status === 201) {
      const apiKey = res.body?.api_key || res.body?.access_token || res.body;
      if (typeof apiKey !== 'string') {
        console.error('[authmd-register] Unexpected response format:', JSON.stringify(res.body));
        return 1;
      }
      const expiresAt = res.body?.expires_at || null;
      storeCredential(svc.credential_path, apiKey, expiresAt);
      console.log(`${serviceName} registered. API key stored at ${svc.credential_path}`);

      // A7: Capture mcp_server from response if present
      const mcpServer = res.body?.mcp_server;
      if (mcpServer && mcpServer.url) {
        const serverKey = addMcpServer(
          serviceName,
          mcpServer.url,
          mcpServer.capabilities || svc.capabilities || []
        );
        console.error(`[authmd-register] MCP server ${serviceName} registered at ${mcpServer.url}`);
      }

      return 0;
    } else if (res.status === 401 || res.status === 403) {
      console.error(`[authmd-register] Authentication failed (${res.status}). Check JWKS export.`);
      console.error('[authmd-register] Run: node scripts/agent-identity.js jwks');
      return 1;
    } else {
      console.error(`[authmd-register] Registration failed: HTTP ${res.status}`);
      if (res.body?.error) {
        console.error(`[authmd-register] Server error: ${res.body.error}`);
      }
      return 1;
    }
  } catch (err) {
    console.error(`[authmd-register] Request failed: ${err.message}`);
    return 1;
  }
}

async function cmdDiscover(url) {
  // Normalize URL
  let baseUrl = url;
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    baseUrl = `https://${baseUrl}`;
  }

  console.error(`[authmd-register] Discovering auth.md endpoint for: ${baseUrl}`);

  try {
    // Step 1: GET /.well-known/oauth-protected-resource
    const protectedRes = await httpRequest(`${baseUrl}/.well-known/oauth-protected-resource`);

    if (protectedRes.status !== 200) {
      console.error(`[authmd-register] ${baseUrl}/.well-known/oauth-protected-resource returned ${protectedRes.status}`);
      console.error('[authmd-register] Service may not support auth.md. Falling back to manual API key.');
      return 1;
    }

    const agentAuth = protectedRes.body?.agent_auth;
    if (!agentAuth) {
      console.error('[authmd-register] No agent_auth block found in protected resource response');
      console.error('[authmd-register] Service may not support auth.md protocol');
      return 1;
    }

    const authServer = agentAuth.authorization_server;
    if (!authServer) {
      console.error('[authmd-register] No authorization_server in agent_auth block');
      return 1;
    }

    console.error(`[authmd-register] Found authorization_server: ${authServer}`);

    // Step 2: GET {authorization_server}/.well-known/oauth-authorization-server
    const authServerRes = await httpRequest(`${authServer}/.well-known/oauth-authorization-server`);

    if (authServerRes.status !== 200) {
      console.error(`[authmd-register] Authorization server metadata returned ${authServerRes.status}`);
      return 1;
    }

    const registrationEndpoint = authServerRes.body?.agent_registration_endpoint;
    if (!registrationEndpoint) {
      console.error('[authmd-register] No agent_registration_endpoint found');
      return 1;
    }

    console.log(`${url}: endpoint = ${registrationEndpoint}`);
    return 0;
  } catch (err) {
    console.error(`[authmd-register] Discovery failed: ${err.message}`);
    return 1;
  }
}

async function cmdList() {
  const config = loadConfig();
  if (!config) return 1;

  const services = config?.agent_identity?.services;
  if (!services || typeof services !== 'object' || Array.isArray(services)) {
    console.error('[authmd-register] No services configured or services is not an object');
    return 1;
  }

  // Header
  console.log('Service'.padEnd(20) + '| Credential Status | Endpoint');
  console.log('-'.repeat(60));

  for (const [name, svc] of Object.entries(services)) {
    const hasCred = fs.existsSync(svc.credential_path);
    const status = hasCred ? 'stored' : 'missing';
    const endpoint = svc.registration_endpoint || svc.discovery_url || 'N/A';
    console.log(`${name.padEnd(20)}| ${status.padEnd(17)}| ${endpoint}`);
  }

  return 0;
}

async function cmdRevoke(serviceName) {
  const config = loadConfig();
  if (!config) return 1;

  const svc = loadServiceConfig(config, serviceName);
  if (!svc) return 1;

  const privKeyPath = path.join(CONFIG_DIR, '.well-known', 'ec-private.pem');
  if (!fs.existsSync(privKeyPath)) {
    console.error('[authmd-register] Private key not found.');
    return 1;
  }

  // Load credential to get any registration ID
  const cred = loadCredential(svc.credential_path);
  if (!cred) {
    console.error(`[authmd-register] No credential found for ${serviceName} at ${svc.credential_path}`);
    return 1;
  }

  const taskId = `revoke-${serviceName}-${Date.now()}`;
  let idJag;
  try {
    idJag = mintIdJag('opencode-agent', taskId);
  } catch (err) {
    console.error(`[authmd-register] ${err.message}`);
    return 1;
  }

  const registrationEndpoint = svc.registration_endpoint;
  if (!registrationEndpoint) {
    console.error(`[authmd-register] No registration_endpoint for ${serviceName}`);
    return 1;
  }

  console.error(`[authmd-register] Revoking ${serviceName} at ${registrationEndpoint}...`);

  try {
    const res = await httpRequest(registrationEndpoint, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
        'X-ID-JAG': idJag
      }
    });

    // 204 No Content = success, 200 also acceptable
    if (res.status === 200 || res.status === 204 || res.status === 202) {
      deleteCredential(svc.credential_path);
      console.log(`${serviceName} revoked`);
      return 0;
    } else if (res.status === 401 || res.status === 403) {
      console.error(`[authmd-register] Authentication failed (${res.status})`);
      return 1;
    } else {
      console.error(`[authmd-register] Revoke failed: HTTP ${res.status}`);
      // Still delete local credential even if server revoke failed
      deleteCredential(svc.credential_path);
      console.error('[authmd-register] Local credential deleted.');
      return 1;
    }
  } catch (err) {
    console.error(`[authmd-register] Request failed: ${err.message}`);
    // Try to delete local credential on network failure
    if (deleteCredential(svc.credential_path)) {
      console.error('[authmd-register] Local credential deleted despite network error.');
    }
    return 1;
  }
}

// ── MCP Registry Commands ────────────────────────────────────────────────────

async function cmdMcpRegistry(args) {
  const subCmd = args[0];

  switch (subCmd) {
    case 'list': {
      const registry = loadMcpRegistry();
      const servers = registry.servers;
      const count = Object.keys(servers).length;

      if (count === 0) {
        console.log('No MCP servers registered.');
        return 0;
      }

      console.log(`MCP Servers (${count}):`);
      console.log('-'.repeat(70));
      for (const [key, srv] of Object.entries(servers)) {
        const caps = (srv.capabilities || []).join(', ');
        console.log(`${srv.name.padEnd(20)} | ${srv.mcp_url.padEnd(35)} | [${caps}]`);
      }
      return 0;
    }

    case 'health': {
      const registry = loadMcpRegistry();
      const servers = registry.servers;
      const keys = Object.keys(servers);

      if (keys.length === 0) {
        console.log('No MCP servers to check.');
        return 0;
      }

      console.log(`Health check for ${keys.length} MCP server(s)...`);
      console.log('-'.repeat(70));

      for (const key of keys) {
        const srv = servers[key];
        try {
          const res = await httpRequest(`${srv.mcp_url}/health`, { method: 'GET' });
          if (res.status === 200) {
            console.log(`[OK]   ${srv.name}: ${srv.mcp_url}`);
          } else {
            console.log(`[WARN] ${srv.name}: HTTP ${res.status}`);
          }
        } catch (err) {
          console.log(`[FAIL] ${srv.name}: ${err.message}`);
        }
      }
      return 0;
    }

    case 'add': {
      // Parse: --service <name> --mcp-url <url> --capabilities <csv>
      const svcIdx = args.indexOf('--service');
      const urlIdx = args.indexOf('--mcp-url');
      const capsIdx = args.indexOf('--capabilities');

      if (svcIdx === -1 || !args[svcIdx + 1]) {
        console.error('Usage: node authmd-register.js mcp-registry add --service <name> --mcp-url <url> --capabilities <csv>');
        return 1;
      }
      if (urlIdx === -1 || !args[urlIdx + 1]) {
        console.error('Usage: node authmd-register.js mcp-registry add --service <name> --mcp-url <url> --capabilities <csv>');
        return 1;
      }

      const name = args[svcIdx + 1];
      const mcpUrl = args[urlIdx + 1];
      const capabilities = capsIdx !== -1 && args[capsIdx + 1]
        ? args[capsIdx + 1].split(',').map(c => c.trim())
        : [];

      const serverKey = addMcpServer(name, mcpUrl, capabilities);
      console.log(`MCP server ${name} added at ${mcpUrl}`);
      return 0;
    }

    default:
      console.error('authmd-register.js mcp-registry — MCP server registry CLI');
      console.error('');
      console.error('Usage:');
      console.error('  node authmd-register.js mcp-registry list           — List all registered MCP servers');
      console.error('  node authmd-register.js mcp-registry health          — Health check all MCP servers');
      console.error('  node authmd-register.js mcp-registry add --service <name> --mcp-url <url> --capabilities <csv>');
      console.error('                                                      — Manually add an MCP server');
      return 1;
  }
}

// ── CLI Router ───────────────────────────────────────────────────────────────

const cmd = process.argv[2];
const args = process.argv.slice(3);

async function main() {
  switch (cmd) {
    case 'register': {
      const serviceIdx = args.indexOf('--service');
      if (serviceIdx === -1 || !args[serviceIdx + 1]) {
        console.error('Usage: node authmd-register.js register --service <name>');
        process.exit(1);
      }
      process.exit(await cmdRegister(args[serviceIdx + 1]));
      break;
    }
    case 'discover': {
      const urlIdx = args.indexOf('--url');
      if (urlIdx === -1 || !args[urlIdx + 1]) {
        console.error('Usage: node authmd-register.js discover --url <url>');
        process.exit(1);
      }
      process.exit(await cmdDiscover(args[urlIdx + 1]));
      break;
    }
    case 'list': {
      process.exit(await cmdList());
      break;
    }
    case 'revoke': {
      const serviceIdx = args.indexOf('--service');
      if (serviceIdx === -1 || !args[serviceIdx + 1]) {
        console.error('Usage: node authmd-register.js revoke --service <name>');
        process.exit(1);
      }
      process.exit(await cmdRevoke(args[serviceIdx + 1]));
      break;
    }
    case 'mcp-registry': {
      process.exit(await cmdMcpRegistry(args));
      break;
    }
    default:
      console.error('authmd-register.js — auth.md service registration CLI');
      console.error('');
      console.error('Usage:');
      console.error('  node authmd-register.js register --service <name>  — Register a service');
      console.error('  node authmd-register.js discover --url <url>       — Discover registration endpoint');
      console.error('  node authmd-register.js list                        — List all services');
      console.error('  node authmd-register.js revoke --service <name>     — Revoke a registration');
      console.error('  node authmd-register.js mcp-registry list           — List all registered MCP servers');
      console.error('  node authmd-register.js mcp-registry health        — Health check all MCP servers');
      console.error('  node authmd-register.js mcp-registry add --service <name> --mcp-url <url> --capabilities <csv>');
      process.exit(1);
  }
}

main();