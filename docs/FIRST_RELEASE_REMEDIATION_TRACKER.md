# First Release Remediation Tracker

Date: 2026-02-12

## Completed

1. `P0` Fixed Iyzico callback LazyInitialization issue and made callback idempotent.
   Files:
   - `backend/src/main/java/com/ingilizce/calismaapp/repository/PaymentTransactionRepository.java`
   - `backend/src/main/java/com/ingilizce/calismaapp/controller/SubscriptionController.java`

2. Added callback regression coverage (unit + containerized integration).
   Files:
   - `backend/src/test/java/com/ingilizce/calismaapp/controller/SubscriptionControllerTest.java`
   - `backend/src/test/java/com/ingilizce/calismaapp/integration/ContainerizedCoreIntegrationTest.java`

3. Removed Docker smoke stack container-name collision and made smoke ports fully isolated.
   Files:
   - `docker-compose.yml`
   - `docker-compose.smoke.yml`
   - `scripts/smoke-clean-db.ps1`

4. Reduced noisy Redis repository auto-detection logs in app startup.
   Files:
   - `backend/src/main/resources/application.properties`
   - `backend/src/main/resources/application-docker.properties`

5. Made local Docker bring-up resilient when `GROQ_API_KEY` is not set.
   File:
   - `docker-compose.yml`

6. Added explicit DB parity checks for running stacks and integrated parity as a CI gate.
   Files:
   - `scripts/check-db-parity.ps1`
   - `scripts/smoke-clean-db.ps1`
   - `.github/workflows/backend-db-readiness.yml`

7. Hardened integration-test log signal by muting known non-actionable Flyway/Lettuce warnings.
   File:
   - `backend/src/test/java/com/ingilizce/calismaapp/integration/ContainerizedCoreIntegrationTest.java`

8. Normalized legacy friendship DDL/index guards to remove clean-run overlap warnings.
   File:
   - `backend/src/main/resources/db/migration/V001__legacy_gamification.sql`

9. Added non-prod Flyway checksum reconciliation automation + runbook for persistent environments.
   Files:
   - `scripts/reconcile-flyway-checksums.ps1`
   - `docs/FLYWAY_CHECKSUM_REPAIR_RUNBOOK.md`
   - `docs/FLYWAY_MIGRATION_GOVERNANCE.md`

10. Hardened checksum reconciliation to run inside docker network (avoids host `localhost:5432` ambiguity).
    File:
    - `scripts/reconcile-flyway-checksums.ps1`

11. `P0` Made progress/SRS flow user-scoped and removed silent `userId=1` fallback from core learning endpoints.
    Files:
    - `backend/src/main/java/com/ingilizce/calismaapp/service/ProgressService.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/service/SRSService.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/service/WordService.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/service/SentencePracticeService.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/controller/WordController.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/controller/SentencePracticeController.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/controller/ProgressController.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/controller/SRSController.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/repository/WordRepository.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/repository/WordReviewRepository.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/exception/GlobalExceptionHandler.java`

12. Updated test suite for new user-scoped contract and reran full backend test + coverage gate.
    Files:
    - `backend/src/test/java/com/ingilizce/calismaapp/controller/WordControllerTest.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/controller/SentencePracticeControllerTest.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/controller/ProgressControllerTest.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/controller/SRSControllerTest.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/service/WordServiceTest.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/service/SentencePracticeServiceTest.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/service/ProgressServiceTest.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/service/SRSServiceTest.java`

13. Removed fallback user parsing from `SubscriptionController` core endpoints (`pay/verify/demo`) and aligned tests to required-header behavior.
    Files:
    - `backend/src/main/java/com/ingilizce/calismaapp/controller/SubscriptionController.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/controller/SubscriptionControllerTest.java`

14. Removed remaining optional/fallback-style user header handling from community REST controllers and normalized them to typed required header contract.
    Files:
    - `backend/src/main/java/com/ingilizce/calismaapp/controller/ChatController.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/controller/SocialController.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/controller/NotificationController.java`

