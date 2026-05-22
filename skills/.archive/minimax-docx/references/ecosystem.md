# DOCX Ecosystem

## Libraries by Language
| Language | Library | Best For |
|----------|---------|----------|
| JavaScript | `docx` (npm) | Creating DOCX from JS, templates, tables, images |
| Python | `python-docx` | Reading/writing .docx with paragraph/table/run API |
| Python | `markitdown` | Text extraction from DOCX (Microsoft maintained) |
| .NET/C# | OpenXML SDK | Full control over OPC/XML, headers/footers, sections |
| .NET/C# | `DocX` | Higher-level DOCX API for .NET |

## Open XML Fundamentals
- DOCX is a ZIP file containing OPC (Open Packaging Convention) package
- Core XML files: `word/document.xml`, `word/styles.xml`, `word/header1.xml`, `word/footer1.xml`
- Relationships: `word/_rels/document.xml.rels` maps IDs to files
- Content Types: `[Content_Types].xml` registers every file

## Template Merge Patterns
| Pattern | Approach | When to Use |
|---------|----------|-------------|
| **Content Replacement** | Find `<w:t>` text placeholders in source, replace | Simple text swap, same structure |
| **Style Overlay** | Copy source body into template's `document.xml` | Keep template headers/footers/styles |
| **Section Merge** | Concatenate `<w:body>` content + preserve `sectPr` | Multi-source documents |
| **Multi-Template** | Merge styles.xml from all sources, content from one | Format + structure from separate files |
| **Mail Merge** | Generate multiple copies with per-copy field values | Batch documents (certificates, letters) |

## Pitfalls to Avoid
- Never modify a DOCX as raw ZIP without updating `[Content_Types].xml` and `.rels` files
- Never use string replace on XML with split runs (`<w:t>` fragments from tracked changes)
- Always merge `<w:r>` runs before extracting text
- Font size in OpenXML is half-points: 12pt = `sz="24"`, 14pt = `sz="28"`
- Margins in DXA: 1 inch = 1440 DXA, 1 cm ≈ 567 DXA
