import zipfile
import xml.etree.ElementTree as ET
import os

pdc_dir = r"D:\Temp\opencode\pdc_docs"

ns = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

def find_criteria_in_doc(doc_path):
    tree = ET.parse(doc_path)
    root = tree.getroot()

    # Get all text
    all_text = []
    for t in root.iter(f'{{{ns}}}t'):
        if t.text:
            all_text.append(t.text)

    full_text = ' '.join(all_text)

    # Find all tables
    tables = list(root.iter(f'{{{ns}}}tbl'))
    print(f"  Total tables: {len(tables)}")

    results = []
    for tbl_idx, tbl in enumerate(tables):
        tbl_text = []
        for row in tbl.iter(f'{{{ns}}}tr'):
            row_text = []
            for cell in row.iter(f'{{{ns}}}tc'):
                for t in cell.iter(f'{{{ns}}}t'):
                    if t.text:
                        row_text.append(t.text)
            row_str = ' '.join(row_text)
            if row_str.strip():
                tbl_text.append(row_str[:150])

        results.append((tbl_idx, tbl_text))

    return full_text, results

for doc_name in ['LENGUAJE_UNIDAD 1_2026', 'MATEMATICAS_ Unidad_1_2026',
                  'MATEMATICAS_ Unidad_2_2026', 'MATEMATICAS_ Unidad_3_2026',
                  'Sociales - Unidad 1 _ 2026', 'Trimestre 1']:
    doc_path = os.path.join(pdc_dir, doc_name, 'word', 'document.xml')
    if os.path.exists(doc_path):
        print(f"\n{'='*60}")
        print(f"DOC: {doc_name}")
        print(f"{'='*60}")
        full_text, tables = find_criteria_in_doc(doc_path)

        # Search for criteria/instrumento keywords
        for tbl_idx, rows in tables:
            for row in rows:
                upper = row.upper()
                if any(k in upper for k in ['CRITERIO', 'INSTRUMENTO', 'EVALUACI', 'DIMENSION']):
                    print(f"  Table {tbl_idx}: {row}")