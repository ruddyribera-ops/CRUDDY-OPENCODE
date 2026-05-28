param(
    [Parameter(Mandatory=$true)]
    [string]$Action,
    [string]$TaskDescription = "",
    [string]$Agent = "",
    [string]$Files = "[]",
    [string]$Status = "completed",
    [string]$TokensEst = "0",
    [string]$DurationMin = "0",
    [string]$Result = "",
    [string]$Decision = "",
    [string]$Lesson = "",
    [string]$NextStep = "",
    [string]$SessionYamlPath = "$env:USERPROFILE\.config\opencode\memory\session.yaml"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $SessionYamlPath)) {
    Write-Error "session.yaml not found"
    exit 1
}

$yaml = Get-Content -Path $SessionYamlPath -Raw
$yaml = $yaml -replace "`r`n", "`n"

switch ($Action) {
    "add-task" {
        $taskCount = ([regex]::Matches($yaml, "^\s+- id:\s+\d+", [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
        $nextId = $taskCount + 1
        
        $newTask = @"
  - id: $nextId
    description: "$TaskDescription"
    agent: $Agent
    files: $Files
    status: $Status
    tokens_est: $TokensEst
    duration_min: $DurationMin
    result: "$Result"
"@
        # Find end of tasks block and insert
        if ($yaml -match "(?ms)(tasks:\n(?:  .*\n)*)") {
            $block = $matches[1]
            $yaml = $yaml.Replace($block, $block + $newTask)
        }
    }
    "add-decision" {
        if ($yaml -match "decisions:\n") {
            $yaml = $yaml -replace "(decisions:\n)", "`$1  - `"$Decision`"`n"
        }
    }
    "add-lesson" {
        if ($yaml -match "lessons:\n") {
            $yaml = $yaml -replace "(lessons:\n)", "`$1  - `"$Lesson`"`n"
        }
    }
    "add-next-step" {
        if ($yaml -match "next_steps:\n") {
            $yaml = $yaml -replace "(next_steps:\n)", "`$1  - `"$NextStep`"`n"
        }
    }
    "update-state" {
        # Don't reference $StateKey with trailing colon in double quotes - split the regex
        # State keys are pre-defined in session.yaml, we just replace them as literal text
        Write-Host "update-state not supported via CLI - edit session.yaml directly"
    }
}

$yaml = $yaml -replace "`n", "`r`n"
$yaml | Out-File -FilePath $SessionYamlPath -Encoding UTF8
Write-Host "OK session.yaml updated: $Action"