15. Normalized `UserController` heartbeat header parsing to global bad-request contract (`Long` header binding instead of manual parse + 500 path).
    File:
    - `backend/src/main/java/com/ingilizce/calismaapp/controller/UserController.java`

16. Added/updated regression tests for new header contract and reran full backend validation.
    Files:
    - `backend/src/test/java/com/ingilizce/calismaapp/controller/ChatControllerTest.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/controller/SocialControllerTest.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/controller/NotificationControllerTest.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/controller/UserControllerTest.java`

17. Validation rerun after this batch:
    - `mvn -q "-Dtest=ChatControllerTest,SocialControllerTest,NotificationControllerTest,UserControllerTest" test` -> `PASS`
    - `mvn -q test` -> `PASS`
    - `pwsh -File scripts/check-core-coverage.ps1 -Threshold 90` -> `PASS` (`99.40%`, `2145/2158`, classes=`56`)
    - `pwsh -File scripts/check-db-parity.ps1 -ProjectName flutter-project-main` -> `PASS` (latest successful run in this sprint)

18. Removed socket identity fallback in matchmaking queue join flow.
    File:
    - `backend/src/main/java/com/ingilizce/calismaapp/controller/MatchmakingController.java`
    Behavior:
    - `join_queue` now rejects missing/blank `userId` with `queue_error` instead of silently falling back to `sessionId`.
    Validation:
    - `mvn -q test` -> `PASS`
    - `pwsh -File scripts/check-core-coverage.ps1 -Threshold 90` -> `PASS` (`99.40%`, `2145/2158`, classes=`56`)

19. Added backend Actuator health probes and wired Docker healthcheck/readiness sequencing.
    Files:
    - `backend/pom.xml`
    - `backend/src/main/resources/application.properties`
    - `backend/src/main/resources/application-docker.properties`
    - `backend/Dockerfile`
    - `docker-compose.yml`
    Behavior:
    - Backend exposes `health/info` actuator endpoints with liveness/readiness probe support.
    - Compose backend now has explicit healthcheck (`/actuator/health`) and frontend waits for backend `service_healthy`.

20. Added Redis capacity guardrails in compose runtime.
    File:
    - `docker-compose.yml`
    Behavior:
    - Redis now runs with configurable `maxmemory` and eviction policy:
      - `REDIS_MAXMEMORY` (default `256mb`)
      - `REDIS_MAXMEMORY_POLICY` (default `allkeys-lru`)

21. Validation rerun after healthcheck/guardrail batch:
    - `mvn -q test` -> `PASS`
    - `pwsh -File scripts/check-core-coverage.ps1 -Threshold 90` -> `PASS` (`99.40%`, `2145/2158`, classes=`56`)
    - `pwsh -File scripts/check-db-parity.ps1 -ProjectName flutter-project-main` -> `PASS`
    - `docker compose -f docker-compose.yml config` -> `PASS`

22. Activated chatbot sentence cache read/write flow (Redis-backed) with graceful fallback.
    Files:
    - `backend/src/main/java/com/ingilizce/calismaapp/controller/ChatbotController.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/controller/ChatbotControllerTest.java`
    Behavior:
    - Cache key is normalized (`word + level/length combinations`).
    - Cache hit serves sentences without LLM call (`cached=true`).
    - Cache miss parses LLM response and stores normalized payload with TTL.
    - Cache errors never fail user-facing request flow.

23. Validation rerun after chatbot cache activation:
    - `mvn -q "-Dtest=ChatbotControllerTest" test` -> `PASS`
    - `mvn -q test` -> `PASS`
    - `pwsh -File scripts/check-core-coverage.ps1 -Threshold 90` -> `PASS` (`99.05%`, `2178/2199`, classes=`56`)
    - `pwsh -File scripts/check-db-parity.ps1 -ProjectName flutter-project-main` -> `PASS`

