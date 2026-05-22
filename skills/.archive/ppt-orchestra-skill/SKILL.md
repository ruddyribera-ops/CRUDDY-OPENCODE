---
name: ppt-orchestra-skill
description: Plan and orchestrate multi-slide PowerPoint creation from scratch. Use before generating a full deck with subagents: classify each slide type, enforce visual variety, set typography/spacing rules, and run text-based QA to catch content issues.
tags: [ppt, pptx, presentation, planning]
---

# Slide Page Types (Standard)

## When to Use
- Plan a multi-slide PowerPoint presentation from scratch
- Orchestrate slide types and visual variety across a deck
- Define typography, spacing, and layout rules before generating
- Run text-based QA on presentation content

## Do Not Use
- Edit existing PPTX files (use ppt-editing-skill)
- Create a single slide (use slide-making-skill)
- Choose colors or fonts (use color-font-skill)
- Generate individual slide implementation

Classify **every slide** as exactly one of these 5 page types:

1. **Cover Page** — opening + tone setting: big title, subtitle, presenter, strong background
2. **Table of Contents** — navigation: section list (3-5 sections, optional icons/page numbers)
3. **Section Divider** — transitions: section number + title (+ optional 1-2 line intro)
4. **Content Page** (pick a subtype):
   - Text: bullets/quotes/short paragraphs + icons/shapes
   - Mixed media: two-column / half-bleed image + text overlay
   - Data visualization: chart + 1-3 key takeaways + source
   - Comparison: side-by-side columns/cards (A vs B, pros/cons)
   - Timeline / process: steps with arrows, journey, phases
   - Image showcase: hero image, gallery, visual-first layout
5. **Summary / Closing Page** — wrap-up: takeaways, CTA, contact/QR, thank-you

**Layout options**: Two-column, icon+text rows, 2x2/2x3 grid, half-bleed image, large stat callouts (60-72pt), comparison columns, timeline/process flow.

See `references/details.md` for full slide type taxonomy table.

## Typography

| Header Font | Body Font |
|-------------|-----------|
| Georgia | Calibri |
| Arial Black | Arial |
| Cambria | Calibri |
| Trebuchet MS | Calibri |
| Palatino | Garamond |

| Element | Size |
|---------|------|
| Slide title | 36-44pt bold |
| Section header | 20-24pt bold |
| Body text | 14-16pt |
| Captions | 10-12pt muted |

## Spacing
- 0.5" minimum margins
- 0.3-0.5" between content blocks
- Leave breathing room

## Common Mistakes to Avoid
- No repeated layouts — vary columns, cards, callouts across slides
- Don't center body text — left-align paragraphs and lists
- Titles need 36pt+ to stand out from 14-16pt body
- Pick topic-relevant colors, not default blue
- No text-only slides — add images, icons, charts
- Don't use accent lines under titles (hallmark of AI slides)
- Check text box padding when aligning with shapes
- Ensure strong contrast on all elements

## Compiling Slides
After JS files are generated in `slides/`, create `slides/compile.js` to combine them. See `references/details.md` for full compile script.

## QA (Required)
**Assume there are problems. Your job is to find them.**

```bash
python -m markitdown output.pptx
# Check for leftover placeholders
python -m markitdown output.pptx | grep -iE "xxxx|lorem|ipsum|this.*(page|slide).*layout"
```

### Verification Loop
1. Generate slides → Extract text → Review content
2. **List issues found** (look critically if none found)
3. Fix issues → Re-verify affected slides
4. Repeat until a full pass reveals no new issues

## Dependencies
- `pip install "markitdown[pptx]"` — text extraction
- `npm install -g pptxgenjs` — creating from scratch

## Verification
- [ ] Every slide classified as exactly one page type
- [ ] No two consecutive slides share the same layout
- [ ] All slides use the same 5-key theme object
- [ ] Font pairing consistent throughout
- [ ] Page number badges on all slides except cover
- [ ] At least one visual element per slide
- [ ] QA markitdown check passes with no placeholders
