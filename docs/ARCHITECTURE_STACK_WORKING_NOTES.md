# Architecture / Stack Working Notes

Date: 2026-02-12  
Status: Geçici çalışma notu (işler tamamlanınca temizlenebilir)

## 1) Mimari Özeti

- Backend: `Spring Boot 3.2.1`, Java 17, tek servis (modüler monolith yaklaşımı).
- API: REST (`/api/...`), OpenAPI non-prod aktif (`/api-docs`, `/swagger-ui`), prod profilde kapalı.
- Database: PostgreSQL (`EnglishApp`), schema yönetimi `Flyway`.
- ORM: Spring Data JPA + Hibernate, `ddl-auto=validate`.
- Cache/Realtime:
  - Redis (leaderboard + cache altyapısı)
  - Socket.IO altyapısı feature-flag ile kapalı (`app.socketio.enabled=false`).
- Frontend: Flutter Web (Nginx üzerinden serve ediliyor).
- Container Orchestration: Docker Compose (`postgres`, `redis`, `backend`, `frontend`).

## 2) Stack ve Operasyon Notları

- Compose servisleri:
  - `postgres:15-alpine`
  - `redis:7-alpine`
  - `backend` (multi-stage Maven + Temurin image)
  - `frontend` (Flutter web container)
- Migration zinciri: `V000 ... V010`
- Baseline görülen ortamlarda (`version=3 baseline`) `version=1` kaydı olmaması normal.
- Checksum reconciliation script:
  - `scripts/reconcile-flyway-checksums.ps1`
  - Artık host `localhost` yerine compose docker network içinde çalışır.

## 3) Son Test/Doğrulama Sonuçları

Son güncel çalıştırmalar:

1. `mvn -q "-Dtest=ChatbotControllerTest,GroqServiceTest" test` (cache + Groq resilience regression)
- Sonuç: `PASS`

2. `mvn -q test` (backend)
- Sonuç: `PASS`

3. `pwsh -File scripts/check-core-coverage.ps1 -Threshold 90`
- Sonuç: `PASS`
- Core line coverage: `98.42%` (`2242/2278`, classes=`58`)

4. `pwsh -File scripts/check-db-parity.ps1 -ProjectName flutter-project-main`
- Sonuç: `PASS`

5. `pwsh -File scripts/reconcile-flyway-checksums.ps1 -ProjectName flutter-project-main -AcknowledgeNonProd`
- Sonuç: `PASS`
- Flyway image/runtime: `12.0.0`
- Not: baseline=3 ortam için `version=1` kaydı bulunmaması beklenen davranış.

6. `docker compose -f docker-compose.yml config`
- Sonuç: `PASS`

7. `mvn -q test` (prod hardening + logging hygiene batch sonrası)
- Sonuç: `PASS`

8. `pwsh -File scripts/check-core-coverage.ps1 -Threshold 90`
- Sonuç: `PASS`
- Core line coverage: `98.39%` (`2204/2240`, classes=`58`)

9. `docker compose -f docker-compose.yml -f docker-compose.prod.yml config`
- Sonuç: `PASS` (zorunlu env değişkenleri set edilerek doğrulandı)

10. `pwsh -File scripts/check-db-parity.ps1 -ProjectName flutter-project-main`
- Sonuç: `PASS`

11. `docker compose -f docker-compose.yml -f docker-compose.monitoring.yml config`
- Sonuç: `PASS`

12. `docker run --rm --entrypoint /bin/promtool -v C:/flutter-project-main/monitoring/prometheus:/etc/prometheus prom/prometheus:v2.53.1 check config /etc/prometheus/prometheus.yml`
- Sonuç: `PASS`
- Not: `monitoring/prometheus/prometheus.yml` ve `monitoring/prometheus/alerts/cache-alerts.yml` sentaksı doğrulandı.

13. `docker compose -p flutter-project-main -f docker-compose.yml -f docker-compose.monitoring.yml up -d prometheus grafana`
- Sonuç: `PASS`

14. Runtime endpoint checks
- `GET http://localhost:9090/-/ready` -> `200`
- `GET http://localhost:3000/api/health` -> `200`
- `GET http://localhost:9090/api/v1/targets` (`job=backend-actuator`) -> `up`
- `GET http://localhost:3000/api/search?query=Chatbot%20Cache%20Observability` -> dashboard provisioned

