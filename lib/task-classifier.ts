/**
 * Task Difficulty Classifier for OpenCode
 * Routes tasks to appropriate model tiers based on complexity scoring
 */

import { readFileSync, existsSync } from 'fs';
import { resolve } from 'path';

// ============================================================================
// Types
// ============================================================================

interface TierAssignment {
  tier: 1 | 2 | 3;
  score: number;
  reasoning: string;
  suggestedProvider: string;
  suggestedModel: string;
  alternativeProviders?: string[];
}

interface TaskContext {
  fileCount?: number;
  filePaths?: string[];
  taskType?: TaskType;
  expectedOperations?: Operation[];
  isNewProject?: boolean;
  isFullStack?: boolean;
  isArchitectureDecision?: boolean;
  isMultiDomain?: boolean;
  hasTesting?: boolean;
  hasMigration?: boolean;
  hasDeployment?: boolean;
}

type TaskType =
  | 'read'
  | 'write'
  | 'edit'
  | 'refactor'
  | 'debug'
  | 'analyze'
  | 'architect'
  | 'generate'
  | 'test'
  | 'deploy'
  | 'review'
  | 'question';

type Operation =
  | 'create'
  | 'delete'
  | 'rename'
  | 'move'
  | 'copy'
  | 'modify'
  | 'read'
  | 'search'
  | 'execute';

interface ProviderConfig {
  [providerName: string]: {
    name?: string;
    models?: {
      [modelName: string]: {
        name: string;
      };
    };
  };
}

interface OpenCodeConfig {
  provider?: ProviderConfig;
}

// ============================================================================
// Provider Definitions
// ============================================================================

const TIER_CONFIGS = {
  1: {
    name: 'Simple',
    scoreRange: [0, 3],
    providers: [
      { provider: 'groq', model: 'llama-3.3-70b-versatile', tier: 1 },      // Fastest, free tier (14.4K/day)
      { provider: 'cohere', model: 'command-a-03-2025', tier: 1 },
    ],
  },
  2: {
    name: 'Medium',
    scoreRange: [4, 6],
    providers: [
      { provider: 'cohere', model: 'command-a-03-2025', tier: 2 },
      { provider: 'groq', model: 'llama-3.3-70b-versatile', tier: 2 },
    ],
  },
  3: {
    name: 'Complex',
    scoreRange: [7, 10],
    providers: [
      { provider: 'minimax', model: 'MiniMax-M2.7', tier: 3 },              // Primary (1500 req/5hrs)
    ],
  },
} as const;

// ============================================================================
// Task Analysis
// ============================================================================

interface TaskAnalysis {
  fileCount: number;
  taskType: TaskType[];
  operations: Operation[];
  isNewProject: boolean;
  isFullStack: boolean;
  isArchitectureDecision: boolean;
  isMultiDomain: boolean;
  hasTesting: boolean;
  hasMigration: boolean;
  hasDeployment: boolean;
  hasSecurityConsideration: boolean;
  isMultiStep: boolean;
  keywords: string[];
}

/**
 * Extract task characteristics from the task string
 */
function analyzeTask(task: string, context?: TaskContext): TaskAnalysis {
  const lowerTask = task.toLowerCase();
  const words = lowerTask.split(/\s+/);

  // Detect keywords
  const keywords = detectKeywords(lowerTask);

  // Extract file count from context or estimate from task
  const fileCount = context?.fileCount ?? estimateFileCount(task);

  // Detect task types
  const taskType = detectTaskTypes(task, lowerTask, context);

  // Detect operations
  const operations = detectOperations(task, lowerTask);

  // Detect special conditions
  const isNewProject = detectNewProject(lowerTask);
  const isFullStack = detectFullStack(lowerTask);
  const isArchitectureDecision = detectArchitectureDecision(lowerTask);
  const isMultiDomain = detectMultiDomain(lowerTask, context);
  const hasTesting = detectTesting(lowerTask);
  const hasMigration = detectMigration(lowerTask);
  const hasDeployment = detectDeployment(lowerTask);
  const hasSecurityConsideration = detectSecurityConsideration(lowerTask);
  const isMultiStep = detectMultiStep(task, lowerTask);

  return {
    fileCount,
    taskType,
    operations,
    isNewProject,
    isFullStack,
    isArchitectureDecision,
    isMultiDomain,
    hasTesting,
    hasMigration,
    hasDeployment,
    hasSecurityConsideration,
    isMultiStep,
    keywords,
  };
}

