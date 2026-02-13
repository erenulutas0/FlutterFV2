package com.ingilizce.calismaapp.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

public class SecurityHeadersFilter extends OncePerRequestFilter {

    private final SecurityHeadersProperties properties;

    public SecurityHeadersFilter(SecurityHeadersProperties properties) {
        this.properties = properties;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        if (properties.isEnabled()) {
            response.setHeader("X-Content-Type-Options", "nosniff");
            response.setHeader("X-Frame-Options", "DENY");
            response.setHeader("Referrer-Policy", properties.getReferrerPolicy());
            response.setHeader("Permissions-Policy", properties.getPermissionsPolicy());
            response.setHeader("Content-Security-Policy", properties.getContentSecurityPolicy());

            if (properties.isHstsEnabled() && isSecureRequest(request)) {
                response.setHeader("Strict-Transport-Security", buildHstsHeaderValue());
            }
        }

        filterChain.doFilter(request, response);
    }

    private boolean isSecureRequest(HttpServletRequest request) {
        if (request.isSecure()) {
            return true;
        }
        String forwardedProto = request.getHeader("X-Forwarded-Proto");
        return forwardedProto != null && "https".equalsIgnoreCase(forwardedProto.trim());
    }

    private String buildHstsHeaderValue() {
        StringBuilder value = new StringBuilder("max-age=").append(properties.getHstsMaxAgeSeconds());
        if (properties.isHstsIncludeSubDomains()) {
            value.append("; includeSubDomains");
        }
        if (properties.isHstsPreload()) {
            value.append("; preload");
        }
        return value.toString();
    }
}
