# Detailed Reference

## XML Manipulation Patterns

### Common Edit Targets
| Edit Goal | XML Path | Element |
|-----------|----------|---------|
| Replace slide text | `p:sld / p:cSld / p:spTree / p:sp / p:txBody / a:p / a:r / a:t` | `<a:t>old text</a:t>` |
| Change font | `a:rPr` inside run | `sz="2400"` (12pt × 100), `typeface="Arial"` |
| Change fill color | `a:solidFill / a:srgbClr` | `val="4A90D9"` |
| Change shape size | `a:xfrm / a:off` + `a:ext` | `cx="9144000"` (10" in EMU) |
| Add/replace image | `p:pic / p:blipFill / a:blip` | `r:embed="rId2"` (points to rels) |
| Edit chart data | `c:chart / c:plotArea / c:ser / c:val` | `<c:numRef><c:numCache><c:pt>` |

### EMU Unit Conversion
- 1 inch = 914400 EMU
- 1 cm = 360000 EMU
- 1 point = 12700 EMU
- PptxGenJS abstracts EMU; raw XML requires `cx="..."` in EMU

### Slide Relationships Pattern
```
slide1.xml.rels → links to:
  - layout (rId1)
  - image assets (rId2, rId3...)
  - chart data (rId4)
  - hyperlinks (rId5...)
```
When adding images, always add both the media file AND a relationship entry.

## Smart Quotes Reference

Handled automatically by unpack/pack, but the Edit tool converts smart quotes to ASCII.

**When adding new text with quotes, use XML entities:**
```xml
<a:t>the &#x201C;Agreement&#x201D;</a:t>
```

| Character | Name | Unicode | XML Entity |
|-----------|------|---------|------------|
| `"` | Left double quote | U+201C | `&#x201C;` |
| `"` | Right double quote | U+201D | `&#x201D;` |
| `'` | Left single quote | U+2018 | `&#x2018;` |
| `'` | Right single quote | U+2019 | `&#x2019;` |

## Multi-Item Content Pattern

If source has multiple items (numbered lists, multiple sections), create separate `<a:p>` elements for each — **never concatenate:**

**❌ WRONG** — all items in one paragraph:
```xml
<a:p>
  <a:r><a:rPr .../><a:t>Step 1: Do the first thing. Step 2: Do the second thing.</a:t></a:r>
</a:p>
```

**✅ CORRECT** — separate paragraphs with bold headers:
```xml
<a:p>
  <a:pPr algn="l"><a:lnSpc><a:spcPts val="3919"/></a:lnSpc></a:pPr>
  <a:r><a:rPr lang="en-US" sz="2799" b="1" .../><a:t>Step 1</a:t></a:r>
</a:p>
<a:p>
  <a:pPr algn="l"><a:lnSpc><a:spcPts val="3919"/></a:lnSpc></a:pPr>
  <a:r><a:rPr lang="en-US" sz="2799" .../><a:t>Do the first thing.</a:t></a:r>
</a:p>
```
Copy `<a:pPr>` from the original paragraph to preserve line spacing. Use `b="1"` on headers.

## Additional Rules
- **Whitespace**: Use `xml:space="preserve"` on `<a:t>` with leading/trailing spaces
- **XML parsing**: Use `defusedxml.minidom`, not `xml.etree.ElementTree` (corrupts namespaces)
- **Bold headers**: Use `b="1"` on `<a:rPr>` for slide titles, section headers, inline labels
- **Never use unicode bullets (•)**: Use proper list formatting with `<a:buChar>` or `<a:buAutoNum>`
- **Bullet consistency**: Let bullets inherit from layout; only specify `<a:buChar>` or `<a:buNone>`