function detectKeywords(lowerTask: string): string[] {
  const keywordPatterns = [
    // Complexity indicators
    { pattern: /\b(new|create|build|generate)\b/, weight: 'positive' },
    { pattern: /\b(refactor|restructure|redesign|rearchitect)\b/, weight: 'positive' },
    { pattern: /\b(fix|bug|issue|problem)\b/, weight: 'mixed' },
    { pattern: /\b(architecture|design|pattern|strategy)\b/, weight: 'positive' },

    // File operation indicators
    { pattern: /\b(file|files|directory|folder|src|lib)\b/, weight: 'neutral' },
    { pattern: /\b(multiple|many|all|\d+)\s*(files?|directories?)/, weight: 'positive' },

    // Specific features
    { pattern: /\b(auth|security|permission|credential)\b/, weight: 'positive' },
    { pattern: /\b(api|endpoint|route|middleware)\b/, weight: 'positive' },
    { pattern: /\b(database|sql|query|migration)\b/, weight: 'positive' },
    { pattern: /\b(test|spec|coverage|unit|integration)\b/, weight: 'mixed' },
    { pattern: /\b(deploy|ci\/cd|pipeline|release)\b/, weight: 'positive' },
  ];

  return keywordPatterns
    .filter((kp) => kp.pattern.test(lowerTask))
    .map((kp) => kp.weight);
}

function estimateFileCount(task: string): number {
  const lowerTask = task.toLowerCase();

  // Look for explicit file mentions
  const filePathMatches = task.match(/[\w\-./\\]+\.\w+/g);
  if (filePathMatches) return filePathMatches.length;

  // Look for number indicators
  const multiMatch = lowerTask.match(/\b(multiple|many|several|all|\d+)\b/);
  if (multiMatch) {
    const num = parseInt(multiMatch[1], 10);
    if (!isNaN(num)) return Math.min(num, 20);
    if (multiMatch[1] === 'multiple') return 3;
    if (multiMatch[1] === 'many' || multiMatch[1] === 'several') return 5;
    if (multiMatch[1] === 'all') return 10;
  }

  // Count file extensions mentioned
  const extCount = (task.match(/\.\w{1,4}/g) || []).length;

  return extCount;
}

function detectTaskTypes(
  task: string,
  lowerTask: string,
  context?: TaskContext
): TaskType[] {
  const types: TaskType[] = [];

  if (context?.taskType) {
    types.push(context.taskType);
  }

  // Detection patterns
  if (/\b(read|show|view|display|get|list|cat|type)\b/.test(lowerTask)) {
    types.push('read');
  }
  if (/\b(write|save|create|new|add|generate)\b/.test(lowerTask)) {
    types.push('write');
  }
  if (/\b(edit|modify|change|update|fix|replace)\b/.test(lowerTask)) {
    types.push('edit');
  }
  if (/\b(refactor|restructure|reorganize)\b/.test(lowerTask)) {
    types.push('refactor');
  }
  if (/\b(debug|troubleshoot|investigate|find\s+(bug|issue|problem))\b/.test(lowerTask)) {
    types.push('debug');
  }
  if (/\b(analyze|review|examine|assess|evaluate)\b/.test(lowerTask)) {
    types.push('analyze');
  }
  if (/\b(architect|design|plan|structure)\b/.test(lowerTask)) {
    types.push('architect');
  }
  if (/\b(test|spec|coverage)\b/.test(lowerTask)) {
    types.push('test');
  }
  if (/\b(deploy|release|push|publish)\b/.test(lowerTask)) {
    types.push('deploy');
  }
  if (/\b(question|what|how|why|explain|tell)\b/.test(lowerTask)) {
    types.push('question');
  }

  // Default to 'question' if no type detected
  if (types.length === 0) {
    types.push('question');
  }

  return [...new Set(types)];
}