15. `docker compose -f docker-compose.yml -f docker-compose.monitoring.yml config`
- Sonuç: `PASS`

16. `docker run --rm --entrypoint /bin/promtool -v C:/flutter-project-main/monitoring/prometheus:/etc/prometheus prom/prometheus:v2.53.1 check config /etc/prometheus/prometheus.yml`
- Sonuç: `PASS`

17. `docker run --rm --entrypoint /bin/amtool -v C:/flutter-project-main/monitoring/alertmanager:/etc/alertmanager prom/alertmanager:v0.27.0 check-config /etc/alertmanager/alertmanager.yml`
- Sonuç: `PASS`

18. `docker compose -p flutter-project-main -f docker-compose.yml -f docker-compose.monitoring.yml up -d alertmanager alert-webhook prometheus grafana`
- Sonuç: `PASS`

19. Runtime endpoint checks (Alertmanager routing batch)
- `GET http://localhost:9093/-/ready` -> `200`
- `GET http://localhost:18080` -> `200`
- `GET http://localhost:9090/api/v1/alertmanagers` -> `http://alertmanager:9093/api/v2/alerts`

20. Alert route smoke checks
- `POST http://localhost:9093/api/v2/alerts` (`severity=warning`) -> webhook log `POST /warning` (`200`)
- `POST http://localhost:9093/api/v2/alerts` (`severity=critical`) -> webhook log `POST /critical` (`200`)

21. `mvn -q test` (Alertmanager routing batch sonrası)
- Sonuç: `PASS`

22. `pwsh -File scripts/check-core-coverage.ps1 -Threshold 90`
- Sonuç: `PASS`
- Core line coverage: `98.39%` (`2204/2240`, classes=`58`)

23. `pwsh -File scripts/check-db-parity.ps1 -ProjectName flutter-project-main`
- Sonuç: `PASS`

24. `docker compose -f docker-compose.yml -f docker-compose.monitoring.yml -f docker-compose.prod.yml config` (required env set)
- Sonuç: `PASS`

25. `docker compose -f docker-compose.yml -f docker-compose.monitoring.yml -f docker-compose.prod.yml config` (missing `ALERTMANAGER_WARNING_WEBHOOK_URL`)
- Sonuç: `FAIL` (beklenen davranış, prod secret requirement enforced)

26. `docker compose -p flutter-project-main -f docker-compose.yml -f docker-compose.monitoring.yml -f docker-compose.prod.yml --profile nonprod-only up -d alert-webhook alertmanager`
- Sonuç: `PASS`

27. Runtime endpoint checks (prod paging binding batch)
- `GET http://localhost:9093/-/ready` -> `200`
- `docker compose ... exec alertmanager grep -n 'url:' /tmp/alertmanager.yml` -> bound env URL values confirmed

28. Alert route smoke checks (prod override path)
- `POST http://localhost:9093/api/v2/alerts` (`severity=warning`) -> webhook log `POST /warning` (`200`)
- `POST http://localhost:9093/api/v2/alerts` (`severity=critical`) -> webhook log `POST /critical` (`200`)

29. `mvn -q test` (prod paging binding batch sonrası)
- Sonuç: `PASS`

30. `pwsh -File scripts/check-core-coverage.ps1 -Threshold 90`
- Sonuç: `PASS`
- Core line coverage: `98.39%` (`2204/2240`, classes=`58`)

31. `pwsh -File scripts/check-db-parity.ps1 -ProjectName flutter-project-main`
- Sonuç: `PASS`

32. Lightweight stress smoke (`GET /actuator/health`)
- Yük: `2000` istek, concurrency=`50`
- Sonuç: `100%` success (`2000/2000`)
- Performans: `~327.06 rps`, latency `avg=9.77ms`, `p95=12.31ms`, `p99=112.12ms`, `max=308.96ms`

33. Lightweight stress smoke (`GET /api/progress/stats`, header `X-User-Id: 1`)
- Yük: `1000` istek, concurrency=`30`
- Sonuç: `100%` success (`1000/1000`)
- Performans: `~208.28 rps`, latency `avg=19.71ms`, `p95=41.68ms`, `p99=255.73ms`, `max=361.46ms`

34. `pwsh -File scripts/validate-prod-alert-routing.ps1` (required env set)
- Sonuç: `PASS`

