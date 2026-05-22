# Cross-Document Workflows

## Word → PDF (via LibreOffice — headless)
```bash
soffice --headless --convert-to pdf --outdir output/ document.docx
```

## Word → PDF (via python-docx + docx2pdf)
```bash
pip install docx2pdf
python -c "from docx2pdf import convert; convert('document.docx', 'output/')"
```

## Excel → PDF (via LibreOffice)
```bash
soffice --headless --convert-to pdf --outdir output/ spreadsheet.xlsx
```

## pandoc — Swiss-army knife converter
```bash
# Markdown → Word
pandoc input.md -o output.docx
# Markdown → formatted Word with reference template
pandoc input.md --reference-doc=template.docx -o output.docx
# Word → Markdown (extract text)
pandoc input.docx -o output.md
# Markdown → PDF (via LaTeX)
pandoc input.md -o output.pdf
# Markdown → PowerPoint
pandoc input.md -o output.pptx
```

## Markdown → Styled Word via docx template

```python
import subprocess

def markdown_to_word(md_file, docx_file, ref_doc=None):
    cmd = ["pandoc", md_file, "-o", docx_file,
           "--reference-doc", ref_doc if ref_doc else "default",
           "--metadata", "title=Document Title"]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"pandoc error: {result.stderr}")
    return docx_file
```