function detectOperations(task: string, lowerTask: string): Operation[] {
  const operations: Operation[] = [];

  if (/\b(create|new|add|generate|make)\b/.test(lowerTask)) {
    operations.push('create');
  }
  if (/\b(delete|remove|cleanup)\b/.test(lowerTask)) {
    operations.push('delete');
  }
  if (/\b(rename|move)\b/.test(lowerTask)) {
    operations.push('rename');
  }
  if (/\b(modify|change|update|edit|fix)\b/.test(lowerTask)) {
    operations.push('modify');
  }
  if (/\b(read|show|view|get|list|cat|type)\b/.test(lowerTask)) {
    operations.push('read');
  }
  if (/\b(search|find|grep|locate)\b/.test(lowerTask)) {
    operations.push('search');
  }
  if (/\b(run|execute|command|npm|pip|git)\b/.test(lowerTask)) {
    operations.push('execute');
  }

  return operations.length > 0 ? operations : ['read'];
}

function detectNewProject(lowerTask: string): boolean {
  return /\b(new\s+project|create\s+project|from\s+scratch|start\s+fresh|boilerplate|scaffold)\b/.test(
    lowerTask
  );
}

function detectFullStack(lowerTask: string): boolean {
  return /\b(full[\s-]?stack|frontend|backend|api|database|ui|frontend|backend)\b/.test(
    lowerTask
  ) && /\b(database|api|server|backend)\b/.test(lowerTask);
}

function detectArchitectureDecision(lowerTask: string): boolean {
  return /\b(architecture|design\s+pattern|strategy|decision|structure|pattern|scale|performance)\b/.test(
    lowerTask
  );
}

function detectMultiDomain(
  lowerTask: string,
  context?: TaskContext
): boolean {
  if (context?.isMultiDomain) return true;

  const domains = [
    /\b(frontend|ui|react|vue|angular)\b/,
    /\b(backend|api|server|express|fastapi)\b/,
    /\b(database|sql|mongo|postgres)\b/,
    /\b(auth|security|oauth|jwt)\b/,
    /\b(deploy|docker|kubernetes|ci\/cd)\b/,
    /\b(mobile|ios|android|react[\s-]?native)\b/,
  ];

  const matchedDomains = domains.filter((d) => d.test(lowerTask)).length;
  return matchedDomains >= 2;
}

function detectTesting(lowerTask: string): boolean {
  return /\b(test|spec|coverage|unit|integration|e2e|jest|pytest|mocha)\b/.test(
    lowerTask
  );
}

function detectMigration(lowerTask: string): boolean {
  return /\b(migration|migrate|upgrade|convert|transform|port)\b/.test(
    lowerTask
  );
}

function detectDeployment(lowerTask: string): boolean {
  return /\b(deploy|release|publish|ci[\s/]?cd|pipeline|docker|kubernetes|railway)\b/.test(
    lowerTask
  );
}

function detectSecurityConsideration(lowerTask: string): boolean {
  return /\b(security|auth|permission|credential|secret|token|encrypt|validate|sanitize)\b/.test(
    lowerTask
  );
}

function detectMultiStep(task: string, lowerTask: string): boolean {
  // Check for step indicators
  if (/\b(step|\d+\s*-\s*\d+|first|then|next|after|before|finally)\b/.test(task)) {
    return true;
  }

  // Check for multiple conjunctions suggesting sequential actions
  const conjunctionCount = (lowerTask.match(/\b(and|then|,)\b/g) || []).length;
  if (conjunctionCount >= 2) return true;

  // Check for question chains
  const questionCount = (lowerTask.match(/\?/g) || []).length;
  if (questionCount >= 2) return true;

  return false;
}

// ============================================================================
// Complexity Scoring
// ============================================================================

interface ScoringWeights {
  fileCount: number;
  taskType: number;
  operations: number;
  specialFactors: number;
  multiStep: number;
}

/**
 * Calculate complexity score (0-10) based on task analysis
 */