35. `scripts/validate-prod-alert-routing.ps1` (missing `ALERTMANAGER_WARNING_WEBHOOK_URL`)
- Sonuç: `FAIL` (beklenen davranış, fail-fast secret kontrolu)

36. `pwsh -File scripts/reconcile-all-nonprod.ps1`
- Sonuç: `PASS` (`flutter-project-main`: reconcile=`PASS`, parity=`PASS`)

37. Script-temelli load smoke rerun (`scripts/run-http-load-smoke.ps1`)
- `GET /actuator/health`, `2000` istek, concurrency=`50` -> `100%` success, `~369.05 rps`, `p95=10.12ms`
- `GET /api/progress/stats`, `1000` istek, concurrency=`30`, `X-User-Id:1` -> `100%` success, `~302.25 rps`, `p95=19.29ms`

38. Batch sonrası standard gate rerun
- `mvn -q test` -> `PASS`
- `pwsh -File scripts/check-core-coverage.ps1 -Threshold 90` -> `PASS` (`98.39%`, `2204/2240`, classes=`58`)
- `pwsh -File scripts/check-db-parity.ps1 -ProjectName flutter-project-main` -> `PASS`

39. One-command rollout orchestrator checks
- `pwsh -File scripts/verify-rollout.ps1 -Mode prod-preflight` -> `PASS`
- `pwsh -File scripts/verify-rollout.ps1 -Mode nonprod-smoke -ProjectName flutter-project-main -BackendBaseUrl http://localhost:8082` -> `PASS`
- `pwsh -File scripts/verify-rollout.ps1 -Mode local-gate -ProjectName flutter-project-main` -> `PASS`

40. Piper TTS single-model stabilization + dynamic status wiring
- `PiperTtsService` default model is now configurable via `piper.tts.default-model` (`PIPER_TTS_DEFAULT_MODEL`).
- Voice/model resolution now falls back in order: requested voice model -> configured default -> first available model.
- `TtsController` status endpoint now returns dynamic `voices` from actual model availability (`getSupportedVoices`) instead of hard-coded list.
- Validation:
  - `mvn -q "-Dtest=PiperTtsServiceTest,TtsControllerTest" test` -> `PASS`
  - `mvn -q test` -> `PASS`
  - `pwsh -File scripts/check-core-coverage.ps1 -Threshold 90` -> `PASS` (`98.33%`, `2231/2269`, classes=`58`)
  - `pwsh -File scripts/check-db-parity.ps1 -ProjectName flutter-project-main` -> `PASS`

41. Post-TTS gate + non-prod smoke rerun
- `pwsh -File scripts/verify-rollout.ps1 -Mode local-gate -ProjectName flutter-project-main` -> `PASS`
- `pwsh -File scripts/verify-rollout.ps1 -Mode nonprod-smoke -ProjectName flutter-project-main -BackendBaseUrl http://localhost:8082` -> `PASS`
- Latest load smoke snapshot:
  - `GET /actuator/health`, `2000` request, concurrency=`50` -> `100%`, `~312.13 rps`, `p95=117.25ms`
  - `GET /api/progress/stats`, `1000` request, concurrency=`30`, `X-User-Id:1` -> `100%`, `~278.08 rps`, `p95=70.83ms`
- Runtime check:
  - `GET /api/tts/status` -> `{"available":false,"voices":["default","amy"]}`
  - Interpretation: code path is ready for single-model behavior, but current Docker runtime still does not have a runnable Piper binary in-container.

## 4) Bu Turda Kapatılanlar

1. Progress/XP tamamen user-aware hale getirildi
- `ProgressService` artık `userId` parametresi olmadan çalışmıyor.
- Achievement, streak, word/review count hesapları kullanıcı bazlı.

2. Core öğrenme endpointlerinde sessiz `userId=1` fallback kaldırıldı
- `WordController`, `SentencePracticeController`, `ProgressController`, `SRSController` için `X-User-Id` zorunlu.
- `WordService` ve `SentencePracticeService` null `userId` ile kayıt kabul etmiyor.

3. SRS akışı user scope’a alındı
- Review fetch/submit/stats artık `userId` bazlı repository sorguları ile çalışıyor.

4. Header/param parse hataları 400 olarak normalize edildi
- `GlobalExceptionHandler` içinde `MissingRequestHeaderException` ve `MethodArgumentTypeMismatchException` bad request olarak ele alınıyor.

