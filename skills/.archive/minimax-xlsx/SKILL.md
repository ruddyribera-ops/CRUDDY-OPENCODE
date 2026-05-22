---
name: minimax-xlsx
description: Open, create, read, analyze, edit, or validate Excel/spreadsheet files (.xlsx, .xlsm, .csv, .tsv). Covers: creating new xlsx from scratch, reading and analyzing existing files, editing existing xlsx with zero format loss, formula recalculation and validation, and applying professional financial formatting standards.
tags: [excel, spreadsheet, minimax, office]
---

# MiniMax XLSX Skill

## When to Use
- Create or edit Excel spreadsheets
- Generate XLSX files with formulas and formatting
- Convert tabular data to Excel format
- Read and analyze existing Excel files

## Do Not Use
- Create DOCX documents (use minimax-docx)
- Create presentations (use pptx-generator)
- Data analysis (use data-analysis skill)
- General Office tasks (use msoffice-tools)

Handle the request directly. Do NOT spawn sub-agents. Always write the output file.

## Task Routing

| Task | Method | Guide |
|------|--------|-------|
| **READ** — analyze existing data | `xlsx_reader.py` + pandas | `references/read-analyze.md` |
| **CREATE** — new xlsx from scratch | XML template | `references/create.md` + `references/format.md` |
| **EDIT** — modify existing xlsx | XML unpack→edit→pack | `references/edit.md` (+ `format.md` if styling needed) |
| **FIX** — repair broken formulas | XML unpack→fix `<f>` nodes→pack | `references/fix.md` |
| **VALIDATE** — check formulas | `formula_check.py` | `references/validate.md` |

## READ — Analyze Data
Read `references/read-analyze.md` first. Use `xlsx_reader.py` for structure discovery, then pandas for analysis. Never modify the source file.

## CREATE — XML Template
Read `references/create.md` + `references/format.md`. Copy `templates/minimal_xlsx/` → edit XML → pack with `xlsx_pack.py`. Every derived value MUST be an Excel formula (`<f>SUM(B2:B9)</f>`), never hardcoded.

## EDIT — XML Direct-Edit
Read `references/edit.md` first. **CRITICAL RULES:**
1. NEVER create a new `Workbook()` for edit tasks — always load the original
2. Output MUST contain the same sheets as input (same names, same data)
3. Only modify specific cells — everything else untouched
4. Never use openpyxl round-trip on existing files (corrupts VBA, pivots, sparklines)

See `references/details.md` for full CLI examples (add column, insert row, borders).

## FIX — Repair Broken Formulas
Read `references/fix.md` first. EDIT task: unpack → fix broken `<f>` nodes → pack. Preserve all sheets.

## VALIDATE — Check Formulas
Read `references/validate.md` first. Run `formula_check.py` for static validation.

## Financial Color Standard
| Cell Role | Font Color | Hex Code |
|-----------|-----------|----------|
| Hard-coded input / assumption | Blue | `0000FF` |
| Formula / computed result | Black | `000000` |
| Cross-sheet reference formula | Green | `00B050` |

## Key Rules
1. **Formula-First**: Every calculated cell MUST use an Excel formula, not hardcoded
2. **CREATE → XML template**: Copy minimal template, edit XML, pack
3. **EDIT → XML unpack/edit/pack**: Never openpyxl round-trip
4. **Always produce the output file** — #1 priority
5. **Validate before delivery**: `formula_check.py` exit code 0

## Verification
- [ ] READ: pandas DataFrame matches expected content
- [ ] CREATE: all calculated cells are formulas, not hardcoded
- [ ] EDIT: output has same sheets as input, only target cells changed
- [ ] FIX: all formulas recalculated correctly
- [ ] VALIDATE: `formula_check.py` exit code = 0
- [ ] Financial colors applied per standard (blue=input, black=formula, green=cross-sheet)

See `references/details.md` for ecosystem, formula patterns, and formatting standards.
