import pandas as pd
import os

path2025 = r"D:\Temp\opencode\reg2025\REGISTROS PEDAGÓGICOS 2025\NIVEL PRIMARIO\1ER TRIMESTRE"
f2025 = [f for f in os.listdir(path2025) if '4' in f and 'PRIMARIA' in f][0]
full2025 = os.path.join(path2025, f2025)

for subj in ['LENGUAJE', 'MATEMÁTICAS', 'SOCIALES', 'VALORES', 'TECNOLOGÍA']:
    df = pd.read_excel(full2025, sheet_name=subj, header=None)
    print(f"\n{'='*50}")
    print(f"SUBJECT: {subj}, Shape: {df.shape}")
    print(f"Row 5 (dimension headers):")
    row5 = df.iloc[5]
    for j, v in enumerate(row5):
        if pd.notna(v):
            print(f"  Col {j} ({chr(65+j) if j < 26 else chr(64+j//26)+chr(65+j%26)}): {v}")

    # Show student row 10 data
    print(f"\nStudent row 10 data:")
    row10 = df.iloc[10]
    data_cols = {}
    for j, v in enumerate(row10):
        if pd.notna(v) and isinstance(v, (int, float)):
            data_cols[j] = v
    print(f"  {data_cols}")