5. Subscription core endpointlerinde fallback kaldırıldı
- `SubscriptionController` artık ödeme/doğrulama/demo aktivasyon akışlarında zorunlu `X-User-Id` kullanıyor.

6. Community REST controller header kontratı normalize edildi
- `ChatController`, `SocialController`, `NotificationController` artık zorunlu ve tip-güvenli `X-User-Id` (`Long`) kullanıyor.
- Optional header / manuel parse kaynaklı 500 riskleri azaltıldı.

7. `UserController` heartbeat parse akışı normalize edildi
- `heartbeat` endpointi manuel `Long.parseLong` + 500 yerine `Long` header bind kullanıyor.
- Geçersiz header artık global contract ile `400 Bad Request`.

8. Matchmaking queue identity fallback kaldırıldı
- `MatchmakingController` artık `join_queue` event’inde `userId` yoksa `queue_error` dönüyor.
- Sessiz `sessionId` fallback kaldırıldı.

9. Backend healthcheck / readiness orchestration eklendi
- Backend Actuator (`health/info`, probe support) aktive edildi.
- Compose backend healthcheck ile frontend artık backend `service_healthy` olduktan sonra ayağa kalkıyor.

10. Redis capacity guardrail eklendi
- Compose Redis komutu `maxmemory` ve eviction policy ile sınırlandı.
- Varsayılanlar: `REDIS_MAXMEMORY=256mb`, `REDIS_MAXMEMORY_POLICY=allkeys-lru`.

11. Chatbot sentence cache akışı aktive edildi
- `ChatbotController` artık cache hit/miss/store akışını gerçek Redis read/write ile kullanıyor.
- Cache hataları kullanıcı akışını bozmayacak şekilde degrade oluyor.

12. Chatbot subscription bypass kaldırıldı
- `ChatbotController` artık tüm kullanıcılar için aynı subscription kontrolünü uyguluyor.
- `userId == 1L` özel izin yolu kaldırıldı.

13. Groq dış AI çağrıları için dayanıklılık eklendi
- `GroqService` artık retry/backoff + timeout budget + circuit-open mantığı ile transient failure dalgalarını yumuşatıyor.
- Retryable/non-retryable hatalar ayrıştırıldı; failure threshold sonrası kısa devre açılıyor.

14. Chatbot cache observability eklendi
- Cache lookup ve write akışları için metrikler emit ediliyor:
  - `chatbot.sentences.cache.lookup.total`
  - `chatbot.sentences.cache.lookup.latency`
  - `chatbot.sentences.cache.write.total`
- Outcome etiketleri: `hit|miss|error|disabled` ve `stored|skipped|error`.
- Actuator exposure `health,info,metrics` olarak güncellendi.

15. Flyway checksum repair akışı güncel sürüme taşındı
- `reconcile-flyway-checksums.ps1` varsayılan Flyway image tag’i `12.0.0` oldu.
- Runbook komutları yeni sürümle hizalandı.

16. Non-prod ortamlar için batch checksum reconcile akışı eklendi
- `scripts/reconcile-all-nonprod.ps1` çalışan compose project isimlerini otomatik keşfedip her biri için:
  - `reconcile-flyway-checksums.ps1`
  - `check-db-parity.ps1`
  sıralı olarak çalıştırıyor.
- Varsayılan olarak adı `prod/production` geçen project'leri atlıyor.

17. Prod hardening profile + compose override eklendi
- `application-prod.properties` ile prod’da secret’lar fallback’siz zorunlu hale getirildi.
- Swagger/OpenAPI prod’da kapatıldı.
- Actuator exposure prod’da `health` ile sınırlandı.
- `docker-compose.prod.yml` ile `postgres` ve `redis` host port publish kapatıldı.

18. Zayıf secret fallback’leri temizlendi
- `IyzicoConfig` içindeki kod-level sandbox default key/secret kaldırıldı.
- Iyzico değerleri property/env üzerinden açıkça yönetilecek hale getirildi; prod’da zorunlu env kullanılıyor.

19. Logging hijyeni tamamlandı
- `System.out.println` / `printStackTrace` kalıpları kaldırılıp structured logger’a taşındı (`AuthController`, `ChatbotController`, `MatchmakingController`, `TtsController`, `PiperTtsService`, `DataLoader`).

