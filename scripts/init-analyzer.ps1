# init-analyzer.ps1
# SP-2: Codebase analyzer — generates draft AGENTS.md for unknown projects
# 5 phases: structure scan, stack detection, pattern detection, agent scan, output
param(
    [string]$ProjectPath = "",
    [string]$OutputPath = "",
    [switch]$Help
)

if ($Help) {
    Write-Host "init-analyzer.ps1 - Codebase analyzer for unknown projects"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  powershell -File scripts/init-analyzer.ps1 -ProjectPath 'path/to/project'"
    Write-Host ""
    Write-Host "Outputs: <project>/AGENTS.md (draft with [TODO] markers)"
    exit 0
}

$ErrorActionPreference = "SilentlyContinue"
$configDir = "$env:USERPROFILE\.config\opencode"

# --- Resolve project path ---
if (-not $ProjectPath) {
    $ProjectPath = Get-Location
} else {
    if (-not (Test-Path $ProjectPath)) {
        Write-Host "[init-analyzer] ERROR: Project path not found: $ProjectPath" -ForegroundColor Red
        exit 1
    }
}
$ProjectPath = (Resolve-Path $ProjectPath).Path

if (-not $OutputPath) {
    $OutputPath = Join-Path $ProjectPath "AGENTS.md"
}

Write-Host "[init-analyzer] Starting analysis of: $ProjectPath" -ForegroundColor Cyan

# =========================================================
# PHASE 1: Structure Scan
# =========================================================
Write-Host "[Phase 1] Scanning structure..." -ForegroundColor Yellow

$folderStats = @{}
$fileTypeCounts = @{}
$configFiles = @()

# Scan directories (max depth 3)
$dirs = Get-ChildItem -Path $ProjectPath -Directory -Depth 3 -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '^(\.git|node_modules|__pycache__|\.next|dist|build|venv|\.venv)$' }
foreach ($d in $dirs) {
    $folderStats[$d.Name] = $d.FullName
}

# Scan file types
$allFiles = Get-ChildItem -Path $ProjectPath -File -Depth 3 -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '^(\.git|node_modules)' }
foreach ($f in $allFiles) {
    $ext = $f.Extension.ToLower()
    if ($ext) {
        $fileTypeCounts[$ext] = if ($fileTypeCounts[$ext]) { $fileTypeCounts[$ext] + 1 } else { 1 }
    }
    # Track config files
    $configNames = 'package.json', 'package-lock.json', 'requirements.txt', 'pyproject.toml', 'go.mod', 'go.sum',
                   'Cargo.toml', 'Gemfile', 'Pipfile', 'setup.py', 'setup.cfg', 'Dockerfile', 'docker-compose.yml',
                   'docker-compose.yaml', '.env', '.env.example', '.env.local', 'tsconfig.json', 'jsconfig.json',
                   'vite.config.js', 'vite.config.ts', 'webpack.config.js', 'next.config.js', 'next.config.mjs',
                   '.eslintrc', '.eslintrc.json', '.prettierrc', 'pytest.ini', 'tox.ini', 'Makefile', 'CMakeLists.txt'
    if ($configNames -contains $f.Name) {
        $configFiles += $f.FullName
    }
}

Write-Host "  Found $($fileTypeCounts.Count) file types, $($configFiles.Count) config files"
$topFolders = ($folderStats.Keys | Select-Object -First 10) -join ', '
Write-Host "  Top folders: $topFolders"

# =========================================================
# PHASE 2: Stack Detection
# =========================================================
Write-Host "[Phase 2] Detecting stack..." -ForegroundColor Yellow

$stack = @{
    Language = ""
    Framework = ""
    Database = ""
    Deploy = ""
    BuildTool = ""
    TestFramework = ""
    HasTypeScript = $false
    HasPython = $false
    HasGo = $false
    HasRust = $false
    HasNode = $false
    IsReact = $false
    IsVue = $false
    IsFastAPI = $false
    IsDjango = $false
    IsFlask = $false
    IsPostgreSQL = $false
    IsSQLite = $false
    IsDocker = $false
    IsRailway = $false
}

