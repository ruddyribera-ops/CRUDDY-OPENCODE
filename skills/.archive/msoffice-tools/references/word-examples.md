# Word Documents — Complete Code Examples

## Document Architecture

```
Document
├── sections[0]                    # Section properties (margins, orientation, page size)
├── paragraph                       # A paragraph is a BLOCK of text
│   ├── style.name                 # "Heading 1", "Normal", "Caption"
│   ├── alignment                  # LEFT, CENTER, RIGHT, JUSTIFY
│   ├── run                        # A run is an inline formatting chunk
│   │   ├── text
│   │   ├── bold
│   │   ├── italic
│   │   ├── font.name
│   │   └── font.size
│   └── paragraph_format
│       ├── space_before
│       ├── space_after
│       ├── left_indent
│       └── line_spacing
├── table                          # Tables come after paragraphs
│   ├── rows
│   │   ├── cells
│   │   │   ├── paragraphs
│   │   │   └── width
│   │   └── cells[i].merge(cells[j])  # Horizontal merge
│   └── rows[0].vertically_center()   # Vertical alignment
└── add_page_break()
```

## Page Setup — Margins, Size, Orientation

```python
from docx import Document
from docx.shared import Inches, Cm, Pt
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.section import WD_ORIENT

def create_document_with_setup(filepath):
    document = Document()
    section = document.sections[0]
    section.page_width  = Inches(8.5)
    section.page_height = Inches(11)
    section.orientation = WD_ORIENT.PORTRAIT
    section.left_margin   = Inches(1.0)
    section.right_margin  = Inches(1.0)
    section.top_margin    = Inches(1.0)
    section.bottom_margin = Inches(1.0)
    section.gutter        = Inches(0.5)  # Extra margin for binding
    document.add_paragraph("Hello World")
    document.save(filepath)
```

## Styles — The Document Design Foundation

```python
from docx import Document
from docx.shared import Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH

def apply_document_styles(document):
    styles = document.styles
    # Heading 1
    h1 = styles['Heading 1']
    h1.font.name  = 'Calibri Light'
    h1.font.size  = Pt(22)
    h1.font.bold  = True
    h1.font.color.rgb = RGBColor(0x1F, 0x49, 0x7D)
    h1.paragraph_format.space_before = Pt(18)
    h1.paragraph_format.space_after  = Pt(6)
    # Heading 2
    h2 = styles['Heading 2']
    h2.font.name  = 'Calibri Light'
    h2.font.size  = Pt(16)
    h2.font.bold  = True
    h2.font.color.rgb = RGBColor(0x2E, 0x74, 0xB5)
    h2.paragraph_format.space_before = Pt(14)
    h2.paragraph_format.space_after  = Pt(4)
    # Normal body text
    normal = styles['Normal']
    normal.font.name = 'Calibri'
    normal.font.size = Pt(11)
    normal.paragraph_format.space_after  = Pt(6)
    normal.paragraph_format.line_spacing = 1.15
    # Quote / Callout
    quote = styles['Quote']
    quote.font.name   = 'Calibri'
    quote.font.size   = Pt(11)
    quote.font.italic = True
    quote.font.color.rgb = RGBColor(0x60, 0x60, 0x60)
    quote.paragraph_format.left_indent   = Inches(0.5)
    quote.paragraph_format.space_before  = Pt(8)
    quote.paragraph_format.space_after   = Pt(8)
    return document
```

## Paragraphs — Spacing, Indentation, Alignment

```python
from docx import Document
from docx.shared import Pt, Inches
from docx.enum.text import WD_ALIGN_PARAGRAPH

def add_styled_paragraphs(document):
    # Centered heading
    title = document.add_paragraph()
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = title.add_run("Annual Report 2026")
    run.bold = True
    run.font.size = Pt(28)
    run.font.name = 'Calibri Light'

    # Left-aligned body
    body = document.add_paragraph("This is the body text.")

    # Justified text (for print documents)
    justified = document.add_paragraph("Justified text fills the line by stretching spaces.")
    justified.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY

    # Indented paragraph (for quotes)
    indented = document.add_paragraph("Indented paragraph.")
    indented.paragraph_format.left_indent = Inches(0.5)

    # Bulleted list
    bullet = document.add_paragraph("First bullet item", style='List Bullet')
    bullet = document.add_paragraph("Second bullet item", style='List Bullet')

    # Numbered list
    num = document.add_paragraph("Step one", style='List Number')
    num = document.add_paragraph("Step two", style='List Number')
    return document
```

