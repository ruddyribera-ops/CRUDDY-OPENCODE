# cass-index.ps1
# Simplified CASS-style session indexer.
# Reads session_log.md entries, extracts structured task records,
# and writes them to memory/cass/index.jsonl for search.
param(
    [string]$SessionLogPath = "",          # Path to session_log.md (default: auto-detect)
    [string]$ProjectDir = "",              # Project dir for project-level logs
    [switch]$Verbose
)

$ErrorActionPreference = "SilentlyContinue"
$configDir = $env:USERPROFILE + "\.config\opencode"
$memoryDir = "$configDir\memory"
$cassDir = "$memoryDir\cass"
$indexFile = "$cassDir\index.jsonl"
$metaFile = "$cassDir\meta.json"  # index stats, last run

# ── Auto-detect session log ─────────────────────────────────────────────
if (-not $SessionLogPath) {
    $globalLog = "$memoryDir\session_log.md"
    if (Test-Path $globalLog) { $SessionLogPath = $globalLog }
    elseif ($ProjectDir) {
        $pLog = Join-Path $ProjectDir ".opencode\memory\session_log.md"
        if (Test-Path $pLog) { $SessionLogPath = $pLog }
    }
}

if (-not (Test-Path $SessionLogPath)) {
    Write-Host "[cass-index] No session log found. Skipping."
    exit 0
}

# ── Extract task entries from session_log.md ─────────────────────────────
# Pattern: | Task | Agent | Result | Tokens Est |
# Also captures standalone [timestamp] log lines for SESSION IDLE/ERROR tracking

$content = Get-Content $SessionLogPath -Raw -Encoding UTF8

# Extract task table rows
$taskRows = [regex]::Matches($content, '(?m)^\| ([^\|]+?) \| ([^\|]+?) \| ([^\|]+?) \| ([^\|]+?) \|')

# Extract session markers [YYYY-MM-DD] SESSION ...
$sessionMarkers = [regex]::Matches($content, '(?m)^\[(\d{4}-\d{2}-\d{2})\] SESSION (\w+): (.+)$')

# Build entries
$entries = @()
$seen = @{}  # deduplicate by task+agent+result hash

foreach ($row in $taskRows) {
    $task = $row.Groups[1].Value.Trim()
    $agent = $row.Groups[2].Value.Trim()
    $result = $row.Groups[3].Value.Trim()
    $tokens = $row.Groups[4].Value.Trim()

    # Skip noise entries
    if ($task -eq "Task" -or $task -eq "" -or $task.Length -lt 2) { continue }
    if ($result -eq "Result" -or $result -eq "Tokens Est") { continue }

    # Extract date from nearby context
    $dateMatch = [regex]::Match($content, "(?m)^(# Session Log.*?\n.*?)(\d{4}-\d{2}-\d{2})")
    $date = "unknown"
    if ($row.Value) {
        # Find the most recent date header before this row
        $pos = $content.IndexOf($row.Value)
        $before = $content.Substring(0, $pos)
        $dateM = [regex]::Matches($before, '(?m)^# Session Log.*?(\d{4}-\d{2}-\d{2})')
        if ($dateM.Count -gt 0) { $date = $dateM[$dateM.Count - 1].Groups[1].Value }
    }

    # Extract key terms from task name
    $terms = Extract-Terms $task

    $entry = @{
        id = [guid]::NewGuid().ToString("N").Substring(0, 12)
        task = $task
        agent = $agent
        result = $result
        tokens = $tokens
        date = $date
        project = if ($ProjectDir) { (Split-Path $ProjectDir -Leaf) } else { "global" }
        terms = $terms
        indexed_at = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
    }

    # Deduplicate
    $hash = "$task|$agent|$result" -replace '\s+', ''
    if (-not $seen.ContainsKey($hash)) {
        $seen[$hash] = $true
        $entries += $entry
    }
}

