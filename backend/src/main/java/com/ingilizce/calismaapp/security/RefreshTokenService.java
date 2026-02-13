package com.ingilizce.calismaapp.security;

import com.ingilizce.calismaapp.entity.RefreshTokenSession;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.RefreshTokenSessionRepository;
import io.micrometer.core.instrument.MeterRegistry;
import jakarta.transaction.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Base64;
import java.util.Optional;

@Service
public class RefreshTokenService {

    public record IssuedRefreshToken(String tokenValue, String sessionId, Instant expiresAt) {
    }

    public record RotationResult(RefreshTokenSession previousSession, IssuedRefreshToken nextToken) {
    }

    public static class RefreshTokenException extends RuntimeException {
        public enum Code {
            INVALID,
            EXPIRED,
            REUSE_DETECTED,
            DEVICE_MISMATCH
        }

        private final Code code;

        public RefreshTokenException(Code code, String message) {
            super(message);
            this.code = code;
        }

        public Code getCode() {
            return code;
        }
    }

    private static final Logger log = LoggerFactory.getLogger(RefreshTokenService.class);
    private static final String TOKEN_PREFIX = "rt";
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private static final String METRIC_ROTATION_TOTAL = "auth.refresh.rotation.total";
    private static final String METRIC_REVOKED_TOTAL = "auth.refresh.revoked.total";
    private static final String METRIC_REUSE_TOTAL = "auth.refresh.reuse.detected.total";
    private static final String METRIC_DEVICE_MISMATCH_TOTAL = "auth.refresh.device.mismatch.total";
    private static final String METRIC_IP_CHANGE_TOTAL = "auth.refresh.ip.change.total";

    private final RefreshTokenSessionRepository refreshTokenSessionRepository;
    private final JwtProperties jwtProperties;
    private final MeterRegistry meterRegistry;

    public RefreshTokenService(RefreshTokenSessionRepository refreshTokenSessionRepository,
                               JwtProperties jwtProperties,
                               @Autowired(required = false) MeterRegistry meterRegistry) {
        this.refreshTokenSessionRepository = refreshTokenSessionRepository;
        this.jwtProperties = jwtProperties;
        this.meterRegistry = meterRegistry;
    }

    @Transactional
    public IssuedRefreshToken issue(User user,
                                    boolean rememberMe,
                                    String deviceId,
                                    String clientIp,
                                    String userAgent,
                                    Instant now) {
        Instant issuedAt = now != null ? now : Instant.now();
        Instant expiresAt = issuedAt.plusSeconds(resolveRefreshTtlSeconds(rememberMe));

        String sessionId = generateSessionId();
        String rawSecret = generateSecret();
        String tokenHash = hashRefreshSecret(rawSecret);

        RefreshTokenSession session = new RefreshTokenSession();
        session.setSessionId(sessionId);
        session.setUser(user);
        session.setTokenHash(tokenHash);
        session.setDeviceId(normalize(deviceId));
        session.setUserAgent(truncate(userAgent, 512));
        session.setCreatedIp(truncate(clientIp, 64));
        session.setLastUsedIp(truncate(clientIp, 64));
        session.setCreatedAt(toLocalDateTime(issuedAt));
        session.setLastUsedAt(toLocalDateTime(issuedAt));
        session.setExpiresAt(toLocalDateTime(expiresAt));
        session.setRememberMe(rememberMe);

        refreshTokenSessionRepository.save(session);
        return new IssuedRefreshToken(formatToken(sessionId, rawSecret), sessionId, expiresAt);
    }

