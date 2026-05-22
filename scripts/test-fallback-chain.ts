/**
 * Fallback Chain Test for OpenCode Multi-Provider Setup
 * Tests MiniMax -> Groq -> Gemini -> Cohere fallback sequence
 */

import { readFileSync, existsSync } from 'fs';
import { resolve } from 'path';

interface ProviderConfig {
  name: string;
  baseURL: string;
  apiKey: string;
  models: Record<string, { name: string }>;
}

interface OpenCodeConfig {
  provider?: Record<string, ProviderConfig>;
}

interface TestResult {
  provider: string;
  model: string;
  success: boolean;
  latency: number;
  error?: string;
  output?: string;
}

async function testProvider(
  providerName: string,
  baseURL: string,
  apiKey: string,
  modelName: string,
  testPrompt: string
): Promise<TestResult> {
  const start = Date.now();

  try {
    // MiniMax uses v2 endpoint with /text/ path
    let endpoint = '/chat/completions';
    // MiniMax uses v2 endpoint with /text/ path
    if (providerName === 'minimax' && baseURL.includes('api.minimax.io')) {
      endpoint = '/text/chatcompletion_v2';
    }
    // Cohere uses /compatibility/v1 path
    if (providerName === 'cohere') {
      endpoint = '/chat/completions';
    }

    const response = await fetch(`${baseURL}${endpoint}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey.includes('env:') ? process.env[apiKey.replace('{env:', '').replace('}', '')] || 'MISSING_ENV' : apiKey}`
      },
      body: JSON.stringify({
        model: modelName,
        messages: [{ role: 'user', content: testPrompt }],
        max_tokens: 20,
        temperature: 0.7,
      }),
    });

    const latency = Date.now() - start;

    if (!response.ok) {
      const errorBody = await response.text().catch(() => 'No body');
      return {
        provider: providerName,
        model: modelName,
        success: false,
        latency,
        error: `HTTP ${response.status}: ${errorBody.substring(0, 200)}`,
      };
    }

    const data = await response.json() as { choices?: { message?: { content?: string } }[] };

    return {
      provider: providerName,
      model: modelName,
      success: true,
      latency,
      output: data?.choices?.[0]?.message?.content?.substring(0, 100) || '(empty)',
    };
  } catch (err) {
    return {
      provider: providerName,
      model: modelName,
      success: false,
      latency: Date.now() - start,
      error: err instanceof Error ? err.message : String(err),
    };
  }
}

function loadOpenCodeConfig(): OpenCodeConfig | null {
  const configPath = resolve(
    process.env.USERPROFILE || process.env.HOME || '',
    '.config',
    'opencode',
    'opencode.json'
  );

  if (!existsSync(configPath)) {
    const altPath = resolve(process.cwd(), 'opencode.json');
    if (existsSync(altPath)) {
      return JSON.parse(readFileSync(altPath, 'utf-8')) as OpenCodeConfig;
    }
    return null;
  }

  return JSON.parse(readFileSync(configPath, 'utf-8')) as OpenCodeConfig;
}

function resolveApiKey(key: string): string {
  if (key.startsWith('{env:') && key.endsWith('}')) {
    const envVar = key.replace('{env:', '').replace('}', '');
    // Try session first
    if (process.env[envVar]) return process.env[envVar];
    // Read from Windows registry via PowerShell - force fresh read
    try {
      const { execSync } = require('child_process');
      const registryValue = execSync(
        `powershell.exe -NoProfile -Command "[System.Environment]::GetEnvironmentVariable('${envVar}', 'User')"`,
        { encoding: 'utf8', windowsHide: true }
      );
      const trimmed = registryValue.trim();
      return trimmed || '{env:VAR_NOT_SET}';
    } catch (e) {
      return '{env:VAR_NOT_SET}';
    }
  }
  return key;
}

const FALLBACK_ORDER = ['minimax', 'groq', 'gemini', 'cohere'];
const TEST_PROMPT = 'Say exactly "MiniMax tested successfully" and nothing else.';

async function runFallbackChainTest(): Promise<void> {
  console.log('='.repeat(70));
  console.log('  OpenCode Multi-Provider Fallback Chain Test');
  console.log('='.repeat(70));
  console.log();

  const config = loadOpenCodeConfig();

  if (!config?.provider) {
    console.error('Could not load OpenCode config.');
    process.exit(1);
  }

  const envVars = ['MINIMAX_API_KEY', 'GROQ_API_KEY', 'GEMINI_API_KEY', 'COHERE_API_KEY'];
  console.log('Env Var Status:');
  for (const ev of envVars) {
    const status = process.env[ev] ? 'SET' : 'NOT SET';
    console.log(`   ${ev}: ${status}`);
  }
  console.log();

  const results: TestResult[] = [];
  let firstSuccess: TestResult | null = null;

  for (const providerName of FALLBACK_ORDER) {
    const provider = config.provider[providerName];
    if (!provider?.options) {
      console.log(`SKIP ${providerName.toUpperCase()}: Not configured`);
      continue;
    }

    const apiKey = resolveApiKey(provider.options.apiKey || '');
    const baseURL = provider.options.baseURL || '';
    const firstModel = Object.values(provider.models || {})[0]?.name || '';

    if (!firstModel) {
      console.log(`SKIP ${providerName.toUpperCase()}: No models configured`);
      continue;
    }

    console.log(`Testing ${providerName.toUpperCase()} (${firstModel})...`);

    if (apiKey === '{env:VAR_NOT_SET}') {
      console.log(`   API Key not set - skipping`);
      console.log();
      continue;
    }

    const result = await testProvider(providerName, baseURL, apiKey, firstModel, TEST_PROMPT);
    results.push(result);

    if (result.success) {
      console.log(`   SUCCESS in ${result.latency}ms`);
      console.log(`   Output: ${result.output}`);
      if (!firstSuccess) firstSuccess = result;
    } else {
      console.log(`   FAILED in ${result.latency}ms`);
      console.log(`   Error: ${result.error}`);
    }
    console.log();
  }

  console.log('='.repeat(70));
  console.log('  SUMMARY');
  console.log('='.repeat(70));
  console.log();

  const successCount = results.filter((r) => r.success).length;
  console.log(`Total tested: ${results.length} | OK: ${successCount} | FAIL: ${results.length - successCount}`);
  console.log();

  if (firstSuccess) {
    console.log(`Primary: ${firstSuccess.provider} (${firstSuccess.model}) - ${firstSuccess.latency}ms`);
  } else {
    console.log('WARNING: NO PROVIDERS SUCCEEDED');
  }

  console.log();
  console.log('All Results:');
  for (const r of results) {
    const status = r.success ? 'OK' : 'FAIL';
    console.log(`   [${status}] ${r.provider.padEnd(10)} ${r.model.padEnd(25)} ${r.latency}ms`);
  }

  console.log();
  console.log('='.repeat(70));
}

runFallbackChainTest().catch((err) => {
  console.error('Test crashed:', err);
  process.exit(1);
});