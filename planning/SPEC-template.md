# SPEC — [PROJECT NAME]

> Living specification. Survives context resets. Source of truth for AI agent and human collaborators.
> Inspired by GitHub Spec Kit (github.com/github/spec-kit) and Addy Osmani's "How to write a good spec for AI agents" (Jan 2026).

**Last updated:** [DATE]
**Last session:** [SESSION-ID]
**Phase:** [planning | building | testing | deploying | maintenance]

---

## 1. Vision (1 sentence)
> What this project does and why it exists.

[Single sentence: e.g., "PRIA is a Streamlit-based learning platform for Bolivian EdTech, used by 500+ students daily."]

## 2. Status
- **Last session:** [session_id from session.yaml]
- **Current phase:** [e.g., "building:auth-flow"]
- **Active task:** [what the coordinator is working on right now]
- **Blockers:** [list, or "none"]
- **Next step:** [immediate next action for the next session]

## 3. Architecture (2-3 sentences)
> Key design decisions, tech stack, boundaries.

[Describe the high-level architecture. Reference the architecture docs for detail. Stay high-level — this is for context, not full design.]

**Stack:**
- Frontend: [framework]
- Backend: [framework]
- Database: [engine]
- Deploy: [platform]

## 4. Boundaries (what this does NOT do)
> Explicit exclusions to prevent scope creep and AI drift.

- [ ] [Exclusion 1: e.g., "No admin panel in v1"]
- [ ] [Exclusion 2: e.g., "No email notifications — handled by separate service"]
- [ ] [Exclusion 3: e.g., "No i18n — Spanish-only for v1"]

## 5. Success Criteria
> What "done" looks like. Each criterion should be testable.

- [ ] [Criterion 1: e.g., "User can sign up with email + password"]
- [ ] [Criterion 2: e.g., "All 7 lessons load in <2s on 3G"]
- [ ] [Criterion 3: e.g., "Zero data loss across Railway deployments"]

## 6. Active Decisions
> Architectural decisions made and why. Add new entries; never delete old ones.

| Date | Decision | Rationale |
|------|----------|-----------|
| [DATE] | [e.g., "Use JWT in httpOnly cookies, not localStorage"] | [e.g., "XSS protection, browser default"] |
| [DATE] | [e.g., "Bcrypt over Argon2 for v1"] | [e.g., "Simpler, no native deps"] |

## 7. Open Questions
> Things the agent should ask the human about, not assume.

- [ ] [Question 1: e.g., "Should we support Google OAuth from day 1?"]
- [ ] [Question 2: e.g., "What happens to in-progress lessons on Railway restart?"]

## 8. Context Files
> Files the agent should read before working on this project.

- `AGENTS.md` — global agent rules
- `.opencode/design.md` — design system (if applicable)
- [project-specific files: e.g., `src/lib/auth.py` for auth work]

## 9. Changelog
> What changed in this SPEC, when, why.

- [DATE] — [change summary]
- [DATE] — [change summary]