function calculateComplexityScore(
  analysis: TaskAnalysis,
  context?: TaskContext
): number {
  let score = 0;
  const weights: ScoringWeights = {
    fileCount: 0,
    taskType: 0,
    operations: 0,
    specialFactors: 0,
    multiStep: 0,
  };

  // File count scoring (0-3 points)
  weights.fileCount = scoreFileCount(analysis.fileCount);
  score += weights.fileCount;

  // Task type scoring (0-2 points)
  weights.taskType = scoreTaskTypes(analysis.taskType);
  score += weights.taskType;

  // Operations scoring (0-1.5 points)
  weights.operations = scoreOperations(analysis.operations);
  score += weights.operations;

  // Special factors scoring (0-3.5 points)
  weights.specialFactors = scoreSpecialFactors(analysis);
  score += weights.specialFactors;

  // Multi-step indicator (0-1 point)
  weights.multiStep = analysis.isMultiStep ? 1 : 0;
  score += weights.multiStep;

  // Ensure score is within bounds
  return Math.max(0, Math.min(10, Math.round(score * 10) / 10));
}

function scoreFileCount(count: number): number {
  if (count === 0) return 0;
  if (count === 1) return 0.5;
  if (count <= 3) return 1;
  if (count <= 5) return 1.5;
  if (count <= 10) return 2;
  if (count <= 20) return 2.5;
  return 3;
}

function scoreTaskTypes(types: TaskType[]): number {
  let score = 0;

  for (const type of types) {
    switch (type) {
      case 'question':
        score += 0;
        break;
      case 'read':
        score += 0.2;
        break;
      case 'write':
      case 'edit':
        score += 0.5;
        break;
      case 'debug':
      case 'analyze':
        score += 1;
        break;
      case 'test':
        score += 1;
        break;
      case 'refactor':
        score += 1.5;
        break;
      case 'deploy':
        score += 1.5;
        break;
      case 'architect':
        score += 2;
        break;
      case 'generate':
        score += 1.5;
        break;
    }
  }

  return Math.min(2, score);
}

function scoreOperations(operations: Operation[]): number {
  let score = 0;

  for (const op of operations) {
    switch (op) {
      case 'read':
        score += 0.1;
        break;
      case 'search':
        score += 0.3;
        break;
      case 'create':
      case 'modify':
        score += 0.5;
        break;
      case 'delete':
        score += 0.5;
        break;
      case 'rename':
        score += 0.7;
        break;
      case 'execute':
        score += 1;
        break;
    }
  }

  return Math.min(1.5, score);
}

function scoreSpecialFactors(analysis: TaskAnalysis): number {
  let score = 0;

  // New project generation
  if (analysis.isNewProject) {
    score += 2;
  }

  // Full-stack tasks
  if (analysis.isFullStack) {
    score += 1.5;
  }

  // Architecture decisions
  if (analysis.isArchitectureDecision) {
    score += 2;
  }

  // Multi-domain
  if (analysis.isMultiDomain) {
    score += 1;
  }

  // Testing
  if (analysis.hasTesting) {
    score += 0.5;
  }

  // Migration
  if (analysis.hasMigration) {
    score += 1.5;
  }

  // Deployment
  if (analysis.hasDeployment) {
    score += 1;
  }

  // Security considerations
  if (analysis.hasSecurityConsideration) {
    score += 0.5;
  }

  return Math.min(3.5, score);
}

// ============================================================================
// Provider Selection
// ============================================================================

interface AvailableProvider {
  provider: string;
  model: string;
  tier: 1 | 2 | 3;
}

/**
 * Load OpenCode configuration to determine available providers
 */
function loadOpenCodeConfig(): OpenCodeConfig | null {
  try {
    const configPath = resolve(
      process.env.USERPROFILE || process.env.HOME || '',
      '.config',
      'opencode',
      'opencode.json'
    );

    if (!existsSync(configPath)) {
      return null;
    }

    const configContent = readFileSync(configPath, 'utf-8');
    return JSON.parse(configContent) as OpenCodeConfig;
  } catch {
    return null;
  }
}

/**
 * Extract available models from OpenCode config
 */