    @Transactional
    public RotationResult rotate(String rawToken,
                                 Long expectedUserId,
                                 String deviceId,
                                 String clientIp,
                                 String userAgent,
                                 Instant now) {
        ParsedToken parsed = parseToken(rawToken);
        Instant requestedAt = now != null ? now : Instant.now();

        RefreshTokenSession session = refreshTokenSessionRepository.findBySessionId(parsed.sessionId())
                .orElseThrow(() -> new RefreshTokenException(RefreshTokenException.Code.INVALID, "Invalid refresh token"));

        if (expectedUserId != null && !expectedUserId.equals(session.getUser().getId())) {
            throw new RefreshTokenException(RefreshTokenException.Code.INVALID, "Invalid refresh token");
        }

        if (!constantTimeEquals(hashRefreshSecret(parsed.secret()), session.getTokenHash())) {
            throw new RefreshTokenException(RefreshTokenException.Code.INVALID, "Invalid refresh token");
        }

        if (session.getRevokedAt() != null) {
            if (session.getReplacedBySessionId() != null) {
                onReuseDetected(session, requestedAt, clientIp, deviceId);
                throw new RefreshTokenException(RefreshTokenException.Code.REUSE_DETECTED, "Refresh token reuse detected");
            }
            throw new RefreshTokenException(RefreshTokenException.Code.INVALID, "Invalid refresh token");
        }

        if (session.getExpiresAt().isBefore(toLocalDateTime(requestedAt))) {
            session.setRevokedAt(toLocalDateTime(requestedAt));
            session.setRevokeReason("expired");
            refreshTokenSessionRepository.save(session);
            incrementMetric(METRIC_REVOKED_TOTAL, "reason", "expired");
            throw new RefreshTokenException(RefreshTokenException.Code.EXPIRED, "Refresh token expired");
        }

        String normalizedDevice = normalize(deviceId);
        if (session.getDeviceId() != null && normalizedDevice != null && !session.getDeviceId().equals(normalizedDevice)) {
            revokeAllForUser(session.getUser().getId(), "device-mismatch", requestedAt);
            incrementMetric(METRIC_DEVICE_MISMATCH_TOTAL, "mode", "blocked");
            throw new RefreshTokenException(RefreshTokenException.Code.DEVICE_MISMATCH, "Refresh token device mismatch");
        }

        if (session.getLastUsedIp() != null && clientIp != null && !session.getLastUsedIp().equals(clientIp)) {
            log.warn("Refresh token IP changed for userId={}, sessionId={} ({} -> {})",
                    session.getUser().getId(), session.getSessionId(), session.getLastUsedIp(), clientIp);
            incrementMetric(METRIC_IP_CHANGE_TOTAL, "result", "changed");
        }

        IssuedRefreshToken next = issue(
                session.getUser(),
                session.isRememberMe(),
                session.getDeviceId(),
                clientIp,
                userAgent,
                requestedAt);

        session.setRevokedAt(toLocalDateTime(requestedAt));
        session.setRevokeReason("rotated");
        session.setReplacedBySessionId(next.sessionId());
        session.setLastUsedAt(toLocalDateTime(requestedAt));
        session.setLastUsedIp(truncate(clientIp, 64));
        refreshTokenSessionRepository.save(session);
        incrementMetric(METRIC_ROTATION_TOTAL, "result", "success");

        return new RotationResult(session, next);
    }

    @Transactional
    public boolean revoke(String rawToken, Long expectedUserId, String reason, Instant now) {
        ParsedToken parsed = parseToken(rawToken);
        Optional<RefreshTokenSession> optional = refreshTokenSessionRepository.findBySessionId(parsed.sessionId());
        if (optional.isEmpty()) {
            return false;
        }

        RefreshTokenSession session = optional.get();
        if (expectedUserId != null && !expectedUserId.equals(session.getUser().getId())) {
            return false;
        }
        if (!constantTimeEquals(hashRefreshSecret(parsed.secret()), session.getTokenHash())) {
            return false;
        }
        if (session.getRevokedAt() != null) {
            return true;
        }

        session.setRevokedAt(toLocalDateTime(now != null ? now : Instant.now()));
        session.setRevokeReason(truncate(reason, 64));
        refreshTokenSessionRepository.save(session);
        incrementMetric(METRIC_REVOKED_TOTAL, "reason", normalizeReason(reason));
        return true;
    }

    @Transactional
    public void revokeBySessionId(String sessionId, Long userId, String reason, Instant now) {
        if (sessionId == null || sessionId.isBlank() || userId == null) {
            return;
        }
        refreshTokenSessionRepository.findBySessionId(sessionId).ifPresent(session -> {
            if (!userId.equals(session.getUser().getId())) {
                return;
            }
            if (session.getRevokedAt() != null) {
                return;
            }
            session.setRevokedAt(toLocalDateTime(now != null ? now : Instant.now()));
            session.setRevokeReason(truncate(reason, 64));
            refreshTokenSessionRepository.save(session);
            incrementMetric(METRIC_REVOKED_TOTAL, "reason", normalizeReason(reason));
        });
    }