24. Removed `ChatbotController` hardcoded `userId == 1L` subscription bypass.
    Files:
    - `backend/src/main/java/com/ingilizce/calismaapp/controller/ChatbotController.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/controller/ChatbotControllerTest.java`
    Behavior:
    - Subscription checks are now uniformly repository-based for all users.
    - Added regression test to ensure user `1` is also blocked when subscription is inactive.
    Validation:
    - `mvn -q "-Dtest=ChatbotControllerTest" test` -> `PASS`
    - `mvn -q test` -> `PASS`
    - `pwsh -File scripts/check-core-coverage.ps1 -Threshold 90` -> `PASS` (`99.04%`, `2176/2197`, classes=`56`)
    - `pwsh -File scripts/check-db-parity.ps1 -ProjectName flutter-project-main` -> `PASS`

25. Added external AI resilience policy for Groq calls (retry/backoff/timeout budget + circuit-open protection).
    Files:
    - `backend/src/main/java/com/ingilizce/calismaapp/service/GroqService.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/service/GroqServiceTest.java`
    - `backend/src/main/resources/application.properties`
    - `backend/src/main/resources/application-docker.properties`
    Behavior:
    - Transient upstream failures are retried with exponential backoff (bounded by attempt count + timeout budget).
    - Repeated failures open a short circuit window to prevent request storms.
    - Non-retryable vs retryable failure paths are separated.

26. Added chatbot cache observability metrics and exposed `metrics` actuator endpoint.
    Files:
    - `backend/src/main/java/com/ingilizce/calismaapp/controller/ChatbotController.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/controller/ChatbotControllerTest.java`
    - `backend/src/main/resources/application.properties`
    - `backend/src/main/resources/application-docker.properties`
    Behavior:
    - Cache lookup metrics: `chatbot.sentences.cache.lookup.total`, `chatbot.sentences.cache.lookup.latency` (tags: `outcome=hit|miss|error|disabled`)
    - Cache write metric: `chatbot.sentences.cache.write.total` (tags: `outcome=stored|skipped|error`)
    - Actuator exposure now includes `metrics` for runtime inspection.

27. Validation rerun after resilience + cache observability batch:
    - `mvn -q "-Dtest=ChatbotControllerTest,GroqServiceTest" test` -> `PASS`
    - `mvn -q test` -> `PASS`
    - `pwsh -File scripts/check-core-coverage.ps1 -Threshold 90` -> `PASS` (`98.42%`, `2242/2278`, classes=`58`)
    - `pwsh -File scripts/check-db-parity.ps1 -ProjectName flutter-project-main` -> `PASS`

28. Updated Flyway checksum-repair runtime image to current major to remove stale-version warnings.
    Files:
    - `scripts/reconcile-flyway-checksums.ps1`
    - `docs/FLYWAY_CHECKSUM_REPAIR_RUNBOOK.md`
    Validation:
    - `pwsh -File scripts/reconcile-flyway-checksums.ps1 -ProjectName flutter-project-main -AcknowledgeNonProd` -> `PASS` (Flyway `12.0.0`)
    - `pwsh -File scripts/check-db-parity.ps1 -ProjectName flutter-project-main` -> `PASS`

29. Added batch reconciliation runner for all discovered non-prod compose projects and validated local running stack.
    Files:
    - `scripts/reconcile-all-nonprod.ps1`
    Validation:
    - `pwsh -File scripts/reconcile-all-nonprod.ps1` -> `PASS` (`flutter-project-main`: reconcile=`PASS`, parity=`PASS`)

30. Added strict production hardening profile and compose override for secret enforcement + surface reduction.
    Files:
    - `backend/src/main/resources/application-prod.properties`
    - `docker-compose.prod.yml`
    Behavior:
    - Production profile now requires sensitive values without fallback (`SPRING_DATASOURCE_PASSWORD`, `SPRING_DATA_REDIS_PASSWORD`, `GROQ_API_KEY`, `IYZICO_API_*`).
    - Swagger/OpenAPI is disabled in production.
    - Actuator exposure is reduced to `health` only in production.
    - DB/Redis host port mappings are removed in prod compose override.