function getAvailableProviders(config: OpenCodeConfig): AvailableProvider[] {
  const available: AvailableProvider[] = [];
  const providerConfig = config.provider;

  if (!providerConfig) return available;

  for (const [providerName, providerDetails] of Object.entries(providerConfig)) {
    if (!providerDetails?.models) continue;

    for (const [modelName, modelDetails] of Object.entries(providerDetails.models)) {
      // Map to tiers based on model name patterns
      const tier = inferTierFromModelName(modelName);
      available.push({
        provider: providerName,
        model: modelDetails.name || modelName,
        tier,
      });
    }
  }

  return available;
}

function inferTierFromModelName(modelName: string): 1 | 2 | 3 {
  const lower = modelName.toLowerCase();

  // Tier 1 indicators
  if (
    lower.includes('haiku') ||
    lower.includes('flash') ||
    lower.includes('command-r') ||
    lower.includes('command_r')
  ) {
    return 1;
  }

  // Tier 3 indicators
  if (
    lower.includes('m2') ||
    lower.includes('opus') ||
    lower.includes('o1') ||
    lower.includes('o3') ||
    lower.includes('ultra')
  ) {
    return 3;
  }

  // Tier 2 by default (sonnet, gpt-4, etc.)
  return 2;
}

/**
 * Select the best available provider for a given tier
 */
function selectProvider(
  tier: 1 | 2 | 3,
  availableProviders: AvailableProvider[]
): { provider: string; model: string; alternatives: string[] } {
  // Filter providers by tier
  const tierProviders = availableProviders.filter((p) => p.tier === tier);

  // If we have providers for this tier, use them
  if (tierProviders.length > 0) {
    // Prefer MiniMax for tier 3, otherwise take first available
    const preferred = tier === 3
      ? tierProviders.find((p) => p.provider.toLowerCase() === 'minimax') ||
        tierProviders[0]
      : tierProviders[0];

    const alternatives = tierProviders
      .filter((p) => p.provider !== preferred.provider)
      .map((p) => `${p.provider}:${p.model}`);

    return {
      provider: preferred.provider,
      model: preferred.model,
      alternatives,
    };
  }

  // Fallback: use any provider from same or adjacent tiers
  const fallbackProviders = availableProviders.filter((p) => p.tier >= tier);

  if (fallbackProviders.length > 0) {
    const fallback = fallbackProviders[0];
    return {
      provider: fallback.provider,
      model: fallback.model,
      alternatives: [],
    };
  }

  // Last resort: return configured MiniMax if available
  return {
    provider: 'minimax',
    model: 'MiniMax-M2.7',
    alternatives: [],
  };
}

// ============================================================================
// Main Classification Function
// ============================================================================

/**
 * Classify a task and return tier assignment with provider recommendation
 */
function classifyTask(task: string, context?: TaskContext): TierAssignment {
  // Step 1: Analyze the task
  const analysis = analyzeTask(task, context);

  // Step 2: Calculate complexity score
  const score = calculateComplexityScore(analysis, context);

  // Step 3: Map score to tier
  const tier = mapScoreToTier(score);

  // Step 4: Load config and select provider
  const config = loadOpenCodeConfig();
  const availableProviders = config ? getAvailableProviders(config) : [];
  const providerSelection = selectProvider(tier, availableProviders);

  // Step 5: Generate reasoning
  const reasoning = generateReasoning(analysis, score, tier);

  return {
    tier,
    score,
    reasoning,
    suggestedProvider: providerSelection.provider,
    suggestedModel: providerSelection.model,
    alternativeProviders:
      providerSelection.alternatives.length > 0
        ? providerSelection.alternatives
        : undefined,
  };
}

function mapScoreToTier(score: number): 1 | 2 | 3 {
  if (score <= 3) return 1;
  if (score <= 6) return 2;
  return 3;
}

