# Data Analysis — Code Patterns

## CSV Parsing (Python — pandas)
```python
import pandas as pd
df = pd.read_csv("data.csv")
print(df.shape, df.dtypes, df.describe(), df.head(10))
print(df.isnull().sum())
active = df[df["status"] == "active"]
summary = df.groupby("category").agg(count=("id","count"), total=("amount","sum"), avg=("amount","mean")).reset_index()
top_10 = df.nlargest(10, "revenue")
```

## CSV Parsing (Node.js)
```javascript
import { createReadStream } from 'fs';
import { parse } from 'csv-parse';
async function parseCSV(filepath) {
  const records = [];
  const parser = createReadStream(filepath).pipe(parse({ columns: true, skip_empty_lines: true }));
  for await (const record of parser) records.push(record);
  return records;
}
```

## JSON Data Manipulation
```python
import json
with open("data.json") as f: data = json.load(f)
df = pd.json_normalize(data, record_path="items", meta=["order_id", "date"])
```

## Data Validation
```python
def validate_dataframe(df: pd.DataFrame, required_cols: list[str]) -> list[str]:
    issues = []
    missing = set(required_cols) - set(df.columns)
    if missing: issues.append(f"Missing columns: {missing}")
    if df.empty: issues.append("DataFrame is empty")
    dupes = df.duplicated().sum()
    if dupes > 0: issues.append(f"Found {dupes} duplicate rows")
    for col in required_cols:
        if col in df.columns:
            nulls = df[col].isnull().sum()
            if nulls > 0: issues.append(f"Column '{col}' has {nulls} null values")
    return issues
```

## Data Cleaning
```python
df = df.drop_duplicates(subset=["email"], keep="last")
df["category"] = df["category"].fillna("Unknown")
df["amount"] = df["amount"].fillna(0)
df["date"] = pd.to_datetime(df["date"], errors="coerce")
df["amount"] = pd.to_numeric(df["amount"], errors="coerce")
str_cols = df.select_dtypes(include="object").columns
df[str_cols] = df[str_cols].apply(lambda x: x.str.strip())
df.columns = df.columns.str.lower().str.replace(" ", "_").str.replace("-", "_")
```

## Export Patterns
```python
df.to_csv("output.csv", index=False)
df.to_json("output.json", orient="records", indent=2)
df.to_excel("output.xlsx", index=False, sheet_name="Data")
print(df.to_markdown(index=False))  # Markdown table
```

## Quick Analysis Checklist
1. Load → check shape/dtypes
2. Inspect → head(), describe(), isnull().sum()
3. Clean → nulls, dupes, type conversion, strip whitespace
4. Validate → required columns, data quality
5. Analyze → group, aggregate, filter
6. Report → generate summary with key findings
7. Export → save in requested format

## Reporting Template
```python
def generate_summary(df: pd.DataFrame, title: str) -> str:
    report = f"# {title}\n\n**Total Records:** {len(df):,}\n**Date Range:** {df['date'].min()} to {df['date'].max()}\n\n"
    report += "## By Category\n\n| Category | Count | Total | Average |\n|---|---|---|---|\n"
    summary = df.groupby("category").agg(count=("id","count"), total=("amount","sum"), avg=("amount","mean"))
    for cat, row in summary.iterrows():
        report += f"| {cat} | {row['count']:,} | ${row['total']:,.2f} | ${row['avg']:,.2f} |\n"
    return report
```

## Ecosystem
- **Engines:** pandas, polars (10-100x faster), ibis, modin, datatable
- **Visualization:** matplotlib, seaborn, plotly, bokeh, altair, streamlit, gradio
- **ETL:** dlt, pathway, apache-airflow, bonobo
- **Validation:** pandera, great-expectations, pydantic
- **Scientific:** numpy, scipy, sympy, numba, statsmodels
