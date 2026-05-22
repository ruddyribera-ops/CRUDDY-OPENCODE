# Slide Making — Detailed Patterns

## Font Rules
| Language | Default | Alternatives |
|----------|---------|--------------|
| Chinese | Microsoft YaHei | — |
| English | Arial | Georgia, Calibri, Cambria, Trebuchet MS |

**No bold for body text.** Reserve bold for titles and headings only.

## Color Palette Rules (MANDATORY)
Use ONLY the provided theme colors. No gradients, no animations.
```javascript
// ✅ Correct
slide.addShape(pres.shapes.RECTANGLE, { fill: { color: theme.primary } });
// Transparency only exception
slide.addShape(pres.shapes.RECTANGLE, { fill: { color: theme.accent, transparency: 50 } });
```

## Theme Object Contract
| Key | Purpose | Example |
|-----|---------|---------|
| `theme.primary` | Darkest color, titles | `"22223b"` |
| `theme.secondary` | Dark accent, body text | `"4a4e69"` |
| `theme.accent` | Mid-tone accent | `"9a8c98"` |
| `theme.light` | Light accent | `"c9ada7"` |
| `theme.bg` | Background color | `"f2e9e4"` |

## Page Number Badge (REQUIRED)
All slides except Cover must include page number badge at bottom-right (x: 9.3", y: 5.1").

### Circle Badge
```javascript
slide.addShape(pres.shapes.OVAL, { x: 9.3, y: 5.1, w: 0.4, h: 0.4, fill: { color: theme.accent } });
slide.addText("3", { x: 9.3, y: 5.1, w: 0.4, h: 0.4, fontSize: 12, fontFace: "Arial",
  color: "FFFFFF", bold: true, align: "center", valign: "middle" });
```

### Pill Badge
```javascript
slide.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 9.1, y: 5.15, w: 0.6, h: 0.35, fill: { color: theme.accent }, rectRadius: 0.15 });
slide.addText("03", { x: 9.1, y: 5.15, w: 0.6, h: 0.35, fontSize: 11, fontFace: "Arial",
  color: "FFFFFF", bold: true, align: "center", valign: "middle" });
```

## Subagent Output Format
Each subagent outputs a complete, runnable JS file:
```javascript
const pptxgen = require("pptxgenjs");
const slideConfig = { type: 'cover', index: 1, title: 'Presentation Title' };

// ⚠️ MUST be synchronous (not async)
function createSlide(pres, theme) {
  const slide = pres.addSlide();
  slide.background = { color: theme.bg };
  slide.addText(slideConfig.title, { x: 0.5, y: 2, w: 9, h: 1.2, fontSize: 48,
    fontFace: "Arial", color: theme.primary, bold: true, align: "center" });
  return slide;
}

// Standalone preview
if (require.main === module) {
  const pres = new pptxgen(); pres.layout = 'LAYOUT_16x9';
  const theme = { primary: "22223b", secondary: "4a4e69", accent: "9a8c98",
    light: "c9ada7", bg: "f2e9e4" };
  createSlide(pres, theme);
  pres.writeFile({ fileName: "slide-01-preview.pptx" });
}
module.exports = { createSlide, slideConfig };
```

## Critical Pitfalls
1. **NEVER use async/await in createSlide()** — compile.js won't await
2. **NEVER use "#" with hex colors** — `"FF0000"` ✅, `"#FF0000"` ❌ corrupts file
3. **NEVER encode opacity in hex** — use `{ color: "000000", opacity: 0.12 }`, not `"00000020"`
4. **Prevent text wrapping in titles** — use `fit: 'shrink'` for long titles
5. **Always set `valign`** for text alignment in shapes

## PptxGenJS API Reference
See `pptxgenjs.md` for complete API: setup, text, lists, shapes, images, backgrounds, tables, charts.
