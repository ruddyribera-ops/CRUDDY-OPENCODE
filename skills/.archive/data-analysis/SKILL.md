---
name: data-analysis
description: Data analysis patterns for CSV, JSON, pandas, and reporting
tags: [data, analysis, pandas, csv, python]
tags: [data-analysis, pandas, csv, json, reporting, python, dataframe]
---

## When to Use
- Parsing and cleaning CSV, JSON, or Excel data with pandas
- Generating statistical summaries and data quality reports
- Performing exploratory data analysis (EDA) on tabular datasets
- Transforming and reshaping data for visualization or export

## Do Not Use
- Real-time streaming (use realtime-patterns)
- ML model training (use cs-fundamentals)
- Database ETL (use database-patterns)
- Excel file generation with formatting (use msoffice-tools)

# Data Analysis Patterns

## Quick Analysis Flow
1. **Load** → read file, check shape/dtypes
2. **Inspect** → head(), describe(), isnull().sum()
3. **Clean** → nulls, dupes, type conversion, strip whitespace
4. **Validate** → required columns, data quality
5. **Analyze** → group, aggregate, filter
6. **Report** → generate summary
7. **Export** → save in requested format

## Core Patterns (with code)
→ See `references/code-patterns.md` for complete code:

| Pattern | Python | Node.js |
|---------|--------|---------|
| CSV parsing | `pd.read_csv()` | csv-parse |
| JSON handling | `json.load()` + `pd.json_normalize()` | JSON.parse + reduce |
| Data cleaning | drop_duplicates, fillna, to_datetime, strip | — |
| Validation | validate_dataframe() function | — |
| Group & aggregate | `df.groupby().agg()` | reduce + map |
| Export | `df.to_csv/json/excel/markdown()` | — |

## Quick Reference (Python)
```python
import pandas as pd
df = pd.read_csv("data.csv")
print(df.shape, df.dtypes, df.describe())
print(df.isnull().sum())
df = df.drop_duplicates(); df = df.fillna({"col": "Unknown"})
df["date"] = pd.to_datetime(df["date"])
summary = df.groupby("category").agg(count=("id","count"), total=("amount","sum")).reset_index()
```

## Ecosystem
→ See `references/code-patterns.md` for full library catalog:
- **Engines:** pandas, polars (10-100x faster), ibis, modin, datatable
- **Visualization:** matplotlib, seaborn, plotly, bokeh, altair
- **ETL:** dlt, pathway, apache-airflow
- **Validation:** pandera, great-expectations, pydantic
- **Scientific:** numpy, scipy, sympy, numba, statsmodels

## Verification
- [ ] Data loads without errors (correct file format and encoding)
- [ ] Shape and dtypes verified
- [ ] Missing values identified and handled
- [ ] Duplicates removed or flagged
- [ ] Types converted correctly (dates, numbers)
- [ ] Summary statistics generated
- [ ] Output file(s) written successfully
- [ ] All reference links resolve
