---
name: rosariosis-codebase-inspection
description: Complete RosarioSIS codebase inspection POA — maps file structure, session vars, DB schema, CSS architecture, module registration, and template rendering before implementing new features
tags: [research, php, sis, education]
---

# RosarioSIS Codebase Inspection POA

## When to Use

- Before implementing a **new UI feature** (sidebar, topbar, dashboard)
- When you need to understand the **full rendering pipeline** (Warehouse.php → Side.php → Modules.php)
- Before refactoring `Side.php` (949 lines of mixed HTML/PHP/JS)
- When you need to know **exactly which session variables, DB functions, and queries** are available
- Before touching module registration or role-based access

## Procedure

### Phase 1: File Structure Audit
```bash
# Find all PHP files (top 2 levels)
docker exec neurosis_rosariosis find /var/www/html -maxdepth 2 -name "*.php" | sort

# Find teacher module files specifically
docker exec neurosis_rosariosis find /var/www/html/modules/Teachers -name "*.php"

# Get line counts
docker exec neurosis_rosariosis wc -l /var/www/html/Side.php /var/www/html/Warehouse.php /var/www/html/Modules.php /var/www/html/index.php
```

### Phase 2: Read Sidebar + Layout Architecture
```bash
# Read full sidebar
docker exec neurosis_rosariosis cat /var/www/html/Side.php

# Read module loader (how pages are served)
docker exec neurosis_rosariosis cat /var/www/html/Modules.php

# Read layout wrapper (where sidebar/header/footer are included)
docker exec neurosis_rosariosis grep -n "require_once\|include\|Side.php\|Bottom.php" /var/www/html/Warehouse.php | head -20
```

### Phase 3: Session Variables
```bash
# Find all $_SESSION keys used across the codebase
docker exec neurosis_rosariosis grep -roh "\$_SESSION\['\w*'\]" /var/www/html --include="*.php" | sort -u

# Check login flow
docker exec neurosis_rosariosis grep -n "\$_SESSION\[" /var/www/html/index.php | head -20
```

### Phase 4: Database Query Functions
```bash
# Get DBGet/DBQuery/DBEscapeString/DBGetOne signatures
docker exec neurosis_rosariosis grep -n "function DBGet\|function DBQuery\|function DBEscapeString\|function DBGetOne" /var/www/html/functions/DBGet.fnc.php /var/www/html/database.inc.php

# Find real examples of DBGet calls in modules
docker exec neurosis_rosariosis grep -A3 "DBGet(" /var/www/html/modules/Grades/StudentGradeBook.php | head -20
```

### Phase 5: Module Registration
```bash
# Read module Menu.php
docker exec neurosis_rosariosis cat /var/www/html/modules/Teachers/Menu.php

# Check profile_exceptions DB table
docker exec neurosis_rosariosis psql -U neurosis_user -d neurosis -c "\d profile_exceptions"
docker exec neurosis_rosariosis psql -U neurosis_user -d neurosis -c "SELECT profile_id, title FROM profile;"
docker exec neurosis_rosariosis psql -U neurosis_user -d neurosis -c "SELECT * FROM profile_exceptions WHERE modname LIKE '%Teachers%' LIMIT 20;"
```

### Phase 6: Navigation Menu Generation
```bash
# Find how menu is built
docker exec neurosis_rosariosis cat /var/www/html/Menu.php

# Understand $_ROSARIO['Menu'] structure
docker exec neurosis_rosariosis grep -n "ROSARIO.*Menu\|_npRenderModule\|np_priority" /var/www/html/Side.php | head -20
```

### Phase 7: Teacher's Courses Query
```bash
# Get exact query from existing teacher module
docker exec neurosis_rosariosis grep -A10 "DBGet.*course_period" /var/www/html/modules/Teachers/TeacherDashboard.php | head -20

# Run it live
docker exec neurosis_rosariosis psql -U neurosis_user -d neurosis -c "
SELECT cp.course_period_id, c.TITLE, cp.TITLE as section, 
  COUNT(s.student_id) as student_count
FROM course_periods cp
JOIN courses c ON cp.course_id = c.course_id
LEFT JOIN schedule s ON s.course_period_id = cp.course_period_id
WHERE cp.teacher_id = 11 AND cp.SYEAR = 2025
GROUP BY cp.course_period_id, c.TITLE, cp.TITLE
ORDER BY c.TITLE
LIMIT 10;"
```

