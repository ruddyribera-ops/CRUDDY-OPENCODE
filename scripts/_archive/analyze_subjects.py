import pandas as pd
import os

path2025 = r"D:\Temp\opencode\reg2025\REGISTROS PEDAGÓGICOS 2025\NIVEL PRIMARIO\1ER TRIMESTRE"
f2025 = [f for f in os.listdir(path2025) if '4' in f and 'PRIMARIA' in f][0]
full2025 = os.path.join(path2025, f2025)

sheets = ['MATEM�TICAS', 'LENGUAJE', 'SOCIALES', 'VALORES', 'TECNOLOG�A']

for sheet in sheets:
    try:
        df = pd.read_excel(full2025, sheet_name=sheet, header=None)
        print(f"\n{'='*60}")
        print(f"SHEET: {sheet}")
        print(f"Shape: {df.shape}")
        # Show rows 0-9 (header area)
        print("\nRows 0-9 (all cols):")
        print(df.iloc[:10, :].to_string())
    except Exception as e:
        print(f"\nSHEET: {sheet} ERROR: {e}")