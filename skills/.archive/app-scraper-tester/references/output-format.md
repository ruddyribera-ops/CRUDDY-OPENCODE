# Output Format Details

## 1. Blueprint.md

Full Markdown blueprint following PRIA v5.4 structure (400+ lines):

```markdown
# <App Name> — Blueprint de Especificación
**Versión:** 1.0  
**Framework:** <detected>  
**URL:** <target>
**
## 1. Arquitectura General
### 1.1 Stack Tecnológico
### 1.2 Flujo de Autenticación (ASCII flow diagram)
### 1.3 Estructura de URLs (URL tree)

## 2. Modelos de Datos
### 2.1 <Entity Name> (Python class definitions)

## 3. Página de Login
### 3.1 Layout (ASCII wireframe)
### 3.2 Componentes (table with Element, Type, Test ID, Notes)
### 3.3 Validación (validation rules)

## N. Estados de Error
### N.1 <Error Type> (error message patterns + screenshot ref)

## Checklist de Funcionalidades
- [ ] Feature 1
- [ ] Feature 2
```

## 2. blueprint.json

```json
{
  "version": "1.0",
  "url": "<target>",
  "crawledAt": "<ISO timestamp>",
  "framework": "<detected>",
  "authRequired": <bool>,
  "pages": [{ "url": "...", "title": "...", "headings": [], "links": [], "forms": [],
              "buttons": [], "inputs": [], "networkRequests": [], "snapshotHash": "", "depth": 0 }],
  "endpoints": [{ "method": "GET|POST|PUT|DELETE", "path": "/api/...",
                  "requestBody": {}, "responseSchema": {}, "discoveredOn": "..." }],
  "forms": { "<name>": { "action": "/submit", "method": "POST", "fields": [],
                          "guards": [], "onSuccess": "redirect" } },
  "navigationTree": { "root": { "label": "Home", "url": "/", "children": [] } },
  "criticalPaths": [{ "name": "login → dashboard", "steps": ["/login", "/dashboard"] }],
  "issues": [{ "severity": "info|warning|critical", "type": "missing_test_id|auth_bypass",
               "description": "...", "url": "..." }]
}
```

## 3. test-coverage.md (optional)

```
# Test Coverage Report
## Forms Tested
| Form | URL | Result | Errors |
| Login | /login | ✅ PASS | None |
## Critical Paths Tested
| Path | Steps | Result |
| Login Flow | / → /login → /dashboard | ✅ PASS |
```
