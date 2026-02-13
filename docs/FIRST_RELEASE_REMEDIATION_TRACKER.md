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

42. Started security phase with production CORS whitelist hardening.
    Files:
    - `backend/src/main/java/com/ingilizce/calismaapp/config/CorsConfig.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/config/CorsProperties.java`
    - `backend/src/main/resources/application-prod.properties`
    - `docker-compose.prod.yml`
    - `scripts/validate-prod-alert-routing.ps1`
    - `docs/PROD_ROLLOUT_SECRET_AND_VERIFY_CHECKLIST.md`
    - `backend/src/test/java/com/ingilizce/calismaapp/config/CorsConfigTest.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/config/CorsPropertiesTest.java`
    Behavior:
    - Added `app.cors.strict-origin-validation` guard to reject wildcard, loopback, empty, unresolved placeholder, and non-http(s) origins when strict mode is enabled.
    - Production profile now enables strict CORS validation and binds `app.cors.allowed-origins` to `APP_CORS_ALLOWED_ORIGINS`.
    - Production compose now requires `APP_CORS_ALLOWED_ORIGINS` (`:?` contract) for fail-fast startup safety.
    - Prod preflight script and rollout checklist were updated from 9 to 10 required environment variables.
    Validation:
    - `mvn -q "-Dtest=CorsConfigTest,CorsPropertiesTest" test` -> `PASS`
    - `pwsh -File scripts/verify-rollout.ps1 -Mode prod-preflight` (all required env set, including `APP_CORS_ALLOWED_ORIGINS`) -> `PASS`
    - `pwsh -File scripts/verify-rollout.ps1 -Mode local-gate -ProjectName flutter-project-main` -> `PASS`
    - Coverage gate -> `PASS` (`98.21%`, `2246/2287`, classes=`58`)
    - DB parity -> `PASS`

43. Added production security headers hardening filter (HTTP response headers baseline).
    Files:
    - `backend/src/main/java/com/ingilizce/calismaapp/config/SecurityHeadersProperties.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/config/SecurityHeadersFilter.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/config/SecurityHeadersConfig.java`
    - `backend/src/main/resources/application-prod.properties`
    - `backend/src/test/java/com/ingilizce/calismaapp/config/SecurityHeadersPropertiesTest.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/config/SecurityHeadersFilterTest.java`
    Behavior:
    - Added centralized filter that can emit:
      - `X-Content-Type-Options: nosniff`
      - `X-Frame-Options: DENY`
      - `Referrer-Policy`
      - `Permissions-Policy`
      - `Content-Security-Policy`
      - `Strict-Transport-Security` (only for secure / forwarded-https requests)
    - Feature is controlled by `app.security.headers.*`; enabled in prod profile.
    Validation:
    - `mvn -q "-Dtest=CorsConfigTest,CorsPropertiesTest,SecurityHeadersFilterTest,SecurityHeadersPropertiesTest" test` -> `PASS`
    - `pwsh -File scripts/verify-rollout.ps1 -Mode local-gate -ProjectName flutter-project-main` -> `PASS`
    - Coverage gate -> `PASS` (`98.26%`, `2310/2351`, classes=`61`)
    - DB parity -> `PASS`

