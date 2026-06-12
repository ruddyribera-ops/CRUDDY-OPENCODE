# Cybersecurity Agent — Build Result

**Built by:** @code-builder (Factory Pipeline)
**Date:** 2026-06-09
**Status:** ✅ Complete

## Deliverables

| Artifact | Path | Lines | Status |
|----------|------|-------|--------|
| Agent file | `C:\Users\Windows\.config\opencode\agents\cybersecurity.md` | 120 | ✅ |
| Test prompts | `C:\Users\Windows\.config\opencode\memory\factory\projects\2A-specialists\test-prompts\cybersecurity.md` | 57 | ✅ |

## Agent Spec Summary

- **Model:** minimax/minimax-m3 (high-reasoning for security analysis)
- **Steps:** 80
- **Mode:** subagent
- **Permissions:** read/glob/grep/list/skill/webfetch/sequential-thinking allowed; edit/write denied; bash limited to read-only whitelist (git log*, rg *, ls *, cat *, find *)

## Sections (8 total, all present)

1. ✅ Identity & Memory — 460 words, first-person, opinionated, scars, anti-patterns
2. ✅ Triggers — 14 triggers (high/med confidence)
3. ✅ Workflow — 7 steps: scope → attack surface → OWASP map → read-only audit → classify → fix → escalate
4. ✅ Handoff — to code-builder, bug-fixer, account-manager, project-manager
5. ✅ Style — direct, severity-first, code-snippet-heavy
6. ✅ Critical Rules — 5 non-negotiable rules (read-only, no weak crypto, no skipped auth, no "later", flag secrets)
7. ✅ When NOT to act — 4 refusal/reroute cases
8. ✅ MCP Tools — 8 tools enabled with rationales

## Research Anchors (2026)

- OWASP Top 10 2021 (stable baseline)
- OWASP Top 10 for Agentic Security Implications (ASI) 2026 (genai.owasp.org)
- OWASP AI Exchange — five-zone navigation lens (owaspai.org)

## Test Prompts

- 5 positive tests (SQLi, MD5 passwords, threat model, hardcoded secrets, OWASP ASI audit)
- 4 negative tests (active exploit, disable controls, build request, news request)
- Verification checklist included

## Key Design Decisions

- **Severity-first output:** every finding leads with Critical/High, never bury the lead
- **Code-fix pairing:** every vulnerability comes with a concrete code fix snippet, not just a name
- **Refusal clarity:** negative test cases have explicit DECLINE/REFUSE with reasoning, not silent routing
- **AI/agentic surfaces:** OWASP ASI 2026 is a first-class part of the workflow, not an afterthought
- **Read-only enforcement:** bash whitelist is explicit, edit/write are deny-only, no exceptions

**Schema:** matches `agent-template.md` verbatim. All 5 required sections in correct order.