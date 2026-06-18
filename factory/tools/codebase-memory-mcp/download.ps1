# Download codebase-memory-mcp binary
# Run this once after cloning to get the MCP server binary.

$repo = "DeusData/codebase-memory-mcp"
$releaseUrl = "https://api.github.com/repos/$repo/releases/latest"
$binaryName = "codebase-memory-mcp.exe"
$outDir = "factory/tools/codebase-memory-mcp"

Write-Host "Downloading codebase-memory-mcp binary..."
Write-Host "Release URL: $releaseUrl"
Write-Host "Destination: $outDir/$binaryName"
Write-Host ""

try {
    $release = Invoke-RestMethod -Uri $releaseUrl -ErrorAction Stop
    $asset = $release.assets | Where-Object { $_.name -eq $binaryName } | Select-Object -First 1

    if (-not $asset) {
        Write-Host "ERROR: Binary '$binaryName' not found in latest release."
        Write-Host "Available assets:"
        $release.assets | ForEach-Object { Write-Host "  - $($_.name)" }
        exit 1
    }

    if (-not (Test-Path $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }

    Write-Host "Downloading from: $($asset.browser_download_url)"
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile "$outDir/$binaryName" -ErrorAction Stop

    $size = (Get-Item "$outDir/$binaryName").Length / 1MB
    Write-Host ""
    Write-Host "SUCCESS: Downloaded $($asset.name) ($([math]::Round($size, 1)) MB)"
    Write-Host "Location: $outDir/$binaryName"
} catch {
    Write-Host "ERROR: Failed to download binary."
    Write-Host "Details: $_"
    Write-Host ""
    Write-Host "Alternative: Download manually from:"
    Write-Host "  https://github.com/DeusData/codebase-memory-mcp/releases"
    exit 1
}