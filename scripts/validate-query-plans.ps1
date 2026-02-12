param(
    [string]$ProjectName = "english-app-plan",
    [int]$BackendPort = 18082,
    [string]$ReportPath = "docs/query-plan-report.txt",
    [switch]$KeepContainers
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$composeBase = Join-Path $repoRoot "docker-compose.yml"
$composeSmoke = Join-Path $repoRoot "docker-compose.smoke.yml"
$baseUrl = "http://localhost:$BackendPort"

if (-not $env:GROQ_API_KEY) {
    $env:GROQ_API_KEY = "query-plan-test-key"
}

if (-not [System.IO.Path]::IsPathRooted($ReportPath)) {
    $ReportPath = Join-Path $repoRoot $ReportPath
}
$reportDir = Split-Path -Parent $ReportPath
if ($reportDir -and -not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir | Out-Null
}

function Invoke-Compose {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
    & docker compose -p $ProjectName -f $composeBase -f $composeSmoke @Args
    if ($LASTEXITCODE -ne 0) {
        throw "docker compose failed: $($Args -join ' ')"
    }
}

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

function Wait-ApiReady {
    param([string]$Url, [int]$Attempts = 90, [int]$SleepSeconds = 2)

    for ($i = 1; $i -le $Attempts; $i++) {
        try {
            $response = Invoke-RestMethod -Method Get -Uri "$Url/api"
            if ($response.message -eq "English Learning App API") {
                Write-Host "[query-plan] API ready (attempt $i/$Attempts)"
                return
            }
        } catch {
            # Retry.
        }
        Start-Sleep -Seconds $SleepSeconds
    }

    throw "API not ready after $Attempts attempts: $Url/api"
}

function Invoke-PostgresSql {
    param(
        [Parameter(Mandatory = $true)][string]$Sql,
        [switch]$CaptureOutput
    )

    $execArgs = @(
        "-p", $ProjectName, "-f", $composeBase, "-f", $composeSmoke,
        "exec", "-T", "postgres",
        "psql", "-U", "postgres", "-d", "EnglishApp",
        "-v", "ON_ERROR_STOP=1",
        "-P", "pager=off"
    )

    $result = $Sql | & docker compose @execArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "psql command failed: $($result | Out-String)"
    }

    if ($CaptureOutput) {
        return ($result | Out-String)
    }
}

$seedSql = @"
INSERT INTO users (id, email, password_hash, display_name, user_tag, role, created_at, is_active, is_email_verified, is_premium, is_online)
SELECT gs,
       'plan_user_' || gs || '@local.test',
       'hash',
       'Plan User ' || gs,
       'plan_user_' || gs,
       'USER',
       NOW(),
       TRUE,
       TRUE,
       FALSE,
       FALSE
FROM generate_series(2, 30) gs
ON CONFLICT (id) DO NOTHING;

INSERT INTO words (user_id, english_word, turkish_meaning, learned_date, difficulty, next_review_date, review_count, ease_factor)
SELECT ((gs - 1) % 30) + 1,
       'word_' || gs,
       'anlam_' || gs,
       CURRENT_DATE - ((gs % 365)::int),
       CASE (gs % 3) WHEN 0 THEN 'easy' WHEN 1 THEN 'medium' ELSE 'hard' END,
       CURRENT_DATE - ((gs % 30)::int),
       (gs % 7),
       2.5
FROM generate_series(1, 60000) gs
ON CONFLICT (user_id, english_word) DO NOTHING;

INSERT INTO sentence_practices (user_id, english_sentence, turkish_translation, difficulty, created_date)
SELECT ((gs - 1) % 30) + 1,
       'sentence ' || gs,
       'ceviri ' || gs,
       CASE (((gs / 30)::int) % 3) WHEN 0 THEN 'EASY' WHEN 1 THEN 'MEDIUM' ELSE 'HARD' END,
       CURRENT_DATE - ((gs % 365)::int)
FROM generate_series(1, 100000) gs;