# Read package.json
$pkgPath = Join-Path $ProjectPath "package.json"
if (Test-Path $pkgPath) {
    $stack.HasNode = $true
    $stack.Language = "JavaScript/TypeScript"
    try {
        $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
        $deps = $pkg.dependencies | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
        if ($deps -contains 'react') { $stack.IsReact = $true; $stack.Framework = "React" }
        if ($deps -contains 'vue') { $stack.IsVue = $true; $stack.Framework = "Vue" }
        if ($deps -contains 'next') { $stack.Framework = "Next.js" }
        if ($deps -contains 'fastify') { $stack.Framework = "Fastify" }
        if ($deps -contains 'express') { $stack.Framework = "Express" }
        if ($deps -contains 'playwright') { $stack.TestFramework = "Playwright" }
        if ($deps -contains 'vitest') { $stack.TestFramework = "Vitest" }
        if ($deps -contains 'jest') { $stack.TestFramework = "Jest" }
    } catch {}
}

# Read tsconfig/jsconfig
$tsconfig = Join-Path $ProjectPath "tsconfig.json"
if (Test-Path $tsconfig) { $stack.HasTypeScript = $true }
$jsconfig = Join-Path $ProjectPath "jsconfig.json"
if (Test-Path $jsconfig) { $stack.HasTypeScript = $true }

# Read pyproject.toml / requirements.txt
$pyproject = Join-Path $ProjectPath "pyproject.toml"
$reqTxt = Join-Path $ProjectPath "requirements.txt"
if (Test-Path $pyproject) {
    $stack.HasPython = $true
    $stack.Language = "Python"
    try {
        $content = Get-Content $pyproject -Raw
        if ($content -match 'fastapi') { $stack.IsFastAPI = $true; $stack.Framework = "FastAPI" }
        if ($content -match 'django') { $stack.IsDjango = $true; $stack.Framework = "Django" }
        if ($content -match 'flask') { $stack.IsFlask = $true; $stack.Framework = "Flask" }
        if ($content -match 'pytest') { $stack.TestFramework = "pytest" }
        if ($content -match 'sqlalchemy') {
            if ($stack.Framework) { $stack.Framework = "$($stack.Framework) + SQLAlchemy" } else { $stack.Framework = "SQLAlchemy" }
        }
        if ($content -match 'psycopg') { $stack.IsPostgreSQL = $true; $stack.Database = "PostgreSQL" }
        if ($content -match 'aiosqlite|sqlite') { $stack.IsSQLite = $true; $stack.Database = "SQLite" }
    } catch {}
} elseif (Test-Path $reqTxt) {
    $stack.HasPython = $true
    $stack.Language = "Python"
    try {
        $content = Get-Content $reqTxt -Raw
        if ($content -match 'fastapi') { $stack.IsFastAPI = $true; $stack.Framework = "FastAPI" }
        if ($content -match 'django') { $stack.IsDjango = $true; $stack.Framework = "Django" }
        if ($content -match 'flask') { $stack.IsFlask = $true; $stack.Framework = "Flask" }
        if ($content -match 'pytest') { $stack.TestFramework = "pytest" }
        if ($content -match 'psycopg|postgresql') { $stack.IsPostgreSQL = $true; $stack.Database = "PostgreSQL" }
        if ($content -match 'sqlite') { $stack.IsSQLite = $true; $stack.Database = "SQLite" }
    } catch {}
}

# Read go.mod
$gomod = Join-Path $ProjectPath "go.mod"
if (Test-Path $gomod) {
    $stack.HasGo = $true
    $stack.Language = "Go"
    try {
        $content = Get-Content $gomod -Raw
        if ($content -match 'gin-gonic/gin') { $stack.Framework = "Gin" }
        if ($content -match 'fiber') { $stack.Framework = "Fiber" }
        if ($content -match 'chi') { $stack.Framework = "Chi" }
        if ($content -match 'testing') { $stack.TestFramework = "testing" }
    } catch {}
}

# Read Cargo.toml
$cargo = Join-Path $ProjectPath "Cargo.toml"
if (Test-Path $cargo) {
    $stack.HasRust = $true
    $stack.Language = "Rust"
}

# Detect Dockerfile
$dockerfile = Join-Path $ProjectPath "Dockerfile"
if (Test-Path $dockerfile) { $stack.IsDocker = $true }
$dcYaml = Join-Path $ProjectPath "docker-compose.yml"
if (Test-Path $dcYaml) { $stack.IsDocker = $true }

# Detect Railway
if ((Test-Path (Join-Path $ProjectPath "railway.json")) -or (Test-Path (Join-Path $ProjectPath ".railway"))) {
    $stack.IsRailway = $true
    $stack.Deploy = "Railway"
}

