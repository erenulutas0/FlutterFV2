package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.config.AuthRateLimitProperties;
import com.ingilizce.calismaapp.service.AuthRateLimitService.RateLimitDecision;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class AuthRateLimitServiceTest {

    @Test
    void login_ShouldBeBlockedAfterConfiguredFailures_AndRecoverAfterBlockWindow() {
        AuthRateLimitProperties properties = new AuthRateLimitProperties();
        properties.setEnabled(true);
        properties.setLoginPrincipalMaxAttempts(2);
        properties.setLoginPrincipalWindowSeconds(60);
        properties.setLoginPrincipalBlockSeconds(120);
        properties.setLoginIpMaxAttempts(100);

        TestableAuthRateLimitService service = new TestableAuthRateLimitService(properties);

        assertFalse(service.checkLogin("user@test.com", "10.0.0.1").blocked());
        service.recordLoginFailure("user@test.com", "10.0.0.1");
        assertFalse(service.checkLogin("user@test.com", "10.0.0.1").blocked());
        service.recordLoginFailure("user@test.com", "10.0.0.1");

        RateLimitDecision blocked = service.checkLogin("user@test.com", "10.0.0.1");
        assertTrue(blocked.blocked());
        assertTrue(blocked.retryAfterSeconds() >= 1);

        service.advanceSeconds(121);
        assertFalse(service.checkLogin("user@test.com", "10.0.0.1").blocked());
    }

    @Test
    void register_ShouldBeBlockedByIpAfterConfiguredFailures() {
        AuthRateLimitProperties properties = new AuthRateLimitProperties();
        properties.setEnabled(true);
        properties.setRegisterIpMaxAttempts(1);
        properties.setRegisterIpWindowSeconds(600);
        properties.setRegisterIpBlockSeconds(60);

        TestableAuthRateLimitService service = new TestableAuthRateLimitService(properties);

        assertFalse(service.checkRegister("10.0.0.2").blocked());
        service.recordRegisterFailure("10.0.0.2");

        assertTrue(service.checkRegister("10.0.0.2").blocked());
    }

    @Test
    void disabledMode_ShouldAlwaysAllow() {
        AuthRateLimitProperties properties = new AuthRateLimitProperties();
        properties.setEnabled(false);

        TestableAuthRateLimitService service = new TestableAuthRateLimitService(properties);
        service.recordLoginFailure("user@test.com", "10.0.0.3");
        service.recordRegisterFailure("10.0.0.3");

        assertFalse(service.checkLogin("user@test.com", "10.0.0.3").blocked());
        assertFalse(service.checkRegister("10.0.0.3").blocked());
    }

    private static class TestableAuthRateLimitService extends AuthRateLimitService {
        private long nowMs = 1_000_000L;

        private TestableAuthRateLimitService(AuthRateLimitProperties properties) {
            super(properties);
        }

        @Override
        protected long currentTimeMillis() {
            return nowMs;
        }

        private void advanceSeconds(long seconds) {
            nowMs += seconds * 1000;
        }
    }
}
