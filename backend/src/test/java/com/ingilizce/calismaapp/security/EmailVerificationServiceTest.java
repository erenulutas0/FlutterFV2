package com.ingilizce.calismaapp.security;

import com.ingilizce.calismaapp.entity.EmailVerificationToken;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.EmailVerificationTokenRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.Instant;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class EmailVerificationServiceTest {

    private EmailVerificationTokenRepository emailVerificationTokenRepository;
    private EmailVerificationService emailVerificationService;

    @BeforeEach
    void setUp() {
        emailVerificationTokenRepository = mock(EmailVerificationTokenRepository.class);
        JwtProperties jwtProperties = new JwtProperties();
        jwtProperties.setSecret("test-only-jwt-secret-test-only-jwt-secret");
        AuthSecurityProperties authSecurityProperties = new AuthSecurityProperties();

        when(emailVerificationTokenRepository.save(any(EmailVerificationToken.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        emailVerificationService = new EmailVerificationService(
                emailVerificationTokenRepository,
                jwtProperties,
                authSecurityProperties);
    }

    @Test
    void issueAndVerify_ShouldMarkUserVerified() {
        User user = new User("verify@test.com", "hash", "Verify User");
        user.setId(3L);

        ArgumentCaptor<EmailVerificationToken> tokenCaptor = ArgumentCaptor.forClass(EmailVerificationToken.class);
        EmailVerificationService.IssuedVerificationToken issued = emailVerificationService.issue(
                user,
                "10.0.0.1",
                "ua-1",
                Instant.now());

        verify(emailVerificationTokenRepository).save(tokenCaptor.capture());
        EmailVerificationToken storedToken = tokenCaptor.getValue();
        String tokenId = issued.tokenValue().split("\\.")[1];
        when(emailVerificationTokenRepository.findByTokenId(tokenId)).thenReturn(Optional.of(storedToken));

        emailVerificationService.verify(issued.tokenValue(), "10.0.0.2", "ua-2", Instant.now());

        assertNotNull(storedToken.getUsedAt());
        assertNotNull(user.getEmailVerifiedAt());
    }

    @Test
    void verify_ShouldThrow_WhenTokenInvalid() {
        assertThrows(EmailVerificationService.EmailVerificationException.class,
                () -> emailVerificationService.verify("bad-token", "ip", "ua", Instant.now()));
    }
}
