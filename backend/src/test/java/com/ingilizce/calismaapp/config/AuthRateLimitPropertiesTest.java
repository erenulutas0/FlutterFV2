package com.ingilizce.calismaapp.config;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class AuthRateLimitPropertiesTest {

    @Test
    void defaults_ShouldMatchSecureBaseline() {
        AuthRateLimitProperties properties = new AuthRateLimitProperties();

        assertTrue(properties.isEnabled());
        assertTrue(properties.isRedisEnabled());
        assertEquals("memory", properties.getRedisFallbackMode());
        assertEquals(60, properties.getRedisFailureBlockSeconds());
        assertEquals(8, properties.getLoginPrincipalMaxAttempts());
        assertEquals(300, properties.getLoginPrincipalWindowSeconds());
        assertEquals(900, properties.getLoginPrincipalBlockSeconds());
        assertEquals(40, properties.getLoginIpMaxAttempts());
        assertEquals(300, properties.getLoginIpWindowSeconds());
        assertEquals(900, properties.getLoginIpBlockSeconds());
        assertEquals(10, properties.getRegisterIpMaxAttempts());
        assertEquals(600, properties.getRegisterIpWindowSeconds());
        assertEquals(1800, properties.getRegisterIpBlockSeconds());
    }
}
