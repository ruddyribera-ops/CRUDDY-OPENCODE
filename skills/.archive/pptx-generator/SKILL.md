---
name: pptx-generator
description: Generate, edit, and read PowerPoint presentations. Create from scratch with PptxGenJS (cover, TOC, content, section divider, summary slides), edit existing PPTX via XML workflows, or extract text with markitdown. Triggers: PPT, PPTX, PowerPoint, presentation, slide, deck, slides.
tags: [ppt, pptx, presentation, office]
---

# PPTX Generator & Editor

## When to Use
- Generate PowerPoint presentations from scratch
- Create PPTX with PptxGenJS (cover, TOC, content, section slides)
- Export content as PPTX format
- Build presentation decks programmatically

## Do Not Use
- Edit existing PPTX templates (use ppt-editing-skill)
- Plan presentation structure (use ppt-orchestra-skill)
- Create individual slides manually (use slide-making-skill)
- Generate DOCX or XLSX files

Handles reading/analyzing, editing via XML, and creating from scratch with PptxGenJS.

## Quick Reference

| Task | Approach |
|------|----------|
| Read/analyze content | `python -m markitdown presentation.pptx` |
| Edit or create from template | See `references/editing.md` |
| Create from scratch | See workflow below |

| Item | Value |
|------|-------|
| **Dimensions** | 10" x 5.625" (LAYOUT_16x9) |
| **Colors** | 6-char hex without # (e.g., `"FF0000"`) |
| **English font** | Arial (default), or approved alternatives |
| **Chinese font** | Microsoft YaHei |
| **Page badge position** | x: 9.3", y: 5.1" |
| **Theme keys** | `primary`, `secondary`, `accent`, `light`, `bg` |
| **Shapes** | RECTANGLE, OVAL, LINE, ROUNDED_RECTANGLE |
| **Charts** | BAR, LINE, PIE, DOUGHNUT, SCATTER, BUBBLE, RADAR |

## Reference Files

| File | Contents |
|------|----------|
| `references/slide-types.md` | 5 slide page types + additional layout patterns |
| `references/design-system.md` | Color palettes, font reference, style recipes, typography |
| `references/editing.md` | Template-based editing workflow, XML manipulation |
| `references/pitfalls.md` | QA process, common mistakes, PptxGenJS pitfalls |
| `references/pptxgenjs.md` | Complete PptxGenJS API reference |
| `references/slide-output.md` | Slide JS file format, page number badge code |
| `references/design-patterns.md` | Slide structure, color, typography patterns |

## Workflow (Create from Scratch)

### Step 1: Research & Requirements
Understand topic, audience, purpose, tone, content depth.

### Step 2: Select Color Palette & Fonts
Use `references/design-system.md` to select palette and font pairing.

### Step 3: Select Design Style
Use `references/design-system.md` style recipes (Sharp, Soft, Rounded, Pill).

### Step 4: Plan Slide Outline
Classify every slide as one of the 5 page types (see `references/slide-types.md`). Ensure visual variety.

### Step 5: Generate Slide JS Files
One file per slide in `slides/` directory. Each exports synchronous `createSlide(pres, theme)`. Generate up to 5 concurrently.

See `references/slide-output.md` for exact JS format and `references/pptxgenjs.md` for API.

### Step 6: Compile into Final PPTX
Create `slides/compile.js` — import all slide modules, call with theme object, write output.

### Step 7: QA
See `references/pitfalls.md`. Run `python -m markitdown output.pptx` and fix issues.

## Theme Object Contract (MANDATORY)
| Key | Purpose | Example |
|-----|---------|---------|
| `theme.primary` | Darkest color, titles | `"22223b"` |
| `theme.secondary` | Dark accent, body text | `"4a4e69"` |
| `theme.accent` | Mid-tone accent | `"9a8c98"` |
| `theme.light` | Light accent | `"c9ada7"` |
| `theme.bg` | Background color | `"f2e9e4"` |

NEVER use other key names.

## Dependencies
- `pip install "markitdown[pptx]"` — text extraction
- `npm install -g pptxgenjs` — creating from scratch

## Verification
- [ ] All slides classified as exactly one page type
- [ ] No repeated layouts on consecutive slides
- [ ] Theme object contract followed exactly (5 keys)
- [ ] Page number badge on all slides except cover
- [ ] `python -m markitdown output.pptx` produces expected content
- [ ] File opens without errors in PowerPoint/LibreOffice
