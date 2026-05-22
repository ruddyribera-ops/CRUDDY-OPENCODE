---
name: msoffice-tools
description: Word, Excel, PowerPoint document design — advanced patterns for professional, well-structured documents
tags: [office, docx, xlsx, pptx, document]
tags: [msoffice, word, excel, powerpoint, document-generation, python-docx, openpyxl]
---

## When to Use

- Generating professional Word documents programmatically with python-docx
- Creating styled Excel workbooks with openpyxl (tables, formulas, formatting)
- Building PowerPoint presentations from scratch
- Designing document layouts with proper margins, headers, footers, and page numbers
- Producing reports, invoices, proposals, or educational materials in Office formats
- Applying consistent branding and typography across documents

## Do Not Use

- Creating PDF documents (use minimax-pdf)
- OCR or text extraction from images (use ocr-tools)
- Web-based document generation (use HTML/CSS + jsPDF)
- Data analysis or statistical reporting without Office export (use data-analysis)
- Editing existing PPTX files (use ppt-editing-skill)

# MSOffice Tools — Advanced Document Design

> **Design philosophy:** A document is a designed artifact. Every margin, every spacing choice, every color is a decision.

## TL;DR — Document Design Checklist

- [ ] Margins set explicitly (1 inch default)
- [ ] At least 2 font sizes max (body + heading)
- [ ] Table borders: 1pt hairline or custom weight, never default grid
- [ ] Colors: semantic or brand-consistent, never random
- [ ] Tables have header row with shading, alternating rows optional
- [ ] Page numbers in footer (center or right)
- [ ] Document has title block / header area
- [ ] Whitespace: breathing room = professionalism

## Word Documents (`python-docx`)

**Architecture:** `Document → sections → paragraph (runs with formatting) → table`

**Full code examples with detailed setup, styles, paragraphs, inline formatting, tables, headers/footers, images, TOC, and a complete document builder:**

→ See `references/word-examples.md`

Basic workflow:
1. Create `Document()`, set `section` margins/orientation
2. Customize styles (`styles['Heading 1']`, `styles['Normal']`, `styles['Quote']`)
3. Build content with `add_paragraph()`, `add_run()`, `add_table()`, `add_picture()`
4. Add header/footer with page numbers and metadata
5. Save with `document.save(path)`

Install: `pip install python-docx`

## Excel Workbooks (`openpyxl`)

**Architecture:** `Workbook → worksheets → cells (with value, font, fill, border, alignment)`

**Full code examples for workbook setup, cell styling, styled tables, conditional formatting, data validation, and charts:**

→ See `references/excel-examples.md`

Basic workflow:
1. Create `Workbook()`, name sheets, set `freeze_panes`
2. Style cells with `Font`, `PatternFill`, `Border`, `Alignment`
3. Build tables with header styling, alternating row fills, column widths
4. Add `ColorScaleRule` or `DataValidation` for interactivity
5. Add charts with `BarChart`/`PieChart` and `Reference` data
6. Save with `wb.save(path)`

Install: `pip install openpyxl`

## PowerPoint Presentations (`python-pptx`)

**Architecture:** `Presentation → slides → shapes (textbox, picture, table, placeholder)`

**Full code examples for slide dimensions, title slides, content slides, two-column layouts, table slides, and speaker notes:**

→ See `references/powerpoint-examples.md`

Basic workflow:
1. Create `Presentation()`, set `slide_width`/`slide_height`
2. Choose layout: `prs.slide_layouts[i]` (0=Title, 1=Content, 5=Blank)
3. Add shapes: `add_textbox()`, `add_shape()`, `add_table()`, `add_picture()`
4. Style all text with explicit `font.name`, `font.size`, `font.color.rgb`
5. Add speaker notes via `slide.notes_slide`
6. Save with `prs.save(path)`

Install: `pip install python-pptx`

## Cross-Document & Conversion Workflows

**LibreOffice, pandoc, docx2pdf, and Markdown→Word conversion patterns:**

→ See `references/cross-doc-workflows.md`

## Design Quick Reference

**Typography scale, brand color palette, document spacing guidelines, and format selection guide:**

→ See `references/design-reference.md`

## Office Automation Ecosystem

**Microsoft Graph API, Office.js, Open XML SDK, VSTO, LibreOffice headless — when to use each:**

→ See `references/office-automation.md`

## Common Pitfalls

| Mistake | Why it looks bad | Fix |
|---|---|---|
| Default table grid (0.5pt black) | School assignment from 2003 | 1pt hairline, light gray (`AAAAAA`) |
| No header/footer | No page numbers | Always add header+footer |
| Random font sizes (8-36) | No hierarchy | 3 sizes max for body content |
| Default Word styles unchanged | "Looks like I pressed a button" | Customize heading + normal |
| No caption on tables/images | Reader doesn't know context | Always add "Tabla X." or "Figura X." |
| Cells with no vertical alignment | Text at bottom = looks off | `alignment.vertical = 'top'` |
| Columns too narrow | Wrapping breaks | Set explicit widths, `wrap_text=True` |
| Mixing 3+ fonts | No visual system | 1 body + 1 display font max |
| Dark background body text | Fails WCAG AA | Light bg, dark text, ≥4.5:1 contrast |

## Verification

- [ ] `pip install` commands work (python-docx, openpyxl, python-pptx)
- [ ] Generated files open in Office/LibreOffice without corruption
- [ ] Margins, fonts, colors match the spec
- [ ] Tables have headers with shading and proper border weight
- [ ] Page numbers render correctly in footer
- [ ] All reference links in this file resolve to existing files
