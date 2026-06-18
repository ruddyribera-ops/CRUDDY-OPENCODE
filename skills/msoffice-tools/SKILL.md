---
name: msoffice-tools
description: Microsoft Office file generation and parsing — Excel (.xlsx), Word (.docx), PowerPoint (.pptx) via programmatic libraries. Covers openpyxl, python-docx, PptxGenJS patterns.
triggers: excel, xlsx, word, docx, powerpoint, pptx, office, spreadsheet, document
auto_load: code-builder
---

# Office File Tools

## Excel (.xlsx)
- **Library**: `openpyxl` (Python) or `xlsx` npm package (Node.js)
- Read: `openpyxl.load_workbook()` with `data_only=True` for values (not formulas)
- Write: use `ExcelWriter` or create workbook directly
- Styles: apply after data write (performance: batch style, not cell-by-cell)
- Formulas: `worksheet["A1"] = "=SUM(B1:B10)"` — evaluate in Excel

## Word (.docx)
- **Library**: `python-docx` (Python)
- Read: extract paragraphs and tables separately (tables are not paragraphs)
- Write: use template with placeholders or build document from scratch
- Sections: headers/footers per section, not global

## PowerPoint (.pptx)
- **Library**: `PptxGenJS` (Node.js — recommended) or `python-pptx` (Python)
- PptxGenJS: `new pptxgen()` → `addSlide()` → `addText()`/`addImage()` → `writeFile()`
- Templates: use slide layouts, not absolute positioning
- Images: base64 or file path, keep under 2MB per slide

## Common Pitfalls
- Excel: empty rows at end of sheet → check `max_row` before iterating
- Word: tables have no `paragraphs` attribute — use `table.rows`
- PPTX: font embedding is unreliable — use web-safe fonts