44. Added auth brute-force protection (rate-limit) for login/register endpoints.
    Files:
    - `backend/src/main/java/com/ingilizce/calismaapp/config/AuthRateLimitProperties.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/service/AuthRateLimitService.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/controller/AuthController.java`
    - `backend/src/main/resources/application.properties`
    - `backend/src/main/resources/application-docker.properties`
    - `backend/src/main/resources/application-prod.properties`
    - `backend/src/test/java/com/ingilizce/calismaapp/controller/AuthControllerUnitTest.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/service/AuthRateLimitServiceTest.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/config/AuthRateLimitPropertiesTest.java`
    Behavior:
    - `POST /api/auth/login` now enforces combined principal+IP throttling and returns `429` + `Retry-After` on block.
    - `POST /api/auth/register` now enforces IP throttling and returns `429` + `Retry-After` on block.
    - Failed auth attempts are counted; successful auth resets relevant counters.
    - Added configurable knobs under `app.security.auth-rate-limit.*` with stricter production defaults.
    Validation:
    - `mvn -q "-Dtest=AuthControllerUnitTest,AuthRateLimitServiceTest,AuthRateLimitPropertiesTest" test` -> `PASS`
    - `pwsh -File scripts/verify-rollout.ps1 -Mode local-gate -ProjectName flutter-project-main` -> `PASS`
    - `pwsh -File scripts/verify-rollout.ps1 -Mode prod-preflight` -> `PASS`
    - Coverage gate -> `PASS` (`97.73%`, `2449/2506`, classes=`65`)
    - DB parity -> `PASS`

45. Added CI vulnerability scanning workflow for dependency and filesystem CVEs.
    Files:
    - `.github/workflows/security-scan.yml`
    Behavior:
    - Pull requests now run `actions/dependency-review-action` (fails on high+ severity dependency risks).
    - Push/PR now run Trivy filesystem scan (`HIGH,CRITICAL`) and publish SARIF to GitHub Security tab.
    Validation:
    - YAML added and committed to workflow directory.
    - Local release gate rerun after workflow addition:
      - `pwsh -File scripts/verify-rollout.ps1 -Mode local-gate -ProjectName flutter-project-main` -> `PASS`
      - Coverage gate -> `PASS` (`97.73%`, `2449/2506`, classes=`65`)
      - DB parity -> `PASS`
    - `pwsh -File scripts/verify-rollout.ps1 -Mode prod-preflight` -> `PASS`
    Notes:
    - Workflow runtime result will be visible on next GitHub `push`/`pull_request` execution.

46. Migrated auth rate-limit enforcement to Redis-backed state with safe local fallback.
    Files:
    - `backend/src/main/java/com/ingilizce/calismaapp/service/AuthRateLimitService.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/config/AuthRateLimitProperties.java`
    - `backend/src/main/resources/application.properties`
    - `backend/src/main/resources/application-docker.properties`
    - `backend/src/main/resources/application-prod.properties`
    - `backend/src/test/java/com/ingilizce/calismaapp/service/AuthRateLimitServiceRedisTest.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/service/AuthRateLimitServiceTest.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/config/AuthRateLimitPropertiesTest.java`
    Behavior:
    - Auth throttling now uses Redis keyspace (`auth:rl:cnt:*`, `auth:rl:block:*`) for distributed consistency across replicas.
    - Added `app.security.auth-rate-limit.redis-enabled` toggle (default `true`).
    - If Redis rate-limit path fails at runtime, service degrades to existing in-memory guard and logs one-time warning until recovery.
    Validation:
    - `mvn -q "-Dtest=AuthControllerUnitTest,AuthRateLimitServiceTest,AuthRateLimitServiceRedisTest,AuthRateLimitPropertiesTest" test` -> `PASS`
    - `pwsh -File scripts/verify-rollout.ps1 -Mode local-gate -ProjectName flutter-project-main` -> `PASS`
    - `pwsh -File scripts/verify-rollout.ps1 -Mode prod-preflight` -> `PASS`
    - Coverage gate -> `PASS` (`96.76%`, `2510/2594`, classes=`65`)
    - DB parity -> `PASS`

