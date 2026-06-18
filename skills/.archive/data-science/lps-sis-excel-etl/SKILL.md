---
name: lps-sis-excel-etl
description: Robust workflow to migrate messy school Excel exports into normalized SIS staging tables with dynamic header detection, data quality checks, and dry-run reconciliation.
tags: [data, etl, excel, education, sis]
---

# LPS SIS Excel ETL

## When to Use
Use this skill when a school dataset is spread across many Excel files and contains:
- shifted headers (example: headers start on row 2, not row 1),
- mixed column names (example: `CORREO` vs `CORREO DE PADRES`),
- multi-value cells (`email1/email2`, `id1--id2`),
- summary rows mixed with student rows,
- attendance files by class and month.

Use this for staging and validation before loading into PostgreSQL SIS tables.

Also use it when timetable and trimester gradebooks must be extracted from visual sheets with mixed structures.

## Procedure
1. Create a migration workspace inside the school dataset root:
   - `SIS_MIGRATION_WORKBENCH/docs`
   - `SIS_MIGRATION_WORKBENCH/sql`
   - `SIS_MIGRATION_WORKBENCH/scripts`
   - `SIS_MIGRATION_WORKBENCH/staging`
   - `SIS_MIGRATION_WORKBENCH/outputs`

2. Build a dynamic parser script for student workbook extraction.
   - Detect header row by searching labels like `EMAIL` + `APELLIDO` within first 30 rows.
   - Map aliases for each canonical field.
   - Reject non-student summary rows.

3. Normalize key fields into staging outputs.
   - `students_staging_v1.csv`
   - `student_guardians_staging_v1.csv`
   - `student_reference_ids_staging_v1.csv`
   - `enrollments_staging_v1.csv`
   - `rejects_students_v1.csv`

4. Run dry-run relational checks.
   - Verify no duplicate student institutional emails.
   - Verify guardians/references/enrollments only point to known student emails.
   - Derive class keys from enrollments into `classes_staging_v1.csv`.

5. Generate reconciliation reports.
   - `outputs/etl_students_summary_v1.txt`
   - `outputs/etl_students_summary_v1.json`
   - `outputs/dry_run_checks_v1.txt`
   - `outputs/dry_run_checks_v1.json`

6. Review counts before DB load.
   - Student count, guardian count, reference count, reject count.
   - Per-sheet acceptance/rejection stats.

7. Parse timetable workbook into class-slot staging.
   - Run `etl_timetable_v1.py` against `HORARIOS OFICIALES Y CARGAS HORARIAS 2026.xlsx`.
   - Detect day headers dynamically (`LUNES..VIERNES`) and time ranges from left columns.
   - Derive `grade_code` from either class header (`2P-2026`, `NIDITO - 2026`) or subject suffix (`TECNOLOGIA 2S`).
   - Write:
     - `staging/timetable_slots_staging_v1.csv`
     - `staging/rejects_timetable_v1.csv`
     - `outputs/etl_timetable_summary_v1.txt|json`

8. Parse trimester gradebooks and reconcile student linkage.
   - Run `etl_grades_v1.py` over all pedagogical workbook files.
   - Use dynamic summary-sheet detection (`1ER TRIM`, `1T`) and dynamic header detection.
   - Write:
     - `staging/gradebook_summary_staging_v1.csv`
     - `staging/rejects_grades_v1.csv`
     - `outputs/etl_grades_summary_v1.txt|json`
   - Run `reconcile_grade_student_links_v1.py` to map unresolved names to institutional emails.
   - Write:
     - `staging/gradebook_summary_staging_v1_linked.csv`
     - `staging/grade_student_link_suggestions_v1.csv`
     - `staging/grade_student_unresolved_candidates_v1.csv`
     - `outputs/reconcile_grade_student_links_v1.txt|json`

9. Run integrated v2 dry-run checks.
   - Execute `dry_run_checks_v2.py`.
   - Validate class coverage across students/classes/timetable/gradebook.
   - Confirm gradebook email linkage ratio and unresolved sample list.

