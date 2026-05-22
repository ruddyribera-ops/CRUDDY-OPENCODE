# PowerPoint Presentations — Complete Code Examples

## Presentation Architecture

```
Presentation
├── slides.add_slide(layout)      # Add a slide
├── slide.shapes                  # All shapes on a slide
│   ├── placeholder              # Pre-defined layout slot (title, body, etc.)
│   ├── textbox                  # Free-form text box
│   ├── picture                  # Image
│   ├── table                    # Table
│   └── shape                   # Basic shapes (rect, oval, line)
├── slide.shapes.title           # Title placeholder
├── slide.shapes.placeholders[i]  # Access by index
├── slide.background             # Background fill
├── slide.slide_layout           # Layout template
└── slide_width / slide_height   # Dimensions
```

## Slide Dimensions and Layout

```python
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.enum.shapes import MSO_SHAPE

def create_presentation(filepath):
    prs = Presentation()
    # Widescreen 16:9
    prs.slide_width  = Inches(13.333); prs.slide_height = Inches(7.5)
    # Available layouts: 0=Title, 1=Title+Content, 2=Section, 3=Two Content
    # 4=Only Title, 5=Blank, 6=Content with Caption, 7=Picture with Caption
    blank_layout = prs.slide_layouts[5]
    title_layout = prs.slide_layouts[0]
    prs.save(filepath); return prs
```

## Title Slide — Professional Treatment

```python
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.enum.shapes import MSO_SHAPE

def add_title_slide(prs):
    slide_layout = prs.slide_layouts[6]
    slide = prs.slides.add_slide(slide_layout)

    # Full-slide brand color background
    bg_shape = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE,
        Inches(0), Inches(0), prs.slide_width, prs.slide_height)
    bg_shape.fill.solid(); bg_shape.fill.fore_color.rgb = RGBColor(0x1F, 0x49, 0x7D)
    bg_shape.line.fill.background()

    # Title
    title_box = slide.shapes.add_textbox(Inches(0.75), Inches(2.2), Inches(11.8), Inches(1.5))
    tf = title_box.text_frame; tf.word_wrap = True
    p = tf.paragraphs[0]; p.text = "Presentation Title"
    p.alignment = PP_ALIGN.CENTER; p.font.name = 'Calibri Light'
    p.font.size = Pt(44); p.font.bold = True; p.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)

    # Subtitle
    sub_box = slide.shapes.add_textbox(Inches(0.75), Inches(3.8), Inches(11.8), Inches(1.0))
    tf = sub_box.text_frame
    p = tf.paragraphs[0]; p.text = "Subtitle | Info"
    p.alignment = PP_ALIGN.CENTER; p.font.name = 'Calibri'
    p.font.size = Pt(18); p.font.color.rgb = RGBColor(0xCC, 0xDD, 0xEE)

    # Bottom accent bar
    bar = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE,
        Inches(0), Inches(6.8), prs.slide_width, Inches(0.7))
    bar.fill.solid(); bar.fill.fore_color.rgb = RGBColor(0x2E, 0x74, 0xB5)
    bar.line.fill.background()

    # Date info
    date_box = slide.shapes.add_textbox(Inches(0.75), Inches(6.85), Inches(11.8), Inches(0.5))
    tf = date_box.text_frame
    p = tf.paragraphs[0]; p.text = "Date: _______________     Group: ______"
    p.alignment = PP_ALIGN.CENTER; p.font.size = Pt(12); p.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
    return slide
```

## Content Slide — Title + Bullets

```python
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN

def add_content_slide(prs, title, bullets, accent_color="1F497D"):
    slide_layout = prs.slide_layouts[1]
    slide = prs.slides.add_slide(slide_layout)
    title_shape = slide.shapes.title; title_shape.text = title
    for para in title_shape.text_frame.paragraphs:
        para.font.name = 'Calibri Light'; para.font.size = Pt(36)
        para.font.bold = True; para.font.color.rgb = RGBColor(0x1F, 0x49, 0x7D)

    body_placeholder = slide.placeholders[1]
    tf = body_placeholder.text_frame; tf.clear()
    for i, bullet in enumerate(bullets):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.text = bullet; p.level = 0; p.font.name = 'Calibri'
        p.font.size = Pt(20); p.font.color.rgb = RGBColor(0x30, 0x30, 0x30)
    return slide
```

