# Master Plan — OpenCode Full Audit & Repair

**Date:** 2026-05-28
**Status:** 🟡 In Progress
**Score actual:** 8.5/10 → **Target:** 9.5/10

---

## 🔴 PRIORIDAD ALTA (Must Fix — Afecta funcionamiento diario)

### A-01 — Skills Referenciadas Que NO Existen
**Archivos:** `agents/code-builder.md`, `agents/bug-fixer.md`
**Problema:** STEP 0 referencea 8 skills que no existen en `skills/`. El agente dice "Read the skill first" pero la skill no está.
**Fix:** Crear skills faltantes como stubs funcionales O remover referencias de los agentes.
**Archivos a crear:**
- `skills/js-modern-patterns/SKILL.md`
- `skills/python-patterns/SKILL.md`
- `skills/data-analysis/SKILL.md`
- `skills/realtime-patterns/SKILL.md`
- `skills/ci-cd-patterns/SKILL.md`
- `skills/code-review/SKILL.md`
- `skills/git-workflow/SKILL.md`
- `skills/msoffice-tools/SKILL.md`

### A-02 — Memory MCP Duplica File-Based Memory
**Archivo:** `opencode.json`
**Problema:** `memory` MCP está `"enabled": true` pero el sistema migró a file-based memory. El knowledge graph JSON no se sincroniza.
**Fix:** Cambiar `"enabled": true` → `false`.

### A-03 — Archivar Reports Obsoletos en memory/
**Archivos:** `memory/OPENCODE_CONFIG_AUDIT_REPORT*.md` (6 archivos), `memory/MASTER_POA_memory_state_handover.md`, `memory/OPENCODE_ARCHITECTURE_REPORT.md`, `memory/OPENCODE_HERMES_INTEGRATION_RESEARCH.md`, `memory/HOOK_WIRING_VERIFICATION.md`, `memory/GRAPH_MIGRATION_SOP.md`
**Problema:** 54 archivos en memory/, muchos de auditorías pasadas que ya no son relevantes.
**Fix:** Mover a `memory/archive/`.

### A-04 — Project Files Sin Consolidar
**Archivos:** `memory/project_bdm-app.md`, `memory/project_gh_token_scope.md`
**Problema:** `project_active.md` es el single source of truth pero estos archivos existen separados.
**Fix:** Consolidar contenido en `project_active.md`, eliminar archivos duplicados.

---

## 🟡 PRIORIDAD MEDIA (Importante — Mejora consistencia)

### B-01 — .gitignore No Cubre Archivos Generados
**Archivos:** `.gitignore`
**Problema:** `memory/interventions.json` y `_source/` se cuelan en commits.
**Fix:** Agregar entries al `.gitignore`.

### B-02 — Review-Loop No Integrado en Pipelines
**Archivos:** `agents/code-builder.md`, `agents/bug-fixer.md`
**Problema:** El review-loop está en el end-of-task checklist pero no en STEP 4 de los agentes.
**Fix:** Agregar `python $CONFIG/scripts/review-loop.py run .` a STEP 4 de ambos agentes.

### B-03 — Scripts Legacy Educativos Mezclados
**Archivos:** ~70 scripts en `scripts/` que son de PRIA/educación, no del sistema OpenCode.
**Problema:** Contaminan el namespace y dificultan encontrar scripts relevantes.
**Fix:** Mover scripts legacy a `scripts/_archive/`.

### B-04 — Challenger Rule y DNA.yaml Desincronizados
**Archivo:** `agents/main-coordinator.md`, `skills/DNA.yaml`
**Problema:** challenger rule tiene 12 patterns hardcodeados. DNA.yaml tiene triggers separados.
**Fix:** Unificar: que el challenger rule lea del DNA.yaml dinámicamente O agregar los triggers faltantes.

---

## 🔵 PRIORIDAD BAJA (Nice to Have)

### C-01 — Session Log Rotation
**Archivo:** `memory/session_log.md`
**Problema:** Crece indefinidamente sin rotación.
**Fix:** Implementar archiving mensual.

### C-02 — Playwright MCP vs browser-robust Skill
**Archivos:** `opencode.json`, `skills/browser-robust/SKILL.md`
**Problema:** Dos sistemas de browser automation compitiendo.
**Fix:** Decidir uno, documentar cuándo usar cuál.

---

## 📋 Execution Log

| Item | Estado | Fecha | Notas |
|------|--------|-------|-------|
| A-01 | ✅ | 2026-05-28 | 8 skills creadas: js-modern-patterns, python-patterns, data-analysis, realtime-patterns, ci-cd-patterns, code-review, git-workflow, msoffice-tools |
| A-02 | ✅ | 2026-05-28 | memory MCP disabled en opencode.json — AGENTS.md actualizado |
| A-03 | ✅ | 2026-05-28 | 12 reports movidos a memory/archive/ |
| A-04 | ✅ | 2026-05-28 | project_bdm-app.md + project_gh_token_scope.md archivados |
| B-01 | ✅ | 2026-05-28 | .gitignore fixed: interventions.json + handover/ agregados |
| B-02 | ✅ | 2026-05-28 | review-loop agregado a STEP 4 de code-builder y bug-fixer |
| B-03 | ✅ | 2026-05-28 | 51 scripts legacy + 2 docx movidos a scripts/_archive/ |
| B-04 | ⬜ | — | DNA+challenger unificación (baja prioridad — sistemas funcionan en paralelo) |
| C-01 | ⬜ | — | Session log rotation (baja prioridad — implementar después) |
| C-02 | ⬜ | — | Playwright vs browser-robust (baja prioridad — decidir después) |
