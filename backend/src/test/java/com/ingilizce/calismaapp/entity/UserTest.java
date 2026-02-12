package com.ingilizce.calismaapp.entity;

import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class UserTest {

    @Test
    void constructorWithNullableDisplayName_ShouldFallbackToEmailPrefix() {
        User user = new User("alice@example.com", "hash", null);

        assertEquals("alice", user.getDisplayName());
        assertEquals(User.Role.USER, user.getRole());
        assertNotNull(user.getCreatedAt());
    }

    @Test
    void constructorWithInvalidEmail_ShouldFallbackToGenericUserName() {
        User user = new User("invalid-email", "hash", null);

        assertEquals("User", user.getDisplayName());
    }

    @Test
    void setters_ShouldAllowRoleAndCreatedAtOverrides() {
        User user = new User();
        LocalDateTime createdAt = LocalDateTime.of(2026, 2, 11, 20, 45);

        user.setRole(User.Role.ADMIN);
        user.setCreatedAt(createdAt);

        assertEquals(User.Role.ADMIN, user.getRole());
        assertEquals(createdAt, user.getCreatedAt());
    }

    @Test
    void subscriptionAndOnlineHelpers_ShouldReflectDateState() {
        User user = new User();

        user.setSubscriptionEndDate(LocalDateTime.now().minusMinutes(1));
        assertFalse(user.isSubscriptionActive());

        user.setSubscriptionEndDate(LocalDateTime.now().plusDays(1));
        assertTrue(user.isSubscriptionActive());

        user.setLastSeenAt(null);
        assertFalse(user.isOnline());

        user.setLastSeenAt(LocalDateTime.now().minusMinutes(10));
        assertFalse(user.isOnline());

        user.setLastSeenAt(LocalDateTime.now().minusMinutes(1));
        assertTrue(user.isOnline());
    }
}