## Two-Column Slide — Comparison Layout

```python
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor

def add_two_column_slide(prs, title, left_title, left_items, right_title, right_items):
    slide_layout = prs.slide_layouts[2]
    slide = prs.slides.add_slide(slide_layout)
    title_shape = slide.shapes.title; title_shape.text = title
    for para in title_shape.text_frame.paragraphs:
        para.font.name = 'Calibri Light'; para.font.size = Pt(36); para.font.bold = True

    # Left column
    left_header = slide.shapes.add_textbox(Inches(0.7), Inches(2.2), Inches(5.8), Inches(0.6))
    p = left_header.text_frame.paragraphs[0]; p.text = left_title
    p.font.bold = True; p.font.size = Pt(22); p.font.color.rgb = RGBColor(0x1F, 0x49, 0x7D)

    left_body = slide.shapes.add_textbox(Inches(0.7), Inches(2.9), Inches(5.8), Inches(4.0))
    tf = left_body.text_frame; tf.word_wrap = True
    for i, item in enumerate(left_items):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.text = f"• {item}"; p.font.size = Pt(16); p.space_after = Pt(8)

    # Right column
    right_header = slide.shapes.add_textbox(Inches(6.8), Inches(2.2), Inches(5.8), Inches(0.6))
    p = right_header.text_frame.paragraphs[0]; p.text = right_title
    p.font.bold = True; p.font.size = Pt(22); p.font.color.rgb = RGBColor(0x2E, 0x74, 0xB5)

    right_body = slide.shapes.add_textbox(Inches(6.8), Inches(2.9), Inches(5.8), Inches(4.0))
    tf = right_body.text_frame; tf.word_wrap = True
    for i, item in enumerate(right_items):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.text = f"• {item}"; p.font.size = Pt(16); p.space_after = Pt(8)
    return slide
```

## Table Slide — Rubric / Scoring Grid

```python
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN

def add_table_slide(prs, title, headers, rows):
    slide_layout = prs.slide_layouts[5]
    slide = prs.slides.add_slide(slide_layout)

    # Title
    title_box = slide.shapes.add_textbox(Inches(0.5), Inches(0.3), Inches(12.3), Inches(0.8))
    p = title_box.text_frame.paragraphs[0]; p.text = title
    p.font.name = 'Calibri Light'; p.font.size = Pt(28)
    p.font.bold = True; p.font.color.rgb = RGBColor(0x1F, 0x49, 0x7D)

    # Table
    cols = len(headers)
    table = slide.shapes.add_table(len(rows)+1, cols,
        Inches(0.5), Inches(1.2), Inches(12.3), Inches(5.5)).table

    col_widths = [Inches(2.0), Inches(2.8), Inches(2.5), Inches(2.5), Inches(2.5)]
    for i, w in enumerate(col_widths): table.columns[i].width = w

    # Header row
    for i, h in enumerate(headers):
        cell = table.cell(0, i); cell.text = h; cell.fill.solid()
        cell.fill.fore_color.rgb = RGBColor(0x1F, 0x49, 0x7D)
        para = cell.text_frame.paragraphs[0]; para.alignment = PP_ALIGN.CENTER
        para.font.bold = True; para.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF); para.font.size = Pt(12)

    # Data rows
    for row_idx, row_data in enumerate(rows):
        for col_idx, val in enumerate(row_data):
            cell = table.cell(row_idx+1, col_idx); cell.text = val
            para = cell.text_frame.paragraphs[0]; para.font.size = Pt(10)
            if row_idx % 2 == 0:
                cell.fill.solid(); cell.fill.fore_color.rgb = RGBColor(0xEB, 0xF3, 0xFB)
    return slide
```

## Speaker Notes

```python
def add_speaker_notes(slide, notes_text):
    notes_slide = slide.notes_slide
    text_frame = notes_slide.notes_text_frame
    text_frame.text = notes_text
    return slide

# Usage: add_speaker_notes(slide, "Teacher note: Allow 5 min review.")
```
