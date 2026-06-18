# Design Patterns for PPTX

## Slide Structure Pattern
```
Cover → TOC → Section Divider → Content → Content → Section Divider → Summary
```
Always alternate layouts within Content slides — never repeat same layout twice.

## Color Application Pattern
- 60% neutral (bg / body text)
- 30% primary (headers, shapes, cards)
- 10% accent (CTAs, highlights, badges)

## Typography Hierarchy Pattern
- Cover title: 44-60pt, bold, prominent
- Slide title: 28-36pt, bold
- Body: 14-16pt, regular
- Caption/label: 10-12pt, muted or italic

## JS Libraries Ecosystem
| Library | Purpose | Install |
|---------|---------|---------|
| **PptxGenJS** | Create PPTX from scratch | `npm i pptxgenjs` |
| **officegen** | Create Office docs (PPTX, DOCX, XLSX) | `npm i officegen` |
| **ExcelJS** | Read/write XLSX with styling | `npm i exceljs` |
| **docx (npm)** | Create DOCX from JavaScript | `npm i docx` |