20. Cache observability dashboard/alert wiring eklendi
- `micrometer-registry-prometheus` dependency eklendi; non-prod actuator exposure `prometheus` endpointini içeriyor.
- `docker-compose.monitoring.yml` ile Prometheus + Grafana servisleri compose ağına eklendi.
- Prometheus scrape/alert kuralları eklendi (`monitoring/prometheus/prometheus.yml`, `monitoring/prometheus/alerts/cache-alerts.yml`).
- Grafana datasource + dashboard provisioning ve cache odaklı dashboard JSON eklendi (`monitoring/grafana/...`).
- Prod profile hala kısıtlı: actuator exposure `health` only, prometheus export disable.

21. Alertmanager severity routing finalize edildi
- docker-compose.monitoring.yml + monitoring/alertmanager/alertmanager.yml ile receiver contract repo içinde kodlandı.
- Warning/critical test alertleri compose içi webhook receiver üzerinden doğrulandı (/warning, /critical).

22. Prod paging/webhook secret binding hardening tamamlandi
- `docker-compose.prod.yml` icinde `ALERTMANAGER_DEFAULT_WEBHOOK_URL`, `ALERTMANAGER_CRITICAL_WEBHOOK_URL`, `ALERTMANAGER_WARNING_WEBHOOK_URL` zorunlu hale getirildi (fallback yok).
- Prod override icinde Alertmanager config bu env degerlerinden runtime'da uretiliyor; eksik secret ile compose render fail oluyor.
- `alert-webhook` servisi prod override'da profile-gated (`nonprod-only`) yapildi.

23. Prod/non-prod operasyonlari icin reusable dogrulama scriptleri eklendi
- `scripts/validate-prod-alert-routing.ps1`: prod alert routing secret contract + compose config check.
- `scripts/run-http-load-smoke.ps1`: endpoint bazli tekrar kullanilabilir HTTP load smoke.

24. Tek komut rollout orkestrasyonu eklendi
- `scripts/verify-rollout.ps1`: `prod-preflight`, `nonprod-smoke`, `local-gate`, `full` modlariyla standard dogrulama setini tek komutta calistirir.
- `docs/PROD_ROLLOUT_SECRET_AND_VERIFY_CHECKLIST.md`: environment bazli secret checklist + command bloklari.

25. TTS tek-model uyarlamasi tamamlandi
- `piper.tts.default-model` ve `PIPER_TTS_DEFAULT_MODEL` ile model secimi tek model kurulumuna uyumlu hale getirildi.
- `/api/tts/status` endpointi dinamik voice listesi donmeye basladi.
- Unit/integration gate'ler tekrar calistirildi ve PASS.

26. Security hardening baslangici: prod CORS whitelist fail-fast
- `CorsConfig` strict origin validation eklendi (`app.cors.strict-origin-validation`):
  - wildcard (`*`), loopback (`localhost/127.0.0.1/0.0.0.0`), bos origin, unresolved placeholder (`${...}`), non-http(s) origin reddediliyor.
- `application-prod.properties`:
  - `app.cors.allowed-origins=${APP_CORS_ALLOWED_ORIGINS}`
  - `app.cors.strict-origin-validation=true`
- `docker-compose.prod.yml`:
  - `APP_CORS_ALLOWED_ORIGINS` zorunlu env kontrati eklendi (`:?`)
- `scripts/validate-prod-alert-routing.ps1` ve `docs/PROD_ROLLOUT_SECRET_AND_VERIFY_CHECKLIST.md` 10 zorunlu env olacak sekilde guncellendi.
- Validation:
  - `mvn -q "-Dtest=CorsConfigTest,CorsPropertiesTest" test` -> `PASS`
  - `pwsh -File scripts/verify-rollout.ps1 -Mode prod-preflight` -> `PASS`
  - `pwsh -File scripts/verify-rollout.ps1 -Mode local-gate -ProjectName flutter-project-main` -> `PASS`
  - Coverage gate -> `PASS` (`98.21%`, `2246/2287`, classes=`58`)
  - DB parity -> `PASS`