31. Removed weak Iyzico default credentials from runtime config and aligned property sources.
    Files:
    - `backend/src/main/java/com/ingilizce/calismaapp/config/IyzicoConfig.java`
    - `backend/src/main/resources/application.properties`
    - `backend/src/main/resources/application-docker.properties`
    - `backend/src/test/resources/application.properties`
    Behavior:
    - Runtime no longer embeds sandbox key/secret defaults in code.
    - Non-prod/test values are explicit in property files; production uses required env vars only.

32. Completed structured logging hygiene pass for remaining raw print patterns.
    Files:
    - `backend/src/main/java/com/ingilizce/calismaapp/config/DataLoader.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/controller/AuthController.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/controller/ChatbotController.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/controller/MatchmakingController.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/controller/TtsController.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/service/PiperTtsService.java`
    Behavior:
    - Replaced `System.out.println` / `printStackTrace` usage with SLF4J structured logger calls.

33. Validation rerun after prod-hardening + logging-hygiene batch:
    - `mvn -q test` -> `PASS`
    - `pwsh -File scripts/check-core-coverage.ps1 -Threshold 90` -> `PASS` (`98.39%`, `2204/2240`, classes=`58`)
    - `docker compose -f docker-compose.yml -f docker-compose.prod.yml config` -> `PASS` (validated with required env vars set)
    - `pwsh -File scripts/check-db-parity.ps1 -ProjectName flutter-project-main` -> `BLOCKED` (Docker engine pipe unavailable: `//./pipe/dockerDesktopLinuxEngine`)

34. Re-ran DB parity after Docker recovery and confirmed active stack is consistent.
    Validation:
    - `pwsh -File scripts/check-db-parity.ps1 -ProjectName flutter-project-main` -> `PASS`

35. Added cache metrics dashboard/alert wiring (Prometheus + Grafana provisioning).
    Files:
    - `backend/pom.xml`
    - `backend/src/main/resources/application.properties`
    - `backend/src/main/resources/application-docker.properties`
    - `backend/src/main/resources/application-prod.properties`
    - `docker-compose.monitoring.yml`
    - `monitoring/prometheus/prometheus.yml`
    - `monitoring/prometheus/alerts/cache-alerts.yml`
    - `monitoring/grafana/provisioning/datasources/prometheus.yml`
    - `monitoring/grafana/provisioning/dashboards/dashboards.yml`
    - `monitoring/grafana/dashboards/chatbot-cache-observability.json`
    Behavior:
    - Non-prod actuator exposure now includes `prometheus`; prod profile keeps restricted surface (`health` only).
    - Monitoring overlay starts Prometheus and Grafana on the same compose network and scrapes `backend:8082/actuator/prometheus`.
    - Alert rules added for cache hit ratio, cache error rate, and cache lookup latency.
    - Pre-provisioned Grafana dashboard added for lookup/write outcomes and SLO-focused stat panels.
    Validation:
    - `mvn -q test` -> `PASS`
    - `pwsh -File scripts/check-core-coverage.ps1 -Threshold 90` -> `PASS` (`98.39%`, `2204/2240`, classes=`58`)
    - `pwsh -File scripts/check-db-parity.ps1 -ProjectName flutter-project-main` -> `PASS`
    - `docker compose -f docker-compose.yml -f docker-compose.monitoring.yml config` -> `PASS`
    - `docker run --rm --entrypoint /bin/promtool -v C:/flutter-project-main/monitoring/prometheus:/etc/prometheus prom/prometheus:v2.53.1 check config /etc/prometheus/prometheus.yml` -> `PASS`
    - `docker compose -p flutter-project-main -f docker-compose.yml -f docker-compose.monitoring.yml up -d prometheus grafana` -> `PASS`
    - `GET http://localhost:9090/-/ready` -> `200`
    - `GET http://localhost:3000/api/health` -> `200`
    - `GET http://localhost:9090/api/v1/targets` (`job=backend-actuator`) -> `health=up`
    - `GET http://localhost:3000/api/search?query=Chatbot%20Cache%20Observability` -> dashboard provisioned

