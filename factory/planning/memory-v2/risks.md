# Memory v2 — Risk Assessment

## Risk Register

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| R1 | ALTER TABLE locks DB during migration | Medium | Low | Backup first, migration is additive only |
| R2 | Importance auto-assignment misclassifies memories | Medium | Medium | Allow manual override via new field |
| R3 | Recency boost causes recency bias — old important memories get buried | Medium | Medium | Importance weight (0.20) offsets recency (0.15) |
| R4 | Cross-memory linking creates too many edges, slows graph traversal | Low | Low | Threshold of 0.3 prevents spurious links |
| R5 | Decay manager runs too often, slows session end | Low | Low | On-demand only, not on every retrieval |
| R6 | LLM extraction produces low-quality facts | Medium | Medium | Start with manual tagging, LLM extraction as Phase 3 |
| R7 | session_id requires OpenCode core changes | High | High | Make session_id optional — no session context needed for v2 |
| R8 | 87 existing memories have stale embeddings (MiniLM-L6-v2 dimension mismatch) | Low | Medium | Embeddings unchanged — no re-embed needed |

---

## Assumptions

1. OpenCode does NOT currently produce structured conversation logs (G1 blocked)
2. Solo dev on Windows — all scripts must be .py with no external services
3. API key for local LLM already available (user says "already have it")
4. No budget for Mem0 Cloud or external vector DB

## Open Questions

| Question | Owner | Answer Needed Before |
|----------|-------|---------------------|
| What is the session_id format in OpenCode? | OpenCode core | G8 implementation |
| Does OpenCode have a hook for session_end? | OpenCode core | Decay integration |
| What LLM endpoint to use for extraction? | User | G1 implementation |
| Should memories with importance < 0.1 be hard-deleted or soft-excluded? | User | G4 implementation |