27. Security hardening devam: prod security headers filter
- `SecurityHeadersFilter` + `SecurityHeadersProperties` + `SecurityHeadersConfig` eklendi.
- Header seti:
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: DENY`
  - `Referrer-Policy`
  - `Permissions-Policy`
  - `Content-Security-Policy`
  - `Strict-Transport-Security` (yalnizca secure request / `X-Forwarded-Proto=https`)
- `application-prod.properties` icinde `app.security.headers.enabled=true` ile prod’da aktif.
- Validation:
  - `mvn -q "-Dtest=CorsConfigTest,CorsPropertiesTest,SecurityHeadersFilterTest,SecurityHeadersPropertiesTest" test` -> `PASS`
  - `pwsh -File scripts/verify-rollout.ps1 -Mode local-gate -ProjectName flutter-project-main` -> `PASS`
  - Coverage gate -> `PASS` (`98.26%`, `2310/2351`, classes=`61`)
  - DB parity -> `PASS`

28. Security hardening devam: auth brute-force / rate-limit guard
- `AuthRateLimitService` eklendi; login icin principal+IP, register icin IP bazli limit uygulanir.
- `AuthController`:
  - Limit asiminda `429 Too Many Requests` + `Retry-After` doner.
  - Basarisiz denemeler sayilir, basarili login kayitlari resetler.
- Config knobs:
  - `app.security.auth-rate-limit.*` (`application.properties`, `application-docker.properties`, `application-prod.properties`)
  - Prod profilde daha siki limitler tanimlandi.
- Validation:
  - `mvn -q "-Dtest=AuthControllerUnitTest,AuthRateLimitServiceTest,AuthRateLimitPropertiesTest" test` -> `PASS`
  - `pwsh -File scripts/verify-rollout.ps1 -Mode local-gate -ProjectName flutter-project-main` -> `PASS`
  - `pwsh -File scripts/verify-rollout.ps1 -Mode prod-preflight` -> `PASS`
  - Coverage gate -> `PASS` (`97.73%`, `2449/2506`, classes=`65`)
  - DB parity -> `PASS`

29. Security hardening devam: CI vulnerability scanning workflow
- `.github/workflows/security-scan.yml` eklendi.
- PR:
  - `actions/dependency-review-action@v4` (high+ severity fail)
- Push/PR:
  - `aquasecurity/trivy-action` filesystem scan (`HIGH,CRITICAL`)
  - SARIF upload (`github/codeql-action/upload-sarif`)
- Validation:
  - Local gate rerun -> `PASS`
  - `pwsh -File scripts/verify-rollout.ps1 -Mode prod-preflight` -> `PASS`
  - GitHub CI execution sonucu bir sonraki push/PR'da gozlemlenecek.

30. Security hardening devam: Redis-backed auth rate-limit state
- `AuthRateLimitService` artik Redis keyspace kullanarak distributed throttle uygular:
  - counter keys: `auth:rl:cnt:*`
  - block keys: `auth:rl:block:*`
- Yeni ayar:
  - `app.security.auth-rate-limit.redis-enabled` (default `true`)
- Redis path hata verirse servis in-memory limiter'a degrade olur (availability-first fallback).
- Validation:
  - `mvn -q "-Dtest=AuthControllerUnitTest,AuthRateLimitServiceTest,AuthRateLimitServiceRedisTest,AuthRateLimitPropertiesTest" test` -> `PASS`
  - `pwsh -File scripts/verify-rollout.ps1 -Mode local-gate -ProjectName flutter-project-main` -> `PASS`
  - `pwsh -File scripts/verify-rollout.ps1 -Mode prod-preflight` -> `PASS`
  - Coverage gate -> `PASS` (`96.76%`, `2510/2594`, classes=`65`)
  - DB parity -> `PASS`

31. Security hardening devam: auth rate-limit Redis fallback observability/alerting
- `AuthRateLimitService` icine fallback metricleri eklendi:
  - `auth.rate.limit.redis.fallback.active` (gauge)
  - `auth.rate.limit.redis.failure.total{operation=*}` (counter)
  - `auth.rate.limit.redis.fallback.transition.total{state=activated|recovered}` (counter)
- Prometheus alert kurallari eklendi:
  - `AuthRateLimitRedisFallbackActive` (`critical`, fallback `2m+`)
  - `AuthRateLimitRedisFailuresDetected` (`warning`, son `5m` icinde `>=3` failure)
- Validation:
  - `mvn -q "-Dtest=AuthRateLimitServiceTest,AuthRateLimitServiceRedisTest" test` -> `PASS`
  - `docker run --rm --entrypoint /bin/promtool -v C:/flutter-project-main/monitoring/prometheus:/etc/prometheus prom/prometheus:v2.53.1 check config /etc/prometheus/prometheus.yml` -> `PASS`

32. Dockerized Piper executable/runtime gap kapatildi
- `backend/Dockerfile` runtime image'i Debian tabanina alinip Linux Piper binary (`/opt/piper/piper`) build sirasinda kurulacak sekilde guncellendi.
- `application-docker.properties` icinde `piper.tts.path` varsayilani `/opt/piper/piper` oldu.
- `docker-compose.yml` backend env tarafina `PIPER_TTS_PATH` + `PIPER_TTS_DEFAULT_MODEL` eklendi.
- Piper model mount path'i host bazli override edilebilir hale getirildi:
  - `${PIPER_MODEL_HOST_PATH:-C:/piper}:/piper:ro`
- `docker-compose.prod.yml` backend env tarafina Piper path/model env'leri eklendi.
- Validation:
  - `docker compose -f docker-compose.yml config` -> `PASS`
  - `docker compose -f docker-compose.yml -f docker-compose.monitoring.yml -f docker-compose.prod.yml config` (required env set) -> `PASS`
  - `docker build -f backend/Dockerfile backend -t flutter-project-main-backend:piper-check` -> `PASS`
  - `docker run --rm --entrypoint /opt/piper/piper flutter-project-main-backend:piper-check --version` -> `PASS` (`1.2.0`)
  - `mvn -q "-Dtest=PiperTtsServiceTest,TtsControllerTest" test` -> `BLOCKED` (sandbox network denied to Maven Central)

33. Staging security smoke otomasyonu eklendi (CORS + response headers)
- `scripts/smoke-security-cors-headers.ps1` eklendi:
  - Allowed-origin preflight kabulunu,
  - disallowed-origin preflight'in bloklanmasini,
  - security header baseline'ini tek scriptte dogrular.
- `scripts/verify-rollout.ps1` nonprod-smoke moduna opsiyonel parametre eklendi:
  - `-SecuritySmokeAllowedOrigin`
  - Parametre verilirse ayni batch icinde `security-cors-headers-smoke` adimi calisir.
- `docs/PROD_ROLLOUT_SECRET_AND_VERIFY_CHECKLIST.md` komut ornekleri guncellendi.
- Validation:
  - PowerShell parser check -> `PASS` (`scripts/smoke-security-cors-headers.ps1`, `scripts/verify-rollout.ps1`)

34. Staging-benzeri canli security smoke calistirildi (izole prod-profile stack)
- Compose bring-up:
  - `docker compose -p flutter-project-main-stage-smoke -f docker-compose.yml -f docker-compose.monitoring.yml -f docker-compose.prod.yml up -d --build postgres redis backend` -> `PASS`
- Smoke komutu:
  - `pwsh -File scripts/smoke-security-cors-headers.ps1 -BaseUrl http://localhost:18082 -AllowedOrigin https://staging.example.com -DisallowedOrigin https://evil.example.com` -> `PASS`
