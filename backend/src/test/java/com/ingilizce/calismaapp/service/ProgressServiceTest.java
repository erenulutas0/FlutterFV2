package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.UserAchievement;
import com.ingilizce.calismaapp.entity.UserProgress;
import com.ingilizce.calismaapp.model.Achievement;
import com.ingilizce.calismaapp.repository.UserAchievementRepository;
import com.ingilizce.calismaapp.repository.UserProgressRepository;
import com.ingilizce.calismaapp.repository.WordRepository;
import com.ingilizce.calismaapp.repository.WordReviewRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.TimeZone;
import java.util.function.Predicate;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@MockitoSettings(strictness = Strictness.LENIENT)
class ProgressServiceTest {

    private static final Long USER_ID = 1L;

    @InjectMocks
    private ProgressService progressService;

    @Mock
    private UserProgressRepository progressRepository;

    @Mock
    private UserAchievementRepository achievementRepository;

    @Mock
    private WordRepository wordRepository;

    @Mock
    private WordReviewRepository reviewRepository;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        when(wordRepository.countByUserId(anyLong())).thenReturn(0L);
        when(reviewRepository.countByWordUserId(anyLong())).thenReturn(0L);
        when(achievementRepository.existsByUserIdAndAchievementCode(anyLong(), anyString())).thenReturn(false);
    }

    @Test
    void getUserProgress_ShouldReturnExistingProgress() {
        UserProgress existingProgress = new UserProgress();
        existingProgress.setUserId(USER_ID);
        existingProgress.setTotalXp(500);

        when(progressRepository.findByUserId(USER_ID)).thenReturn(Optional.of(existingProgress));

        UserProgress result = progressService.getUserProgress(USER_ID);

        assertNotNull(result);
        assertEquals(500, result.getTotalXp());
        verify(progressRepository, never()).save(any(UserProgress.class));
    }

    @Test
    void getUserProgress_ShouldCreateNewProgress_WhenNoneExists() {
        when(progressRepository.findByUserId(USER_ID)).thenReturn(Optional.empty());
        when(progressRepository.save(any(UserProgress.class))).thenAnswer(invocation -> invocation.getArgument(0));

        UserProgress result = progressService.getUserProgress(USER_ID);

        assertNotNull(result);
        assertEquals(0, result.getTotalXp());
        verify(progressRepository, times(1)).save(any(UserProgress.class));
    }

    @Test
    void awardXp_ShouldIncreaseXp_AndSave() {
        UserProgress progress = new UserProgress();
        progress.setTotalXp(100);
        progress.setLevel(2);

        when(progressRepository.findByUserId(USER_ID)).thenReturn(Optional.of(progress));
        when(achievementRepository.existsByUserIdAndAchievementCode(eq(USER_ID), anyString())).thenReturn(true);

        progressService.awardXp(USER_ID, 50, "Test Activity");

        assertEquals(150, progress.getTotalXp());
        verify(progressRepository, atLeastOnce()).save(progress);
    }

    @Test
    void awardXp_ShouldTriggerLevelUp() {
        UserProgress progress = new UserProgress();
        progress.setTotalXp(80);
        progress.setLevel(1);

        when(progressRepository.findByUserId(USER_ID)).thenReturn(Optional.of(progress));
        when(achievementRepository.existsByUserIdAndAchievementCode(eq(USER_ID), anyString())).thenReturn(true);

        progressService.awardXp(USER_ID, 50, "Big Win");

        assertEquals(130, progress.getTotalXp());
        assertTrue(progress.getLevel() >= 2);
        verify(progressRepository, atLeastOnce()).save(progress);
    }

    @Test
    void updateStreak_ShouldIncrement_IfActivityYesterday() {
        UserProgress progress = new UserProgress();
        progress.setCurrentStreak(5);
        progress.setLongestStreak(5);
        progress.setLastActivityDate(LocalDate.now().minusDays(1));

        when(progressRepository.findByUserId(USER_ID)).thenReturn(Optional.of(progress));

        progressService.updateStreak(USER_ID);

        assertEquals(6, progress.getCurrentStreak());
        assertEquals(6, progress.getLongestStreak());
        assertEquals(LocalDate.now(), progress.getLastActivityDate());
        verify(progressRepository, times(1)).save(progress);
    }

    @Test
    void updateStreak_ShouldReset_IfActivityMissed() {
        UserProgress progress = new UserProgress();
        progress.setCurrentStreak(10);
        progress.setLongestStreak(10);
        progress.setLastActivityDate(LocalDate.now().minusDays(2));

        when(progressRepository.findByUserId(USER_ID)).thenReturn(Optional.of(progress));

        progressService.updateStreak(USER_ID);

        assertEquals(1, progress.getCurrentStreak());
        assertEquals(10, progress.getLongestStreak());
        assertEquals(LocalDate.now(), progress.getLastActivityDate());
        verify(progressRepository, times(1)).save(progress);
    }

    @Test
    void updateStreak_ShouldDoNothing_IfAlreadyUpdatedToday() {
        UserProgress progress = new UserProgress();
        progress.setCurrentStreak(4);
        progress.setLongestStreak(7);
        progress.setLastActivityDate(LocalDate.now());

        when(progressRepository.findByUserId(USER_ID)).thenReturn(Optional.of(progress));

        progressService.updateStreak(USER_ID);

        assertEquals(4, progress.getCurrentStreak());
        assertEquals(7, progress.getLongestStreak());
        verify(progressRepository, never()).save(progress);
    }

    @Test
    void unlockAchievement_ShouldSave_IfNotUnlocked() {
        Achievement achievement = Achievement.FIRST_WORD;
        when(achievementRepository.existsByUserIdAndAchievementCode(USER_ID, achievement.getCode())).thenReturn(false);

        progressService.unlockAchievement(USER_ID, achievement);

        verify(achievementRepository, times(1)).save(any(UserAchievement.class));
    }

    @Test
    void unlockAchievement_ShouldNotSave_IfAlreadyUnlocked() {
        Achievement achievement = Achievement.FIRST_WORD;
        when(achievementRepository.existsByUserIdAndAchievementCode(USER_ID, achievement.getCode())).thenReturn(true);

        progressService.unlockAchievement(USER_ID, achievement);

        verify(achievementRepository, never()).save(any(UserAchievement.class));
    }

    @Test
    void checkAndUnlockAchievements_ShouldUnlock_FirstWord() {
        UserProgress progress = new UserProgress();
        when(progressRepository.findByUserId(USER_ID)).thenReturn(Optional.of(progress));

        when(wordRepository.countByUserId(USER_ID)).thenReturn(1L);
        when(achievementRepository.existsByUserIdAndAchievementCode(eq(USER_ID), eq(Achievement.FIRST_WORD.getCode())))
                .thenReturn(false);

        List<Achievement> unlocked = progressService.checkAndUnlockAchievements(USER_ID);

        assertTrue(unlocked.contains(Achievement.FIRST_WORD));
        verify(achievementRepository, atLeastOnce()).save(any(UserAchievement.class));
    }

    @Test
    void checkAndUnlockAchievements_ShouldReturnEmpty_WhenAllAchievementsAlreadyUnlocked() {
        UserProgress progress = new UserProgress();
        progress.setCurrentStreak(50);
        progress.setLevel(10);

        when(progressRepository.findByUserId(USER_ID)).thenReturn(Optional.of(progress));
        when(wordRepository.countByUserId(USER_ID)).thenReturn(999L);
        when(reviewRepository.countByWordUserId(USER_ID)).thenReturn(999L);
        when(achievementRepository.existsByUserIdAndAchievementCode(eq(USER_ID), anyString())).thenReturn(true);

        List<Achievement> unlocked = progressService.checkAndUnlockAchievements(USER_ID);

        assertTrue(unlocked.isEmpty());
        verify(progressRepository, never()).save(progress);
    }

    @Test
    void getUnlockedAchievements_ShouldMapOnlyKnownAchievementCodes() {
        UserAchievement valid = new UserAchievement(USER_ID, Achievement.FIRST_WORD.getCode());
        valid.setUnlockedAt(LocalDateTime.now());
        UserAchievement unknown = new UserAchievement(USER_ID, "UNKNOWN_CODE");

        when(achievementRepository.findByUserId(USER_ID)).thenReturn(List.of(valid, unknown));

        List<Map<String, Object>> unlocked = progressService.getUnlockedAchievements(USER_ID);

        assertEquals(1, unlocked.size());
        assertEquals(Achievement.FIRST_WORD.getCode(), unlocked.get(0).get("code"));
    }

    @Test
    void getAllAchievements_ShouldIncludeUnlockedFlag() {
        when(achievementRepository.existsByUserIdAndAchievementCode(eq(USER_ID), anyString()))
                .thenAnswer(invocation -> Achievement.FIRST_WORD.getCode().equals(invocation.getArgument(1)));

        List<Map<String, Object>> all = progressService.getAllAchievements(USER_ID);

        assertEquals(Achievement.values().length, all.size());
        Map<String, Object> firstWord = all.stream()
                .filter(a -> Achievement.FIRST_WORD.getCode().equals(a.get("code")))
                .findFirst()
                .orElseThrow();
        assertEquals(true, firstWord.get("unlocked"));
    }

    @Test
    void getStats_ShouldReturnProgressAndAchievementCounts() {
        UserProgress progress = new UserProgress();
        progress.setUserId(USER_ID);
        progress.setTotalXp(200);
        progress.setLevel(2);
        progress.setCurrentStreak(3);
        progress.setLongestStreak(8);
        progress.setLastActivityDate(LocalDate.now().minusDays(1));

        when(progressRepository.findByUserId(USER_ID)).thenReturn(Optional.of(progress));
        when(achievementRepository.findByUserId(USER_ID))
                .thenReturn(List.of(
                        new UserAchievement(USER_ID, Achievement.FIRST_WORD.getCode()),
                        new UserAchievement(USER_ID, Achievement.FIRST_REVIEW.getCode())));

        Map<String, Object> stats = progressService.getStats(USER_ID);

        assertEquals(200, stats.get("totalXp"));
        assertEquals(2, stats.get("level"));
        assertEquals(3, stats.get("currentStreak"));
        assertEquals(8, stats.get("longestStreak"));
        assertEquals(2L, stats.get("achievementsUnlocked"));
        assertEquals((long) Achievement.values().length, stats.get("achievementsTotal"));
    }

    @Test
    void isAchievementUnlocked_ShouldReturnRepositoryValue() {
        when(achievementRepository.existsByUserIdAndAchievementCode(USER_ID, Achievement.STREAK_3.getCode()))
                .thenReturn(true);

        boolean unlocked = progressService.isAchievementUnlocked(USER_ID, Achievement.STREAK_3);

        assertTrue(unlocked);
    }

    @Test
    void checkAndUnlockAchievements_ShouldUnlockEarlyBird_WhenLocalTimeBeforeEight() {
        TimeZone original = TimeZone.getDefault();
        String zoneId = findZoneId(time -> time.isBefore(LocalTime.of(8, 0)));
        assertNotNull(zoneId, "No timezone found with local hour < 8");

        try {
            TimeZone.setDefault(TimeZone.getTimeZone(zoneId));

            UserProgress progress = new UserProgress();
            progress.setCurrentStreak(0);
            progress.setLevel(1);
            when(progressRepository.findByUserId(USER_ID)).thenReturn(Optional.of(progress));
            when(wordRepository.countByUserId(USER_ID)).thenReturn(0L);
            when(reviewRepository.countByWordUserId(USER_ID)).thenReturn(0L);
            when(achievementRepository.existsByUserIdAndAchievementCode(eq(USER_ID), anyString())).thenReturn(false);

            List<Achievement> unlocked = progressService.checkAndUnlockAchievements(USER_ID);

            assertTrue(unlocked.contains(Achievement.EARLY_BIRD));
        } finally {
            TimeZone.setDefault(original);
        }
    }

    @Test
    void checkAndUnlockAchievements_ShouldUnlockNightOwl_WhenLocalTimeAfterTwentyThree() {
        TimeZone original = TimeZone.getDefault();
        String zoneId = findZoneId(time -> time.isAfter(LocalTime.of(23, 0)));
        assertNotNull(zoneId, "No timezone found with local time after 23:00");

        try {
            TimeZone.setDefault(TimeZone.getTimeZone(zoneId));

            UserProgress progress = new UserProgress();
            progress.setCurrentStreak(0);
            progress.setLevel(1);
            when(progressRepository.findByUserId(USER_ID)).thenReturn(Optional.of(progress));
            when(wordRepository.countByUserId(USER_ID)).thenReturn(0L);
            when(reviewRepository.countByWordUserId(USER_ID)).thenReturn(0L);
            when(achievementRepository.existsByUserIdAndAchievementCode(eq(USER_ID), anyString())).thenReturn(false);

            List<Achievement> unlocked = progressService.checkAndUnlockAchievements(USER_ID);

            assertTrue(unlocked.contains(Achievement.NIGHT_OWL));
        } finally {
            TimeZone.setDefault(original);
        }
    }

    private static String findZoneId(Predicate<LocalTime> timePredicate) {
        return ZoneId.getAvailableZoneIds().stream()
                .filter(id -> timePredicate.test(LocalTime.now(ZoneId.of(id))))
                .findFirst()
                .orElse(null);
    }
}
