package com.ingilizce.calismaapp.entity;

import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

class UserProgressTest {

    @Test
    void constructor_ShouldInitializeDefaults() {
        UserProgress progress = new UserProgress();

        assertEquals(1L, progress.getUserId());
        assertEquals(0, progress.getTotalXp());
        assertEquals(1, progress.getLevel());
        assertEquals(0, progress.getCurrentStreak());
        assertEquals(0, progress.getLongestStreak());
        assertNotNull(progress.getCreatedAt());
        assertNotNull(progress.getUpdatedAt());
    }

    @Test
    void addXp_ShouldComputeLevelsAcrossThresholds() {
        assertLevelForTotalXp(99, 1);
        assertLevelForTotalXp(100, 2);
        assertLevelForTotalXp(249, 2);
        assertLevelForTotalXp(250, 3);
        assertLevelForTotalXp(499, 3);
        assertLevelForTotalXp(500, 4);
        assertLevelForTotalXp(999, 4);
        assertLevelForTotalXp(1000, 5);
        assertLevelForTotalXp(1999, 5);
        assertLevelForTotalXp(2000, 6);
        assertLevelForTotalXp(3499, 6);
        assertLevelForTotalXp(3500, 7);
        assertLevelForTotalXp(5499, 7);
        assertLevelForTotalXp(5500, 8);
        assertLevelForTotalXp(7999, 8);
        assertLevelForTotalXp(8000, 9);
        assertLevelForTotalXp(10999, 9);
        assertLevelForTotalXp(11000, 10);
        assertLevelForTotalXp(14999, 10);
        assertLevelForTotalXp(15000, 10);
        assertLevelForTotalXp(19999, 10);
        assertLevelForTotalXp(20000, 11);
        assertLevelForTotalXp(20001, 11);
    }

    @Test
    void addXp_ShouldReturnTrueWhenLevelUp() {
        UserProgress progress = new UserProgress();
        boolean leveledUp = progress.addXp(100);

        assertTrue(leveledUp);
        assertEquals(2, progress.getLevel());
    }

    @Test
    void addXp_ShouldReturnFalseWhenNoLevelUp() {
        UserProgress progress = new UserProgress();
        boolean leveledUp = progress.addXp(20);

        assertFalse(leveledUp);
        assertEquals(1, progress.getLevel());
    }

    @Test
    void getXpForNextLevel_ShouldMatchCurrentLevel() {
        UserProgress progress = new UserProgress();

        progress.setLevel(1);
        assertEquals(100, progress.getXpForNextLevel());

        progress.setLevel(2);
        assertEquals(150, progress.getXpForNextLevel());

        progress.setLevel(10);
        assertEquals(4000, progress.getXpForNextLevel());

        progress.setLevel(11);
        assertEquals(5000, progress.getXpForNextLevel());

        progress.setLevel(12);
        assertEquals(5000, progress.getXpForNextLevel());
    }

    @Test
    void getXpForNextLevel_ShouldMatchMidLevelBands() {
        UserProgress progress = new UserProgress();

        progress.setLevel(4);
        assertEquals(500, progress.getXpForNextLevel());

        progress.setLevel(5);
        assertEquals(1000, progress.getXpForNextLevel());

        progress.setLevel(6);
        assertEquals(1500, progress.getXpForNextLevel());

        progress.setLevel(7);
        assertEquals(2000, progress.getXpForNextLevel());

        progress.setLevel(8);
        assertEquals(2500, progress.getXpForNextLevel());

        progress.setLevel(9);
        assertEquals(3000, progress.getXpForNextLevel());
    }

    @Test
    void getLevelProgress_ShouldReturnFractionForCurrentBand() {
        UserProgress progress = new UserProgress();
        progress.setTotalXp(175);
        progress.setLevel(2);

        assertEquals(0.5d, progress.getLevelProgress(), 0.0001d);
    }

    @Test
    void setters_ShouldUpdateUpdatedAtForMutableFields() throws InterruptedException {
        UserProgress progress = new UserProgress();
        LocalDateTime initialUpdatedAt = progress.getUpdatedAt();

        Thread.sleep(2);
        progress.setTotalXp(10);
        assertTrue(progress.getUpdatedAt().isAfter(initialUpdatedAt));

        LocalDateTime afterXp = progress.getUpdatedAt();
        Thread.sleep(2);
        progress.setLevel(2);
        assertTrue(progress.getUpdatedAt().isAfter(afterXp));

        LocalDateTime afterLevel = progress.getUpdatedAt();
        Thread.sleep(2);
        progress.setCurrentStreak(3);
        assertTrue(progress.getUpdatedAt().isAfter(afterLevel));

        LocalDateTime afterStreak = progress.getUpdatedAt();
        Thread.sleep(2);
        progress.setLongestStreak(5);
        assertTrue(progress.getUpdatedAt().isAfter(afterStreak));

        LocalDateTime afterLongest = progress.getUpdatedAt();
        Thread.sleep(2);
        progress.setLastActivityDate(LocalDate.now());
        assertTrue(progress.getUpdatedAt().isAfter(afterLongest));
    }

    @Test
    void idAndCreatedUpdatedSetters_ShouldSetExplicitValues() {
        UserProgress progress = new UserProgress();
        LocalDateTime created = LocalDateTime.of(2026, 2, 10, 12, 0);
        LocalDateTime updated = LocalDateTime.of(2026, 2, 10, 12, 30);

        progress.setId(55L);
        progress.setUserId(9L);
        progress.setCreatedAt(created);
        progress.setUpdatedAt(updated);

        assertEquals(55L, progress.getId());
        assertEquals(9L, progress.getUserId());
        assertEquals(created, progress.getCreatedAt());
        assertEquals(updated, progress.getUpdatedAt());
    }

    private static void assertLevelForTotalXp(int xp, int expectedLevel) {
        UserProgress progress = new UserProgress();
        progress.addXp(xp);
        assertEquals(expectedLevel, progress.getLevel(), "xp=" + xp);
    }
}
