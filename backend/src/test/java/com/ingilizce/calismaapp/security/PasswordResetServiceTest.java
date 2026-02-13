package com.ingilizce.calismaapp.security;

import com.ingilizce.calismaapp.entity.PasswordResetToken;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.PasswordResetTokenRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.Instant;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class PasswordResetServiceTest {

    private PasswordResetTokenRepository passwordResetTokenRepository;
    private PasswordResetService passwordResetService;
    private PasswordEncoder passwordEncoder;
    private RefreshTokenService refreshTokenService;

    @BeforeEach
    void setUp() {
        passwordResetTokenRepository = mock(PasswordResetTokenRepository.class);
        JwtProperties jwtProperties = new JwtProperties();
        jwtProperties.setSecret("test-only-jwt-secret-test-only-jwt-secret");
        AuthSecurityProperties authSecurityProperties = new AuthSecurityProperties();
        passwordEncoder = mock(PasswordEncoder.class);
        refreshTokenService = mock(RefreshTokenService.class);

        when(passwordResetTokenRepository.save(any(PasswordResetToken.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        when(passwordEncoder.encode(any(String.class))).thenReturn("encoded-password");

        passwordResetService = new PasswordResetService(
                passwordResetTokenRepository,
                jwtProperties,
                authSecurityProperties,
                passwordEncoder,
                refreshTokenService);
    }

    @Test
    void issueAndConsume_ShouldResetPassword_AndRevokeSessions() {
        User user = new User("reset@test.com", "old-hash", "Reset User");
        user.setId(9L);

        ArgumentCaptor<PasswordResetToken> tokenCaptor = ArgumentCaptor.forClass(PasswordResetToken.class);
        PasswordResetService.IssuedResetToken issued = passwordResetService.issue(
                user,
                "10.0.0.1",
                "ua-1",
                Instant.now());

        verify(passwordResetTokenRepository).save(tokenCaptor.capture());
        PasswordResetToken storedToken = tokenCaptor.getValue();
        String tokenId = issued.tokenValue().split("\\.")[1];
        when(passwordResetTokenRepository.findByTokenId(tokenId)).thenReturn(Optional.of(storedToken));

        passwordResetService.consume(issued.tokenValue(), "new-password-123", "10.0.0.2", "ua-2", Instant.now());

        assertNotNull(storedToken.getUsedAt());
        assertEquals("encoded-password", user.getPasswordHash());
        verify(passwordEncoder).encode("new-password-123");
        verify(refreshTokenService).revokeAllForUser(eq(9L), eq("password-reset"), any(Instant.class));
    }

    @Test
    void consume_ShouldThrow_WhenTokenInvalid() {
        assertThrows(PasswordResetService.PasswordResetException.class,
                () -> passwordResetService.consume("invalid-token", "new-password", "ip", "ua", Instant.now()));
    }
}