36. Finalized Alertmanager receiver/contact-point routing for cache alerts and verified severity-based delivery.
    Files:
    - `docker-compose.monitoring.yml`
    - `monitoring/prometheus/prometheus.yml`
    - `monitoring/alertmanager/alertmanager.yml`
    Behavior:
    - Prometheus alert pipeline now targets in-repo Alertmanager configuration.
    - Severity routes are codified (`critical` -> `/critical`, `warning` -> `/warning`, fallback -> `/default`).
    - Local webhook receiver is wired for deterministic route validation in compose.
    Validation:
    - `docker compose -f docker-compose.yml -f docker-compose.monitoring.yml config` -> `PASS`
    - `docker run --rm --entrypoint /bin/promtool -v C:/flutter-project-main/monitoring/prometheus:/etc/prometheus prom/prometheus:v2.53.1 check config /etc/prometheus/prometheus.yml` -> `PASS`
    - `docker run --rm --entrypoint /bin/amtool -v C:/flutter-project-main/monitoring/alertmanager:/etc/alertmanager prom/alertmanager:v0.27.0 check-config /etc/alertmanager/alertmanager.yml` -> `PASS`
    - `docker compose -p flutter-project-main -f docker-compose.yml -f docker-compose.monitoring.yml up -d alertmanager alert-webhook prometheus grafana` -> `PASS`
    - `GET http://localhost:9093/-/ready` -> `200`
    - `GET http://localhost:18080` -> `200`
    - `GET http://localhost:9090/api/v1/alertmanagers` -> `http://alertmanager:9093/api/v2/alerts`
    - `POST http://localhost:9093/api/v2/alerts` (`severity=warning`) -> webhook log `POST /warning` (`200`)
    - `POST http://localhost:9093/api/v2/alerts` (`severity=critical`) -> webhook log `POST /critical` (`200`)
    - `mvn -q test` -> `PASS`
    - `pwsh -File scripts/check-core-coverage.ps1 -Threshold 90` -> `PASS` (`98.39%`, `2204/2240`, classes=`58`)
    - `pwsh -File scripts/check-db-parity.ps1 -ProjectName flutter-project-main` -> `PASS`

37. Hardened production alert paging binding with fallback-free secret contract.
    Files:
    - `docker-compose.prod.yml`
    Behavior:
    - Production `alertmanager` now requires `ALERTMANAGER_DEFAULT_WEBHOOK_URL`, `ALERTMANAGER_CRITICAL_WEBHOOK_URL`, `ALERTMANAGER_WARNING_WEBHOOK_URL` at compose render time (`:?` contract).
    - Alertmanager runtime config is generated from those environment values at container startup; no repository default webhook endpoints are used in prod override.
    - Local `alert-webhook` service is profile-gated (`nonprod-only`) so it is not started by default in production runs.
    Validation:
    - `docker compose -f docker-compose.yml -f docker-compose.monitoring.yml -f docker-compose.prod.yml config` (with required env vars set) -> `PASS`
    - `docker compose -f docker-compose.yml -f docker-compose.monitoring.yml -f docker-compose.prod.yml config` (missing `ALERTMANAGER_WARNING_WEBHOOK_URL`) -> `FAIL` (expected, hard requirement enforced)
    - `docker compose -p flutter-project-main -f docker-compose.yml -f docker-compose.monitoring.yml -f docker-compose.prod.yml --profile nonprod-only up -d alert-webhook alertmanager` -> `PASS`
    - `GET http://localhost:9093/-/ready` -> `200`
    - `docker compose ... exec alertmanager grep -n 'url:' /tmp/alertmanager.yml` -> generated URLs match bound env values
    - `POST http://localhost:9093/api/v2/alerts` (`severity=warning`) -> webhook log `POST /warning` (`200`)
    - `POST http://localhost:9093/api/v2/alerts` (`severity=critical`) -> webhook log `POST /critical` (`200`)
    - `mvn -q test` -> `PASS`
    - `pwsh -File scripts/check-core-coverage.ps1 -Threshold 90` -> `PASS` (`98.39%`, `2204/2240`, classes=`58`)
    - `pwsh -File scripts/check-db-parity.ps1 -ProjectName flutter-project-main` -> `PASS`
    - Lightweight stress smoke (`GET /actuator/health`, `2000` req @ `50` concurrency) -> `100%` success, `~327 rps`, `p95=12.31ms`
    - Lightweight stress smoke (`GET /api/progress/stats`, `1000` req @ `30` concurrency, `X-User-Id:1`) -> `100%` success, `~208 rps`, `p95=41.68ms`