47. Added observability + alerting for auth rate-limit Redis fallback mode.
    Files:
    - `backend/src/main/java/com/ingilizce/calismaapp/service/AuthRateLimitService.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/service/AuthRateLimitServiceRedisTest.java`
    - `monitoring/prometheus/alerts/cache-alerts.yml`
    Behavior:
    - Added Redis fallback observability metrics:
      - `auth.rate.limit.redis.fallback.active` (gauge, `1` while Redis path is degraded to local fallback)
      - `auth.rate.limit.redis.failure.total{operation=*}` (counter)
      - `auth.rate.limit.redis.fallback.transition.total{state=activated|recovered}` (counter)
    - Added Prometheus alerts:
      - `AuthRateLimitRedisFallbackActive` (`critical`, fallback active for `2m+`)
      - `AuthRateLimitRedisFailuresDetected` (`warning`, `>=3` failures in `5m`)
    Validation:
    - `mvn -q "-Dtest=AuthRateLimitServiceTest,AuthRateLimitServiceRedisTest" test` -> `PASS`
    - `docker run --rm --entrypoint /bin/promtool -v C:/flutter-project-main/monitoring/prometheus:/etc/prometheus prom/prometheus:v2.53.1 check config /etc/prometheus/prometheus.yml` -> `PASS`

48. Closed Dockerized Piper runtime executable gap for backend containers.
    Files:
    - `backend/Dockerfile`
    - `backend/src/main/resources/application-docker.properties`
    - `docker-compose.yml`
    - `docker-compose.prod.yml`
    Behavior:
    - Backend runtime image now installs Linux Piper binary during Docker build (`/opt/piper/piper`).
    - Docker profile now defaults `piper.tts.path` to `/opt/piper/piper` (can still be overridden via `PIPER_TTS_PATH`).
    - Compose backend environment now wires `PIPER_TTS_PATH` and `PIPER_TTS_DEFAULT_MODEL` explicitly.
    - Piper model bind mount became host-path configurable via `PIPER_MODEL_HOST_PATH` (default remains `C:/piper`).
    Validation:
    - `docker compose -f docker-compose.yml config` -> `PASS`
    - `docker compose -f docker-compose.yml -f docker-compose.monitoring.yml -f docker-compose.prod.yml config` (required env set) -> `PASS`
    - `docker build -f backend/Dockerfile backend -t flutter-project-main-backend:piper-check` -> `PASS`
    - `docker run --rm --entrypoint /opt/piper/piper flutter-project-main-backend:piper-check --version` -> `PASS` (`1.2.0`)
    - `mvn -q "-Dtest=PiperTtsServiceTest,TtsControllerTest" test` -> `BLOCKED` in sandbox (`repo.maven.apache.org` network denied)

49. Added staging smoke automation for security headers + strict CORS behavior.
    Files:
    - `scripts/smoke-security-cors-headers.ps1`
    - `scripts/verify-rollout.ps1`
    - `docs/PROD_ROLLOUT_SECRET_AND_VERIFY_CHECKLIST.md`
    Behavior:
    - New script validates:
      - Allowed-origin CORS preflight (`Access-Control-Allow-Origin`/`Credentials`)
      - Disallowed-origin preflight rejection behavior
      - Security headers baseline (`nosniff`, `DENY`, `Referrer-Policy`, `Permissions-Policy`, `CSP`, `HSTS`)
    - `verify-rollout.ps1 -Mode nonprod-smoke` now supports optional `-SecuritySmokeAllowedOrigin` to run this check in the same batch.
    Validation:
    - PowerShell parser check for both scripts -> `PASS`
      - `scripts/smoke-security-cors-headers.ps1`
      - `scripts/verify-rollout.ps1`

50. Executed live staging-like security smoke on isolated prod-profile compose stack.
    Validation:
    - `docker compose -p flutter-project-main-stage-smoke -f docker-compose.yml -f docker-compose.monitoring.yml -f docker-compose.prod.yml up -d --build postgres redis backend` -> `PASS`
    - `pwsh -File scripts/smoke-security-cors-headers.ps1 -BaseUrl http://localhost:18082 -AllowedOrigin https://staging.example.com -DisallowedOrigin https://evil.example.com` -> `PASS`
      - allowed-origin preflight -> `200`
      - disallowed-origin preflight -> `403`
      - security headers probe (`nosniff`, `DENY`, `Referrer-Policy`, `Permissions-Policy`, `CSP`, `HSTS`) -> `200` + expected headers
    - `docker run --rm --entrypoint /opt/piper/piper flutter-project-main-backend:piper-check --version` -> `PASS` (`1.2.0`)
    - `docker compose ... down` (`flutter-project-main-stage-smoke`) -> `PASS`

