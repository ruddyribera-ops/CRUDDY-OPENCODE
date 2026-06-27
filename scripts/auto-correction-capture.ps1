# auto-correction-capture.ps1
# SP-1: Captures corrections from conversation transcript and writes to lessons_learned.md
# Triggered by on-stop.ps1 at session end
# Deduplicates: won't write same correction within 7 days

param(
    [string]$TranscriptPath = "",
    [string]$OutputPath = "",
    [switch]$Verbose
)

$ErrorActionPreference = "SilentlyContinue"
$configDir = "$env:USERPROFILE\.config\opencode"
$memoryDir = "$configDir\memory"
$logFile = "$configDir\hook-errors.log"

# Defaults
if (-not $TranscriptPath) {
    $stdinRaw = [Console]::In.ReadToEnd()
    if ($stdinRaw -and $stdinRaw.Trim() -ne '') {
        try {
            $data = $stdinRaw | ConvertFrom-Json -ErrorAction Stop
            $TranscriptPath = $data.transcript_path
        } catch {}
    }
}

if (-not $OutputPath) {
    $OutputPath = "$memoryDir\lessons_learned.md"
}

# --- Helper ---
function Log-CaptureError {
    param([string]$Msg)
    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] auto-correction-capture.ps1: $Msg" | Out-File -FilePath $logFile -Append -Encoding UTF8
}

# --- Load transcript ---
if (-not $TranscriptPath -or -not (Test-Path $TranscriptPath)) {
    if ($Verbose) { Write-Host "[auto-correction] No transcript path or file not found: $TranscriptPath" }
    exit 0
}

$content = Get-Content $TranscriptPath -Raw -ErrorAction Stop
if (-not $content) {
    exit 0
}

# --- Correction patterns (Ruddy's language + English) ---
# Format: @{ Pattern = "..."; WrongGroup = N; RightGroup = N }
# Groups are regex capture groups: (.*?) for wrong, (.*?) for right
$patterns = @(
    # English corrections
    @{ Pattern = '(?i)no[,]?\s+(?:do it|make it|go|do this|the)\s+(?:this\s+)?way[:\s]*(.*?)(?:\n|$)'; WrongGroup = 0; RightGroup = 1; Example = 'no, do it this way: X' },                        @{ Pattern = '(?i)not\s+(?:like\s+)?that[:\s]*(.*?)(?:\n|$)'; WrongGroup = 0; RightGroup = 1; Example = 'not like that: X' },
    @{ Pattern = '(?i)should be[:\s]*(.*?)(?:\n|$)'; WrongGroup = 0; RightGroup = 1; Example = 'should be: X' },
    @{ Pattern = '(?i)that''?s?\s+(?:incorrect|wrong)[:\s]*(.*?)(?:\n|$)'; WrongGroup = 0; RightGroup = 1; Example = "that's incorrect: X" },
    @{ Pattern = '(?i)wrong[:\s]*(.*?)(?:\n|$)'; WrongGroup = 0; RightGroup = 1; Example = 'wrong: X' },
    @{ Pattern = '(?i)the\s+correct\s+(?:approach|way)\s+is[:\s]*(.*?)(?:\n|$)'; WrongGroup = 0; RightGroup = 1; Example = 'the correct approach is: X' },
    @{ Pattern = '(?i)correct\s+approach\s+is[:\s]*(.*?)(?:\n|$)'; WrongGroup = 0; RightGroup = 1; Example = 'correct approach is: X' },
    @{ Pattern = '(?i)do\s+(?:it|this)\s+(?:the\s+)?right\s+way[:\s]*(.*?)(?:\n|$)'; WrongGroup = 0; RightGroup = 1; Example = 'do it the right way: X' },
    @{ Pattern = '(?i)actually[:\s]*(.*?)(?:\n|$)'; WrongGroup = 0; RightGroup = 1; Example = 'actually: X' },
    # Ruddy's Spanish corrections
    @{ Pattern = '(?i)no[,]?\s+(?:hazlo|hacerlo|as[ií])[:\s]*(.*?)(?:\n|$)'; WrongGroup = 0; RightGroup = 1; Example = 'no, hazlo así: X' },
    @{ Pattern = '(?i)est[aá]\s+mal[:\s]*(.*?)(?:\n|$)'; WrongGroup = 0; RightGroup = 1; Example = 'está mal: X' },
    @{ Pattern = '(?i)la\s+(?:forma|manera)\s+correcta\s+(?:es|de)[:\s]*(.*?)(?:\n|$)'; WrongGroup = 0; RightGroup = 1; Example = 'la forma correcta es: X' },
    @{ Pattern = '(?i)correcto[:\s]*(.*?)(?:\n|$)'; WrongGroup = 0; RightGroup = 1; Example = 'correcto: X' },
    @{ Pattern = '(?i)no\s+es\s+as[ií][:\s]*(.*?)(?:\n|$)'; WrongGroup = 0; RightGroup = 1; Example = 'no es así: X' },
    @{ Pattern = '(?i)as[ií]\s+no\s+se\s+hace[:\s]*(.*?)(?:\n|$)'; WrongGroup = 0; RightGroup = 1; Example = 'así no se hace: X' }
)

