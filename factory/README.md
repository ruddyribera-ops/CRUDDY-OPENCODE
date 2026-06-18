# factory/

This is the single source of truth for all system code. Everything that makes CRUDDY-OPENCODE work lives here.

## Structure

| Subdir | Purpose |
|--------|---------|
| `scripts/autoresearch/` | Self-improving loop (Karpathy pattern) |
| `scripts/memory_retrieval/` | Hybrid BM25 + vector + graph retrieval |
| `hooks/` | Session-start hook scripts |
| `tools/` | Pre-flight snapshot + MCP binaries |
| `planning/` | Architecture specs and roadmaps |
| `docs/` | HOOKS.md, ARCHITECTURE.md |

## Design principle

If a piece of code is in `factory/`, it's part of the system. If it's outside, it's OpenCode's own. Don't add to this directory casually — every file here is intentional.

## Adding a new tool

1. Create the file under the appropriate subdir
2. Add it to the [INDEX.md](INDEX.md)
3. If it touches user data, add a pre-flight gate
4. Update the ARCHITECTURE.md diagram
5. Test it with `python -m ...` before committing

## Updating an existing tool

1. Read the file first
2. Run `python factory/tools/preflight-snapshot.py --paths <file> --operation "edit"` if editing config files
3. Make the change
4. Run the tool's verification commands
5. Commit