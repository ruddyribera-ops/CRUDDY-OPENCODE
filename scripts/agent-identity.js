#!/usr/bin/env node
/**
 * agent-identity.js — ES256 keygen + ID-JAG minting
 *
 * CLI:
 *   node agent-identity.js init          — generate keypair (first run)
 *   node agent-identity.js mint --sub <name> --task-id <N>  — mint ID-JAG
 *   node agent-identity.js jwks          — export public key as JWKS
 *
 * Config: reads opencode.local.json for provider settings.
 * Keys cached in .well-known/ec-private.pem (DO NOT COMMIT).
 */

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const CONFIG_DIR = path.resolve(__dirname, '..');
const LOCAL_CONFIG = path.join(CONFIG_DIR, 'opencode.local.json');
const PRIV_KEY_PATH = path.join(CONFIG_DIR, '.well-known', 'ec-private.pem');
const PUB_KEY_PATH = path.join(CONFIG_DIR, '.well-known', 'ec-public.pem');
const JWKS_PATH = path.join(CONFIG_DIR, '.well-known', 'jwks.json');

function loadConfig() {
  try {
    return JSON.parse(fs.readFileSync(LOCAL_CONFIG, 'utf8'));
  } catch { return { agent_identity: { provider: 'main-coordinator', jwt_ttl_seconds: 300 } }; }
}

function base64url(buf) {
  return buf.toString('base64url');
}

function keygen() {
  const { privateKey, publicKey } = crypto.generateKeyPairSync('ec', {
    namedCurve: 'P-256',
    privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
    publicKeyEncoding: { type: 'spki', format: 'pem' }
  });
  fs.mkdirSync(path.dirname(PRIV_KEY_PATH), { recursive: true });
  fs.writeFileSync(PRIV_KEY_PATH, privateKey, 'utf8');
  fs.writeFileSync(PUB_KEY_PATH, publicKey, 'utf8');
  console.error('✅ ES256 keypair generated');
  return { privateKey, publicKey };
}

function loadKeys() {
  if (!fs.existsSync(PRIV_KEY_PATH)) return keygen();
  return {
    privateKey: fs.readFileSync(PRIV_KEY_PATH, 'utf8'),
    publicKey: fs.readFileSync(PUB_KEY_PATH, 'utf8')
  };
}

function mint(sub, taskId) {
  const config = loadConfig();
  const ttl = config.agent_identity?.jwt_ttl_seconds || 300;
  const provider = config.agent_identity?.provider || 'main-coordinator';
  const keys = loadKeys();

  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'ES256', typ: 'JWT', kid: 'opencode-v1' };
  const payload = {
    iss: provider,
    sub: `${sub}@${taskId}`,
    aud: 'auth.md',
    exp: now + ttl,
    nbf: now - 5,
    iat: now,
    jti: crypto.randomUUID(),
    identity_scope: 'agent'
  };

  const b64Header = base64url(Buffer.from(JSON.stringify(header)));
  const b64Payload = base64url(Buffer.from(JSON.stringify(payload)));
  const signingInput = `${b64Header}.${b64Payload}`;

  const signature = crypto.sign('sha256', Buffer.from(signingInput), keys.privateKey);
  const b64Sig = base64url(signature);

  return `${signingInput}.${b64Sig}`;
}

function exportJwks() {
  const keys = loadKeys();
  const pubKeyObj = crypto.createPublicKey(keys.publicKey);
  const jwk = pubKeyObj.export({ format: 'jwk' });

  const jwks = {
    keys: [{
      kty: jwk.kty,
      crv: jwk.crv,
      x: jwk.x,
      y: jwk.y,
      kid: 'opencode-v1',
      use: 'sig',
      alg: 'ES256'
    }]
  };

  fs.mkdirSync(path.dirname(JWKS_PATH), { recursive: true });
  fs.writeFileSync(JWKS_PATH, JSON.stringify(jwks, null, 2), 'utf8');
  console.log(JSON.stringify(jwks, null, 2));
}

// ── CLI ──
const cmd = process.argv[2];

if (cmd === 'init') {
  keygen();
  process.exit(0);
} else if (cmd === 'mint') {
  const subIdx = process.argv.indexOf('--sub');
  const taskIdx = process.argv.indexOf('--task-id');
  if (subIdx === -1 || taskIdx === -1 || !process.argv[subIdx + 1] || !process.argv[taskIdx + 1]) {
    console.error('Usage: node agent-identity.js mint --sub <name> --task-id <N>');
    process.exit(1);
  }
  const sub = process.argv[subIdx + 1];
  const taskId = process.argv[taskIdx + 1];
  console.log(mint(sub, taskId));
  process.exit(0);
} else if (cmd === 'jwks') {
  exportJwks();
  process.exit(0);
} else {
  console.error('Usage:');
  console.error('  node agent-identity.js init                        — generate keypair');
  console.error('  node agent-identity.js mint --sub <name> --task-id <N>  — mint ID-JAG JWT');
  console.error('  node agent-identity.js jwks                        — export public JWKS');
  process.exit(1);
}
