---
name: ppt-editing-skill
description: Edit existing PowerPoint files or templates with XML-safe workflows. Use for template-based deck updates: analyze layouts, map content to slides, duplicate/reorder/delete slides safely, edit slide XML in parallel, clean orphaned assets, and repack validated PPTX output.
tags: [ppt, pptx, office, presentation]
---

# Editing Presentations

## When to Use
- Edit existing PowerPoint files/templates
- Update slide content in existing PPTX
- Modify layouts or styles in existing presentations
- Repurpose existing PPTX decks

## Do Not Use
- Create presentations from scratch (use pptx-generator or ppt-orchestra-skill)
- Design individual slides (use slide-making-skill)
- Choose color/font schemes (use color-font-skill)
- Create DOCX or XLSX files

## Template-Based Workflow

1. **Copy and analyze**: `cp user.pptx template.pptx` → `python -m markitdown template.pptx > template.md`
2. **Plan slide mapping**: For each content section, choose a template slide. Use varied layouts!
3. **Unpack**: Extract PPTX XML for editing
4. **Build presentation** (do yourself, not subagents): Delete unwanted slides, duplicate reuse slides, reorder
5. **Edit content**: Update text in each `slide{N}.xml`. Use subagents here if available (parallel XML edits)
6. **Clean**: Remove orphaned files
7. **Pack**: Repack with validation

## Output Structure
```
./
├── template.pptx               # Copy of user-provided file (never modified)
├── template.md                 # markitdown extraction
├── unpacked/                   # Editable XML tree
└── edited.pptx                 # Final repacked deck
```

## Scripts
| Script | Purpose |
|--------|---------|
| `unpack.py` | Extract and pretty-print PPTX |
| `add_slide.py` | Duplicate slide or create from layout |
| `clean.py` | Remove orphaned files, unreferenced media |
| `pack.py` | Repack with validation, repair, condense XML |

Always write to `/tmp/` first, then copy to final path (Python's `zipfile` seeks internally, failing on some volume mounts).

## Slide Operations
- **Reorder**: Rearrange `<p:sldId>` elements in `ppt/presentation.xml`
- **Delete**: Remove `<p:sldId>`, then run `clean.py`
- **Add**: Use `add_slide.py` — never manually copy slide files

## Editing Content
1. Read the slide's XML
2. Identify ALL placeholder content (text, images, charts, icons, captions)
3. Replace each with final content

**Use the Edit tool** — forces specificity about what to replace.

See `references/details.md` for XML manipulation patterns, EMU conversion, smart quotes, and multi-item content patterns.

## Common Pitfalls

### Template Adaptation
- Source has fewer items than template: **remove excess elements entirely**, don't just clear text
- Longer replacements may overflow — verify with `markitdown`
- **Template slots ≠ Source items**: delete entire groups, not just text

### Multi-Item Content
- Create separate `<a:p>` elements per item — never concatenate (see `references/details.md`)

## Verification Checklist
- [ ] `unpack.py` → directory structure matches original ZIP
- [ ] All modified `slide{N}.xml` files validate XML well-formedness
- [ ] `Content_Types.xml` lists all slide files, no orphans
- [ ] `ppt/_rels/presentation.xml.rels` has correct `rId` references
- [ ] No orphaned media files
- [ ] `ppt/presentation.xml` → `<p:sldIdLst>` order matches intended sequence
- [ ] `pack.py` exit code = 0
- [ ] `python -m markitdown edited.pptx` produces expected content
- [ ] File opens without errors in PowerPoint/LibreOffice
