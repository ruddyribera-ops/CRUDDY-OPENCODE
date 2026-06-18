# Autoresearch Program — Skill Content for the Agent
# ==================================================
# This file defines what the agent should do during each iteration.
# In Karpathy's original pattern, this is read by the agent before making changes.
# For our use case, this is the SKILL.md content that guides the improvement.

## Objective
Improve the target config file against the specified metric. Make ONE change per iteration.

## Process
1. Read the current target file
2. Understand what the metric measures and what direction is "better"
3. Make ONE surgical change that could improve the metric
4. The iterate.py loop will evaluate and decide whether to keep the change

## Principles (from Karpathy)
- **Think Before Coding**: State your assumption before changing
- **Simplicity First**: Minimum code that solves the problem
- **Surgical Changes**: Touch only what must change
- **Goal-Driven**: Every change traces to a measurable improvement

## What to Change
The agent should look at:
- The target file's current state
- The metric being optimized
- What a "better" value would look like
- One specific change that could achieve it

## Example Changes
- Add/remove/expand a keyword in challenger-rule.md
- Adjust a threshold in a gate config
- Simplify a complex rule
- Add missing error handling
- Remove an overly aggressive pattern

## What NOT to Change
- Don't reformat or "improve" adjacent code
- Don't add speculative features
- Don't change multiple things at once
- Don't modify prepare.py (it's read-only and SHA-verified)

## Success Criteria
- The metric improves (lower or higher, depending on direction)
- The change is surgical (traces directly to the goal)
- No syntax errors or broken configs
