# Excel Workbooks — Complete Code Examples

## Workbook Architecture

```
Workbook
├── active                        # Active sheet
├── create_sheet(name)            # Add new sheet
├── sheetnames                    # List of sheet names
├── ├── cell(row, col)            # Access cell directly
├── ├── cell(row, col).value      # Read/write cell value
├── ├── cell(row, col).number_format  # Format (date, currency, %)
├── ├── cell(row, col).fill       # Background color
├── ├── cell(row, col).font       # Font styling
├── ├── cell(row, col).border     # Border styling
├── ├── cell(row, col).alignment  # Horizontal/vertical alignment
├── ├── column_dimensions[col].width    # Column width
├── ├── row_dimensions[row].height      # Row height
├── ├── merge_cells(start:end)    # Merge range
└── └── freeze_panes              # Freeze rows/cols
```

## Workbook and Sheet Setup

```python
from openpyxl import Workbook
from openpyxl.styles import Font, Alignment, PatternFill, Border, Side
from openpyxl.utils import get_column_letter

def create_workbook(filepath):
    wb = Workbook()
    ws = wb.active; ws.title = "Resultados"
    ws2 = wb.create_sheet("Summary"); ws3 = wb.create_sheet("Statistics")
    ws.sheet_properties.tabColor = "1F497D"; ws2.sheet_properties.tabColor = "2E74B5"
    ws.freeze_panes = "A2"   # Freeze row 1
    wb.save(filepath); return wb
```

## Cell Styling — Font, Fill, Border, Alignment

```python
from openpyxl.styles import Font, Alignment, PatternFill, Border, Side

def style_cell(ws, row, col, value, bold=False, size=11, font_name='Calibri',
               bg_color=None, font_color="000000", h_align='left', v_align='center',
               border_style=None):
    cell = ws.cell(row=row, column=col, value=value)
    cell.font = Font(name=font_name, size=size, bold=bold, color=font_color)
    cell.alignment = Alignment(horizontal=h_align, vertical=v_align, wrap_text=True)
    if bg_color: cell.fill = PatternFill(fill_type='solid', fgColor=bg_color)
    if border_style:
        thin = Side(style='thin', color='AAAAAA')
        cell.border = Border(left=thin, right=thin, top=thin, bottom=thin)
    return cell
```

## Styled Table — Professional Spreadsheet Pattern

```python
from openpyxl import Workbook
from openpyxl.styles import Font, Alignment, PatternFill, Border, Side
from openpyxl.utils import get_column_letter

def create_styled_table(filepath):
    wb = Workbook(); ws = wb.active; ws.title = "Evaluation Rubric"

    header_fill = PatternFill(fill_type='solid', fgColor='1F497D')
    alt_fill_odd = PatternFill(fill_type='solid', fgColor='EBF3FB')
    alt_fill_even = PatternFill(fill_type='solid', fgColor='FFFFFF')
    header_font = Font(name='Calibri', size=11, bold=True, color='FFFFFF')
    body_font = Font(name='Calibri', size=10)
    thin_border = Border(left=Side(style='thin', color='CCCCCC'),
                         right=Side(style='thin', color='CCCCCC'),
                         top=Side(style='thin', color='CCCCCC'),
                         bottom=Side(style='thin', color='CCCCCC'))

    headers = ["Dimension", "Criteria", "Needs Work (1)", "In Progress (2)", "Achieved (3)", "Score"]
    col_widths = [18, 30, 25, 25, 25, 10]

    for col_idx, header in enumerate(headers, start=1):
        cell = ws.cell(row=1, column=col_idx, value=header)
        cell.font = header_font; cell.fill = header_fill
        cell.alignment = Alignment(horizontal='center', vertical='center', wrap_text=True)
        cell.border = thin_border
        ws.column_dimensions[get_column_letter(col_idx)].width = col_widths[col_idx-1]
    ws.row_dimensions[1].height = 30

    data = [
        ["KNOW", "Identifies concepts", "None identified", "Some identified", "All identified", ""],
        ["KNOW", "Recognizes elements", "None", "Some", "All", ""],
        ["DO", "Creates original work", "Copy/paste", "Incomplete", "Complete & original", ""],
        ["BE", "Reflects on process", "No reflection", "Surface reflection", "Deep reflection", ""],
    ]

    for row_idx, row_data in enumerate(data, start=2):
        bg = alt_fill_odd if row_idx % 2 == 0 else alt_fill_even
        for col_idx, value in enumerate(row_data, start=1):
            cell = ws.cell(row=row_idx, column=col_idx, value=value)
            cell.font = body_font; cell.border = thin_border
            cell.alignment = Alignment(vertical='top', wrap_text=True)
            if col_idx == 1:
                cell.fill = PatternFill(fill_type='solid', fgColor='1F497D')
                cell.font = Font(name='Calibri', size=10, bold=True, color='FFFFFF')
                cell.alignment = Alignment(horizontal='center', vertical='center')
            elif col_idx in (3, 4, 5):
                level_fills = {1: 'FFF2CC', 2: 'DEEAF1', 3: 'E2EFDA'}
                cell.fill = PatternFill(fill_type='solid', fgColor=level_fills[col_idx-2])
            else:
                cell.fill = bg

    wb.save(filepath); return wb
```

## Conditional Formatting — Traffic Light

```python
from openpyxl import Workbook
from openpyxl.formatting.rule import ColorScaleRule, CellIsRule, FormulaRule
from openpyxl.styles import PatternFill

def add_conditional_formatting(ws):
    color_scale = ColorScaleRule(
        start_type='num', start_value=1, start_color='F8696B',
        mid_type='num',   mid_value=2,   mid_color='FDC868',
        end_type='num',   end_value=3,   end_color='63BE7B'
    )
    ws.conditional_formatting.add('F2:F100', color_scale)
    return ws
```

## Data Validation — Dropdowns

```python
from openpyxl import Workbook
from openpyxl.worksheet.datavalidation import DataValidation

def add_input_validation(ws):
    dv_dimension = DataValidation(type="list", formula1='"KNOW,DO,BE/DECIDE"', allow_blank=True)
    dv_dimension.error = "Select from KNOW, DO, or BE/DECIDE"
    dv_dimension.errorTitle = "Invalid value"
    ws.add_data_validation(dv_dimension); dv_dimension.add('A2:A100')

    dv_status = DataValidation(type="list", formula1='"✅ Achieved,🔄 In Progress,⚠️ Needs Work"', allow_blank=True)
    ws.add_data_validation(dv_status); dv_status.add('D2:D100')
    return ws
```

## Charts — Bar and Pie

```python
from openpyxl import Workbook
from openpyxl.chart import BarChart, PieChart, Reference
from openpyxl.chart.label import DataLabelList

def add_chart(ws):
    chart = BarChart(); chart.type = "col"
    chart.title = "Results by Dimension"; chart.y_axis.title = "Average Score"
    chart.x_axis.title = "Dimension"
    data = Reference(ws, min_col=6, min_row=1, max_row=ws.max_row)
    cats = Reference(ws, min_col=1, min_row=2, max_row=ws.max_row)
    chart.add_data(data, titles_from_data=True); chart.set_categories(cats)
    chart.shape = 4; chart.width = 15; chart.height = 10
    ws.add_chart(chart, "H2"); return ws
```
