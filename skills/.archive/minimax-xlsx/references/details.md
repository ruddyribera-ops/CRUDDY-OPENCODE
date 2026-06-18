# Detailed XLSX Reference

## Utility Scripts (Full CLI Reference)

```bash
python3 SKILL_DIR/scripts/xlsx_reader.py input.xlsx                 # structure discovery
python3 SKILL_DIR/scripts/formula_check.py file.xlsx --json         # formula validation
python3 SKILL_DIR/scripts/formula_check.py file.xlsx --report       # standardized report
python3 SKILL_DIR/scripts/xlsx_unpack.py in.xlsx /tmp/work/         # unpack for XML editing
python3 SKILL_DIR/scripts/xlsx_pack.py /tmp/work/ out.xlsx          # repack after editing
python3 SKILL_DIR/scripts/xlsx_shift_rows.py /tmp/work/ insert 5 1  # shift rows for insertion
python3 SKILL_DIR/scripts/xlsx_add_column.py /tmp/work/ --col G ... # add column with formulas
python3 SKILL_DIR/scripts/xlsx_insert_row.py /tmp/work/ --at 6 ...  # insert row with data
```

## EDIT: Add Column (Full Example)

```bash
python3 SKILL_DIR/scripts/xlsx_unpack.py input.xlsx /tmp/xlsx_work/
python3 SKILL_DIR/scripts/xlsx_add_column.py /tmp/xlsx_work/ --col G \
    --sheet "Sheet1" --header "% of Total" \
    --formula '=F{row}/$F$10' --formula-rows 2:9 \
    --total-row 10 --total-formula '=SUM(G2:G9)' --numfmt '0.0%' \
    --border-row 10 --border-style medium
python3 SKILL_DIR/scripts/xlsx_pack.py /tmp/xlsx_work/ output.xlsx
```

The `--border-row` flag applies a top border to ALL cells in that row (not just the new column).

## EDIT: Insert Row (Full Example)

```bash
python3 SKILL_DIR/scripts/xlsx_unpack.py input.xlsx /tmp/xlsx_work/
# Find the correct --at row by searching for the label text in worksheet XML
python3 SKILL_DIR/scripts/xlsx_insert_row.py /tmp/xlsx_work/ --at 5 \
    --sheet "Budget FY2025" --text A=Utilities \
    --values B=3000 C=3000 D=3500 E=3500 \
    --formula 'F=SUM(B{row}:E{row})' --copy-style-from 4
python3 SKILL_DIR/scripts/xlsx_pack.py /tmp/xlsx_work/ output.xlsx
```

**Row lookup rule**: Always find the row by searching for the label text in the worksheet XML. Use the actual row number + 1 for `--at`.

## EDIT: Apply Row-Wide Borders

After running helper scripts, apply borders to ALL cells in the target row:

```xml
<!-- In xl/styles.xml, append to <borders>: -->
<border>
  <left/><right/><top style="medium"/><bottom/><diagonal/>
</border>
```

## EDIT: Manual XML Edit

For anything the helper scripts don't cover:
```bash
python3 SKILL_DIR/scripts/xlsx_unpack.py input.xlsx /tmp/xlsx_work/
# ... edit XML with the Edit tool ...
python3 SKILL_DIR/scripts/xlsx_pack.py /tmp/xlsx_work/ output.xlsx
```

## XLSX Ecosystem

### Libraries by Language
| Language | Library | Best For |
|----------|---------|----------|
| JavaScript | **ExcelJS** | Read/write XLSX with styling, formulas, streaming |
| JavaScript | **SheetJS** (xlsx) | Ultra-fast parsing, CSV/XLSB support |
| Python | **openpyxl** | Full read/write with styles, charts, conditional formatting |
| Python | **xlsxwriter** | Write-only, best for large files |
| Python | **pylightxl** | Lightweight, no dependency |
| .NET | **EPPlus** | Full Excel support with pivot tables, charts |
| .NET | **ClosedXML** | Simplified OpenXML wrapper |

### Formula Patterns
| Pattern | Formula | Example |
|---------|---------|---------|
| Column sum | `SUM(start:end)` | `=SUM(B2:B10)` |
| Conditional sum | `SUMIF(range, criteria)` | `=SUMIF(A:A,">=100",B:B)` |
| Cross-sheet sum | `SUM('Sheet'!range)` | `=SUM('Sales Data'!D2:D13)` |
| Lookup | `VLOOKUP(val, table, col, false)` | `=VLOOKUP(A2,$F$2:$G$100,2,FALSE)` |
| XLOOKUP | `XLOOKUP(val, lookup, return)` | `=XLOOKUP(A2,F:F,G:G)` |
| Running total | `SUM($start:current)` | `=SUM($B$2:B2)` |
| Percentage | `part/total` | `=F2/$F$10` |
| Conditional | `IF(condition, iftrue, iffalse)` | `=IF(A2>=B2,"On Time","Late")` |
| Date diff | `DATEDIF(start, end, unit)` | `=DATEDIF(A2,B2,"d")` |
| Index-Match | `INDEX(col, MATCH(val, col, 0))` | `=INDEX(C:C, MATCH(E2, A:A, 0))` |

### Financial Formatting Standards
| Format Code | Meaning | Example |
|-------------|---------|---------|
| `#,##0` | Number with comma separator | `12,845` |
| `#,##0.00` | 2 decimal places | `12,845.00` |
| `$#,##0.00` | US dollar | `$12,845.00` |
| `0.0%` | Percentage, 1 decimal | `15.3%` |
| `#,##0.00;(#,##0.00)` | Negative in red parens | `(12,845.00)` |
| `MM/DD/YYYY` | Date | `05/11/2026` |

### Financial Color Convention
- **Blue (0000FF)**: Hard-coded input, assumption, driver cell
- **Black (000000)**: Formula output, computed value
- **Green (00B050)**: Cross-sheet reference formula
- **Red (FF0000)**: Negative value / variance (optional)
