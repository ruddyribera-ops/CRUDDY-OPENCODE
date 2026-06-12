# /cass — Search session history
# Queries the CASS index for past tasks, solutions, and patterns.
# Usage: /cass [query] [-days N] [-agent NAME] [-project NAME]

Run cass-search.ps1 with the query string and optional filters.

Script: `$CONFIG/scripts/cass-search.ps1`
Arguments: `-Query "<text>" [-Days N] [-Agent "<name>"] [-Project "<name>"] [-Limit N]`

Examples:
```
/cass authentication fix
/cass PRIA sprint -days 30
/cass biome -days 14
/cass checkpoint outcome -agent main-coordinator
```

The CASS index is auto-built from session_log.md. Run `cass-index.ps1` to rebuild the index.

First-time setup: the index builds automatically every 5 tasks via auto-memory.ps1.
To force a rebuild: `cass-index.ps1 -SessionLogPath <path>`