package com.ingilizce.calismaapp.security;

import com.ingilizce.calismaapp.entity.PasswordResetToken;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.PasswordResetTokenRepository;
import jakarta.transaction.Transactional;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Base64;

@Service
public class PasswordResetService {

    public record IssuedResetToken(String tokenValue, Instant expiresAt) {
    }

    public static class PasswordResetException extends RuntimeException {
        public enum Code {
            INVALID,
            EXPIRED,
            ALREADY_USED
        }

        private final Code code;

        public PasswordResetException(Code code, String message) {
            super(message);
            this.code = code;
        }

        public Code getCode() {
            return code;
        }
    }

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();
    private static final String TOKEN_PREFIX = "prt";

    private final PasswordResetTokenRepository passwordResetTokenRepository;
    private final JwtProperties jwtProperties;
    private final AuthSecurityProperties authSecurityProperties;
    private final PasswordEncoder passwordEncoder;
    private final RefreshTokenService refreshTokenService;

    public PasswordResetService(PasswordResetTokenRepository passwordResetTokenRepository,
                                JwtProperties jwtProperties,
                                AuthSecurityProperties authSecurityProperties,
                                PasswordEncoder passwordEncoder,
                                RefreshTokenService refreshTokenService) {
        this.passwordResetTokenRepository = passwordResetTokenRepository;
        this.jwtProperties = jwtProperties;
        this.authSecurityProperties = authSecurityProperties;
        this.passwordEncoder = passwordEncoder;
        this.refreshTokenService = refreshTokenService;
    }

    @Transactional
    public IssuedResetToken issue(User user, String requestedIp, String requestedUserAgent, Instant now) {
        Instant issuedAt = now != null ? now : Instant.now();
        Instant expiresAt = issuedAt.plusSeconds(resolveTtlSeconds());

        String tokenId = generateTokenId();
        String secret = generateSecret();

        PasswordResetToken token = new PasswordResetToken();
        token.setTokenId(tokenId);
        token.setUser(user);
        token.setTokenHash(hashTokenSecret(secret));
        token.setCreatedAt(toLocalDateTime(issuedAt));
        token.setExpiresAt(toLocalDateTime(expiresAt));
        token.setRequestedIp(truncate(requestedIp, 64));
        token.setRequestedUserAgent(truncate(requestedUserAgent, 512));
        passwordResetTokenRepository.save(token);

        return new IssuedResetToken(formatToken(tokenId, secret), expiresAt);
    }

    @Transactional
    public void consume(String rawToken, String newPassword, String usedIp, String usedUserAgent, Instant now) {
        ParsedToken parsed = parseToken(rawToken);
        PasswordResetToken token = passwordResetTokenRepository.findByTokenId(parsed.tokenId())
                .orElseThrow(() -> new PasswordResetException(PasswordResetException.Code.INVALID, "Invalid reset token"));

        if (!constantTimeEquals(hashTokenSecret(parsed.secret()), token.getTokenHash())) {
            throw new PasswordResetException(PasswordResetException.Code.INVALID, "Invalid reset token");
        }

        Instant consumedAt = now != null ? now : Instant.now();
        if (token.getUsedAt() != null) {
            throw new PasswordResetException(PasswordResetException.Code.ALREADY_USED, "Reset token already used");
        }
        if (token.getExpiresAt().isBefore(toLocalDateTime(consumedAt))) {
            throw new PasswordResetException(PasswordResetException.Code.EXPIRED, "Reset token expired");
        }

        User user = token.getUser();
        user.setPasswordHash(passwordEncoder.encode(newPassword));

        token.setUsedAt(toLocalDateTime(consumedAt));
        token.setUsedIp(truncate(usedIp, 64));
        token.setUsedUserAgent(truncate(usedUserAgent, 512));
        passwordResetTokenRepository.save(token);

        refreshTokenService.revokeAllForUser(user.getId(), "password-reset", consumedAt);
    }

    private long resolveTtlSeconds() {
        return Math.max(300L, authSecurityProperties.getPasswordResetTokenTtlSeconds());
    }

    private ParsedToken parseToken(String rawToken) {
        if (rawToken == null || rawToken.isBlank()) {
            throw new PasswordResetException(PasswordResetException.Code.INVALID, "Invalid reset token");
        }
        String[] parts = rawToken.split("\\.");
        if (parts.length != 3 || !TOKEN_PREFIX.equals(parts[0])) {
            throw new PasswordResetException(PasswordResetException.Code.INVALID, "Invalid reset token");
        }
        if (parts[1].isBlank() || parts[2].isBlank()) {
            throw new PasswordResetException(PasswordResetException.Code.INVALID, "Invalid reset token");
        }
        return new ParsedToken(parts[1], parts[2]);
    }

    private String generateTokenId() {
        byte[] buffer = new byte[24];
        SECURE_RANDOM.nextBytes(buffer);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(buffer);
    }

    private String generateSecret() {
        byte[] buffer = new byte[48];
        SECURE_RANDOM.nextBytes(buffer);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(buffer);
    }

    private String formatToken(String tokenId, String secret) {
        return TOKEN_PREFIX + "." + tokenId + "." + secret;
    }

    private String hashTokenSecret(String rawSecret) {
        try {
            String material = rawSecret + ":" + jwtProperties.getSecret();
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(material.getBytes(StandardCharsets.UTF_8));
            return toHex(digest);
        } catch (Exception ex) {
            throw new IllegalStateException("Unable to hash reset token", ex);
        }
    }

    private String toHex(byte[] bytes) {
        StringBuilder builder = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) {
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

    private record ParsedToken(String tokenId, String secret) {
    }
}