38. Added reusable production-routing validation + load-smoke scripts and reran non-prod automation checks.
    Files:
    - `scripts/validate-prod-alert-routing.ps1`
    - `scripts/run-http-load-smoke.ps1`
    Validation:
    - `pwsh -File scripts/validate-prod-alert-routing.ps1` (required env vars set) -> `PASS`
    - `scripts/validate-prod-alert-routing.ps1` (missing `ALERTMANAGER_WARNING_WEBHOOK_URL`) -> `FAIL` (expected, fails fast)
    - `pwsh -File scripts/reconcile-all-nonprod.ps1` -> `PASS` (`flutter-project-main`: reconcile=`PASS`, parity=`PASS`)
    - `pwsh -File scripts/run-http-load-smoke.ps1 -Uri http://localhost:8082/actuator/health -TotalRequests 2000 -Concurrency 50` -> `PASS` (`100%`, `~369.05 rps`, `p95=10.12ms`)
    - `pwsh -File scripts/run-http-load-smoke.ps1 -Uri http://localhost:8082/api/progress/stats -TotalRequests 1000 -Concurrency 30 -HeadersJson '{"X-User-Id":"1"}'` -> `PASS` (`100%`, `~302.25 rps`, `p95=19.29ms`)
    - `mvn -q test` -> `PASS`
    - `pwsh -File scripts/check-core-coverage.ps1 -Threshold 90` -> `PASS` (`98.39%`, `2204/2240`, classes=`58`)
    - `pwsh -File scripts/check-db-parity.ps1 -ProjectName flutter-project-main` -> `PASS`

39. Added one-command rollout orchestrator and environment checklist runbook.
    Files:
    - `scripts/verify-rollout.ps1`
    - `docs/PROD_ROLLOUT_SECRET_AND_VERIFY_CHECKLIST.md`
    Validation:
    - `pwsh -File scripts/verify-rollout.ps1 -Mode prod-preflight` -> `PASS`
    - `pwsh -File scripts/verify-rollout.ps1 -Mode nonprod-smoke -ProjectName flutter-project-main -BackendBaseUrl http://localhost:8082` -> `PASS`
    - `pwsh -File scripts/verify-rollout.ps1 -Mode local-gate -ProjectName flutter-project-main` -> `PASS`

