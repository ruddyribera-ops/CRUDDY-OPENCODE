# AM Brief

**User said:** "I want the agents that we have on deck to inspect every project that I have in my system. Both C: and D:. catalogue it. organize my files and hot mess. classify trash files and clean up. the works"

**My approach:**
1. User confirmed they don't know the exact mess areas. Made conservative assumptions.
2. Scoped C: to user folders only (Desktop, Documents, Downloads, AppData) â€” never system files.
3. Scoped D: to all user content (it's the project drive).
4. Defined project detection rules (known dev files like package.json, .csproj, etc.)
5. Defined trash classification rules (temp, cache, build artifacts, duplicates).
6. Built in safety: move to holding folder, never auto-delete, generate restore script.
7. Out of scope: cloud, system files, auto-delete, anything needing admin.

**Full brief:** brief.md
**Ready to hand to PM.**