### Phase 8: CSS Architecture
```bash
# Find CSS files
docker exec neurosis_rosariosis find /var/www/html -name "*.css" | head -10

# Read main stylesheet (first 100 lines for variables/setup)
docker exec neurosis_rosariosis cat /var/www/html/assets/themes/NeuroPalma/css/stylesheet.css | head -100

# Check for icon libraries (FontAwesome, etc.)
docker exec neurosis_rosariosis grep -ro "font-awesome\|fontawesome\|fa-\|bootstrap" /var/www/html --include="*.php" --include="*.css" | sort -u | head -20
```

### Phase 9: Role-Based Access Control
```bash
# Check profile IDs
docker exec neurosis_rosariosis psql -U neurosis_user -d neurosis -c "SELECT * FROM user_profiles;"
docker exec neurosis_rosariosis psql -U neurosis_user -d neurosis -c "SELECT profile_id, title FROM profile;"

# Find role checks in Portal.php (teacher redirect)
docker exec neurosis_rosariosis grep -n "User.*PROFILE\|PROFILE_ID\|profile" /var/www/html/modules/misc/Portal.php | head -15
docker exec neurosis_rosariosis cat /var/www/html/modules/misc/Portal.php
```

### Phase 10: Live DB Stats
```bash
docker exec neurosis_rosariosis psql -U neurosis_user -d neurosis -c "
SELECT 'Teachers' as stat, COUNT(*) FROM staff WHERE profile_id = 2
UNION ALL SELECT 'Students', COUNT(*) FROM students
UNION ALL SELECT 'Schools', COUNT(*) FROM schools;
"
docker exec neurosis_rosariosis psql -U neurosis_user -d neurosis -c "
SELECT marking_period_id, title, start_date, end_date 
FROM school_marking_periods ORDER BY start_date;
"
```

## Pitfalls

- **Side.php (949 lines) is the entire sidebar** — not split into components. Replacing it means preserving `sidefunc=update` AJAX handlers for school/year/MP/course period selection.
- **`config.inc.php` may have stale DefaultSyear** — always verify against DB marking periods. They often drift.
- **No FontAwesome globally** — only emojis. If you need icons, load FA from CDN explicitly.
- **No notification system exists** — don't wire a bell icon without backend data.
- **`User('PROFILE_ID')` returns int (0-3)** but **`User('PROFILE')` returns string** ('admin', 'teacher', 'parent', 'student'). Use the string form for readability.
- **`Warehouse('header')` includes sidebar BEFORE module content** — the sidebar is loaded in the `<head>` phase, not after content.
- **Bottom.php is rendered in `<footer>` ABOVE sidebar in HTML order** but fixed to bottom via CSS.
- **`$_REQUEST` is already sanitized** (strip_tags + DBEscapeString) by the time it reaches Side.php — don't double-escape.
- **Profile IDs**: 0=Student, 1=Admin, 2=Teacher, 3=Parent (from `user_profiles` table). But `profile_exceptions` uses `profile_id` values from the `profile` table which may differ.

## Verification

After running the full POA, confirm:

1. [ ] Every `[ ]` in the POA document is filled
2. [ ] Every `???` placeholder is replaced with a real value
3. [ ] Session variables list is complete (no missing `$_SESSION` keys)
4. [ ] DB queries are verified by running them live
5. [ ] File paths are exact (cat/wc confirmed them)
6. [ ] Module registration flow is understood (Menu.php → $_ROSARIO['Menu'] → Side.php rendering)
7. [ ] Gotchas have been identified and documented

## Reference

- **Teacher ID for testing**: `11` (Ruddy Ribera)
- **Default school year in config**: `$DefaultSyear = '2025'` in config.inc.php
- **DB credentials (inside container)**: host=postgres, db=neurosis, user=neurosis_user
- **Admin login**: admin/admin
- **Teacher test login**: ruddy.ribera / lp2026
- **Container name**: neurosis_rosariosis
- **Web root inside container**: /var/www/html/
## Do Not Use
- Direct code modification in RosarioSIS (use code-builder)
- Database schema changes (use database-patterns)
- General PHP development outside RosarioSIS
- Security audit of RosarioSIS (use security-basics)
