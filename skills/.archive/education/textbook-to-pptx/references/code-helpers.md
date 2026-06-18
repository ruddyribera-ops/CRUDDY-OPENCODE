# code-helpers.md — Python-pptx Helpers Robustos

Helpers probados que evitan bugs conocidos de python-pptx (bold/color, tipos, etc.).

## Imports

```python
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.enum.shapes import MSO_SHAPE
from lxml import etree
import os
```

## Helpers Base

```python
def add_bg(slide, color):
    slide.background.fill.solid()
    slide.background.fill.fore_color.rgb = color

def rect(slide, l, t, w, h, color, radius=None):
    """Rectángulo. radius=0.05 para esquinas redondeadas."""
    st = MSO_SHAPE.ROUNDED_RECTANGLE if radius else MSO_SHAPE.RECTANGLE
    s = slide.shapes.add_shape(st, Inches(l), Inches(t), Inches(w), Inches(h))
    s.fill.solid()
    s.fill.fore_color.rgb = color
    s.line.fill.background()
    if radius:
        s.adjustments[0] = radius
    return s

def txt(slide, l, t, w, h, text, size=18, bold=False, color=None, align=PP_ALIGN.LEFT):
    """Textbox robusto: detecta si color se pasó en posición de bold."""
    if isinstance(bold, (RGBColor, tuple)):
        color = bold
        bold = False
    tb = slide.shapes.add_textbox(Inches(l), Inches(t), Inches(w), Inches(h))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = text
    p.font.size = Pt(size)
    p.font.bold = bold
    if color:
        p.font.color.rgb = color
    p.font.name = 'Calibri'
    p.alignment = align
    return tb

def add_img(slide, path, l, t, w, h=None):
    """Solo agrega si el archivo existe."""
    if path and os.path.exists(path):
        kw = {'left': Inches(l), 'top': Inches(t), 'width': Inches(w)}
        if h:
            kw['height'] = Inches(h)
        slide.shapes.add_picture(path, **kw)
        return True
    return False

def add_fade_transition(slide, duration_ms=500):
    """Transición FADE. Compatible WPS."""
    ns_slide = 'http://schemas.openxmlformats.org/presentationml/2006/main'
    ns_dml = 'http://schemas.openxmlformats.org/drawingml/2006/main'
    transition = etree.SubElement(slide._element, f'{{{ns_slide}}}transition')
    fade = etree.SubElement(transition, f'{{{ns_dml}}}fade')
    fade.set('dur', str(duration_ms))

def add_attribution(slide, text, l=0.6, t=7.0):
    """Texto de atribución CC. Llamar después de cada imagen."""
    txt(slide, l, t, 8, 0.3, text, 8, color=RGBColor(0xAA, 0xAA, 0xAA))
```

## Patrones de Slide

### Progressive Disclosure (2 slides con fade)
```python
def create_progressive_pair(prs, theme, title, items_batch1, items_all):
    """Crea 2 slides: primero parcial, luego completo. Con fade."""
    # Slide A: items 1-2
    s1 = prs.slides.add_slide(prs.slide_layouts[6])
    add_fade_transition(s1)
    # ... agregar title + items_batch1 ...
    
    # Slide B: todos los items
    s2 = prs.slides.add_slide(prs.slide_layouts[6])
    add_fade_transition(s2)
    # ... mismo title + items_all ...
    
    return s1, s2
```

### Image Labeling
```python
def add_labeled_image(slide, img_path, label, subtitle, size_compare, x, y, w, h, theme):
    """Imagen con etiqueta + tamaño comparativo + attribution."""
    add_img(slide, img_path, x, y, w, h)
    # Label
    rect(slide, x+0.2, y+0.1, 3.0, 0.7, theme.primary)
    txt(slide, x+0.4, y+0.15, 2.6, 0.5, label, 16, True, WHITE)
    txt(slide, x+0.4, y+0.5, 2.6, 0.3, subtitle, 10, color=RGBColor(0xD4,0xEC,0xEC))
    # Size comparison badge
    rect(slide, x+0.2, y+h-0.6, 2.5, 0.5, theme.secondary)
    txt(slide, x+0.4, y+h-0.55, 2.1, 0.4, size_compare, 11, True, WHITE)
```

### Data Cards
```python
def add_data_cards(slide, cards, start_y=1.7, card_w=3.8, gap=0.4):
    """Tarjetas: icono + número grande + texto. Cognitive load optimizado."""
    for i, (icon, value, label, color) in enumerate(cards):
        x = 0.6 + i * (card_w + gap)
        rect(slide, x, start_y, card_w, 3.0, WHITE)
        rect(slide, x, start_y, card_w, 0.08, color)
        txt(slide, x+1.2, start_y+0.2, 1.4, 0.7, icon, 36, align=PP_ALIGN.CENTER)
        txt(slide, x+0.2, start_y+0.9, card_w-0.4, 0.6, value, 26, True, color, PP_ALIGN.CENTER)
        txt(slide, x+0.2, start_y+1.5, card_w-0.4, 1.0, label, 14, align=PP_ALIGN.CENTER)
```

## Template Theme Contract

```python
T_WARM = {
    'primary':   RGBColor(0x0F, 0x7C, 0x7C),  # teal
    'secondary': RGBColor(0xE8, 0x7A, 0x2A),  # orange
    'accent':    RGBColor(0xF4, 0xC5, 0x42),  # yellow
    'bg':        RGBColor(0xFF, 0xF8, 0xF0),  # cream
    'card':      RGBColor(0xFF, 0xFF, 0xFF),
    'text':      RGBColor(0x2D, 0x2D, 0x2D),
    'light':     RGBColor(0xD4, 0xEC, 0xEC),
    'warm':      RGBColor(0xFD, 0xED, 0xDD),
}

T_PRO = {
    'primary':   RGBColor(0x1B, 0x3A, 0x5C),  # dark blue
    'secondary': RGBColor(0x2E, 0x86, 0xAB),  # medium blue
    'accent':    RGBColor(0xF4, 0xA2, 0x61),  # orange
    'bg':        RGBColor(0xF0, 0xF4, 0xF8),
    'card':      RGBColor(0xFF, 0xFF, 0xFF),
    'text':      RGBColor(0x2D, 0x2D, 0x2D),
    'light':     RGBColor(0xD6, 0xE4, 0xF0),
    'warm':      RGBColor(0xFD, 0xF2, 0xE9),
}
```