# --- Extract corrections ---
$captured = @()

# Normalize line endings
$normalized = $content -replace "`r`n", "`n"

# Split into lines for context extraction
$lines = $normalized -split "`n"

# Simple extraction: find lines matching patterns and grab adjacent context
foreach ($line in $lines) {
    $trimmed = $line.Trim()
    if (-not $trimmed) { continue }

    foreach ($p in $patterns) {
        if ($trimmed -match $p.Pattern) {
            $match = $Matches[0]
            $whatWasWrong = $match -replace $p.Pattern, '' -replace '^\s*[:\s]*', ''

            # Get surrounding context (2 lines before, 2 lines after)
            $lineIdx = $lines.IndexOf($line)
            $contextBefore = if ($lineIdx -ge 2) { ($lines[($lineIdx-2)..($lineIdx-1)] -join " | ").Trim() } else { "" }
            $contextAfter = if ($lineIdx -lt $lines.Count - 2) { ($lines[($lineIdx+1)..($lineIdx+2)] -join " | ").Trim() } else { "" }

            $captured += @{
                Wrong = $whatWasWrong.Trim()
                Right = ""
                Example = $match.Trim()
                Context = "$contextBefore >> $contextAfter"
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            }
            break  # one pattern per line to avoid duplicates
        }
    }
}

if ($captured.Count -eq 0) {
    if ($Verbose) { Write-Host "[auto-correction] No corrections detected in transcript" }
    exit 0
}

# --- Deduplicate: skip if same correction written in last 7 days ---
$existing = if (Test-Path $OutputPath) { Get-Content $OutputPath -Raw } else { "" }
$recentWindow = (Get-Date).AddDays(-7)

$newCaptures = @()
foreach ($cap in $captured) {
    # Check if the same example text appears in an auto: true entry within 7 days
    $isDuplicate = $false
    $examplePrefix = $cap.Example.Substring(0, [Math]::Min(40, $cap.Example.Length))

    # Find all occurrences of this example in existing content
    $searchFrom = 0
    while (($idx = $existing.IndexOf($examplePrefix, $searchFrom)) -ge 0) {
        # Check if this occurrence is in an auto:true entry by searching backwards for "auto: true"
        $chunkBefore = $existing.Substring(0, $idx)
        $lastAutoTag = $chunkBefore.LastIndexOf("auto: true")
        $lastDateTag = $chunkBefore.LastIndexOf("date: ")

        if ($lastAutoTag -gt 0 -and $lastDateTag -gt 0) {
            # Extract the date after the date tag (within ~30 chars)
            $dateArea = $existing.Substring($lastDateTag, [Math]::Min(30, $existing.Length - $lastDateTag))
            if ($dateArea -match '(\d{4}-\d{2}-\d{2})') {
                try {
                    $entryDate = [DateTime]::ParseExact($matches[1], 'yyyy-MM-dd', $null)
                    if ($entryDate -ge $recentWindow) {
                        $isDuplicate = $true
                        break
                    }
                } catch {}
            }
        }
        $searchFrom = $idx + 1
    }

    if (-not $isDuplicate) {
        $newCaptures += $cap
    }
}

if ($newCaptures.Count -eq 0) {
    if ($Verbose) { Write-Host "[auto-correction] All $($captured.Count) correction(s) already captured within 7 days" }
    exit 0
}

# --- Write to lessons_learned.md ---
$today = Get-Date -Format 'yyyy-MM-dd'
$entryLines = @()

foreach ($cap in $newCaptures) {
    $entryLines += "---"
    $entryLines += "date: $today"
    $entryLines += "auto: true"
    $entryLines += "source: transcript"
    $entryLines += "timestamp: $($cap.Timestamp)"
    $entryLines += "---"
    $entryLines += ""
    $entryLines += "## [Auto-Capture] Ruddy Correction"
    $entryLines += ""
    $entryLines += "**What was said:** $($cap.Example)"
    $entryLines += ""
    $entryLines += "**Context:** $($cap.Context)"
    $entryLines += ""
    $entryLines += "**What to do instead:** $($cap.Right -join '; ') (review needed)"
    $entryLines += ""
    $entryLines += "**Status:** PENDING_RUDDY_REVIEW"
    $entryLines += ""
    $entryLines += "*This entry was auto-captured by SP-1 auto-correction system. Ruddy should review and confirm or correct.*"
    $entryLines += ""
}

$entryText = $entryLines -join "`n"

try {
    Add-Content -Path $OutputPath -Value $entryText -Encoding UTF8
    Write-Host "[auto-correction] Captured $($newCaptures.Count) new correction(s) to lessons_learned.md"
} catch {
    Log-CaptureError "Failed to write to $OutputPath : $_"
    exit 1
}

exit 0