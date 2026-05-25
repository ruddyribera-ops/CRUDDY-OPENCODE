---
description: No single file over 350 lines — adapt codebase to model context limits
condition: .*
scope: "tool:edit(**/*.{py,ts,tsx,js,jsx,go,rs,php,java})"
severity: warning
triggered_by: file too large for model context
check: file_length
threshold: 350
---

# No Files Over 350 Lines

Code files must stay under 350 lines. This adapts the codebase to the model's context window.

## Why
- Models lose coherence in very long files
- Agents navigate smaller files more efficiently
- Fewer merge conflicts on smaller files
- Easier to review and test

## Fix
- Split large files by responsibility
- Extract helper functions to separate modules
- Break large components into smaller ones
- If a file is mostly types/constants, move them to a separate file
