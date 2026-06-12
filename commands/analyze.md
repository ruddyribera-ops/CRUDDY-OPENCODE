---
description: Long-context code analysis — reads full files into context and produces structured analysis. Use for understanding large codebases, security audits, or architectural deep-dives.
usage: /analyze <path> [--depth shallow|deep] [--focus security|architecture|performance|all]
---

# /analyze — Long-Context Code Analysis

Reads target files into full context, then produces a structured analysis report. Designed for use with M2.7's large context window.

## Research-Backed Approach
Based on Anthropic's "Effective Context Engineering for AI Agents" (Sep 2025):
- **Select**: pick only relevant files (don't dump entire monorepo)
- **Compress**: summarize older observations into higher-level patterns
- **Organize**: structured sections with XML/markdown headers
- **Minimize**: smallest set of high-signal tokens

## Modes

| Flag | Default | What |
|------|---------|------|
| `<path>` | required | File or directory to analyze |
| `--depth` | `deep` | `shallow` = quick scan, `deep` = exhaustive |
| `--focus` | `all` | `security`, `architecture`, `performance`, or `all` |

## Execution Flow

```
1. Discover files in <path>
   - Skip: node_modules, .git, dist, build, __pycache__, .venv
   - Include: code files + configs + docs

2. Read files into context
   - Single file: full read
   - Directory: concatenate with file headers
   - If total > 200K chars: warn and suggest narrower path

3. Run analysis sections (parallel where possible)
   - Architecture: module structure, dependencies, layering
   - Security: secrets, auth, input validation, injection risks
   - Performance: N+1 queries, hot paths, caching
   - Patterns: conventions, anti-patterns, tech debt

4. Output structured report
```

## Output Format

```
## ANALYSIS REPORT — <path>
Depth: deep | Focus: all | Files scanned: N | Lines: N

### ARCHITECTURE
- Entry points: [list]
- Module structure: [tree]
- Dependencies: [categorized]
- Layering: [observation]

### SECURITY
- [CRITICAL] file:line — issue — fix
- [HIGH] file:line — issue — fix
- [MEDIUM] file:line — issue — fix
- Auth/authz assessment
- Secret exposure check
- Input validation review

### PERFORMANCE
- Hot paths identified
- Database query patterns
- Caching opportunities
- Memory/CPU concerns

### PATTERNS
- Conventions followed
- Anti-patterns detected
- Tech debt hotspots
- Code reuse opportunities

### RECOMMENDATIONS
1. [P0] immediate
2. [P1] this sprint
3. [P2] next sprint
4. [P3] backlog
```

## Rules

1. **Read full files** — don't just grep snippets, you need full context
2. **Be specific** — cite file:line for every finding
3. **Prioritize** — CRITICAL/HIGH/MEDIUM/LOW severity
4. **Actionable** — every recommendation has a concrete next step
5. **Stay in scope** — if you find something outside the path, note it but don't analyze

## Token Budget

- Shallow: ~5K tokens for analysis output
- Deep: ~15K tokens for analysis output
- Input: scales with file count and size

## When to Use

- **Onboarding to a new codebase**: `/analyze ./src --focus architecture`
- **Pre-deploy audit**: `/analyze ./src --focus security`
- **Performance investigation**: `/analyze ./api --focus performance`
- **Full code review**: `/analyze . --depth deep`

## When NOT to Use

- Single function/line fixes (use bug-fixer instead)
- Read-before-write (just use read tool)
- Quick questions (use code-explainer)
