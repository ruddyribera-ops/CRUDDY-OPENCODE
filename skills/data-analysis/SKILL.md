---
name: data-analysis
description: Data analysis patterns — pandas, CSV/JSON/Excel processing, ETL pipelines, data validation, and reporting. Covers file parsing, cleaning, transformation, and export.
triggers: data, csv, json, excel, pandas, analysis, etl, parsing, dataframe
auto_load: code-builder
---

# Data Analysis Patterns

## File Parsing
- CSV: use `pandas.read_csv()` with `dtype` specified (never infer)
- JSON: use `pandas.json_normalize()` for nested structures
- Excel: use `pandas.read_excel()` or `openpyxl` for cell-level access

## Data Cleaning
- Handle missing values explicitly — never `dropna()` without understanding why
- Validate data types after import (especially dates and numbers)
- Log row count before and after each transformation

## ETL Pattern
1. **Extract**: read source file with schema validation
2. **Transform**: one transformation per step, log each
3. **Load**: write with idempotency (ON CONFLICT DO NOTHING)

## Validation
- Expected columns match? If not, log warning or fail
- Required fields non-null? If not, flag rows
- Data range sanity checks (dates in future? negative prices?)

## Export
- Always UTF-8 encoding (not Latin-1/Windows-1252 unless specified)
- CSV: `index=False` by default
- Excel: use `ExcelWriter` with `openpyxl` engine
