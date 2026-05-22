$ErrorActionPreference = 'Stop'

$apiKey = $env:OPENCODE_API_KEY
if ([string]::IsNullOrWhiteSpace($apiKey)) {
    $apiKey = [System.Environment]::GetEnvironmentVariable('OPENCODE_API_KEY', 'User')
}

if ([string]::IsNullOrWhiteSpace($apiKey)) {
    Write-Host 'ERROR: OPENCODE_API_KEY is not set (session or user env).'
    exit 1
}

$uri = 'https://opencode.ai/zen/v1/responses'
$headers = @{
    Authorization = "Bearer $apiKey"
}

try {
    $response = Invoke-WebRequest -Uri $uri -Method Get -Headers $headers -UseBasicParsing
    Write-Host "Status: $($response.StatusCode) $($response.StatusDescription)"
    Write-Host "Endpoint: $uri"
    exit 0
}
catch {
    if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
        $statusCode = [int]$_.Exception.Response.StatusCode
        $statusText = $_.Exception.Response.StatusDescription
        Write-Host "Status: $statusCode $statusText"
        Write-Host "Endpoint: $uri"
        exit 0
    }

    Write-Host "Request failed: $($_.Exception.Message)"
    exit 1
}
