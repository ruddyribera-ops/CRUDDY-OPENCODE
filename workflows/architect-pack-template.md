# Architect Pack — Template

**For Complex tasks (score 7-10).** Produced by architecture-advisor BEFORE any code is written. 
The builder reads this pack, implements against it, then feeds back to architect for review.

---

## Sprint: [Sprint Number]
## Pack: [Pack Version]

---

### 1. REQUIREMENTS — What we're building and why

**Business Goal:**
[One sentence — what problem this solves for the user]

**Users:**
[Who uses this? Internal team, external customers, both?]

**Inputs:**
[What data/inputs does this need? CSV files, API calls, user input, database?]

**Outputs:**
[What does the system produce? HTML reports, PDFs, API responses, database updates?]

**Core Functionality:**
- [ ] Feature 1: one sentence
- [ ] Feature 2: one sentence
- [ ] Feature 3: one sentence

**Out of Scope (explicit):**
- What this sprint is NOT building
- This prevents scope creep

---

### 2. BLUEPRINT — How we plan to build it

**Architecture Summary:**
[One paragraph: how the pieces fit together]

**Key Files to Create/Modify:**
| File | Purpose |
|------|---------|
| `src/path/to/file.py` | Handles X |
| `src/path/to/other.py` | Handles Y |

**Data Flow:**
```
[Input] → [Processing Step] → [Output]
```

**External Dependencies:**
- Libraries: [list]
- APIs: [list]
- Services: [list]

---

### 3. ACCEPTANCE CRITERIA — What "done" looks like

**Must Have (blocking):**
- [ ] Input parsing works with all edge cases
- [ ] Output format matches requirements
- [ ] Handles errors gracefully (no crashes on bad input)
- [ ] Testable with sample data

**Should Have (non-blocking):**
- [ ] Performance is reasonable (< 5s for typical inputs)
- [ ] Code is clean and follows project style

**Verification Method:**
How do we prove each criterion is met? (manual test, automated test, visual inspection)

---

### 4. RISKS & ASSUMPTIONS — What could go wrong

**Known Risks:**

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk description] | High/Med/Low | High/Med/Low | [How to prevent] |

**Assumptions Made:**
- [Assumption 1: e.g., "Input CSV always has a header row"]
- [Assumption 2: e.g., "User has Python 3.11+"]

**Open Questions:**
- [ ] Question for user/stakeholder

---

### 5. HANDOFF PROMPT (for builder)

```
You are the builder. Read the following Architect Pack files:
- requirements.md
- blueprint.md
- acceptance.md
- risks.md

1. Do a dry-run first — summarize what you will build before writing any code.
2. Implement against the blueprint.
3. After building, verify against acceptance criteria.
4. Report back: what was built, what was verified, any deviations from plan.
```
