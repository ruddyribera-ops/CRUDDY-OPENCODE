# beads.ps1 - Git-backed task tracking (Hive pattern)
# Usage:
#   .\beads.ps1 create --title "Implement auth" --type feature --agent worker-a
#   .\beads.ps1 start --id bd-001 --files "src/auth/*"
#   .\beads.ps1 close --id bd-001 --reason "Done: auth implemented"
#   .\beads.ps1 list [--status in_progress]
#   .\beads.ps1 query --status in_progress --limit 10

param(
    [Parameter(Mandatory=$false)]
    [string]$Command = "",

    [Parameter(Mandatory=$false)]
    [string]$Id = "",

    [Parameter(Mandatory=$false)]
    [string]$Title = "",

    [Parameter(Mandatory=$false)]
    [ValidateSet("feature", "bug", "chore", "refactor", "docs", "coordination", "implementation")]
    [string]$Type = "feature",

    [Parameter(Mandatory=$false)]
    [string]$Agent = "",

    [Parameter(Mandatory=$false)]
    [string]$Files = "",

    [Parameter(Mandatory=$false)]
    [string]$Reason = "",

    [Parameter(Mandatory=$false)]
    [ValidateSet("in_progress", "completed", "cancelled", "blocked")]
    [string]$Status = "",

    [Parameter(Mandatory=$false)]
    [int]$Limit = 20
)

$CONFIG_ROOT = $env:OPENCODE_CONFIG_HOME
if (-not $CONFIG_ROOT) {
    if ($env:USERPROFILE) { $CONFIG_ROOT = Join-Path $env:USERPROFILE ".config\opencode" }
    else { $CONFIG_ROOT = "C:\Users\Windows\.config\opencode" }
}

$HIVE_DIR = Join-Path $CONFIG_ROOT "memory\hive"
$ACTIVE_DIR = Join-Path $HIVE_DIR "active"
$INDEX_FILE = Join-Path $HIVE_DIR "beads_index.jsonl"

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ACTIVE_DIR)) {
    New-Item -ItemType Directory -Path $ACTIVE_DIR -Force | Out-Null
}

# ── Helpers ────────────────────────────────────────────────────────

function Get-NextBeadId {
    $nextNum = 1
    if (Test-Path $INDEX_FILE) {
        $lines = [System.IO.File]::ReadAllLines($INDEX_FILE)
        foreach ($line in $lines) {
            if ($line -ne "") {
                try {
                    $parsed = $line | ConvertFrom-Json
                    if ($parsed.id -match "^bd-(\d+)$") {
                        $num = [int]$Matches[1]
                        if ($num -ge $nextNum) { $nextNum = $num + 1 }
                    }
                } catch {}
            }
        }
    }
    return "bd-{0:D3}" -f $nextNum
}

function Save-Bead {
    param([object]$Bead, [string]$FilePath)
    # Handle both PSCustomObject (from ConvertFrom-Json) and Hashtable
    $json = if ($Bead -is [hashtable]) {
        $Bead | ConvertTo-Json -Depth 5 -Compress
    } else {
        # PSCustomObject - convert via hashtable first
        $dict = @{}
        $Bead.PSObject.Properties | ForEach-Object { $dict[$_.Name] = $_.Value }
        $dict | ConvertTo-Json -Depth 5 -Compress
    }
    [System.IO.File]::WriteAllText($FilePath, $json, [System.Text.Encoding]::UTF8)
}

function Load-Bead {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return $null }
    $content = [System.IO.File]::ReadAllText($FilePath, [System.Text.Encoding]::UTF8)
    $obj = $content | ConvertFrom-Json
    # Convert PSCustomObject to hashtable for consistent mutation
    $ht = @{}
    $obj.PSObject.Properties | ForEach-Object { $ht[$_.Name] = $_.Value }
    return $ht
}

function Append-Index {
    param([hashtable]$Entry)
    $line = $Entry | ConvertTo-Json -Compress
    [System.IO.File]::AppendAllText($INDEX_FILE, "$line`n", [System.Text.Encoding]::UTF8)
}

function Invoke-GitCommit {
    param([string]$Message, [string]$FilePath)
    $dir = Split-Path $FilePath -Parent
    if (Test-Path (Join-Path $dir ".git")) {
        try {
            $null = git -C $dir add $FilePath 2>$null
            $null = git -C $dir commit -m $Message 2>$null
            return $true
        } catch {
            return $false
        }
    }
    return $false
}

# ── Commands ──────────────────────────────────────────────────────

function cmd-create {
    if ($Title -eq "") { return @{ok=$false; error="--title required"} }

    $id = Get-NextBeadId
    $timestamp = (Get-Date).ToUniversalTime().ToString("o")
    $bead = @{
        id = $id
        title = $Title
        type = $Type
        status = "created"
        agent = $Agent
        files_reserved = @($Files -split "," | Where-Object { $_.Trim() -ne "" })
        created_at = $timestamp
        completed_at = $null
        outcome = $null
        reason = $null
    }

    $filePath = Join-Path $ACTIVE_DIR "${id}.json"
    Save-Bead $bead $filePath

    # Index entry
    $indexEntry = @{
        id = $id
        type = "created"
        timestamp = $timestamp
        status = "created"
    }
    Append-Index $indexEntry

    $gitCommit = Invoke-GitCommit -Message "bead: $id created - $Title" -FilePath $filePath

    return @{
        ok = $true
        data = @{
            id = $id
            title = $Title
            status = "created"
            git_committed = $gitCommit
        }
    }
}