51. Made auth rate-limit Redis outage policy configurable (fail-open/fail-closed).
    Files:
    - `backend/src/main/java/com/ingilizce/calismaapp/config/AuthRateLimitProperties.java`
    - `backend/src/main/java/com/ingilizce/calismaapp/service/AuthRateLimitService.java`
    - `backend/src/main/resources/application.properties`
    - `backend/src/main/resources/application-docker.properties`
    - `backend/src/main/resources/application-prod.properties`
    - `backend/src/test/java/com/ingilizce/calismaapp/config/AuthRateLimitPropertiesTest.java`
    - `backend/src/test/java/com/ingilizce/calismaapp/service/AuthRateLimitServiceRedisTest.java`
    - `docker-compose.yml`
    - `docker-compose.prod.yml`
    - `monitoring/prometheus/alerts/cache-alerts.yml`
    Behavior:
    - New policy knobs:
      - `app.security.auth-rate-limit.redis-fallback-mode=memory|deny`
      - `app.security.auth-rate-limit.redis-failure-block-seconds`
    - Default remains availability-first (`memory`) to preserve current behavior.
    - `deny` mode enforces fail-closed behavior during Redis degradation and emits:
      - `auth.rate.limit.redis.fail.closed.block.total{operation=*}`
    - Added alert:
      - `AuthRateLimitFailClosedBlocking` (`critical`, any fail-closed block activity in 5m window)
    Validation:
    - `docker run --rm -v C:/flutter-project-main/backend:/app -w /app maven:3.9.6-eclipse-temurin-17-alpine mvn -q "-Dtest=AuthRateLimitServiceTest,AuthRateLimitServiceRedisTest,AuthRateLimitPropertiesTest,AuthControllerUnitTest" test` -> `PASS`
    - `docker compose -f docker-compose.yml config` -> `PASS`
    - `docker compose -f docker-compose.yml -f docker-compose.monitoring.yml -f docker-compose.prod.yml config` (required env set) -> `PASS`
    - `docker run --rm --entrypoint /bin/promtool -v C:/flutter-project-main/monitoring/prometheus:/etc/prometheus prom/prometheus:v2.53.1 check config /etc/prometheus/prometheus.yml` -> `PASS`

52. Completed local vulnerability triage/remediation pass for HIGH/CRITICAL findings.
    Files:
    - `backend/pom.xml`
    Behavior:
    - Upgraded security-relevant dependency baseline:
      - Spring Boot parent `3.2.1` -> `3.4.5`
      - `spring-framework.version=6.2.11`
      - `tomcat.version=10.1.45`
      - `postgresql.version=42.7.2`
    Validation:
    - Local Trivy scan (initial): `17` findings (`HIGH=15`, `CRITICAL=2`)
      - `docker run --rm -v C:/flutter-project-main:/workspace aquasec/trivy:0.58.1 fs --severity HIGH,CRITICAL --ignore-unfixed --no-progress /workspace`
    - Local Trivy scan (after remediation): no HIGH/CRITICAL findings (`exit-code` stayed `0` with `--exit-code 1`)
      - `docker run --rm -v C:/flutter-project-main:/workspace aquasec/trivy:0.58.1 fs --scanners vuln --severity HIGH,CRITICAL --ignore-unfixed --no-progress --exit-code 1 /workspace`
    - Targeted auth/security regression:
      - `docker run --rm -v C:/flutter-project-main/backend:/app -w /app maven:3.9.6-eclipse-temurin-17-alpine mvn -q "-Dtest=AuthRateLimitServiceTest,AuthRateLimitServiceRedisTest,AuthRateLimitPropertiesTest,AuthControllerUnitTest" test` -> `PASS`
    - Backend image build after dependency updates:
      - `docker build -f backend/Dockerfile backend -t flutter-project-main-backend:security-refresh` -> `PASS`

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

