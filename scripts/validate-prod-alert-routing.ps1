param(
    [switch]$SkipComposeConfig
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$requiredVars = @(
    "POSTGRES_PASSWORD",
    "SPRING_DATA_REDIS_PASSWORD",
    "APP_CORS_ALLOWED_ORIGINS",
    "IYZICO_API_KEY",
    "IYZICO_API_SECRET",
    "IYZICO_API_BASE_URL",
    "GROQ_API_KEY",
    "ALERTMANAGER_DEFAULT_WEBHOOK_URL",
    "ALERTMANAGER_CRITICAL_WEBHOOK_URL",
    "ALERTMANAGER_WARNING_WEBHOOK_URL"
)

$missing = New-Object System.Collections.Generic.List[string]
foreach ($name in $requiredVars) {
    $value = [Environment]::GetEnvironmentVariable($name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        $missing.Add($name)
    }
}

if ($missing.Count -gt 0) {
    throw "[prod-alert-routing] Missing required env vars: $($missing -join ', ')"
}

Write-Host "[prod-alert-routing] Required env vars are present."

if ($SkipComposeConfig) {
    Write-Host "[prod-alert-routing] Skipping compose config validation by request."
    Write-Host "[prod-alert-routing] SUCCESS"
    return
}

$composeBase = Join-Path $repoRoot "docker-compose.yml"
$composeMonitoring = Join-Path $repoRoot "docker-compose.monitoring.yml"
$composeProd = Join-Path $repoRoot "docker-compose.prod.yml"

& docker compose -f $composeBase -f $composeMonitoring -f $composeProd config | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "[prod-alert-routing] docker compose config failed."
}

Write-Host "[prod-alert-routing] docker compose config passed."
Write-Host "[prod-alert-routing] SUCCESS"