40. Stabilized Piper TTS for single-model usage and dynamic status reporting.
    Files:
    - `backend/src/main/java/com/ingilizce/calismaapp/service/PiperTtsService.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/controller/TtsController.java`
    - `backend/src/main/resources/application.properties`
    - `backend/src/main/resources/application-docker.properties`
    - `backend/src/test/java/com/ingilizce/calismaapp/service/PiperTtsServiceTest.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/controller/TtsControllerTest.java`
    Behavior:
    - TTS default model is now configurable via `piper.tts.default-model` (`PIPER_TTS_DEFAULT_MODEL`).
    - Availability no longer hard-codes Amy only; it validates Piper executable + at least one available model in configured/known list.
    - `/api/tts/status` now returns dynamic `voices` from actual model availability instead of a hard-coded list.
    Validation:
    - `mvn -q "-Dtest=PiperTtsServiceTest,TtsControllerTest" test` -> `PASS`
    - `mvn -q test` -> `PASS`
    - `pwsh -File scripts/check-core-coverage.ps1 -Threshold 90` -> `PASS` (`98.33%`, `2231/2269`, classes=`58`)
    - `pwsh -File scripts/check-db-parity.ps1 -ProjectName flutter-project-main` -> `PASS`

41. Re-ran local release gate and non-prod smoke after TTS changes.
    Validation:
    - `pwsh -File scripts/verify-rollout.ps1 -Mode local-gate -ProjectName flutter-project-main` -> `PASS`
    - `pwsh -File scripts/verify-rollout.ps1 -Mode nonprod-smoke -ProjectName flutter-project-main -BackendBaseUrl http://localhost:8082` -> `PASS`
    - Load smoke (`GET /actuator/health`, `2000` req @ `50` concurrency) -> `100%` success, `~312.13 rps`, `p95=117.25ms`
    - Load smoke (`GET /api/progress/stats`, `1000` req @ `30` concurrency, `X-User-Id:1`) -> `100%` success, `~278.08 rps`, `p95=70.83ms`
    - Runtime check `GET /api/tts/status` -> `{"available":false,"voices":["default","amy"]}`
    Interpretation:
    - Single-model fallback logic and test gates are healthy, but Docker runtime still needs a runnable Piper binary path in-container.
## New Findings During Implementation

1. `P2` Persistent non-prod rollout still requires host-by-host execution.
   Evidence:
   - Local host run is passing with batch automation, but the same runbook still needs execution on each persistent non-prod host/environment.
   Impact:
   - If skipped, startup validation may fail on those specific environments.
   Next action:
   - Run `scripts/reconcile-all-nonprod.ps1 -ProjectNames <env1>,<env2>,...` in each persistent non-prod host.

2. `P2` Alert paging destination rollout remains environment-specific.
   Evidence:
   - Production compose now enforces required `ALERTMANAGER_*_WEBHOOK_URL` variables with no fallback, but real endpoint values still need to be provisioned per environment/secret store.
   Impact:
   - Runtime startup is protected from silent fallback, yet paging delivery still depends on correct CI/CD or vault injection of the real URLs.
   Next action:
   - Populate `ALERTMANAGER_*_WEBHOOK_URL` in production secret manager and record the final destination contract.

3. `P2` Dockerized TTS runtime still unavailable.
   Evidence:
   - `GET /api/tts/status` returns `available=false` while dynamic voices are reported.
   - Backend logs indicate `Cannot run program "piper": error=2` in container.
   Impact:
   - TTS endpoint remains unavailable in current Docker runtime despite model selection improvements.
   Next action:
   - Either package a Linux Piper binary into backend image and set `PIPER_TTS_PATH`, or run backend on host with Windows Piper executable.

## Ordered Next Steps

1. Execute `scripts/reconcile-all-nonprod.ps1` on each persistent non-prod host with explicit project list and record results.
2. Run `pwsh -File scripts/verify-rollout.ps1 -Mode nonprod-smoke -ProjectName <project> -BackendBaseUrl <backend-url>` on each non-prod environment and record output.
3. Populate `ALERTMANAGER_*_WEBHOOK_URL` secrets in each production environment, then run `pwsh -File scripts/verify-rollout.ps1 -Mode prod-preflight`.
4. Close Docker Piper runtime gap (`PIPER_TTS_PATH` + executable availability) and re-check `GET /api/tts/status` for `available=true`.
5. Keep all subsequent schema fixes forward-only (`V011+`) to avoid new checksum drift.

