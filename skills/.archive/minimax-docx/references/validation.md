# Validation Pipeline

Run after every write operation. For Scenario C the full pipeline is **mandatory**; for A/B it is **recommended**.

```bash
$CLI merge-runs --input doc.docx                                    # 1. consolidate runs
$CLI validate --input doc.docx --xsd assets/xsd/wml-subset.xsd     # 2. XSD structure
$CLI validate --input doc.docx --business                           # 3. business rules
```

### If XSD Fails
```bash
$CLI fix-order --input doc.docx
$CLI validate --input doc.docx --xsd assets/xsd/wml-subset.xsd
```

### If XSD Still Fails (Fallback)
```bash
$CLI validate --input doc.docx --business
scripts/docx_preview.sh doc.docx
# Verify: font contamination=0, table count correct, drawing count correct, sectPr count correct
```

### Hard Gate-Check (Scenario C)
```bash
$CLI validate --input out.docx --gate-check assets/xsd/business-rules.xsd
```
Gate-check is a **hard requirement**. Do NOT deliver until it passes.

### Diff Verification
```bash
$CLI diff --before source.docx --after out.docx
```

### Final Preview
```bash
scripts/docx_preview.sh doc.docx
```
