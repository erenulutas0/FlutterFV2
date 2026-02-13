package com.ingilizce.calismaapp.config;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class SecurityHeadersPropertiesTest {

    @Test
    void defaults_ShouldBeSafeForNonProd() {
        SecurityHeadersProperties properties = new SecurityHeadersProperties();

        assertFalse(properties.isEnabled());
        assertTrue(properties.isHstsEnabled());
        assertEquals(31536000, properties.getHstsMaxAgeSeconds());
        assertTrue(properties.isHstsIncludeSubDomains());
        assertFalse(properties.isHstsPreload());
    }

    @Test
    void setters_ShouldOverrideDefaults() {
        SecurityHeadersProperties properties = new SecurityHeadersProperties();
        properties.setEnabled(true);
        properties.setHstsEnabled(false);
        properties.setHstsMaxAgeSeconds(60);
        properties.setHstsIncludeSubDomains(false);
        properties.setHstsPreload(true);
        properties.setContentSecurityPolicy("default-src 'none'");
        properties.setReferrerPolicy("same-origin");
        properties.setPermissionsPolicy("microphone=()");

        assertTrue(properties.isEnabled());
        assertFalse(properties.isHstsEnabled());
        assertEquals(60, properties.getHstsMaxAgeSeconds());
        assertFalse(properties.isHstsIncludeSubDomains());
        assertTrue(properties.isHstsPreload());
        assertEquals("default-src 'none'", properties.getContentSecurityPolicy());
        assertEquals("same-origin", properties.getReferrerPolicy());
        assertEquals("microphone=()", properties.getPermissionsPolicy());
    }
}
