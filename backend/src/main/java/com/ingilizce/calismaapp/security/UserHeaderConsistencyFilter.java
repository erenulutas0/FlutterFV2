package com.ingilizce.calismaapp.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Map;

@Component
public class UserHeaderConsistencyFilter extends OncePerRequestFilter {

    private static final String USER_ID_HEADER = "X-User-Id";

    private final JwtProperties jwtProperties;
    private final ObjectMapper objectMapper;

    public UserHeaderConsistencyFilter(JwtProperties jwtProperties, ObjectMapper objectMapper) {
        this.jwtProperties = jwtProperties;
        this.objectMapper = objectMapper;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        if (!jwtProperties.isEnforceAuth()) {
            filterChain.doFilter(request, response);
            return;
        }

        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            filterChain.doFilter(request, response);
            return;
        }

        Long authenticatedUserId = extractAuthenticatedUserId(authentication.getPrincipal());
        if (authenticatedUserId == null) {
            filterChain.doFilter(request, response);
            return;
        }

        String headerUserId = request.getHeader(USER_ID_HEADER);
        if (headerUserId == null || headerUserId.isBlank()) {
            filterChain.doFilter(request, response);
            return;
        }

        Long requestedUserId;
        try {
            requestedUserId = Long.parseLong(headerUserId.trim());
        } catch (NumberFormatException ex) {
            writeError(response, HttpServletResponse.SC_BAD_REQUEST, "Invalid X-User-Id header");
            return;
        }

        if (!authenticatedUserId.equals(requestedUserId)) {
            writeError(response, HttpServletResponse.SC_FORBIDDEN, "User identity mismatch");
            return;
        }

        filterChain.doFilter(request, response);
    }

    private Long extractAuthenticatedUserId(Object principal) {
        if (principal instanceof Long id) {
            return id;
        }
        if (principal instanceof String text) {
            try {
                return Long.parseLong(text);
            } catch (NumberFormatException ignored) {
                return null;
            }
        }
        return null;
    }

    private void writeError(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.getWriter().write(objectMapper.writeValueAsString(Map.of("error", message, "success", false)));
    }
}
