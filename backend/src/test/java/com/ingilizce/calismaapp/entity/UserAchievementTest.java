package com.ingilizce.calismaapp.entity;

import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class UserAchievementTest {

    @Test
    void defaultConstructor_ShouldInitializeDefaults() {
        UserAchievement achievement = new UserAchievement();

        assertEquals(1L, achievement.getUserId());
        assertNotNull(achievement.getUnlockedAt());
    }

    @Test
    void constructorWithArgs_ShouldSetFields() {
        UserAchievement achievement = new UserAchievement(7L, "first_streak");

        assertEquals(7L, achievement.getUserId());
        assertEquals("first_streak", achievement.getAchievementCode());
        assertNotNull(achievement.getUnlockedAt());
    }

    @Test
    void setters_ShouldUpdateFields() {
        UserAchievement achievement = new UserAchievement();
        LocalDateTime now = LocalDateTime.now();

        achievement.setId(10L);
        achievement.setUserId(11L);
        achievement.setAchievementCode("weekly_master");
        achievement.setUnlockedAt(now);

        assertEquals(10L, achievement.getId());
        assertEquals(11L, achievement.getUserId());
        assertEquals("weekly_master", achievement.getAchievementCode());
        assertEquals(now, achievement.getUnlockedAt());
    }
}
