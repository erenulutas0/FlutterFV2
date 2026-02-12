param(
    [switch]$SkipSmokeFallback,
    [switch]$KeepContainers,
    [switch]$FailOnSkip
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$backendDir = Join-Path $repoRoot "backend"
$surefireReport = Join-Path $backendDir "target\surefire-reports\com.ingilizce.calismaapp.integration.ContainerizedCoreIntegrationTest.txt"
$smokeScript = Join-Path $PSScriptRoot "smoke-clean-db.ps1"

function Test-DockerReady {
    $dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
    if ($null -eq $dockerCmd) {
        throw "Docker CLI not found in PATH."
    }

    $null = & docker info --format "{{.ServerVersion}}" 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker daemon is not reachable. Start Docker Desktop and retry."
    }
}

if ($env:DOCKER_HOST) {
    Write-Warning "[db-readiness] Ignoring inherited DOCKER_HOST=$($env:DOCKER_HOST) for Testcontainers autodiscovery."
    Remove-Item Env:DOCKER_HOST -ErrorAction SilentlyContinue
}

Test-DockerReady

Write-Host "[db-readiness] Running Testcontainers core integration test..."
Push-Location $backendDir
try {
    & mvn -q clean "-Dtest=ContainerizedCoreIntegrationTest" test
    if ($LASTEXITCODE -ne 0) {
        throw "ContainerizedCoreIntegrationTest failed."
    }
} finally {
    Pop-Location
}

if (-not (Test-Path $surefireReport)) {
    throw "Surefire report not found: $surefireReport"
}

$reportText = Get-Content $surefireReport -Raw
$skipped = 0
if ($reportText -match "Skipped:\s*(\d+)") {
    $skipped = [int]$matches[1]
}

if ($skipped -eq 0) {
    Write-Host "[db-readiness] SUCCESS: Testcontainers integration test executed (no skip)."
    return
}

Write-Warning "[db-readiness] Testcontainers test skipped ($skipped)."
if ($FailOnSkip) {
    throw "Testcontainers integration test was skipped ($skipped) and -FailOnSkip is enabled."
}
if ($SkipSmokeFallback) {
    Write-Warning "[db-readiness] Smoke fallback disabled by flag."
    return
}

if (-not (Test-Path $smokeScript)) {
    throw "Smoke fallback script not found: $smokeScript"
}

Write-Host "[db-readiness] Running docker-compose smoke fallback..."
if ($KeepContainers) {
    & pwsh -File $smokeScript -KeepContainers
} else {
    & pwsh -File $smokeScript
}

if ($LASTEXITCODE -ne 0) {
    throw "Smoke fallback failed."
}

Write-Host "[db-readiness] SUCCESS: smoke fallback passed."
