---
name: minimax-docx
description: DOCX document generation and editing using MiniMax API. Create Word documents from templates or programmatically.
tags: [office, docx, minimax, document]
---

# minimax-docx

## When to Use
- Create or edit DOCX files programmatically
- Generate Word documents from templates
- Convert content to Word format
- Batch document generation

## Do Not Use
- Create PPTX files (use pptx-generator)
- Create XLSX files (use minimax-xlsx)
- OCR document extraction (use ocr-tools)
- General Office automation (use msoffice-tools)

Create, edit, and format DOCX documents via CLI tools or direct C# scripts built on OpenXML SDK (.NET).

## Setup
**First time:** `bash scripts/setup.sh` (or `powershell scripts/setup.ps1` on Windows, `--minimal` to skip optional deps).

**First operation in session:** `scripts/env_check.sh` — stop if `NOT READY`.

## Pipeline Routing

```
User task
├─ No input file → Pipeline A: CREATE
│   → Read references/scenario_a_create.md
│
└─ Has input .docx
    ├─ Replace/fill/modify content → Pipeline B: FILL-EDIT
    │   → Read references/scenario_b_edit_content.md
    │
    └─ Reformat/apply style/template → Pipeline C: FORMAT-APPLY
        ├─ Template is pure style → C-1: OVERLAY
        └─ Template has structure → C-2: BASE-REPLACE
        → Read references/scenario_c_apply_template.md
```

If the request spans multiple pipelines, run them sequentially.

## Scenario A: Create
Read `references/scenario_a_create.md`, `references/typography_guide.md`, and `references/design_principles.md`. For CJK, also read `references/cjk_typography.md`.

- **Simple** (plain text, minimal formatting): use CLI — `$CLI create --type report --output out.docx --config content.json`
- **Structural** (custom styles, multi-section, TOC): write C# directly. Read relevant `Samples/*.cs` first.

See `references/cli-commands.md` for CLI options and C# scaffold.

## Scenario B: Edit / Fill
Read `references/scenario_b_edit_content.md`. Preview → analyze → edit → validate.
- **Simple** (text replacement, placeholder fill): use CLI subcommands
- **Structural** (add/reorganize sections, tables, images): write C# directly

## Scenario C: Apply Template
Read `references/scenario_c_apply_template.md`. Preview and analyze both source and template.
```bash
$CLI apply-template --input source.docx --template template.docx --output out.docx
```

See `references/critical-rules.md` for multi-template merge and multi-section header/footer rules.

## Validation Pipeline
Run after every write operation. Mandatory for Scenario C; recommended for A/B.

1. `$CLI merge-runs --input doc.docx` — consolidate runs
2. `$CLI validate --input doc.docx --xsd assets/xsd/wml-subset.xsd` — XSD structure
3. `$CLI validate --input doc.docx --business` — business rules

See `references/validation.md` for full pipeline, fallback, and gate-check procedures.

## References (C# Samples)
Read the relevant `Samples/*.cs` file before writing code — they contain compilable, SDK-version-verified patterns:

| File | Topic |
|------|-------|
| `Samples/DocumentCreationSamples.cs` | Document lifecycle, page setup, multi-section |
| `Samples/StyleSystemSamples.cs` | Styles, CJK, APA 7th, import/resolve |
| `Samples/TableSamples.cs` | Tables, borders, merge, three-line, zebra |
| `Samples/HeaderFooterSamples.cs` | Page numbers, "Page X of Y", per-section |
| `Samples/AestheticRecipeSamples.cs` | 13 aesthetic recipes from authoritative sources |

Full table in `references/` section at end of scenario guides. See also `references/ecosystem.md` for libraries, fundamentals, and pitfalls.

## Verification
- [ ] Validation pipeline passes (XSD + business rules)
- [ ] Scenario C: gate-check passes
- [ ] Diff shows only intended changes
- [ ] Preview: font contamination=0, correct table/drawing/sectPr counts
- [ ] File opens without errors in Word/LibreOffice
