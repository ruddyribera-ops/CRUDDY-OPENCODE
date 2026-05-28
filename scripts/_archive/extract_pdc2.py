import xml.etree.ElementTree as ET
import os

pdc_dir = r"D:\Temp\opencode\pdc_docs"
ns = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

def get_full_table_content(doc_path):
    tree = ET.parse(doc_path)
    root = tree.getroot()

    tables = list(root.iter(f'{{{ns}}}tbl'))
    all_content = []

    for tbl_idx, tbl in enumerate(tables):
        tbl_data = []
        for row in tbl.iter(f'{{{ns}}}tr'):
            row_data = []
            for cell in row.iter(f'{{{ns}}}tc'):
                cell_text = []
                for t in cell.iter(f'{{{ns}}}t'):
                    if t.text:
                        cell_text.append(t.text)
                row_data.append(' '.join(cell_text))
            tbl_data.append(' | '.join(row_data))

        all_content.append(tbl_data)

    return all_content

for doc_name in ['LENGUAJE_UNIDAD 1_2026', 'MATEMATICAS_ Unidad_1_2026',
                  'MATEMATICAS_ Unidad_2_2026', 'MATEMATICAS_ Unidad_3_2026',
                  'Sociales - Unidad 1 _ 2026', 'Trimestre 1']:
    doc_path = os.path.join(pdc_dir, doc_name, 'word', 'document.xml')
    if os.path.exists(doc_path):
        print(f"\n{'='*60}")
        print(f"DOC: {doc_name}")
        print(f"{'='*60}")
        tables = get_full_table_content(doc_path)
        for tbl_idx, rows in enumerate(tables):
            print(f"\nTable {tbl_idx}:")
            for row in rows:
                if row.strip():
                    print(f"  {row}")