## Pitfalls
- Header drift in one sheet can silently drop data.
  - Workaround: detect header row dynamically, never assume row 1 headers.

- Mixed parent email columns (`CORREO`, `CORREO DE PADRES`).
  - Workaround: fallback logic and normalization to lowercase.

- Multi-value IDs/emails in single cell.
  - Workaround: split using `/`, `,`, `;`, `--` and store as one-value-per-row in child tables.

- Timetable sheets are visual grids, not strict tables.
  - Workaround: parse with dedicated adapters or manual QA-assisted extraction.

- Gradebook student names may contain typos or accent/spacing drift.
  - Workaround: run deterministic name reconciliation and keep unresolved candidates in a separate review file.

- Inicial gradebooks can be missing numeric trimester summaries.
  - Workaround: treat as expected data gap and flag in dry-run status, not as hard ETL failure.

## Verification
Run the ETL script:

```powershell
python "<INSTALL_DIR>/LasPalmasSchoolBD2026\SIS_MIGRATION_WORKBENCH\scripts\etl_students_v1.py"
```

Run dry-run checks:

```powershell
python "<INSTALL_DIR>/LasPalmasSchoolBD2026\SIS_MIGRATION_WORKBENCH\scripts\dry_run_checks_v1.py"
```

Run timetable + grades + reconciliation:

```powershell
python "<INSTALL_DIR>/LasPalmasSchoolBD2026\SIS_MIGRATION_WORKBENCH\scripts\etl_timetable_v1.py"
python "<INSTALL_DIR>/LasPalmasSchoolBD2026\SIS_MIGRATION_WORKBENCH\scripts\etl_grades_v1.py"
python "<INSTALL_DIR>/LasPalmasSchoolBD2026\SIS_MIGRATION_WORKBENCH\scripts\reconcile_grade_student_links_v1.py"
python "<INSTALL_DIR>/LasPalmasSchoolBD2026\SIS_MIGRATION_WORKBENCH\scripts\dry_run_checks_v2.py"
```

Expected success signals:
- `outputs/etl_students_summary_v1.txt` exists and includes per-sheet stats.
- `outputs/dry_run_checks_v1.txt` exists and shows:
  - `students_duplicate_email_rows: 0`
  - `guardians_orphan_rows: 0`
  - `references_orphan_rows: 0`
  - `enrollments_orphan_rows: 0`

- `outputs/etl_timetable_summary_v1.txt` shows all grade codes detected (`ND, PK, K, 1P..6P, 1S..5S`).
- `outputs/reconcile_grade_student_links_v1.txt` shows linkage ratio near 1.0 and low unresolved count.
- `outputs/dry_run_checks_v2.txt` reports timetable coverage with empty `timetable_missing_grade_codes`.

## Reference Commands
```powershell
python "<INSTALL_DIR>/LasPalmasSchoolBD2026\SIS_MIGRATION_WORKBENCH\scripts\etl_students_v1.py"
python "<INSTALL_DIR>/LasPalmasSchoolBD2026\SIS_MIGRATION_WORKBENCH\scripts\dry_run_checks_v1.py"
python "<INSTALL_DIR>/LasPalmasSchoolBD2026\SIS_MIGRATION_WORKBENCH\scripts\etl_timetable_v1.py"
python "<INSTALL_DIR>/LasPalmasSchoolBD2026\SIS_MIGRATION_WORKBENCH\scripts\etl_grades_v1.py"
python "<INSTALL_DIR>/LasPalmasSchoolBD2026\SIS_MIGRATION_WORKBENCH\scripts\reconcile_grade_student_links_v1.py"
python "<INSTALL_DIR>/LasPalmasSchoolBD2026\SIS_MIGRATION_WORKBENCH\scripts\dry_run_checks_v2.py"
```
## Do Not Use
- General Excel file creation (use minimax-xlsx)
- Data analysis or reporting (use data-analysis)
- Database schema design (use database-patterns)
- General ETL pipeline design