- Sonuclar:
  - allowed-origin preflight -> `200`
  - disallowed-origin preflight -> `403`
  - header probe -> `200` (security header baseline beklenen sekilde geldi)
- TTS runtime dogrulamasi:
  - `docker run --rm --entrypoint /opt/piper/piper flutter-project-main-backend:piper-check --version` -> `1.2.0`
- Temizlik:
  - `docker compose ... down` (`flutter-project-main-stage-smoke`) -> `PASS`

35. Auth rate-limit fallback policy config-driven hale getirildi
- Yeni config anahtarlari:
  - `app.security.auth-rate-limit.redis-fallback-mode=memory|deny`
  - `app.security.auth-rate-limit.redis-failure-block-seconds`
- Varsayilan davranis korunur:
  - `memory` (fail-open, availability-first)
- `deny` modunda Redis degrade oldugunda auth istekleri bloklanir (fail-closed) ve metrik uretilir:
  - `auth.rate.limit.redis.fail.closed.block.total{operation=*}`
- Prometheus alert eklendi:
  - `AuthRateLimitFailClosedBlocking` (`critical`)
- Compose env override'lari eklendi:
  - `APP_SECURITY_AUTH_RATE_LIMIT_REDIS_FALLBACK_MODE`
  - `APP_SECURITY_AUTH_RATE_LIMIT_REDIS_FAILURE_BLOCK_SECONDS`
