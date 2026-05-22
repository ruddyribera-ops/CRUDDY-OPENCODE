/**
 * Task Classifier Test - 5 Example Tasks Across All 3 Tiers
 * Inlined classifier to avoid ESM import issues
 */

interface TierAssignment {
  tier: 1 | 2 | 3;
  score: number;
  reasoning: string;
  suggestedProvider: string;
  suggestedModel: string;
}

interface TaskContext {
  fileCount?: number;
  taskType?: string;
  isNewProject?: boolean;
  isFullStack?: boolean;
  isArchitectureDecision?: boolean;
  isMultiDomain?: boolean;
  hasMigration?: boolean;
  hasDeployment?: boolean;
}

// ============================================================================
// Classifier Logic (inlined from task-classifier.ts)
// ============================================================================

function analyzeTask(task: string, context?: TaskContext) {
  const lowerTask = task.toLowerCase();

  const filePathMatches = task.match(/[\w\-./\\]+\.\w+/g) || [];
  const fileCount = context?.fileCount ?? (filePathMatches.length > 0 ? filePathMatches.length : (task.match(/\.\w{1,4}/g) || []).length);

  const taskTypes: string[] = [];
  if (/\b(read|show|view|get|list)\b/.test(lowerTask)) taskTypes.push('read');
  if (/\b(write|create|add|generate|make)\b/.test(lowerTask)) taskTypes.push('write');
  if (/\b(edit|modify|change|update|fix)\b/.test(lowerTask)) taskTypes.push('edit');
  if (/\b(refactor|restructure|reorganize)\b/.test(lowerTask)) taskTypes.push('refactor');
  if (/\b(debug|troubleshoot|investigate|root\s+cause|why\s+is|fixing|fix\s+the)\b/.test(lowerTask)) taskTypes.push('debug');
  if (/\b(analyze|review|examine|assess)\b/.test(lowerTask)) taskTypes.push('analyze');
  if (/\b(architect|design|plan)\b/.test(lowerTask)) taskTypes.push('architect');
  if (/\b(test|spec)\b/.test(lowerTask)) taskTypes.push('test');
  if (/\b(deploy|release|push|publish)\b/.test(lowerTask)) taskTypes.push('deploy');
  if (/\b(question|what|how|why|explain)\b/.test(lowerTask)) taskTypes.push('question');
  // Context override - use provided taskType to boost priority
  if (context?.taskType) {
    if (!taskTypes.includes(context.taskType)) taskTypes.push(context.taskType);
    // Move context taskType to front so it scores highest
    const idx = taskTypes.indexOf(context.taskType);
    if (idx > 0) taskTypes.splice(idx, 1);
    taskTypes.unshift(context.taskType);
  }

  return {
    fileCount: Math.min(fileCount, 20),
    taskTypes: taskTypes.length > 0 ? taskTypes : ['question'],
    isNewProject: /\b(new\s+project|create\s+project|from\s+scratch|start\s+fresh)\b/.test(lowerTask),
    isFullStack: /\b(full[\s-]?stack|frontend|backend)\b/.test(lowerTask) && /\b(database|api|server|backend)\b/.test(lowerTask),
    isArchitectureDecision: /\b(architecture|design\s+pattern|strategy|decision|structure)\b/.test(lowerTask),
    isMultiDomain: context?.isMultiDomain || false,
    hasMigration: /\b(migration|migrate|upgrade|convert)\b/.test(lowerTask),
    hasDeployment: /\b(deploy|release|publish|docker|kubernetes|railway)\b/.test(lowerTask),
    isMultiStep: /\b(step|then|next|after|before|finally)\b/.test(task) ||
    (task.match(/\?/g) || []).length >= 2 ||
    (lowerTask.match(/\b(check|fix|debug|analyze|investigate)\b.*\b(and|then|or)\b/g) || []).length >= 1 ||
    (lowerTask.match(/\bcheck\b.*\bfix\b|\bfix\b.*\bcheck\b/g)) !== null,
  };
}

