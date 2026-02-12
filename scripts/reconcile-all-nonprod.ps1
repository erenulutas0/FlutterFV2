param(
    [string[]]$ProjectNames = @(),
    [switch]$ContinueOnError,
    [switch]$AllowProdName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$reconcileScript = Join-Path $PSScriptRoot "reconcile-flyway-checksums.ps1"
$parityScript = Join-Path $PSScriptRoot "check-db-parity.ps1"

if (-not (Test-Path $reconcileScript)) {
    throw "Missing script: $reconcileScript"
}
if (-not (Test-Path $parityScript)) {
    throw "Missing script: $parityScript"
}

function Get-ComposeProjectsFromRunningContainers {
    $lines = & docker ps --format '{{.Label "com.docker.compose.project"}}'
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to discover running docker compose projects."
    }

    return @(
        $lines |
            ForEach-Object { $_.ToString().Trim() } |
            Where-Object { $_ -ne "" } |
            Sort-Object -Unique
    )
}

function Test-ProdLikeName {
    param([string]$ProjectName)
    return ($ProjectName -match "(^|[-_])(prod|production)([-_]|$)")
}

[array]$targets = @($ProjectNames | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" } | Sort-Object -Unique)
if ($targets.Count -eq 0) {
    [array]$targets = @(Get-ComposeProjectsFromRunningContainers)
}

if ($targets.Count -eq 0) {
    throw "No compose project detected. Start target stack(s) or pass -ProjectNames explicitly."
}

Write-Host "[batch-reconcile] Target projects: $($targets -join ', ')"

$results = New-Object System.Collections.Generic.List[object]
$failed = $false

foreach ($project in $targets) {
    if ((-not $AllowProdName) -and (Test-ProdLikeName -ProjectName $project)) {
        Write-Warning "[batch-reconcile] Skipping '$project' (name looks production-like). Use -AllowProdName to override."
        $results.Add([PSCustomObject]@{
                Project = $project
                Reconcile = "SKIPPED"
                Parity = "SKIPPED"
                Note = "Production-like name"
            })
        continue
    }

    $reconcileOk = $false
    $parityOk = $false
    $note = ""

    try {
        Write-Host "[batch-reconcile] Running checksum reconcile for '$project'..."
        & pwsh -File $reconcileScript -ProjectName $project -AcknowledgeNonProd
        if ($LASTEXITCODE -ne 0) {
            throw "reconcile script failed with exit code $LASTEXITCODE"
        }
        $reconcileOk = $true

        Write-Host "[batch-reconcile] Running db parity for '$project'..."
        & pwsh -File $parityScript -ProjectName $project
        if ($LASTEXITCODE -ne 0) {
            throw "db parity script failed with exit code $LASTEXITCODE"
        }
        $parityOk = $true
    } catch {
        $failed = $true
        $note = $_.Exception.Message
        Write-Warning "[batch-reconcile] Project '$project' failed: $note"
        if (-not $ContinueOnError) {
            $results.Add([PSCustomObject]@{
                    Project = $project
                    Reconcile = $(if ($reconcileOk) { "PASS" } else { "FAIL" })
                    Parity = $(if ($parityOk) { "PASS" } else { "FAIL" })
                    Note = $note
                })
            break
        }
    }

    if ($note -eq "") {
        $note = "OK"
    }

    $results.Add([PSCustomObject]@{
            Project = $project
            Reconcile = $(if ($reconcileOk) { "PASS" } else { "FAIL" })
            Parity = $(if ($parityOk) { "PASS" } else { "FAIL" })
            Note = $note
        })
}

Write-Host "`n[batch-reconcile] Summary"
$results | Format-Table -AutoSize

if ($failed) {
    throw "[batch-reconcile] One or more projects failed."
}

Write-Host "[batch-reconcile] SUCCESS: all targeted non-prod projects passed."
