package com.ingilizce.calismaapp.security;

import com.ingilizce.calismaapp.entity.EmailVerificationToken;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.EmailVerificationTokenRepository;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Base64;

@Service
public class EmailVerificationService {

    public record IssuedVerificationToken(String tokenValue, Instant expiresAt) {
    }

    public static class EmailVerificationException extends RuntimeException {
        public enum Code {
            INVALID,
            EXPIRED,
            ALREADY_USED
        }

        private final Code code;

        public EmailVerificationException(Code code, String message) {
            super(message);
            this.code = code;
        }

        public Code getCode() {
            return code;
        }
    }

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();
    private static final String TOKEN_PREFIX = "evt";

    private final EmailVerificationTokenRepository emailVerificationTokenRepository;
    private final JwtProperties jwtProperties;
    private final AuthSecurityProperties authSecurityProperties;

    public EmailVerificationService(EmailVerificationTokenRepository emailVerificationTokenRepository,
                                    JwtProperties jwtProperties,
                                    AuthSecurityProperties authSecurityProperties) {
        this.emailVerificationTokenRepository = emailVerificationTokenRepository;
        this.jwtProperties = jwtProperties;
        this.authSecurityProperties = authSecurityProperties;
    }

    @Transactional
    public IssuedVerificationToken issue(User user, String requestedIp, String requestedUserAgent, Instant now) {
        Instant issuedAt = now != null ? now : Instant.now();
        Instant expiresAt = issuedAt.plusSeconds(resolveTtlSeconds());
        String tokenId = generateTokenId();
        String secret = generateSecret();

        EmailVerificationToken token = new EmailVerificationToken();
        token.setTokenId(tokenId);
        token.setUser(user);
        token.setTokenHash(hashTokenSecret(secret));
        token.setCreatedAt(toLocalDateTime(issuedAt));
        token.setExpiresAt(toLocalDateTime(expiresAt));
        token.setRequestedIp(truncate(requestedIp, 64));
        token.setRequestedUserAgent(truncate(requestedUserAgent, 512));
        emailVerificationTokenRepository.save(token);

        return new IssuedVerificationToken(formatToken(tokenId, secret), expiresAt);
    }

    @Transactional
    public User verify(String rawToken, String usedIp, String usedUserAgent, Instant now) {
        ParsedToken parsed = parseToken(rawToken);
        EmailVerificationToken token = emailVerificationTokenRepository.findByTokenId(parsed.tokenId())
                .orElseThrow(() -> new EmailVerificationException(EmailVerificationException.Code.INVALID, "Invalid verification token"));

        if (!constantTimeEquals(hashTokenSecret(parsed.secret()), token.getTokenHash())) {
            throw new EmailVerificationException(EmailVerificationException.Code.INVALID, "Invalid verification token");
        }

        Instant verifiedAt = now != null ? now : Instant.now();
        if (token.getUsedAt() != null) {
            throw new EmailVerificationException(EmailVerificationException.Code.ALREADY_USED, "Verification token already used");
        }
        if (token.getExpiresAt().isBefore(toLocalDateTime(verifiedAt))) {
            throw new EmailVerificationException(EmailVerificationException.Code.EXPIRED, "Verification token expired");
        }

        token.setUsedAt(toLocalDateTime(verifiedAt));
        token.setUsedIp(truncate(usedIp, 64));
        token.setUsedUserAgent(truncate(usedUserAgent, 512));
        emailVerificationTokenRepository.save(token);

        User user = token.getUser();
        if (!user.isEmailVerified()) {
            user.setEmailVerifiedAt(toLocalDateTime(verifiedAt));
        }
        return user;
    }

    private long resolveTtlSeconds() {
        return Math.max(600L, authSecurityProperties.getEmailVerificationTokenTtlSeconds());
    }

    private ParsedToken parseToken(String rawToken) {
        if (rawToken == null || rawToken.isBlank()) {
            throw new EmailVerificationException(EmailVerificationException.Code.INVALID, "Invalid verification token");
        }
        String[] parts = rawToken.split("\\.");
        if (parts.length != 3 || !TOKEN_PREFIX.equals(parts[0])) {
            throw new EmailVerificationException(EmailVerificationException.Code.INVALID, "Invalid verification token");
        }
        if (parts[1].isBlank() || parts[2].isBlank()) {
            throw new EmailVerificationException(EmailVerificationException.Code.INVALID, "Invalid verification token");
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
            throw new IllegalStateException("Unable to hash verification token", ex);
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