# Default language if not detected
if (-not $stack.Language) {
    if ($fileTypeCounts['.py']) { $stack.Language = "Python (inferred from .py files)" }
    elseif ($fileTypeCounts['.ts'] -or $fileTypeCounts['.tsx']) { $stack.Language = "TypeScript (inferred)" }
    elseif ($fileTypeCounts['.go']) { $stack.Language = "Go (inferred)" }
    elseif ($fileTypeCounts['.rs']) { $stack.Language = "Rust (inferred)" }
    elseif ($fileTypeCounts['.java']) { $stack.Language = "Java (inferred)" }
    else { $stack.Language = "[TODO: detect]" }
}

Write-Host "  Language: $($stack.Language)"
Write-Host "  Framework: $($stack.Framework)"
Write-Host "  Database: $($stack.Database)"
Write-Host "  Deploy: $($stack.Deploy)"

# =========================================================
# PHASE 3: Pattern Detection
# =========================================================
Write-Host "[Phase 3] Detecting patterns..." -ForegroundColor Yellow

$namingConv = ""
$errorHandling = ""
$testPatterns = ""

# Naming convention detection (src folders only)
$srcDir = Get-ChildItem -Path $ProjectPath -Directory -Depth 2 -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^src$|^app$|^lib$|^internal$|^pkg$' } | Select-Object -First 1
if ($srcDir) {
    $srcFiles = Get-ChildItem -Path $srcDir.FullName -File -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 20
    $kebab = ($srcFiles | Where-Object { $_.Name -match '^[a-z][a-z0-9]+(-[a-z0-9]+)+\.[a-z]+$' }).Count
    $snake = ($srcFiles | Where-Object { $_.Name -match '^[a-z][a-z0-9]+(_[a-z0-9]+)+\.[a-z]+$' }).Count
    $camel = ($srcFiles | Where-Object { $_.Name -match '^[a-z][a-zA-Z0-9]+[a-z]\.[a-z]+$' }).Count
    $pascal = ($srcFiles | Where-Object { $_.Name -match '^[A-Z][a-zA-Z0-9]+\.[a-z]+$' }).Count

    if ($kebab -gt $snake -and $kebab -gt $camel -and $kebab -gt $pascal) { $namingConv = "kebab-case (e.g., my-file.ts)" }
    elseif ($snake -gt $kebab -and $snake -gt $camel -and $snake -gt $pascal) { $namingConv = "snake_case (e.g., my_file.py)" }
    elseif ($camel -gt $kebab -and $camel -gt $snake -and $camel -gt $pascal) { $namingConv = "camelCase (e.g., myFile.ts)" }
    elseif ($pascal -gt $kebab -and $pascal -gt $snake -and $pascal -gt $camel) { $namingConv = "PascalCase (e.g., MyFile.ts)" }
    else { $namingConv = "[TODO: detect from samples]" }
}

# Error handling pattern
$allSrcFiles = Get-ChildItem -Path $ProjectPath -File -Recurse -Depth 3 -ErrorAction SilentlyContinue | Where-Object { $_.Extension -match '\.(py|ts|js|go)$' -and $_.Name -notmatch '^(\.git|node_modules)' } | Select-Object -First 30
if ($allSrcFiles) {
    $tryCatchPy = ($allSrcFiles | Where-Object { $_.Extension -eq '.py' -and (Select-String -Path $_.FullName -Pattern 'try:|except' -Quiet) }).Count
    $tryCatchTs = ($allSrcFiles | Where-Object { $_.Extension -match '\.ts$|\.js' -and (Select-String -Path $_.FullName -Pattern 'try \{|catch \(' -Quiet) }).Count
    $tryCatchGo = ($allSrcFiles | Where-Object { $_.Extension -eq '.go' -and (Select-String -Path $_.FullName -Pattern 'if err != nil' -Quiet) }).Count

    if ($tryCatchPy -gt 3) { $errorHandling = "Python try/except pattern" }
    elseif ($tryCatchTs -gt 3) { $errorHandling = "JS try/catch pattern" }
    elseif ($tryCatchGo -gt 3) { $errorHandling = "Go if err != nil pattern" }
    else { $errorHandling = "[TODO: detect from samples]" }
}

