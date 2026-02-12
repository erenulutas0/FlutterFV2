# Query Plan And Index Tuning Notes

Date: 2026-02-11

Scope:
- `words`
- `sentence_practices`
- `word_reviews`

Method:
- PostgreSQL `EXPLAIN (ANALYZE, BUFFERS)` on migrated schema (`V000..V008`).
- High-volume synthetic data inserted to simulate real usage.
- Compared plans before and after candidate indexes.

## Automated Validation

Run end-to-end validation locally (clean stack + seed + plan checks):

```powershell
pwsh -File .\scripts\validate-query-plans.ps1
```

What it does:
- boots `postgres + redis + backend` with `docker-compose.yml` + `docker-compose.smoke.yml`
- seeds high-volume synthetic rows for `words`, `sentence_practices`, `word_reviews`
- executes `EXPLAIN (ANALYZE, BUFFERS)` for core query shapes
- fails if expected indexes are not observed in the plan output
- writes detailed output to `docs/query-plan-report.txt`

## Validated Existing Index Usage

- `words` user paging and date range queries use `idx_words_user_learned_date`.
- SRS due query uses `idx_word_user_srs`.
- `sentence_practices` user paging and date range queries use `idx_sentence_practices_user_created_date` / `idx_sp_created_date`.
- `word_reviews` by word/date-desc uses `idx_word_reviews_word_review_date`.

## Findings

1. Difficulty-filtered sentence query (`user_id + difficulty + created_date`) used:
- index on `(user_id, created_date)` + post-filter on `difficulty`.
- visible rows removed by filter in plan.

2. Date-only word review query (`review_date = ?`) used:
- `Seq Scan` on `word_reviews` (because existing index starts with `word_id`).

## Applied Tuning

Added migration:
- `backend/src/main/resources/db/migration/V009__add_query_plan_tuning_indexes.sql`

Indexes:
- `idx_sentence_practices_user_difficulty_created_date` on `(user_id, difficulty, created_date DESC)`
- `idx_word_reviews_review_date` on `(review_date)`

## Before/After Snapshot

- `sentence_practices` difficulty query:
  - Before: index scan + filter (`Rows Removed by Filter` present)
  - After: direct index condition on `user_id + difficulty`
  - Execution improved in measured run.

- `word_reviews` by date query:
  - Before: `Seq Scan`
  - After: `Bitmap Index Scan` on `idx_word_reviews_review_date`
  - Execution improved in measured run.

## Latest Automated Run (2026-02-11)

Command:

```powershell
pwsh -File .\scripts\validate-query-plans.ps1
```

Output report:
- `docs/query-plan-report.txt`

Observed index usage:
- `words` date-range: `Index Scan Backward using idx_words_user_learned_date`
- `words` SRS due: `Index Scan using idx_word_user_srs`
- `sentence_practices` difficulty: `Index Scan using idx_sentence_practices_user_difficulty_created_date`
- `word_reviews` word/date: `Index Scan Backward using idx_word_reviews_word_review_date`
- `word_reviews` by date: `Bitmap Index Scan on idx_word_reviews_review_date`