# Also index session markers (SESSION IDLE/ERROR events)
$sessionEvents = @()
foreach ($m in $sessionMarkers) {
    $eventDate = $m.Groups[1].Value
    $eventType = $m.Groups[2].Value  # IDLE, ERROR, NEW SESSION
    $sessionName = $m.Groups[3].Value.Trim()

    $sessionEntries = @{
        id = [guid]::NewGuid().ToString("N").Substring(0, 12)
        task = "session:$eventType"
        agent = "opencode"
        result = if ($eventType -eq "ERROR") { "FAIL" } elseif ($eventType -eq "NEW SESSION") { "START" } else { "IDLE" }
        tokens = "0"
        date = $eventDate
        project = "opencode-system"
        terms = @($eventType.ToLower(), "session", "system-event")
        indexed_at = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
        session_name = $sessionName
    }
    $sessionEvents += $sessionEntries
}

# ── Write to index ───────────────────────────────────────────────────────
New-Item -ItemType Directory -Path $cassDir -Force | Out-Null

# Load existing entries (skip duplicates by id)
$existing = @()
if (Test-Path $indexFile) {
    $raw = Get-Content $indexFile -Raw -Encoding UTF8
    if ($raw.Trim()) {
        $existing = $raw -split "`n" | Where-Object { $_.Trim() } | ForEach-Object {
            try { $_ | ConvertFrom-Json } catch { $null }
        }
    }
}

$existingCount = $existing.Count
$idSet = @{}
foreach ($e in $existing) { if ($e.id) { $idSet[$e.id] = $true } }

# Append only new entries
$newCount = 0
$appendHandle = $null
try {
    $appendHandle = [System.IO.File]::Open($indexFile, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write)
    $writer = New-Object System.IO.StreamWriter($appendHandle)

    foreach ($entry in ($entries + $sessionEvents)) {
        if (-not $idSet.ContainsKey($entry.id)) {
            $writer.WriteLine((ConvertTo-Json $entry -Compress))
            $newCount++
        }
    }
    $writer.Flush()
} finally {
    if ($appendHandle) { $appendHandle.Close() }
}

# Update meta
$meta = @{
    last_run = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
    total_entries = $existingCount + $newCount
    new_entries = $newCount
    source_log = $SessionLogPath
    project = if ($ProjectDir) { (Split-Path $ProjectDir -Leaf) } else { "global" }
}
$meta | ConvertTo-Json | Set-Content "$metaFile" -Encoding UTF8

if ($Verbose -or $newCount -gt 0) {
    Write-Host "[cass-index] $newCount new entries indexed (total: $($meta.total_entries))"
}

exit 0


# ── Helper: Extract search terms ─────────────────────────────────────────
function Extract-Terms {
    param([string]$text)

    # Stopwords to filter
    $stopwords = @("the", "a", "an", "of", "in", "for", "to", "and", "or", "with", "on", "at", "by",
                    "is", "it", "as", "be", "was", "are", "been", "from", "this", "that", "done",
                    "global", "windows", "test", "audit", "fix", "add", "update", "build", "done",
                    "step", "phase", "task", "module", "complete", "completed", "verification",
                    "verify", "pass", "failed", "working")

    # Extract camelCase, snake_case, words 3+ chars, and ALL-CAPS acronyms
    $words = [regex]::Matches($text, '(?<![a-z])([A-Z][a-z]+|[a-z]{3,}|_[a-z]{3,}|[A-Z]{2,})', "IgnoreCase")

    $terms = @()
    foreach ($w in $words) {
        $term = $w.Value.TrimStart('_').ToLower()
        # Keep all-caps acronyms (PRIA, API, SQL, etc.) and 3+ char terms
        $isAcronym = $w.Value -cmatch '^[A-Z]{2,}$'
        if ($isAcronym -or ($term.Length -ge 3 -and $stopwords -notcontains $term)) {
            $terms += $term
        }
    }

    # Unique
    return ($terms | Sort-Object -Unique)
}