3. `P2` Dockerized TTS model mount remains environment-specific.
   Evidence:
   - Backend image now includes Linux Piper executable, but model files are still expected from bind mount (`/piper`).
   - Compose default host path is Windows-specific (`C:/piper`) unless `PIPER_MODEL_HOST_PATH` override is provided.
   Impact:
   - Non-Windows or CI hosts can still report `available=false` unless a valid model directory is mounted.
   Next action:
   - Set `PIPER_MODEL_HOST_PATH` per environment and verify `GET /api/tts/status` returns `available=true`.

4. `P2` Production rollout now has an extra required env var for CORS whitelist.
   Evidence:
   - `docker-compose.prod.yml` and `validate-prod-alert-routing.ps1` now enforce `APP_CORS_ALLOWED_ORIGINS`.
   Impact:
   - Existing prod/stage pipelines that do not inject this variable will fail fast at preflight/render time.
   Next action:
   - Add `APP_CORS_ALLOWED_ORIGINS` to all production/stage secret stores and deployment manifests.

5. `P2` Security headers are profile-driven and currently active on prod profile only.
   Evidence:
   - `app.security.headers.enabled=true` is defined in `application-prod.properties`.
   Impact:
   - Non-prod runs won't automatically reflect these headers unless profile/env enables them.
   Next action:
   - Enable headers in staging for browser-level pre-prod validation before production rollout.

6. `P3` GitHub-hosted vulnerability workflow result is still pending.
   Evidence:
   - Local equivalent Trivy scan is now clean for HIGH/CRITICAL, but the GitHub Actions run has not yet executed for this commit set.
   Impact:
   - Remote policy gates (dependency-review + SARIF upload + repository security policies) are not yet confirmed.
   Next action:
   - Push current branch and validate `security-scan` workflow result matches local clean baseline.

7. `P2` Auth rate-limit fallback mode rollout is pending per environment.
   Evidence:
   - Runtime now supports both `memory` (fail-open) and `deny` (fail-closed) via config.
   - Compose defaults remain `memory`; environment-specific override has not yet been applied.
   Impact:
   - Policy is codified but final enforcement posture is not yet rolled out per environment.
   Next action:
   - Set `APP_SECURITY_AUTH_RATE_LIMIT_REDIS_FALLBACK_MODE` and `APP_SECURITY_AUTH_RATE_LIMIT_REDIS_FAILURE_BLOCK_SECONDS` per environment and document rationale.

## Ordered Next Steps

1. Execute `scripts/reconcile-all-nonprod.ps1` on each persistent non-prod host with explicit project list and record results.
2. Run `pwsh -File scripts/verify-rollout.ps1 -Mode nonprod-smoke -ProjectName <project> -BackendBaseUrl <backend-url>` on each non-prod environment and record output.
3. Populate `ALERTMANAGER_*_WEBHOOK_URL` secrets in each production environment, then run `pwsh -File scripts/verify-rollout.ps1 -Mode prod-preflight`.
4. Set `PIPER_MODEL_HOST_PATH` in each non-prod/prod host and verify `GET /api/tts/status` reports `available=true`.
5. Roll out `APP_CORS_ALLOWED_ORIGINS` into production/stage secret management and verify `prod-preflight` end-to-end.
6. Enable and validate security headers in staging (`docker,prod` profile or explicit env overrides), then verify browser/API compatibility.
7. Execute and review `security-scan` GitHub CI results and confirm parity with local clean Trivy baseline.
8. Roll out environment-specific auth fallback mode (`memory`/`deny`) and verify alert behavior.
9. Keep all subsequent schema fixes forward-only (`V011+`) to avoid new checksum drift.

