package com.ingilizce.calismaapp.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component
public class CurrentUserContext {

    private final JwtProperties jwtProperties;

    public CurrentUserContext(JwtProperties jwtProperties) {
        this.jwtProperties = jwtProperties;
    }

    public Optional<Long> getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            return Optional.empty();
        }

        Object principal = authentication.getPrincipal();
        if (principal instanceof Long id) {
            return Optional.of(id);
        }
        if (principal instanceof String value) {
            try {
                return Optional.of(Long.parseLong(value));
            } catch (NumberFormatException ignored) {
                return Optional.empty();
            }
        }
        return Optional.empty();
    }

    public boolean hasRole(String role) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getAuthorities() == null) {
            return false;
        }
        String expected = "ROLE_" + role;
        for (GrantedAuthority authority : authentication.getAuthorities()) {
            if (expected.equals(authority.getAuthority())) {
                return true;
            }
        }
        return false;
    }

    public boolean isSelfOrAdmin(Long targetUserId) {
        if (!jwtProperties.isEnforceAuth()) {
            return true;
        }
        if (targetUserId == null) {
            return false;
        }
        if (hasRole("ADMIN")) {
            return true;
        }
        return getCurrentUserId().map(id -> id.equals(targetUserId)).orElse(false);
    }

    public boolean shouldEnforceAuthz() {
        return jwtProperties.isEnforceAuth();
    }
}