    @Transactional
    public void revokeAllForUser(Long userId, String reason, Instant now) {
        if (userId == null) {
            return;
        }
        LocalDateTime nowLdt = toLocalDateTime(now != null ? now : Instant.now());
        refreshTokenSessionRepository.revokeActiveSessionsForUser(
                userId,
                nowLdt,
                truncate(reason, 64),
                nowLdt);
        incrementMetric(METRIC_REVOKED_TOTAL, "reason", normalizeReason(reason));
    }

    private void onReuseDetected(RefreshTokenSession session, Instant now, String clientIp, String deviceId) {
        if (session.getReuseDetectedAt() == null) {
            session.setReuseDetectedAt(toLocalDateTime(now));
        }
        session.setLastUsedAt(toLocalDateTime(now));
        session.setLastUsedIp(truncate(clientIp, 64));
        refreshTokenSessionRepository.save(session);
        revokeAllForUser(session.getUser().getId(), "reuse-detected", now);
        log.error("Refresh token reuse detected for userId={}, sessionId={}, ip={}, deviceId={}",
                session.getUser().getId(), session.getSessionId(), clientIp, deviceId);
        incrementMetric(METRIC_REUSE_TOTAL, "result", "detected");
    }

    private ParsedToken parseToken(String rawToken) {
        if (rawToken == null || rawToken.isBlank()) {
            throw new RefreshTokenException(RefreshTokenException.Code.INVALID, "Invalid refresh token");
        }
        String[] parts = rawToken.split("\\.");
        if (parts.length != 3 || !TOKEN_PREFIX.equals(parts[0])) {
            throw new RefreshTokenException(RefreshTokenException.Code.INVALID, "Invalid refresh token");
        }
        if (parts[1].isBlank() || parts[2].isBlank()) {
            throw new RefreshTokenException(RefreshTokenException.Code.INVALID, "Invalid refresh token");
        }
        return new ParsedToken(parts[1], parts[2]);
    }

    private long resolveRefreshTtlSeconds(boolean rememberMe) {
        long ttl = rememberMe ? jwtProperties.getRefreshTokenRememberMeTtlSeconds()
                : jwtProperties.getRefreshTokenTtlSeconds();
        return Math.max(300L, ttl);
    }

    private String generateSessionId() {
        byte[] buffer = new byte[24];
        SECURE_RANDOM.nextBytes(buffer);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(buffer);
    }

    private String generateSecret() {
        byte[] buffer = new byte[48];
        SECURE_RANDOM.nextBytes(buffer);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(buffer);
    }

    private String formatToken(String sessionId, String rawSecret) {
        return TOKEN_PREFIX + "." + sessionId + "." + rawSecret;
    }

    private String hashRefreshSecret(String rawSecret) {
        try {
            String material = rawSecret + ":" + jwtProperties.getSecret();
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(material.getBytes(StandardCharsets.UTF_8));
            return toHex(digest);
        } catch (Exception ex) {
            throw new IllegalStateException("Unable to hash refresh token", ex);
        }
    }

    private String toHex(byte[] data) {
        StringBuilder builder = new StringBuilder(data.length * 2);
        for (byte b : data) {
            builder.append(String.format("%02x", b));
        }
        return builder.toString();
    }

    private boolean constantTimeEquals(String left, String right) {
        if (left == null || right == null) {
            return false;
        }
        return MessageDigest.isEqual(left.getBytes(StandardCharsets.UTF_8), right.getBytes(StandardCharsets.UTF_8));
    }

    private LocalDateTime toLocalDateTime(Instant instant) {
        return LocalDateTime.ofInstant(instant, ZoneOffset.UTC);
    }

    private void incrementMetric(String metricName, String tagKey, String tagValue) {
        if (meterRegistry == null) {
            return;
        }
        meterRegistry.counter(metricName, tagKey, tagValue).increment();
    }

    private String truncate(String value, int maxLen) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        if (trimmed.isEmpty()) {
            return null;
        }
        return trimmed.length() <= maxLen ? trimmed : trimmed.substring(0, maxLen);
    }

    private String normalize(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private String normalizeReason(String reason) {
        if (reason == null || reason.isBlank()) {
            return "unknown";
        }
        return reason.trim().toLowerCase();
    }

    private record ParsedToken(String sessionId, String secret) {
    }
}