function generateReasoning(
  analysis: TaskAnalysis,
  score: number,
  tier: 1 | 2 | 3
): string {
  const parts: string[] = [];

  // File count
  if (analysis.fileCount === 0) {
    parts.push('No file operations detected');
  } else if (analysis.fileCount === 1) {
    parts.push('Single file operation');
  } else {
    parts.push(`${analysis.fileCount} file operations`);
  }

  // Task types
  if (analysis.taskType.length > 0) {
    parts.push(`task type: ${analysis.taskType.join('/')}`);
  }

  // Special conditions
  if (analysis.isNewProject) {
    parts.push('new project generation');
  }
  if (analysis.isArchitectureDecision) {
    parts.push('architecture decision');
  }
  if (analysis.isMultiDomain) {
    parts.push('multi-domain');
  }
  if (analysis.isFullStack) {
    parts.push('full-stack');
  }
  if (analysis.hasMigration) {
    parts.push('migration');
  }
  if (analysis.hasDeployment) {
    parts.push('deployment');
  }
  if (analysis.hasSecurityConsideration) {
    parts.push('security considerations');
  }
  if (analysis.isMultiStep) {
    parts.push('multi-step task');
  }

  // Score summary
  parts.push(`(score: ${score}/10)`);

  return parts.join(' | ');
}

// ============================================================================
// Exports
// ============================================================================

export {
  classifyTask,
  analyzeTask,
  calculateComplexityScore,
  TierAssignment,
  TaskContext,
  TaskAnalysis,
  TaskType,
  Operation,
  TIER_CONFIGS,
  loadOpenCodeConfig,
  getAvailableProviders,
};

// ============================================================================
// Example Usage
// ============================================================================

if (require.main === module) {
  console.log('='.repeat(70));
  console.log('TASK DIFFICULTY CLASSIFIER - Example Usage');
  console.log('='.repeat(70));
  console.log();

  const examples: Array<{ task: string; context?: TaskContext }> = [
    // Tier 1 - Simple
    {
      task: 'Read the contents of src/index.ts to understand the structure',
    },
    // Tier 1 - Simple
    {
      task: 'Fix the typo in the README.md file',
    },
    // Tier 2 - Medium
    {
      task: 'Refactor the user authentication module across 3 files: login.ts, auth.ts, and session.ts',
      context: { fileCount: 3, taskType: 'refactor' },
    },
    // Tier 2 - Medium
    {
      task: 'Debug why the API endpoint is returning 500 errors. Check the error logs and fix the issue.',
    },
    // Tier 3 - Complex
    {
      task: 'Design and implement a new microservices architecture for the e-commerce platform. Include API gateway, auth service, product service, and database migration strategy.',
      context: {
        isNewProject: false,
        isArchitectureDecision: true,
        isFullStack: true,
        isMultiDomain: true,
        hasMigration: true,
        hasDeployment: true,
      },
    },
    // Tier 3 - Complex
    {
      task: 'Generate a full-stack React + Node.js application from scratch with authentication, database models, and deployment configuration',
      context: {
        isNewProject: true,
        isFullStack: true,
        hasDeployment: true,
        hasTesting: false,
      },
    },
  ];

  examples.forEach((example, index) => {
    console.log(`Example ${index + 1}:`);
    console.log(`Task: "${example.task}"`);
    if (example.context) {
      console.log(
        `Context: ${JSON.stringify(example.context, null, 2)
          .split('\n')
          .join('\n         ')}`
      );
    }
    console.log();

    const result = classifyTask(example.task, example.context);

    console.log('Result:');
    console.log(`  Tier:        ${result.tier} (${['Simple', 'Medium', 'Complex'][result.tier - 1]})`);
    console.log(`  Score:       ${result.score}/10`);
    console.log(`  Reasoning:   ${result.reasoning}`);
    console.log(`  Provider:    ${result.suggestedProvider}`);
    console.log(`  Model:      ${result.suggestedModel}`);
    if (result.alternativeProviders && result.alternativeProviders.length > 0) {
      console.log(`  Alternatives: ${result.alternativeProviders.join(', ')}`);
    }
    console.log();
    console.log('-'.repeat(70));
    console.log();
  });

  // Show current OpenCode config info
  console.log('\nOpenCode Provider Configuration:');
  const config = loadOpenCodeConfig();
  if (config) {
    const providers = getAvailableProviders(config);
    console.log(`  Available providers: ${JSON.stringify(providers, null, 2)}`);
  } else {
    console.log('  No OpenCode config found - using default provider selection');
  }
}