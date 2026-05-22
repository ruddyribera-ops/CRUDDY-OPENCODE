# CLI Commands Reference

All CLI commands use `$CLI` as shorthand for:
```bash
dotnet run --project scripts/dotnet/MiniMaxAIDocx.Cli --
```

## Quick Start: Direct C# Path

For structural document manipulation (custom styles, complex tables, multi-section layouts, headers/footers, TOC, images):

```csharp
// File: scripts/dotnet/task.csx (or a new .cs in a Console project)
#r "nuget: DocumentFormat.OpenXml, 3.2.0"

using DocumentFormat.OpenXml;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Wordprocessing;

using var doc = WordprocessingDocument.Create("output.docx", WordprocessingDocumentType.Document);
var mainPart = doc.AddMainDocumentPart();
mainPart.Document = new Document(new Body());

// Read the relevant Samples/*.cs file FIRST for tested patterns.
```

### CLI Options for Create
`--type` (report|letter|memo|academic), `--title`, `--author`, `--page-size` (letter|a4|legal|a3), `--margins` (standard|narrow|wide), `--header`, `--footer`, `--page-numbers`, `--toc`, `--content-json`.

### CLI Edit Subcommands
- `replace-text --find "X" --replace "Y"`
- `fill-placeholders --data '{"key":"value"}'`
- `fill-table --data table.json`
- `insert-section`, `remove-section`, `update-header-footer`

```bash
$CLI edit replace-text --input in.docx --output out.docx --find "OLD" --replace "NEW"
$CLI edit fill-placeholders --input in.docx --output out.docx --data '{"name":"John"}'
```

### Pre-processing
```bash
# Convert .doc → .docx
scripts/doc_to_docx.sh input.doc output_dir/

# Preview document structure
scripts/docx_preview.sh document.docx

# Analyze structure
$CLI analyze --input document.docx
```
