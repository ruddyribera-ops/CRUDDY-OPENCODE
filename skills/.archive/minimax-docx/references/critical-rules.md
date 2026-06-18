# Critical Rules — OpenXML

## Element Order (Properties Always First)

| Parent | Order |
|--------|-------|
| `w:p`  | `pPr` → runs |
| `w:r`  | `rPr` → `t`/`br`/`tab` |
| `w:tbl`| `tblPr` → `tblGrid` → `tr` |
| `w:tr` | `trPr` → `tc` |
| `w:tc` | `tcPr` → `p` (min 1 `<w:p/>`) |
| `w:body` | block content → `sectPr` (LAST child) |

## Direct Format Contamination
When copying content from a source document, inline `rPr` (fonts, color) and `pPr` (borders, shading, spacing) override template styles. Always strip direct formatting — keep only `pStyle` reference and `t` text.

## Track Changes
- `<w:del>` uses `<w:delText>`, never `<w:t>`
- `<w:ins>` uses `<w:t>`, never `<w:delText>`

## Font Size & Units
- `w:sz` = points × 2 (12pt → `sz="24"`)
- Margins/spacing in DXA (1 inch = 1440, 1 cm ≈ 567)

## Heading Styles MUST Have OutlineLevel
When defining heading styles (Heading1, ThesisH1, etc.), always include `new OutlineLevel { Val = N }` in `StyleParagraphProperties` (H1→0, H2→1, H3→2). Without this, TOC and navigation pane won't work.

## Multi-Template Merge Rules
- Merge styles from all templates into one styles.xml
- Each content paragraph must appear exactly ONCE
- NEVER insert empty/blank paragraphs as separators
- Insert oddPage section breaks BEFORE every chapter heading
- Dual-column chapters need THREE section breaks: (1) oddPage in preceding para's pPr, (2) continuous+cols=2 in the chapter HEADING's pPr, (3) continuous+cols=1 in the last body para's pPr

## Multi-Section Headers/Footers
For templates with 10+ sections (e.g., Chinese thesis):
- Use C-2 Base-Replace: copy the TEMPLATE as output base, then replace body content
- NEVER recreate headers/footers from scratch — copy template header/footer XML byte-for-byte
- NEVER add formatting not present in the template header XML
- Non-cover sections MUST have header/footer XML files
- Copy `titlePg` settings from the breaks template for EACH section