## Inline Formatting — Bold, Italic, Color, Highlight

```python
from docx import Document
from docx.shared import Pt, RGBColor, HighlightColor

def add_formatted_text(document):
    p = document.add_paragraph()
    p.add_run("This is ")
    run = p.add_run("bold text"); run.bold = True
    p.add_run(" and this is ")
    run = p.add_run("italic text"); run.italic = True
    p.add_run(". Now ")
    run = p.add_run("bold italic"); run.bold = True; run.italic = True
    p.add_run(".\nColored: ")
    run = p.add_run("blue text"); run.font.color.rgb = RGBColor(0x2E, 0x74, 0xB5)
    p.add_run(" | Highlighted: ")
    run = p.add_run("yellow highlight"); run.font.highlight_color = HighlightColor.YELLOW
    p.add_run(" | Font size 14pt: "); run = p.add_run("larger"); run.font.size = Pt(14)
    p.add_run(" | Subscript: "); run = p.add_run("H₂O"); run.font.subscript = True
    p.add_run(" | Superscript: "); run = p.add_run("E=mc²"); run.font.superscript = True
    return document
```

## Tables — Borders, Shading, Merging, Header Row

```python
from docx import Document
from docx.shared import Pt, Inches, RGBColor, Cm
from docx.oxml.ns import qn
from docx.oxml import OxmlElement
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL

def set_cell_border(cell, **kwargs):
    tc = cell._tc
    tcPr = tc.get_or_add_tcPr()
    tcBorders = OxmlElement('w:tcBorders')
    for edge in ('top', 'left', 'bottom', 'right'):
        tag = 'w:' + edge
        element = OxmlElement(tag)
        element.set(qn('w:val'),   kwargs.get(edge, 'none'))
        element.set(qn('w:sz'),    kwargs.get('sz', '4'))
        element.set(qn('w:space'), '0')
        element.set(qn('w:color'), kwargs.get('color', 'auto'))
        tcBorders.append(element)
    tcPr.append(tcBorders)

def set_cell_shading(cell, fill_color):
    tc = cell._tc; tcPr = tc.get_or_add_tcPr()
    shading = OxmlElement('w:shd')
    shading.set(qn('w:val'), 'clear'); shading.set(qn('w:color'), 'auto')
    shading.set(qn('w:fill'), fill_color)
    tcPr.append(shading)

def add_styled_table(document):
    headers = ["Name", "Department", "Score", "Status"]
    rows = [["María García", "Marketing", "94", "✅ Logrado"],
            ["Carlos Ruiz", "Ventas", "78", "🔄 En proceso"],
            ["Ana López", "IT", "85", "✅ Logrado"],
            ["Pedro Sánchez", "RH", "61", "⚠️ Por reforzar"]]
    table = document.add_table(rows=len(rows) + 1, cols=len(headers))
    table.alignment = WD_TABLE_ALIGNMENT.CENTER; table.style = 'Table Grid'

    # Header row
    header_row = table.rows[0]
    for i, header in enumerate(headers):
        cell = header_row.cells[i]; cell.text = header
        set_cell_shading(cell, "1F497D")
        para = cell.paragraphs[0]; para.alignment = 1
        run = para.runs[0]; run.bold = True
        run.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF); run.font.size = Pt(11)

    # Data rows with alternating shading
    for row_idx, row_data in enumerate(rows):
        row = table.rows[row_idx + 1]; bg = "EBF3FB" if row_idx % 2 == 0 else "FFFFFF"
        for col_idx, cell_text in enumerate(row_data):
            cell = row.cells[col_idx]; cell.text = cell_text
            set_cell_shading(cell, bg)
            para = cell.paragraphs[0]; run = para.runs[0]; run.font.size = Pt(10)
            if col_idx in (2, 3): para.alignment = 1
            if col_idx == 2: para.alignment = 2

    # Column widths
    widths = [Inches(1.5), Inches(1.5), Inches(0.8), Inches(1.2)]
    for row in table.rows:
        for i, cell in enumerate(row.cells): cell.width = widths[i]

    # Caption
    caption = document.add_paragraph("Tabla 1. Resultados por estudiante")
    caption.alignment = 1; caption.runs[0].italic = True; caption.runs[0].font.size = Pt(9)
    caption.paragraph_format.space_before = Pt(4)
    return document, table
```

