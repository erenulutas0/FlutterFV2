# Flyway Checksum Repair Runbook (Non-Prod)

Date: 2026-02-11

Scope:
- One-time checksum reconciliation after normalization of `V001__legacy_gamification.sql`.
- Non-production environments only.

## When To Run

- Flyway validation fails with a checksum mismatch for migration version `1`.
- The environment has a persistent database that previously applied the old `V001` checksum.

## Preconditions

- Docker stack is already up for the target environment.
- `postgres` service is healthy.
- Migration files in `backend/src/main/resources/db/migration` are from the target branch/version.

## Command

From repository root:

```powershell
pwsh -File .\scripts\reconcile-flyway-checksums.ps1 -ProjectName <compose-project-name> -AcknowledgeNonProd
```

If your stack uses multiple compose files:

```powershell
pwsh -File .\scripts\reconcile-flyway-checksums.ps1 `
  -ProjectName <compose-project-name> `
  -ComposeFiles "docker-compose.yml,docker-compose.smoke.yml" `
  -AcknowledgeNonProd
```

Optional DB credentials (if not default):

```powershell
pwsh -File .\scripts\reconcile-flyway-checksums.ps1 `
  -ProjectName <compose-project-name> `
  -DbUser <db-user> `
  -DbPassword <db-password> `
  -Database <db-name> `
  -AcknowledgeNonProd
```

## Expected Result

- Script prints current and updated checksum for version `1`.
- Script ends with:
  - `[flyway-repair] SUCCESS: checksum reconciliation completed.`
- For baselined environments, this is normal:
  - `No version=1 row found. Baseline version is 3 (expected for baselined environments).`

## Post-Check

Run DB readiness and parity checks:

```powershell
pwsh -File .\scripts\run-db-readiness.ps1 -FailOnSkip
pwsh -File .\scripts\check-db-parity.ps1 -ProjectName <compose-project-name>
```

If parity reports `DB=9, expected latest migration=10`, run migrate inside the compose network:

```powershell
docker run --rm --network <compose-project-name>_app-network `
  -v C:/flutter-project-main/backend/src/main/resources/db/migration:/flyway/sql `
  flyway/flyway:12.0.0 `
  -url=jdbc:postgresql://postgres:5432/EnglishApp `
  -user=postgres `
  -password=postgres `
  -locations=filesystem:/flyway/sql `
  migrate
```

## Safety Notes

- Do not run this procedure on production.
- This procedure updates Flyway metadata (`flyway_schema_history`) only; it does not modify migration SQL files.
