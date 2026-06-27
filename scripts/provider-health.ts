/**
 * OpenCode Provider Health Check
 * Tests all providers and reports status
 * Run: node --experimental-strip-types scripts/provider-health.ts
 */

interface ProviderHealth {
  provider: string;
  model: string;
  healthy: boolean;
  latency: number;
  error?: string;
}

const PROVIDERS = [
  { name: 'minimax', model: 'MiniMax-M2.7', baseURL: 'https://api.minimax.chat/v1', endpoint: '/chat/completions' },
  { name: 'groq', model: 'llama-3.3-70b-versatile', baseURL: 'https://api.groq.com/openai/v1', endpoint: '/chat/completions' },
  { name: 'gemini', model: 'gemini-2.0-flash', baseURL: 'https://generativelanguage.googleapis.com/v1beta', endpoint: '/models/gemini-2.0-flash:generateContent' },
  { name: 'cohere', model: 'command-a-03-2025', baseURL: 'https://api.cohere.ai/compatibility/v1', endpoint: '/chat/completions' },
];

function getApiKey(providerName: string): string | null {
  const keyMap: Record<string, string> = {
    minimax: 'MINIMAX_API_KEY',
    groq: 'GROQ_API_KEY',
    gemini: 'GEMINI_API_KEY',
    cohere: 'COHERE_API_KEY',
  };
  const envVar = keyMap[providerName];
  if (!envVar) return null;
  if (process.env[envVar]) return process.env[envVar];
  try {
    const { execSync } = require('child_process');
    const val = execSync(`powershell.exe -NoProfile -Command "[System.Environment]::GetEnvironmentVariable('${envVar}', 'User')"`, { encoding: 'utf8', windowsHide: true });
    return val.trim() || null;
  } catch { return null; }
}

async function testProvider(p: { name: string; model: string; baseURL: string; endpoint: string }): Promise<ProviderHealth> {
  const start = Date.now();
  const apiKey = getApiKey(p.name);
  
  if (!apiKey) {
    return { provider: p.name, model: p.model, healthy: false, latency: 0, error: 'API key not set' };
  }

  try {
    const testPayload = p.name === 'gemini' 
      ? { contents: [{ parts: [{ text: 'hi' }] }] }
      : { model: p.model, messages: [{ role: 'user', content: 'hi' }], max_tokens: 1 };

    const response = await fetch(`${p.baseURL}${p.endpoint}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
      },
      body: JSON.stringify(testPayload),
    });

    const latency = Date.now() - start;
    
    if (response.ok) {
      return { provider: p.name, model: p.model, healthy: true, latency };
    } else {
      return { provider: p.name, model: p.model, healthy: false, latency, error: `HTTP ${response.status}` };
    }
  } catch (e) {
    return { provider: p.name, model: p.model, healthy: false, latency: Date.now() - start, error: e instanceof Error ? e.message : 'Unknown error' };
  }
}

async function runHealthCheck() {
  console.log('============================================================');
  console.log('  OpenCode Provider Health Check');
  console.log('============================================================');
  console.log();

  const results: ProviderHealth[] = [];
  
  for (const p of PROVIDERS) {
    process.stdout.write(`Testing ${p.name.padEnd(10)}... `);
    const result = await testProvider(p);
    results.push(result);
    if (result.healthy) {
      console.log(`OK (${result.latency}ms)`);
    } else {
      console.log(`FAILED - ${result.error || 'error'}`);
    }
  }

  console.log();
  console.log('============================================================');
  console.log('  Summary');
  console.log('============================================================');
  
  const healthy = results.filter(r => r.healthy);
  console.log(`Total: ${results.length} | Healthy: ${healthy.length} | Failed: ${results.length - healthy.length}`);
  console.log();

  const fallbackOrder = results
    .filter(r => r.healthy)
    .sort((a, b) => a.latency - b.latency)
    .map(r => r.provider);

  console.log('Fallback Chain (healthy, sorted by latency):');
  console.log(`  ${fallbackOrder.join(' -> ')}`);
  console.log();

  if (fallbackOrder.length > 0) {
    console.log(`Primary: ${fallbackOrder[0]} (fastest healthy provider)`);
  } else {
    console.log('WARNING: NO HEALTHY PROVIDERS');
  }

  console.log('============================================================');
  
  return { results, fallbackOrder, primary: fallbackOrder[0] || null };
}

runHealthCheck().catch(console.error);