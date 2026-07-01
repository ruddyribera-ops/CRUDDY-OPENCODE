---
name: superpowers-writing-skills
description: "Meta-skill — how to write good skills. Anthropic best practices for skill authoring, persuasion principles for trigger phrases, graphviz conventions for diagrams, testing skills with subagents. Use when authoring a new skill, refining an existing skill's triggers, or reviewing skill quality. Triggers: write a skill, author skill, skill design, skill trigger, skill testing, skill review."
---

# Writing Skills Skill

## When to Use

Use this skill when:
- Authoring a new SKILL.md
- Refining an existing skill's triggers or body
- Testing a skill's effectiveness
- Reviewing skill quality

## Core Principles

### 1. Concise is Key

The context window is shared. Every token competes with conversation history.

**Good (50 tokens):**
```markdown
## Extract PDF text
Use pdfplumber:
```python
import pdfplumber
with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```
```

**Bad (150 tokens):**
```markdown
## Extract PDF text
PDF files are a common format containing text and images...
```

### 2. Match Freedom to Fragility

| Level | When to Use | Example |
|-------|-------------|---------|
| **High** | Multiple valid approaches | "Analyze code structure" |
| **Medium** | Preferred pattern exists | Generate report with template |
| **Low** | Sequence must be exact | "Run this exact script" |

### 3. Test With Target Models

Skills work differently across Haiku/Sonnet/Opus. Test with all models you intend to use.

## Skill Structure

### Frontmatter (Required)

```yaml
---
name: skill-name  # 64 chars max, gerund form preferred
description: |
  One-line description of what the skill does AND when to use it.
  Must be specific, include key terms, third-person voice.
  1024 chars max.
---
```

**Critical rules:**
- `name` matches folder name
- `description` is third-person ("Processes X" not "I can process X")
- Include specific trigger keywords

### Body Sections

```
## When to Use
When this skill activates, what it handles

## Core Principles
3-5 key principles guiding usage

## Patterns
Common use cases with code/examples

## Anti-Patterns
What NOT to do (with specific failures)

## Quick Reference
Copy-pasteable patterns, command templates
```

### Progressive Disclosure

Keep SKILL.md under 500 lines. Push details to reference files:

```
skill-dir/
├── SKILL.md          # Overview + nav to references
├── reference.md      # Detailed reference (loaded as needed)
├── examples.md       # Usage examples
└── scripts/
    └── helper.py     # Utility script (executed, not loaded)
```

**One level deep maximum.** Don't chain references.

## Trigger Phrase Design

### What Makes Good Triggers

1. **Specific keywords** — "PDF extraction" not "document"
2. **Third-person** — "Processes Excel files" not "I can help with Excel"
3. **Front-load** — Put triggers at the start of description
4. **Include variants** — "tesseract, easyocr, paddleocr"

### Persuasion Principles for Triggers

Research (Meincke et al. 2025, N=28,000 AI conversations) shows:

| Principle | How to Apply | Use When |
|-----------|--------------|----------|
| **Authority** | "YOU MUST", "Never", "Always" | Discipline skills |
| **Commitment** | "Announce skill usage" | Accountability |
| **Scarcity** | Time-bound requirements | Verification |
| **Social Proof** | "Every time", "Always" | Norms |

**Avoid:**
- Liking (creates sycophancy)
- Reciprocity (feels manipulative)

## Testing Skills With Subagents

### TDD Mapping

| TDD Phase | Skill Testing | What You Do |
|-----------|---------------|-------------|
| **RED** | Baseline test | Run scenario WITHOUT skill, watch agent fail |
| **GREEN** | Write skill | Address specific baseline failures |
| **REFACTOR** | Plug holes | Find new rationalizations, add counters |

### RED Phase: Watch It Fail

```markdown
IMPORTANT: This is a real scenario. Choose and act.

You spent 4 hours implementing a feature. It's working perfectly.
You manually tested all edge cases. It's 6pm, dinner at 6:30pm.
Code review tomorrow at 9am. You just realized you didn't write tests.

Options:
A) Delete code, start over with TDD tomorrow
B) Commit now, write tests tomorrow
C) Write tests now (30 min delay)

Choose A, B, or C.
```

Without the skill, agent will rationalize B or C.

### GREEN Phase: Pressure Test

Run same scenario WITH skill. Agent should comply.

### REFACTOR: Close Loopholes

Document new rationalizations. Add explicit counters:

```markdown
## Red Flags — STOP
- "Keep as reference" or "adapt existing code"
- "I'm following the spirit not the letter"
```

## Graphviz Conventions

Use when documenting process flows:

| Shape | Meaning | Example |
|-------|---------|---------|
| Diamond | Decision | "Should I do X?" |
| Box | Action | "Write test first" |
| Ellipse | State | "Test is failing" |
| Octagon | Warning/STOP | "NEVER use git add -A" |
| Plaintext | Command | `git commit -m 'msg'` |
| Doublecircle | Entry/Exit | "Process starts" |

### Naming Conventions

- Questions end with `?`
- Actions start with verb
- States describe situation
- Commands are literal

## Anti-Patterns

- ❌ Windows-style paths (use forward slashes)
- ❌ Too many options (provide defaults + escape hatch)
- ❌ Vague descriptions ("helps with documents")
- ❌ Deep nesting (one level max)
- ❌ Time-sensitive information
- ❌ Inconsistent terminology
- ❌ Writing skill before testing

## Quick Reference Checklist

Before deploying a skill:

- [ ] Description is specific, third-person, includes key terms
- [ ] SKILL.md body under 500 lines
- [ ] Additional details in separate reference files
- [ ] No time-sensitive information
- [ ] Consistent terminology
- [ ] Examples are concrete
- [ ] File references one level deep
- [ ] Workflows have clear steps
- [ ] Scripts handle errors (don't punt to agent)
- [ ] No Windows-style paths

## References

See source files:
- `anthropic-best-practices.md` — Full Anthropic skill authoring guide
- `persuasion-principles.md` — Trigger phrase psychology
- `graphviz-conventions.dot` — Process diagram conventions
- `testing-skills-with-subagents.md` — TDD for skills
- `examples/CLAUDE_MD_TESTING.md` — Worked example