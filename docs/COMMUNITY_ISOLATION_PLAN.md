# Community Bounded Context Isolation Plan

Date: 2026-02-11

Status:
- Community endpoints are feature-flagged off (`app.features.community.enabled=false`).
- Schema is still shared in core migration chain.

## Goal

Isolate community capabilities (`friendship/chat/social/feed/notification/matchmaking`) from core learning domain so that:
- core deploys and migrates independently,
- community can stay disabled without schema/runtime side effects,
- future re-enable is explicit and controlled.

## Current Coupling Snapshot

- Shared migration chain:
  - community tables exist in `V000__core_schema.sql`.
- Runtime couplings:
  - `WordService` depends on `FeedService` for activity logging.
  - `FeedService` depends on `FriendshipService`.
  - `SocialService` / `FriendshipService` depend on `NotificationService`.
- Packaging:
  - core and community repositories/services/controllers live in same module/package tree.

## Target Architecture

Bounded contexts:
- `core-learning`
  - words, sentences, reviews, SRS, progress, subscription/payment
- `community-social`
  - friendship, feed, posts/comments/likes, chat/messages, notifications, matchmaking

Boundary rule:
- core must not directly depend on community services.
- cross-context interactions go through ports/interfaces with noop core-safe adapters.

## Migration Isolation Strategy

1. Keep `V000..V009` immutable.
2. Introduce separate migration location for community:
   - `classpath:db/migration-community`
3. Use separate Flyway execution for community (conditional):
   - core Flyway always runs
   - community Flyway runs only when community feature is enabled
4. Seed/baseline community schema in new chain:
   - first community migration creates/validates community-owned objects
   - follow-up migrations apply community-only changes

Note:
- Existing shared tables cannot be deleted in-place immediately.
- Initial split is ownership + execution split, then physical schema cleanup in later phase.

## Runtime Isolation Strategy

Phase A (safe decoupling):
- Add core port: `ActivityPublisher` (or similar).
- Replace direct `FeedService` dependency in `WordService` with that port.
- Provide default core adapter (noop or `UserActivity`-only local logger).
- Move community side-effects behind conditional beans.

Phase B (module hygiene):
- Group community controllers/services/repos/entities under `community` package boundary.
- Keep only boundary interfaces visible to core.

Phase C (optional hard split):
- Extract community into separate Spring module/service when operationally justified.

## Proposed Execution Plan

1. Ownership Map
- Produce table-to-context ownership list and mark shared transitional tables.

2. Port-Based Decoupling
- Remove `core -> community` direct service dependencies (start with `WordService -> FeedService`).

3. Dual Flyway Setup
- Add conditional community Flyway configuration and migration path.

4. Community Migration Baseline
- Create initial `migration-community` baseline and validate on clean DB + existing DB.

5. Contract Tests
- Add tests asserting core startup/migrations succeed with community disabled and no community beans loaded.

## Acceptance Criteria

- Core startup passes with community disabled, without initializing community migration chain.
- `run-db-readiness.ps1 -FailOnSkip` remains green.
- Core test suite and coverage gate remain green.
- No direct compile-time dependency from core services to community services.

## Risks And Mitigations

- Risk: hidden runtime coupling causes bean creation failure.
  - Mitigation: explicit port interfaces + `@ConditionalOnProperty` beans + startup contract test.
- Risk: migration drift between shared and isolated chains.
  - Mitigation: ownership map + immutable old chain + forward-only community migrations.
- Risk: operational complexity from dual Flyway.
  - Mitigation: single documented toggle and CI profile checks for both modes.
