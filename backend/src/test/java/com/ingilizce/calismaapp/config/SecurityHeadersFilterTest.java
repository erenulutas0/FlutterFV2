package com.ingilizce.calismaapp.config;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class SecurityHeadersFilterTest {

    @Test
    void doFilter_ShouldSetHeaders_WhenEnabledAndSecureRequest() throws Exception {
        SecurityHeadersProperties properties = new SecurityHeadersProperties();
        properties.setEnabled(true);
        properties.setHstsEnabled(true);
        properties.setHstsMaxAgeSeconds(86400);
        properties.setHstsIncludeSubDomains(true);
        properties.setHstsPreload(true);

        SecurityHeadersFilter filter = new SecurityHeadersFilter(properties);
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/health");
        request.setSecure(true);
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, new MockFilterChain());

        assertEquals("nosniff", response.getHeader("X-Content-Type-Options"));
        assertEquals("DENY", response.getHeader("X-Frame-Options"));
        assertEquals(properties.getReferrerPolicy(), response.getHeader("Referrer-Policy"));
        assertEquals(properties.getPermissionsPolicy(), response.getHeader("Permissions-Policy"));
        assertEquals(properties.getContentSecurityPolicy(), response.getHeader("Content-Security-Policy"));
        assertEquals("max-age=86400; includeSubDomains; preload", response.getHeader("Strict-Transport-Security"));
    }

    @Test
    void doFilter_ShouldSkipHsts_WhenRequestIsNotSecure() throws Exception {
        SecurityHeadersProperties properties = new SecurityHeadersProperties();
        properties.setEnabled(true);
        properties.setHstsEnabled(true);

        SecurityHeadersFilter filter = new SecurityHeadersFilter(properties);
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/health");
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, new MockFilterChain());

        assertNull(response.getHeader("Strict-Transport-Security"));
        assertEquals("nosniff", response.getHeader("X-Content-Type-Options"));
    }

    @Test
    void doFilter_ShouldNotSetHeaders_WhenDisabled() throws Exception {
        SecurityHeadersProperties properties = new SecurityHeadersProperties();
        properties.setEnabled(false);

        SecurityHeadersFilter filter = new SecurityHeadersFilter(properties);
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/health");
        request.setSecure(true);
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, new MockFilterChain());

        assertNull(response.getHeader("X-Content-Type-Options"));
        assertNull(response.getHeader("X-Frame-Options"));
        assertNull(response.getHeader("Content-Security-Policy"));
        assertNull(response.getHeader("Strict-Transport-Security"));
    }

    @Test
    void doFilter_ShouldTreatForwardedProtoAsSecure() throws Exception {
        SecurityHeadersProperties properties = new SecurityHeadersProperties();
        properties.setEnabled(true);
        properties.setHstsEnabled(true);
        properties.setHstsIncludeSubDomains(false);
        properties.setHstsPreload(false);
        properties.setHstsMaxAgeSeconds(31536000);

        SecurityHeadersFilter filter = new SecurityHeadersFilter(properties);
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/health");
        request.addHeader("X-Forwarded-Proto", "https");
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, new MockFilterChain());

        assertEquals("max-age=31536000", response.getHeader("Strict-Transport-Security"));
    }
}
