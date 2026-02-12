package com.ingilizce.calismaapp.entity;

import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class UserActivityTest {

    @Test
    void defaultConstructor_ShouldInitializeCreatedAt() {
        UserActivity activity = new UserActivity();

        assertNotNull(activity.getCreatedAt());
    }

    @Test
    void argsConstructorAndGetters_ShouldExposeAssignedValues() {
        UserActivity activity = new UserActivity(5L, UserActivity.ActivityType.EXAM_COMPLETED, "Completed mock exam");

        assertEquals(5L, activity.getUserId());
        assertEquals(UserActivity.ActivityType.EXAM_COMPLETED, activity.getType());
        assertEquals("Completed mock exam", activity.getDescription());
        assertNotNull(activity.getCreatedAt());
    }

    @Test
    void getters_ShouldReturnReflectedFields() {
        UserActivity activity = new UserActivity();
        LocalDateTime now = LocalDateTime.of(2026, 2, 11, 12, 0);

        ReflectionTestUtils.setField(activity, "id", 11L);
        ReflectionTestUtils.setField(activity, "userId", 9L);
        ReflectionTestUtils.setField(activity, "type", UserActivity.ActivityType.ACHIEVEMENT_UNLOCKED);
        ReflectionTestUtils.setField(activity, "description", "Unlocked streak");
        ReflectionTestUtils.setField(activity, "createdAt", now);

        assertEquals(11L, activity.getId());
        assertEquals(9L, activity.getUserId());
        assertEquals(UserActivity.ActivityType.ACHIEVEMENT_UNLOCKED, activity.getType());
        assertEquals("Unlocked streak", activity.getDescription());
        assertEquals(now, activity.getCreatedAt());
    }
}
