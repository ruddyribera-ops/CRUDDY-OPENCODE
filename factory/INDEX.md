# Factory Index — File-by-File Map

## scripts/autoresearch/
```
scripts/autoresearch/
├── analyze.py        # Post-run analysis of results
├── iterate.py        # Core loop: eval → pointer → update program.md
├── nightly_run.ps1   # Scheduled task wrapper (02:00 daily)
├── prepare.py        # Read-only evaluation (eval)
├── prepare.sha       # SHA of last evaluated config
├── program.md        # Skill/template written by train.py
├── README.md         # Autoresearch documentation
├── results.tsv       # Tab-separated run results log
└── train.py          # Pointer manipulation + program.md update
```

## scripts/memory_retrieval/
```
scripts/memory_retrieval/
├── __init__.py       # Package marker
├── __main__.py       # python -m memory_retrieval entry
├── cli.py            # CLI: query, index, stats commands
├── embedder.py       # OpenAI embeddings wrapper
├── graph.py          # BM25 + cosine hybrid retriever
├── hook_integration.py # Session-start hook interface
├── indexer.py        # Document chunking + indexing
├── migrate_v2.py     # Migration from v1 store format
├── models.py         # Pydantic schemas (Query, Result, etc.)
├── requirements.txt  # Dependencies
├── retriever.py      # Core retrieval logic
├── store.py          # JSONLines document store
├── watcher.py        # File-system watcher daemon
└── watcher_run.ps1   # Watcher launch script
```

## hooks/
```
hooks/
└── session_start.py  # Runs on opencode session start (via session-start-memory plugin)
```

## planning/memory-retrieval/
```
planning/memory-retrieval/
├── acceptance.md     # v1 acceptance criteria
├── blueprint.md      # v1 system design
├── requirements.md   # v1 requirements
└── risks.md          # v1 risk assessment
```

## planning/memory-v2/
```
planning/memory-v2/
├── blueprint.md      # v2 system design
├── gap-analysis.md   # v1 → v2 gap analysis
├── migration.md      # Migration playbook
├── priority-roadmap.md # Prioritized feature list
└── risks.md          # v2 risk assessment
```

## docs/
```
docs/
├── ARCHITECTURE.md   # System-wide architecture diagram
└── HOOKS.md          # Hook reference (moved from docs/HOOKS.md)
```

## Root level
```
factory/
├── README.md         # This file
├── INDEX.md          # This index
└── docs/
    └── ARCHITECTURE.md  # System diagram
```