function cmd-start {
    if ($Id -eq "") { return @{ok=$false; error="--id required"} }

    $filePath = Join-Path $ACTIVE_DIR "${Id}.json"
    if (-not (Test-Path $filePath)) { return @{ok=$false; error="Bead $Id not found"} }

    $bead = Load-Bead $filePath
    $bead.status = "in_progress"
    $bead.agent = if ($Agent -ne "") { $Agent } else { $bead.agent }
    $bead.files_reserved = if ($Files -ne "") { @($Files -split "," | Where-Object { $_.Trim() -ne "" }) } else { $bead.files_reserved }
    $bead.started_at = (Get-Date).ToUniversalTime().ToString("o")

    Save-Bead $bead $filePath

    $indexEntry = @{
        id = $Id
        type = "started"
        timestamp = (Get-Date).ToUniversalTime().ToString("o")
        status = "in_progress"
        agent = $bead.agent
    }
    Append-Index $indexEntry

    return @{
        ok = $true
        data = @{
            id = $Id
            status = "in_progress"
            agent = $bead.agent
        }
    }
}

function cmd-close {
    if ($Id -eq "") { return @{ok=$false; error="--id required"} }

    $filePath = Join-Path $ACTIVE_DIR "${Id}.json"
    if (-not (Test-Path $filePath)) { return @{ok=$false; error="Bead $Id not found"} }

    $bead = Load-Bead $filePath
    $bead.status = "completed"
    $bead.completed_at = (Get-Date).ToUniversalTime().ToString("o")
    $bead.outcome = "success"
    $bead.reason = $Reason

    Save-Bead $bead $filePath

    $indexEntry = @{
        id = $Id
        type = "closed"
        timestamp = (Get-Date).ToUniversalTime().ToString("o")
        status = "completed"
        reason = $Reason
    }
    Append-Index $indexEntry

    $gitCommit = Invoke-GitCommit -Message "bead: $Id closed - $Reason" -FilePath $filePath

    return @{
        ok = $true
        data = @{
            id = $Id
            status = "completed"
            reason = $Reason
            git_committed = $gitCommit
        }
    }
}

function cmd-list {
    $statusFilter = $Status
    $results = @()

    foreach ($f in Get-ChildItem $ACTIVE_DIR -Filter "*.json" -ErrorAction SilentlyContinue) {
        $bead = Load-Bead $f.FullName
        if ($null -eq $bead) { continue }
        if ($statusFilter -ne "" -and $bead.status -ne $statusFilter) { continue }
        $results += @{
            id = $bead.id
            title = $bead.title
            type = $bead.type
            status = $bead.status
            agent = $bead.agent
            created_at = $bead.created_at
            completed_at = $bead.completed_at
        }
        if ($results.Count -ge $Limit) { break }
    }

    $results = $results | Sort-Object { $_.created_at } -Descending

    return @{
        ok = $true
        data = @{
            count = $results.Count
            beads = $results
        }
    }
}

function cmd-query {
    # Query across all beads (including completed)
    $results = @()

    foreach ($f in Get-ChildItem $ACTIVE_DIR -Filter "*.json" -ErrorAction SilentlyContinue) {
        $bead = Load-Bead $f.FullName
        if ($null -eq $bead) { continue }
        if ($Status -ne "" -and $bead.status -ne $Status) { continue }
        if ($Agent -ne "" -and $bead.agent -ne $Agent) { continue }

        $results += @{
            id = $bead.id
            title = $bead.title
            type = $bead.type
            status = $bead.status
            agent = $bead.agent
            files_reserved = $bead.files_reserved
            created_at = $bead.created_at
            completed_at = $bead.completed_at
            reason = $bead.reason
        }
        if ($results.Count -ge $Limit) { break }
    }

    $results = $results | Sort-Object { $_.created_at } -Descending

    return @{
        ok = $true
        data = @{
            count = $results.Count
            beads = $results
        }
    }
}

# ── Main ──────────────────────────────────────────────────────────

$cmd = $Command.ToLower()
$result = @{ok=$false; error="unknown command '$cmd'. Use: create, start, close, list, query"}

if ($cmd -eq "create" -or $cmd -eq "new") {
    $result = cmd-create
} elseif ($cmd -eq "start" -or $cmd -eq "begin") {
    $result = cmd-start
} elseif ($cmd -eq "close" -or $cmd -eq "complete" -or $cmd -eq "done") {
    $result = cmd-close
} elseif ($cmd -eq "list" -or $cmd -eq "ls") {
    $result = cmd-list
} elseif ($cmd -eq "query" -or $cmd -eq "search") {
    $result = cmd-query
}

$result | ConvertTo-Json -Depth 5
exit 0