## Header, Footer, Page Numbers

```python
from docx import Document
from docx.shared import Pt
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

def add_header_and_footer(document):
    section = document.sections[0]
    # Header
    header = section.header
    header_para = header.paragraphs[0]
    header_para.text = "Project Title | Unit 1 | Grade"
    header_para.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = header_para.runs[0]; run.font.size = Pt(9)

    # Footer with page number field
    footer = section.footer
    footer_para = footer.paragraphs[0]
    left_run = footer_para.add_run("Teacher: ___________     "); left_run.font.size = Pt(9)
    center_run = footer_para.add_run()
    fldChar1 = OxmlElement('w:fldChar'); fldChar1.set(qn('w:fldCharType'), 'begin')
    instrText = OxmlElement('w:instrText'); instrText.text = ' PAGE '
    fldChar2 = OxmlElement('w:fldChar'); fldChar2.set(qn('w:fldCharType'), 'separate')
    fldChar3 = OxmlElement('w:fldChar'); fldChar3.set(qn('w:fldCharType'), 'end')
    run._r.append(fldChar1); center_run._r.append(instrText)
    center_run._r.append(fldChar2); center_run._r.append(fldChar3)
    center_run.font.size = Pt(9); center_run.bold = True
    right_run = footer_para.add_run("     Date: ___________"); right_run.font.size = Pt(9)
    footer_para.alignment = WD_ALIGN_PARAGRAPH.CENTER
    return document
```

## Images

```python
from docx import Document
from docx.shared import Inches, Pt
from docx.enum.text import WD_ALIGN_PARAGRAPH

def add_image(document, image_path, width=Inches(5)):
    para = document.add_paragraph(); para.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = para.add_run(); run.add_picture(image_path, width=width)
    caption = document.add_paragraph("Figure 1. Image title")
    caption.alignment = WD_ALIGN_PARAGRAPH.CENTER
    caption.runs[0].italic = True; caption.runs[0].font.size = Pt(9)
    caption.paragraph_format.space_before = Pt(2)
    return document
```

## Table of Contents (static)

```python
from docx import Document
from docx.shared import Pt, Inches

def add_table_of_contents(document):
    toc_heading = document.add_paragraph("Index"); toc_heading.style = 'Heading 1'
    toc_items = [("Section 1", "3"), ("Section 2", "5"), ("Section 3", "7")]
    for title, page in toc_items:
        p = document.add_paragraph()
        p.add_run(f"{title}"); p.add_run(f"\t{page}")
        p.paragraph_format.tab_stops.add_tab_stop(Inches(5.5), alignment=2)
        p.runs[0].font.size = Pt(11)
    return document
```

## Complete Document Builder

```python
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.section import WD_ORIENT

def build_professional_document(filepath):
    document = Document()
    # 1. Page setup
    section = document.sections[0]
    section.page_width   = Inches(8.5); section.page_height = Inches(11)
    section.left_margin  = Inches(1.0); section.right_margin = Inches(1.0)
    section.top_margin   = Inches(1.0); section.bottom_margin = Inches(1.0)
    # 2. Styles
    document = apply_document_styles(document)
    # 3. Title block
    title = document.add_paragraph()
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = title.add_run("Document Title"); run.bold = True; run.font.size = Pt(26)
    run.font.name = 'Calibri Light'
    subtitle = document.add_paragraph(); subtitle.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = subtitle.add_run("Subtitle info"); run.font.size = Pt(12)
    run.font.color.rgb = RGBColor(0x60, 0x60, 0x60)
    document.add_paragraph()
    # 4. Header/Footer
    document = add_header_and_footer(document)
    # 5. Content sections
    h1 = document.add_paragraph("🔵 Section Title"); h1.style = 'Heading 1'
    body = document.add_paragraph("Body text here.")
    # 6. Table
    document, table = add_styled_table(document)
    # 7. Lists
    document.add_paragraph(); h2 = document.add_paragraph("Activities"); h2.style = 'Heading 2'
    for item in ["☐ Activity 1", "☐ Activity 2"]:
        document.add_paragraph(item, style='List Bullet')
    # 8. Page break
    document.add_page_break()
    h1 = document.add_paragraph("🟢 Next Section"); h1.style = 'Heading 1'
    document.save(filepath)
    print(f"Document saved: {filepath}")
    return filepath
```