- Validation:
  - `docker run --rm -v C:/flutter-project-main/backend:/app -w /app maven:3.9.6-eclipse-temurin-17-alpine mvn -q "-Dtest=AuthRateLimitServiceTest,AuthRateLimitServiceRedisTest,AuthRateLimitPropertiesTest,AuthControllerUnitTest" test` -> `PASS`
  - `docker compose -f docker-compose.yml config` -> `PASS`
  - `docker compose -f docker-compose.yml -f docker-compose.monitoring.yml -f docker-compose.prod.yml config` -> `PASS`
  - `docker run --rm --entrypoint /bin/promtool -v C:/flutter-project-main/monitoring/prometheus:/etc/prometheus prom/prometheus:v2.53.1 check config /etc/prometheus/prometheus.yml` -> `PASS`

36. Local security-scan triage/remediation tamamlandi (HIGH/CRITICAL)
- `backend/pom.xml` dependency baseline guncellendi:
  - Spring Boot parent `3.4.5`
  - `spring-framework.version=6.2.11`
  - `tomcat.version=10.1.45`
  - `postgresql.version=42.7.2`
- Trivy sonucu:
  - ilk run: `17` bulgu (`HIGH=15`, `CRITICAL=2`)
  - guncelleme sonrasi: `HIGH/CRITICAL = 0` (Trivy `--exit-code 1` ile de `PASS`)
- Validation:
  - `docker run --rm -v C:/flutter-project-main/backend:/app -w /app maven:3.9.6-eclipse-temurin-17-alpine mvn -q "-Dtest=AuthRateLimitServiceTest,AuthRateLimitServiceRedisTest,AuthRateLimitPropertiesTest,AuthControllerUnitTest" test` -> `PASS`
  - `docker build -f backend/Dockerfile backend -t flutter-project-main-backend:security-refresh` -> `PASS`

## 5) Geliştirilmesi Gereken Alanlar

1. Monitoring paging destination hardening
- Alertmanager severity routing repo içinde kodlandı ve warning/critical route doğrulandı.
- Prod compose tarafında `ALERTMANAGER_*_WEBHOOK_URL` zorunlu/fallbacksiz hale getirildi.
- Hedef ortamda gerçek URL secretlarının (vault/env) rollout'u ve son destination kontratı dokümantasyonu tamamlanmalı.

2. Migration guard’larını daha da sertleştirme
- Özellikle legacy varyasyonlar için `column exists` kontrolleri artırılmalı.

3. Metriklerin merkezi scrape/publish entegrasyonu
- Repo tarafında Prometheus/Grafana compose wiring var.
- Hedef ortamda merkezi observability cluster (ve retention/paging politikaları) ile son bağlantı netleştirilmeli.

4. Docker model mount env senkronizasyonu
- Piper executable artik image icinde mevcut; kalan konu model dosyalarinin host bazli dogru mount edilmesi.
- Windows disi hostlarda `PIPER_MODEL_HOST_PATH` override edilmezse `/api/tts/status` hala `available=false` donebilir.

5. Security rollout env senkronizasyonu
- Prod/stage pipeline'larina `APP_CORS_ALLOWED_ORIGINS` eklenmeli; aksi halde preflight fail-fast verecek.

6. Security headers staging dogrulamasi
- Header seti su an prod profilde aktif; staging'de de etkinlestirilip (profil/env) browser uyumlulugu smoke edilmelidir.

7. CI scanner sonuc parity dogrulamasi
- Local Trivy HIGH/CRITICAL baseline temiz.
- Kalan adim: GitHub `security-scan` workflow sonucunun ayni commit seti icin parity vermesini dogrulamak.

8. Auth rate-limit fallback mode rollout'u
- Politika artik config ile secilebilir (`memory`/`deny`), ancak ortam bazli nihai secim rollout edilmelidir.
- `deny` secilen ortamlarda fail-closed block metriği/alert davranisi smoke edilmelidir.

## 6) Güncelleme Notu

- Bu dosya sprint boyunca canlı not olarak kullanılabilir.
- Her büyük değişiklikten sonra bu dosyada:
  - yapılan değişiklik,
  - test çıktısı,
  - kalan risk
  kısa formatta güncellenecek.

