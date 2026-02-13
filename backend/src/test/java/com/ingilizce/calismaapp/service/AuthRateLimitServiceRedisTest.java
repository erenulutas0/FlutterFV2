package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.config.AuthRateLimitProperties;
import com.ingilizce.calismaapp.service.AuthRateLimitService.RateLimitDecision;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.Test;
import org.springframework.data.redis.core.StringRedisTemplate;

import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class AuthRateLimitServiceRedisTest {

    @Test
    void checkLogin_ShouldReturnBlockedFromRedisBlockKey() {
        AuthRateLimitProperties properties = new AuthRateLimitProperties();
        properties.setEnabled(true);
        properties.setRedisEnabled(true);

        StringRedisTemplate redisTemplate = mock(StringRedisTemplate.class);
        String principalBlockKey = "auth:rl:block:login:principal:user@test.com";

        when(redisTemplate.hasKey(principalBlockKey)).thenReturn(true);
        when(redisTemplate.getExpire(principalBlockKey, TimeUnit.SECONDS)).thenReturn(42L);

        AuthRateLimitService service = new AuthRateLimitService(properties, redisTemplate);
        RateLimitDecision decision = service.checkLogin("User@Test.com", "10.0.0.1");

        assertTrue(decision.blocked());
        assertEquals(42, decision.retryAfterSeconds());
    }

    @Test
    void redisFailure_ShouldExposeFallbackMetrics_AndRecoverOnNextSuccess() {
        AuthRateLimitProperties properties = new AuthRateLimitProperties();
        properties.setEnabled(true);
        properties.setRedisEnabled(true);

        StringRedisTemplate redisTemplate = mock(StringRedisTemplate.class);
        String principalBlockKey = "auth:rl:block:login:principal:user@test.com";
        String ipBlockKey = "auth:rl:block:login:ip:10.0.0.1";

        when(redisTemplate.hasKey(principalBlockKey))
                .thenThrow(new RuntimeException("redis-down"))
                .thenReturn(false);
        when(redisTemplate.hasKey(ipBlockKey)).thenReturn(false);

        SimpleMeterRegistry meterRegistry = new SimpleMeterRegistry();
        AuthRateLimitService service = new AuthRateLimitService(properties, redisTemplate, meterRegistry);

        RateLimitDecision firstDecision = service.checkLogin("User@Test.com", "10.0.0.1");
        assertFalse(firstDecision.blocked());
        assertEquals(1.0, meterRegistry.get("auth.rate.limit.redis.fallback.active").gauge().value(), 0.0001);
        assertEquals(1.0, meterRegistry.get("auth.rate.limit.redis.failure.total")
                .tag("operation", "checkLogin")
                .counter()
                .count(), 0.0001);
        assertEquals(1.0, meterRegistry.get("auth.rate.limit.redis.fallback.transition.total")
                .tag("state", "activated")
                .counter()
                .count(), 0.0001);

        RateLimitDecision secondDecision = service.checkLogin("User@Test.com", "10.0.0.1");
        assertFalse(secondDecision.blocked());
        assertEquals(0.0, meterRegistry.get("auth.rate.limit.redis.fallback.active").gauge().value(), 0.0001);
        assertEquals(1.0, meterRegistry.get("auth.rate.limit.redis.fallback.transition.total")
                .tag("state", "recovered")
                .counter()
                .count(), 0.0001);
    }

    @Test
    void redisFailure_ShouldBlockAuth_WhenFailClosedModeEnabled() {
        AuthRateLimitProperties properties = new AuthRateLimitProperties();
        properties.setEnabled(true);
        properties.setRedisEnabled(true);
        properties.setRedisFallbackMode("deny");
        properties.setRedisFailureBlockSeconds(90);

        StringRedisTemplate redisTemplate = mock(StringRedisTemplate.class);
        when(redisTemplate.hasKey("auth:rl:block:register:ip:10.0.0.2"))
                .thenThrow(new RuntimeException("redis-down"));

        SimpleMeterRegistry meterRegistry = new SimpleMeterRegistry();
        AuthRateLimitService service = new AuthRateLimitService(properties, redisTemplate, meterRegistry);

        RateLimitDecision decision = service.checkRegister("10.0.0.2");
        assertTrue(decision.blocked());
        assertEquals(90, decision.retryAfterSeconds());
        assertEquals(1.0, meterRegistry.get("auth.rate.limit.redis.fail.closed.block.total")
                .tag("operation", "checkRegister")
                .counter()
                .count(), 0.0001);
    }
}
