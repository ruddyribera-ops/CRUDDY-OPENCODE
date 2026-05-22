---
name: slide-making-skill
description: Implement single-slide PowerPoint pages with PptxGenJS. Covers dimensions, positioning, text/image/chart APIs, styling rules, and export expectations for native .pptx output.
tags: [ppt, slide, presentation, office]
tags: [powerpoint, pptx, slide, pptxgenjs, presentation, javascript]
---

## When to Use
- Generating individual PowerPoint slides programmatically with PptxGenJS
- Positioning and styling text, images, shapes, and charts on slides
- Writing JS code that produces native .pptx output
- Creating reusable slide templates

## Do Not Use
- Editing existing PPTX files (use ppt-editing-skill)
- Orchestrating multi-slide presentations (use ppt-orchestra-skill)
- Creating Word docs or PDFs (use msoffice-tools or minimax-pdf)
- Design decisions (use color-font-skill)

# PptxGenJS Slide Making Skill

## PptxGenJS API Reference
→ See `pptxgenjs.md` for complete API: setup, text & formatting, lists & bullets, shapes & shadows, images & icons, slide backgrounds, tables & charts.

## Theme & Formatting Rules

**Font families:** Chinese → Microsoft YaHei, English → Arial (or Georgia, Calibri, Cambria). No bold for body text, captions, or footnotes — reserve for titles/headings only.

**Color palette:** Use ONLY provided `theme` object keys (`primary`, `secondary`, `accent`, `light`, `bg`). No gradients. No animations.

**Page number badge:** All slides except Cover must have badge at bottom-right (x:9.3", y:5.1").

**Subagent output:** Complete runnable JS files with synchronous `createSlide(pres, theme)` function.

→ See `references/slide-patterns.md` for:
- Font, color, and theme rules with code examples
- Page number badge patterns (circle + pill)
- Subagent output format template
- Critical pitfalls (no async, no `#` in hex, no opacity in hex)

## Critical Pitfalls (Must Follow)
1. **NO async/await** in createSlide() — must be synchronous
2. **NO `#` prefix** on hex colors — `"FF0000"` not `"#FF0000"`
3. **NO opacity in hex strings** — use `opacity: 0.12` separately
4. **Always set `valign`** for text in shapes
5. **Use `fit: 'shrink'`** for long single-line titles

## Verification
- [ ] Slide file generates without errors: `node slide-XX.js`
- [ ] Output `.pptx` opens in PowerPoint/LibreOffice
- [ ] Colors match theme object exactly (no external colors)
- [ ] Page numbers present on all non-cover slides
- [ ] Body text not bold, titles are bold
- [ ] No `#` in any color value
- [ ] All reference links resolve