function calculateScore(analysis: ReturnType<typeof analyzeTask>, task: string): number {
  let score = 0;

  // File count (0-3)
  if (analysis.fileCount === 0) score += 0;
  else if (analysis.fileCount === 1) score += 0.5;
  else if (analysis.fileCount <= 3) score += 1;
  else if (analysis.fileCount <= 5) score += 1.5;
  else if (analysis.fileCount <= 10) score += 2;
  else score += 2.5;

  // Task type scoring - debug/refactor score boosted when multiple files involved
  const isMultiFile = analysis.fileCount > 1;
  for (const type of analysis.taskTypes) {
    switch (type) {
      case 'read': score += 0.2; break;
      case 'question': score += 0.3; break;
      case 'edit': case 'write': score += 0.5; break;
      case 'debug': score += isMultiFile ? 2.5 : 1.5; break;
      case 'analyze': case 'test': score += isMultiFile ? 2 : 1; break;
      case 'refactor': score += isMultiFile ? 3 : 1.5; break;
      case 'deploy': score += 1.5; break;
      case 'architect': score += 2; break;
    }
  }
  score = Math.min(3, score);

  // Special factors (0-3.5)
  if (analysis.isNewProject) score += 2;
  if (analysis.isFullStack) score += 1.5;
  if (analysis.isArchitectureDecision) score += 2;
  if (analysis.isMultiDomain) score += 1;
  if (analysis.hasMigration) score += 1.5;
  if (analysis.hasDeployment) score += 1;
  if (analysis.isMultiStep) score += 0.5;

  // Boost for explicit "across N files" mentions
  if (/across \d+ files/i.test(task) || /in \d+ files/i.test(task)) score += 0.5;

  return Math.max(0, Math.min(10, Math.round(score * 10) / 10));
}

function mapScoreToTier(score: number): 1 | 2 | 3 {
  if (score <= 3) return 1;
  if (score <= 6) return 2;
  return 3;
}

function classifyTask(task: string, context?: TaskContext): TierAssignment {
  const analysis = analyzeTask(task, context);
  const score = calculateScore(analysis, task);
  const tier = mapScoreToTier(score);

  const providerMap: Record<number, { provider: string; model: string }> = {
    1: { provider: 'groq', model: 'llama-3.3-70b-versatile' },      // Fastest, free tier
    2: { provider: 'cohere', model: 'command-a-03-2025' },           // Good balance
    3: { provider: 'minimax', model: 'MiniMax-M2.7' },                // Primary (1500 req/5hrs)
  };

  const selected = providerMap[tier] || providerMap[3];

  const reasoningParts: string[] = [];
  if (analysis.fileCount === 1) reasoningParts.push('single file');
  else if (analysis.fileCount > 1) reasoningParts.push(`${analysis.fileCount} files`);
  if (analysis.isNewProject) reasoningParts.push('new project');
  if (analysis.isArchitectureDecision) reasoningParts.push('architecture');
  if (analysis.isFullStack) reasoningParts.push('full-stack');
  if (analysis.isMultiDomain) reasoningParts.push('multi-domain');
  if (analysis.hasMigration) reasoningParts.push('migration');
  if (analysis.hasDeployment) reasoningParts.push('deployment');
  if (analysis.isMultiStep) reasoningParts.push('multi-step');
  reasoningParts.push(`score:${score}`);

  return {
    tier,
    score,
    reasoning: reasoningParts.join(' | '),
    suggestedProvider: selected.provider,
    suggestedModel: selected.model,
  };
}

// ============================================================================
// Tests
// ============================================================================

const examples = [
  { task: 'Read the contents of src/index.ts to understand the structure', expectedTier: 1 },
  { task: 'Fix the typo in the README.md file', expectedTier: 1 },
  { task: 'Refactor the user authentication module across 3 files: login.ts, auth.ts, and session.ts', context: { fileCount: 3, taskType: 'refactor' }, expectedTier: 2 },
  { task: 'Debug why the API endpoint is returning 500 errors. Check the error logs and fix the issue.', expectedTier: 2 },
  { task: 'Design and implement a new microservices architecture for the e-commerce platform. Include API gateway, auth service, product service, and database migration strategy.', context: { isArchitectureDecision: true, isFullStack: true, isMultiDomain: true, hasMigration: true, hasDeployment: true }, expectedTier: 3 },
];

console.log('='.repeat(70));
console.log('  Task Classifier Test - 5 Examples');
console.log('='.repeat(70));
console.log();

const tierNames = ['', 'Simple', 'Medium', 'Complex'];
let passed = 0, failed = 0;

examples.forEach((ex, i) => {
  const result = classifyTask(ex.task, ex.context);
  const expectedName = tierNames[ex.expectedTier];
  const actualName = tierNames[result.tier];
  const match = result.tier === ex.expectedTier ? 'PASS' : 'FAIL';

  console.log(`Test ${i + 1}: [${match}]`);
  console.log(`  Task: "${ex.task.substring(0, 55)}${ex.task.length > 55 ? '...' : ''}"`);
  console.log(`  Expected: ${expectedName} | Got: ${actualName} (score: ${result.score})`);
  console.log(`  Provider: ${result.suggestedProvider}:${result.suggestedModel}`);
  console.log(`  ${result.reasoning}`);
  console.log();

  if (match === 'PASS') passed++; else failed++;
});

console.log('='.repeat(70));
console.log(`Results: ${passed}/${examples.length} passed`);
console.log('='.repeat(70));