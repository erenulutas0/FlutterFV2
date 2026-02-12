# Flyway Migration Governance

Date: 2026-02-11

Scope:
- `backend/src/main/resources/db/migration`
- Core schema and data migrations (`V000..V009` and onward)

## Runtime Contract

- Flyway is the single source of truth for schema changes.
- `spring.jpa.hibernate.ddl-auto=validate` must stay enabled.
- `spring.flyway.baseline-on-migrate=false` must stay enabled.
- Applied migration files are immutable.

## Versioning And Naming

- Format: `V###__short_description.sql`
- Current sequence: `V000` to `V009`; next migration must be `V010`.
- Use clear, intent-based names:
  - Good: `V010__add_user_activity_indexes.sql`
  - Bad: `V010__fix.sql`

## Authoring Rules

- Make DDL idempotent where possible:
  - `CREATE INDEX IF NOT EXISTS`
  - guarded `ALTER TABLE`/constraint creation (`IF EXISTS` / catalog checks)
- Keep migrations deterministic:
  - no environment-specific branching
  - no dependence on application runtime state
- Prefer forward-only fixes:
  - add a new migration instead of editing a previously applied one
- Keep scope tight:
  - one migration = one coherent change set

## Data Migration Rules

- Treat existing data as potentially dirty; normalize before adding strict constraints.
- When seeding/fixing IDs, repair sequences after manual inserts.
- For large updates/deletes:
  - re-point child rows first
  - enforce constraints/indexes after cleanup

## Core Vs Community Boundary

- Core migrations go to the shared path above.
- Community modules are currently feature-flagged off; avoid mixing community-only schema churn into core migrations.
- Until dedicated migration grouping is introduced, keep community-impacting changes isolated and explicitly documented in the PR.

## Required Validation Before PR

From repository root:

```powershell
mvn -q clean test -f .\backend\pom.xml
pwsh -File .\scripts\run-db-readiness.ps1 -FailOnSkip
pwsh -File .\scripts\check-core-coverage.ps1 -Threshold 90
```

If migration changes indexes or query-critical paths, also run:

```powershell
pwsh -File .\scripts\validate-query-plans.ps1
```

## Checksum Reconciliation (Non-Prod Only)

If a previously applied migration file was normalized and persistent environments report checksum mismatch, use:

```powershell
pwsh -File .\scripts\reconcile-flyway-checksums.ps1 -ProjectName <compose-project-name> -AcknowledgeNonProd
```

Runbook:
- `docs/FLYWAY_CHECKSUM_REPAIR_RUNBOOK.md`

## PR Checklist (Copy/Paste)

- [ ] Added new migration with correct next version number.
- [ ] Did not modify previously applied migration files.
- [ ] Migration is idempotent/guarded where applicable.
- [ ] `mvn -q clean test -f .\backend\pom.xml` passed.
- [ ] `pwsh -File .\scripts\run-db-readiness.ps1 -FailOnSkip` passed.
- [ ] `pwsh -File .\scripts\check-core-coverage.ps1 -Threshold 90` passed.
- [ ] (`if index/query change`) `pwsh -File .\scripts\validate-query-plans.ps1` passed.
