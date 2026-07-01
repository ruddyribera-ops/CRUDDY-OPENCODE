**Category:** `rosariosis`
**Cross-reference:** `import_student_schedule.php`, `import_student_schedule_q4.php`

---

## [2026-05-10] RosarioSIS config rows — serialized PHP arrays vs plain strings

**Context:** After a SQL update with PHP heredoc escaping, ALL 23 config rows with school_id=0 got corrupted. The problem: RosarioSIS config table stores BOTH serialized PHP arrays AND plain strings, and they look identical in the raw column.

**What happened:** A single SQL UPDATE with improper escaping caused `CONTENT_SECURITY_POLICY`, `THEME`, `TITLE`, `DISPLAY_NAME`, `MODULES`, `PLUGINS`, `VERSION`, etc. ALL to have the same garbage value. After fixing one row, if VERSION was valid serialized string, Update() would see VERSION < ROSARIO_VERSION and try to run UpdateV4_5, which creates school_fields_seq → conflicts with existing school_fields_id_seq → error page.

**Lesson:** In RosarioSIS config table:
- STRING config values (TITLE, THEME, VERSION, NAME, etc.) are stored as **plain strings** — NOT serialized. E.g., `Garden`, `12.8`, `Las Palmas School`.
- ARRAY config values (MODULES, PLUGINS) are stored as **serialized PHP arrays** — E.g., `a:15:{s:6:"School";b:1;...}`.
- Mixing them up causes garbage. Debug: `php -r 'var_dump(unserialize("VALUE"))'` to test validity.
- VERSION must always be stored as plain string `12.8` (not serialized) to prevent Update() from running.
- Debug Config() output in actual app context with `docker exec neurosis_rosariosis php /tmp/debug_version5.php`.
- If `school_fields_id_seq already exists` appears after all other fixes, VERSION is still triggering Update() — set VERSION to plain `12.8` AND create event trigger to block duplicate sequence creation as belt-and-suspenders.

**Category:** `rosariosis`
**Cross-reference:** `D:/Temp/fix_all_config.sql`, `D:/Temp/fix_config_plain.sql`, `D:/Temp/block_seq_creation.sql`