INSERT INTO word_reviews (word_id, review_date, review_type, notes, was_correct, response_time_seconds)
SELECT w.id,
       CURRENT_DATE - (((w.id + n.n) % 120)::int),
       CASE (n.n % 3) WHEN 0 THEN 'daily' WHEN 1 THEN 'weekly' ELSE 'monthly' END,
       'plan-note',
       ((w.id + n.n) % 2 = 0),
       (((w.id + n.n) % 30) + 1)
FROM words w
CROSS JOIN generate_series(1, 3) AS n(n)
WHERE w.id <= 40000;

ANALYZE users;
ANALYZE words;
ANALYZE sentence_practices;
ANALYZE word_reviews;
"@

$planSql = @"
\echo ===== words_user_date_range =====
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, english_word, learned_date
FROM words
WHERE user_id = 1
  AND learned_date BETWEEN CURRENT_DATE - 180 AND CURRENT_DATE
ORDER BY learned_date DESC
LIMIT 100;

\echo ===== words_srs_due =====
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, next_review_date
FROM words
WHERE user_id = 1
  AND next_review_date <= CURRENT_DATE
ORDER BY next_review_date ASC
LIMIT 100;

\echo ===== sentence_practices_user_difficulty =====
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, created_date, difficulty
FROM sentence_practices
WHERE user_id = 1
  AND difficulty = 'HARD'
ORDER BY created_date DESC
LIMIT 100;

\echo ===== word_reviews_word_date_range =====
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, review_date
FROM word_reviews
WHERE word_id = (SELECT MIN(id) FROM words WHERE user_id = 1)
  AND review_date BETWEEN CURRENT_DATE - 90 AND CURRENT_DATE
ORDER BY review_date DESC
LIMIT 100;

\echo ===== word_reviews_by_review_date =====
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, word_id
FROM word_reviews
WHERE review_date = CURRENT_DATE - 7
LIMIT 100;
"@

$expectedIndexes = @(
    "idx_words_user_learned_date",
    "idx_word_user_srs",
    "idx_sentence_practices_user_difficulty_created_date",
    "idx_word_reviews_word_review_date",
    "idx_word_reviews_review_date"
)

$canCompose = $false

try {
    Test-DockerReady
    $canCompose = $true

    Write-Host "[query-plan] Cleaning previous stack and volumes..."
    Invoke-Compose @("down", "--volumes", "--remove-orphans")

    Write-Host "[query-plan] Starting postgres + redis + backend..."
    Invoke-Compose @("up", "-d", "--build", "postgres", "redis", "backend")

    Wait-ApiReady -Url $baseUrl

    Write-Host "[query-plan] Loading synthetic high-volume dataset..."
    Invoke-PostgresSql -Sql $seedSql

    Write-Host "[query-plan] Running EXPLAIN ANALYZE set..."
    $planOutput = Invoke-PostgresSql -Sql $planSql -CaptureOutput
    Set-Content -Path $ReportPath -Value $planOutput -Encoding UTF8
    Write-Host "[query-plan] Report written: $ReportPath"

    $missingIndexes = @()
    foreach ($indexName in $expectedIndexes) {
        if ($planOutput -notmatch [regex]::Escape($indexName)) {
            $missingIndexes += $indexName
        }
    }

    if ($missingIndexes.Count -gt 0) {
        Write-Warning "[query-plan] Missing expected indexes in query plans:"
        $missingIndexes | ForEach-Object { Write-Warning " - $_" }
        throw "Query plan validation failed; see report: $ReportPath"
    }

    Write-Host "[query-plan] SUCCESS: all expected indexes are visible in plans."
} finally {
    if ($canCompose -and -not $KeepContainers) {
        Write-Host "[query-plan] Cleaning stack..."
        try {
            Invoke-Compose @("down", "--volumes", "--remove-orphans")
        } catch {
            Write-Warning "[query-plan] Cleanup failed: $($_.Exception.Message)"
        }
    } elseif ($canCompose) {
        Write-Host "[query-plan] Keeping containers running (ProjectName=$ProjectName)."
    }
}
