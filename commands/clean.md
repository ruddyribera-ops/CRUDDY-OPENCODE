---
description: Clean cloned source code and temporary artifacts
usage: /clean [--source]
---

# /clean — Cleanup

Removes temporary files, cloned source code, and build artifacts.

## Steps
1. With `--source`: run `python $CONFIG/scripts/opensource.py clean`
2. Remove `_source/` directory
3. Report what was freed
