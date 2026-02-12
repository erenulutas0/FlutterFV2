# Prod Rollout Secret and Verify Checklist

Date: 2026-02-12

## 1) Environment Secret Checklist

Minimum required secrets for prod/stage compose rendering and runtime:

- `POSTGRES_PASSWORD`
- `SPRING_DATA_REDIS_PASSWORD`
- `IYZICO_API_KEY`
- `IYZICO_API_SECRET`
- `IYZICO_API_BASE_URL`
- `GROQ_API_KEY`
- `ALERTMANAGER_DEFAULT_WEBHOOK_URL`
- `ALERTMANAGER_CRITICAL_WEBHOOK_URL`
- `ALERTMANAGER_WARNING_WEBHOOK_URL`

Rules:

- Do not leave any of the values empty.
- `ALERTMANAGER_*_WEBHOOK_URL` values must point to real environment-specific destinations.
- Production and stage must use different paging endpoints.

## 2) One-Command Verification Blocks

Run from repository root (`C:\flutter-project-main`).

### A) Prod Preflight (Secret Contract + Compose Render)

```powershell
pwsh -File .\scripts\verify-rollout.ps1 -Mode prod-preflight
```

Notes:

- Requires the 9 env vars above to be already exported/injected.
- Fails fast if any required secret is missing.

### B) Non-Prod Rollout Smoke (Reconcile + Load)

```powershell
pwsh -File .\scripts\verify-rollout.ps1 -Mode nonprod-smoke -ProjectName flutter-project-main -BackendBaseUrl http://localhost:8082
```

What it runs:

- `scripts/reconcile-all-nonprod.ps1`
- `scripts/run-http-load-smoke.ps1` on `/actuator/health`
- `scripts/run-http-load-smoke.ps1` on `/api/progress/stats` (`X-User-Id: 1`)

### C) Local Release Gate

```powershell
pwsh -File .\scripts\verify-rollout.ps1 -Mode local-gate -ProjectName flutter-project-main
```

What it runs:

- `mvn -q test`
- `scripts/check-core-coverage.ps1 -Threshold 90`
- `scripts/check-db-parity.ps1`

### D) Full Batch (All Three)

```powershell
pwsh -File .\scripts\verify-rollout.ps1 -Mode full -ProjectName flutter-project-main -BackendBaseUrl http://localhost:8082
```

## 3) Rollout Done Criteria

- Prod preflight passes with real secret values.
- Non-prod smoke passes with `100%` success on both endpoints.
- Local release gate passes (`test`, `coverage`, `db parity`).