# Test patterns
$testDirs = Get-ChildItem -Path $ProjectPath -Directory -Recurse -Depth 3 -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^test(s)?$|__tests__|spec$' } | Select-Object -First 3
if ($testDirs) {
    $testFiles = Get-ChildItem -Path $testDirs[0].FullName -File -ErrorAction SilentlyContinue
    if (($testFiles | Where-Object { $_.Name -match '\.test\.' }).Count -gt 0) { $testPatterns = "*.test.* files" }
    elseif (($testFiles | Where-Object { $_.Name -match '_test\.go$' }).Count -gt 0) { $testPatterns = "*_test.go files (Go)" }
    elseif (($testFiles | Where-Object { $_.Name -match 'test_.+\.py$' -or $_.Name -match '_test\.py$' }).Count -gt 0) { $testPatterns = "test_*.py / *_test.py (pytest)" }
    else { $testPatterns = "[TODO: detect from test dir samples]" }
} else {
    $testPatterns = "[TODO: no test dir found]"
}

Write-Host "  Naming: $namingConv"
Write-Host "  Error handling: $errorHandling"
Write-Host "  Test pattern: $testPatterns"

# =========================================================
# PHASE 4: Build/Test Commands
# =========================================================
Write-Host "[Phase 4] Detecting build/test commands..." -ForegroundColor Yellow

$buildCmd = "[TODO]"
$testCmd = "[TODO]"
$devCmd = "[TODO]"

# From package.json scripts
if ($stack.HasNode) {
    try {
        $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
        $scripts = $pkg.scripts
        if ($scripts) {
            if ($scripts.dev) { $devCmd = "npm run dev" }
            if ($scripts.build) { $buildCmd = "npm run build" }
            if ($scripts.test) { $testCmd = "npm run test" }
        }
    } catch {}
}

# From Makefile
$makefile = Join-Path $ProjectPath "Makefile"
if (Test-Path $makefile) {
    $content = Get-Content $makefile -Raw
    if ($content -match '^test:') { $testCmd = "make test" }
    if ($content -match '^build:') { $buildCmd = "make build" }
    if ($content -match '^dev:') { $devCmd = "make dev" }
}

# From pyproject.toml
if ($stack.HasPython) {
    if (Test-Path $pyproject) {
        $content = Get-Content $pyproject -Raw
        if ($content -match 'pytest') { $testCmd = "pytest" }
    }
}

Write-Host "  Build: $buildCmd"
Write-Host "  Test: $testCmd"
Write-Host "  Dev: $devCmd"

# =========================================================
# PHASE 5: Output Draft AGENTS.md
# =========================================================
Write-Host "[Phase 5] Writing draft AGENTS.md..." -ForegroundColor Yellow

$projectName = Split-Path $ProjectPath -Leaf
$detectDate = Get-Date -Format 'yyyy-MM-dd'

$draft = @"
# [Project Name] — Agent Instructions

<!-- AUTO-GENERATED by init-analyzer.ps1 on $detectDate -->
<!-- REVIEW and update all [TODO] markers before first use -->

<!-- This file overrides/extends global AGENTS.md. Keep under 300 lines. -->

## 1. What This Project Is (READ FIRST)
<!-- [TODO: Describe what the app does, who it's for] -->
- **App:** [TODO: one sentence description]
- **Services:** [TODO: what services make up the app? API, frontend, worker, etc.]
- **Dependencies:** [TODO: key external services: Railway, Supabase, Vercel, etc.]
- **Critical context:** [TODO: anything the agent would never guess]

---

## 2. Tech Stack

- **Language:** $($stack.Language)
- **Framework:** $($stack.Framework)
- **Database:** $($stack.Database)
- **Deploy:** $($stack.Deploy)
- **Test Framework:** $($stack.TestFramework)

**Detected from scan:**
- File types: $(($fileTypeCounts.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5 | ForEach-Object { "$($_.Key)($($_.Value))" }) -join ', ')
- Top folders: $topFolders
- TypeScript: $($stack.HasTypeScript)
- Docker: $($stack.IsDocker)

---

## 3. Project Conventions

**Naming:** $namingConv
**Error handling:** $errorHandling
**Test pattern:** $testPatterns

---

## 4. Commands

- **Run:** $devCmd
- **Build:** $buildCmd
- **Test:** $testCmd

---

## 5. Known Issues
<!-- [TODO: document known bugs and workarounds] -->

---

## 6. Key Files
<!-- [TODO: point to the most important files] -->

"@

try {
    [System.IO.File]::WriteAllText($OutputPath, $draft, [System.Text.Encoding]::UTF8)
    Write-Host "[init-analyzer] Draft AGENTS.md written to: $OutputPath" -ForegroundColor Green
} catch {
    Write-Host "[init-analyzer] ERROR: Failed to write $OutputPath : $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Analysis complete. Review $($OutputPath) and fill in [TODO] markers." -ForegroundColor Cyan
exit 0