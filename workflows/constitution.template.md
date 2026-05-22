# Constitution — [Project Name]

**Per-project principles, constraints, and preferences that guide ALL agents.**
Place this file at `.opencode/constitution.md` in your project root.
Agents read it automatically when routing tasks to this project.

---

## 1. Project Identity

| Field | Value |
|-------|-------|
| **Name** | |
| **Purpose** | One sentence — what this project does |
| **Primary users** | Who uses it? |
| **Current phase** | Prototype / MVP / Production / Maintenance |

---

## 2. Tech Stack (Approved Only)

**Language:**
- [ ] Python 3.12+
- [ ] TypeScript / JavaScript (Node 20+)
- [ ] Go
- [ ] Rust
- [ ] Other: _________

**Frontend:**
- [ ] None (CLI/backend only)
- [ ] Streamlit
- [ ] React / Next.js
- [ ] Vue / Nuxt
- [ ] HTML + vanilla JS
- [ ] Other: _________

**Backend / API:**
- [ ] None (standalone)
- [ ] FastAPI
- [ ] Flask
- [ ] Express.js
- [ ] Go net/http
- [ ] Other: _________

**Database:**
- [ ] None
- [ ] SQLite
- [ ] PostgreSQL
- [ ] Supabase
- [ ] MongoDB
- [ ] Other: _________

**Deployment:**
- [ ] Local only
- [ ] Railway
- [ ] Docker
- [ ] Vercel
- [ ] GitHub Pages
- [ ] Other: _________

---

## 3. Design Principles (Pick 3-5)

- [ ] **Simple over clever** — straightforward code, minimal abstraction
- [ ] **Performance first** — optimize where it matters, avoid premature optimization
- [ ] **Security by default** — never trust input, validate everything
- [ ] **Accessibility** — works for all users
- [ ] **Testable** — make it easy to verify correctness
- [ ] **Maintainable** — clear naming, documentation for non-obvious decisions
- [ ] **Progressive enhancement** — core works without JS, enhanced with JS
- [ ] **Offline-first** — works without internet where possible
- [ ] **Don't repeat yourself** — extract shared logic, not at the cost of clarity
- [ ] **Fail fast** — crash early with clear errors instead of silent failures

**Top priority:** [Pick one from above]

---

## 4. Testing Requirements

- [ ] No tests required (prototype phase)
- [ ] Tests for critical paths only
- [ ] Unit tests for all business logic
- [ ] Integration tests for API endpoints
- [ ] E2E tests for user flows
- [ ] Visual regression tests

**Test framework:** ___________

**Coverage target:** ___%

---

## 5. Code Conventions

**Imports:** [standard / isort / alphabetical]

**Line length:** [88 / 100 / 120]

**Formatting:** [black / ruff / prettier / biome]

**Naming:**
- Variables: snake_case / camelCase
- Functions: snake_case / camelCase
- Classes: PascalCase
- Constants: UPPER_CASE / SCREAMING_SNAKE
- Files: snake_case / kebab-case

**Documentation:**
- [ ] Docstrings on all public functions
- [ ] README for each module
- [ ] Inline comments for complex logic only

**Error handling style:**
- [ ] Early return on error
- [ ] try/except with specific exceptions
- [ ] Result type (Rust-style)

---

## 6. Constraints (Hard Rules)

**Do NOT use:**
- [List libraries, patterns, or approaches that are off-limits]

**Must use if applicable:**
- [List required libraries or patterns]

**Regulatory / compliance:**
- [List any legal or compliance requirements]

---

## 7. Dependencies

**Package manager:** [pip / uv / npm / yarn / pnpm / go mod]

**Preferred libraries:**
- [Library] — [purpose]

**Blocked libraries (don't add without approval):**
- [Library] — [reason]

---

## 8. Agent Behavior Preferences

**Communication style:**
- [ ] Short, direct (caveman mode)
- [ ] Detailed with explanations
- [ ] Spanish (default)
- [ ] English (default)

**Ask before:**
- [ ] Installing new dependencies
- [ ] Modifying config files
- [ ] Running destructive commands
- [ ] Refactoring existing code
- [ ] Creating new files

**Routing preferences:**
- [ ] Route everything through coordinator (safe)
- [ ] Allow specialists to work independently (fast)

---

*Generated with Constitution from Spec Kit design pattern.*
*Edit this file to match your project's needs.*
