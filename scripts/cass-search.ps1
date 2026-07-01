# cass-search.ps1
param(
    [string]$Query = "",
    [int]$Days = 0,
    [int]$Limit = 20,
    [string]$Agent = "",
    [string]$Project = ""
)
$ErrorActionPreference = "SilentlyContinue"
$configDir = $env:USERPROFILE + "\.config\opencode"
$memoryDir = "$configDir\memory"
$cassDir = "$memoryDir\cass"
$indexFile = "$cassDir\index.jsonl"
$metaFile = "$cassDir\meta.json"
if (-not (Test-Path $indexFile)) {
    Write-Host "[cass-search] Index empty. Run cass-index.ps1 first."
    exit 0
}
$entries = @()
$raw = Get-Content $indexFile -Raw -Encoding UTF8
if ($raw.Trim()) {
    $lines = $raw -split "`n"
    foreach ($l in $lines) {
        $l = $l.Trim()
        if ($l) {
            try {
$entries += $l | ConvertFrom-Json
        } catch {
            # Skip malformed JSON lines; don't fail entire search
            Write-Warning "cass-search: skipping malformed JSON line - $($_.Exception.Message)"
        }
        }
    }
}
if ($entries.Count -eq 0) {
    Write-Host "[cass-search] No entries in index."
    exit 0
}
$queryTerms = $Query.ToLower() -split '\s+' | Where-Object { $_.Length -ge 2 }
$cutoffDate = if ($Days -gt 0) { (Get-Date).AddDays(-$Days).ToString("yyyy-MM-dd") } else { "" }
$results = @()
foreach ($entry in $entries) {
    if ($cutoffDate -and $entry.date -and $entry.date -lt $cutoffDate) { continue }
    if ($Agent -and $entry.agent -notmatch $Agent) { continue }
    if ($Project -and $entry.project -notmatch $Project) { continue }
    $score = 0
    $text = ($entry.task + " " + $entry.agent + " " + $entry.result + " " + ($entry.terms -join " ")).ToLower()
    if ($queryTerms.Count -gt 0) {
        foreach ($term in $queryTerms) {
            if ($entry.task -and $entry.task.ToLower() -match $term) { $score += 10 }
            if ($entry.terms -and $entry.terms -contains $term) { $score += 5 }
            if ($text -match $term) { $score += 2 }
        }
        if ($score -eq 0) { continue }
    } else {
        $score = 1
    }
    $results += @{ score = $score; entry = $entry }
}
if ($results.Count -eq 0) {
    Write-Host "[cass-search] No results for: $Query"
    exit 0
}
$results = $results | Sort-Object { $_.score } -Descending | Select-Object -First $Limit
$meta = $null
if (Test-Path $metaFile) {
        try {
            $meta = Get-Content $metaFile -Raw | ConvertFrom-Json
        } catch {
            # Corrupt meta file; default to empty
            Write-Warning "cass-search: corrupt meta file, using defaults - $($_.Exception.Message)"
            $meta = @{ last_run = $null; total_entries = 0 }
        }
    }
Write-Host "=== CASS Search: ""$Query"" ===" -ForegroundColor Cyan
Write-Host "Found $($results.Count) results"
if ($meta) { Write-Host "Total indexed: $($meta.total_entries)" -ForegroundColor DarkGray }
if ($Days -gt 0) { Write-Host "Last $Days days" -ForegroundColor DarkGray }
if ($Agent) { Write-Host "Agent: $Agent" -ForegroundColor DarkGray }
if ($Project) { Write-Host "Project: $Project" -ForegroundColor DarkGray }
Write-Host ""
foreach ($r in $results) {
    $e = $r.entry
    $proj = $e.project
    $taskDisplay = if ($e.task.Length -gt 65) { $e.task.Substring(0, 62) + "..." } else { $e.task }
    Write-Host "[$($e.date)] [$proj]" -NoNewline -ForegroundColor DarkGray
    Write-Host " $taskDisplay" -ForegroundColor White
    Write-Host "  agent=$($e.agent) result=$($e.result)" -ForegroundColor DarkGray
    Write-Host "  score=$($r.score) terms=$($e.terms -join ', ')" -ForegroundColor Green
    Write-Host ""
}
if ($meta) { Write-Host "--- Last indexed: $($meta.last_run) ---" -ForegroundColor DarkGray }
exit 0