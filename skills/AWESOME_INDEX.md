# Awesome Skills Index

Skills cloned from [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills) (MIT, 22k+ stars).

## Cloned Skills

| # | Skill Name | Description | Source | Path |
|---|------------|-------------|--------|------|
| 1 | `awesome-investigate` | Structured debugging workflow enforcing root cause analysis before any fix. Four phases: investigate, analyze, hypothesize, implement. | [garrytan/gstack](https://github.com/garrytan/gstack/tree/main/investigate) | `skills/awesome-investigate/` |
| 2 | `awesome-office-hours` | Two-mode office hours simulation for brainstorming. Startup mode runs YC-style demand-forcing questions; Builder mode is a brainstorming partner. | [garrytan/gstack](https://github.com/garrytan/gstack/tree/main/office-hours) | `skills/awesome-office-hours/` |
| 3 | `awesome-ask-questions-if-underspecified` | Guides pausing to ask clarifying questions before action when request has ambiguous objectives, unclear scope, or missing constraints. | [trailofbits/skills](https://github.com/trailofbits/skills/tree/main/plugins/ask-questions-if-underspecified) | `skills/awesome-ask-questions-if-underspecified/` |
| 4 | `awesome-webapp-testing` | Automates interaction with local web applications using Python Playwright. Handles server lifecycle, DOM inspection, screenshot capture, and browser log collection. | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/webapp-testing) | `skills/awesome-webapp-testing/` |
| 5 | `awesome-differential-review` | Security-focused differential reviews on PRs, commits, and diffs. Scales analysis depth to codebase size, calculates blast radius, checks test coverage gaps. | [trailofbits/skills](https://github.com/trailofbits/skills/tree/main/plugins/differential-review) | `skills/awesome-differential-review/` |

## Selection Rationale

These skills fill gaps in our existing configuration:

1. **Debugging**: We had no structured root-cause debugging methodology
2. **Brainstorming/Spec**: No YC-style demand validation or design doc creation
3. **Clarification**: No skill for structured question-asking before ambiguous work
4. **Playwright**: We had testing-standards but not Playwright-specific automation
5. **Security PR Review**: We had code-review but not security-focused differential review

## Superpowers Skills (from obra/superpowers)

Skills cloned from [obra/superpowers](https://github.com/obra/superpowers) (MIT, 232k+ stars).

| # | Skill Name | Description | Justification |
|---|------------|-------------|----------------|
| 6 | `superpowers-writing-skills` | TDD applied to skill creation — RED-GREEN-REFACTOR for documentation, skill bulletproofing against rationalization, Skill Discovery Optimization (SDO). | Fills critical gap in our skill-authoring methodology. Our `skill-learning` exists but lacks TDD discipline, rationalization tables, and SDO patterns. |
| 7 | `superpowers-systematic-debugging` | Four-phase debugging: Root Cause → Pattern Analysis → Hypothesis → Implementation. Includes condition-based-waiting, defense-in-depth, root-cause-tracing, and test-pressure scenarios. | Complements `awesome-investigate` with concrete techniques (backward tracing, condition polling, multi-layer defense). |
| 8 | `superpowers-test-driven-development` | Strict RED-GREEN-REFACTOR TDD cycle with Iron Law enforcement and rationalization tables. Tests-first discipline with scientific method. | Our `testing-standards` covers test structure but not TDD-first enforcement. This adds the discipline layer. |
| 9 | `superpowers-subagent-driven-development` | Subagent orchestration for plan execution — fresh subagent per task, task review gates (spec + quality), broad final review, durable progress ledger. | New methodology we lack — coordinates multiple subagents with review checkpoints and recovery via ledger. |

## License

All skills are MIT licensed via their respective source repositories.
