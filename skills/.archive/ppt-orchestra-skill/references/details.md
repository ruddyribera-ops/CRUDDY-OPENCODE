# Detailed Reference

## Compiling Slides (Full Code)

After all slide JS files are generated in `slides/`, create `slides/compile.js`:

```javascript
// slides/compile.js
const pptxgen = require('pptxgenjs');
const pres = new pptxgen();
pres.layout = 'LAYOUT_16x9';

const theme = {
  primary: "22223b",
  secondary: "4a4e69",
  accent: "9a8c98",
  light: "c9ada7",
  bg: "f2e9e4"
};

for (let i = 1; i <= 12; i++) {
  const num = String(i).padStart(2, '0');
  const slideModule = require(`./slide-${num}.js`);
  slideModule.createSlide(pres, theme);
}

pres.writeFile({ fileName: './output/presentation.pptx' });
```

Run with: `cd slides && node compile.js`

## Slide Type Taxonomy

| Type | Purpose | Visual Treatment | Count |
|------|---------|-----------------|-------|
| **Cover** | Brand + title + presenter | Full-bleed bg, oversized title, strong contrast | 1 |
| **TOC** | Sections overview | Grid/list of sections with page refs | 1 |
| **Section Divider** | Transition between parts | Large number, minimal text, atmospheric | 1 per section |
| **Content — Text** | Bullets, paragraphs, quotes | Left-aligned body, icon accents | varies |
| **Content — Mixed Media** | Image + text combo | 50/50 split, or 60/40 image-dominant | varies |
| **Content — Data Viz** | Chart + key takeaways | Chart prominent, 1-3 insights right/below | varies |
| **Content — Comparison** | A vs B, before/after | Side-by-side cards, pros/cons columns | varies |
| **Content — Timeline** | Steps, phases, journey | Horizontal/vertical arrows, numbered nodes | varies |
| **Content — Image Showcase** | Visual focus | Large image, minimal text overlay | varies |
| **Summary** | Takeaways + CTA | Bold recap, actionable next step | 1 |

## Design Consistency Checklist
- [ ] All slides use the same 5-key theme object (`primary`, `secondary`, `accent`, `light`, `bg`)
- [ ] Font pairing is consistent: 1 header font + 1 body font throughout
- [ ] Same border radius system applied to all shapes
- [ ] Page number badges on all slides except cover, same position (x: 9.3", y: 5.1")
- [ ] No two consecutive content slides share the same layout
- [ ] At least one visual element per slide — no plain text-only
- [ ] Color contrast: body text ≥ 4.5:1 against background
- [ ] Margins: 0.5" minimum on all sides
- [ ] Captions/attribution on all charts and external images
- [ ] Final slide: includes CTA OR thank-you OR contact info
