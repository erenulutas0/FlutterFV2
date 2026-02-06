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

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

@MockitoSettings(strictness = Strictness.LENIENT)
class ProgressServiceTest {

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

        // Default stubs to prevent NPEs and ensure flow works
        when(wordRepository.count()).thenReturn(0L);
        when(reviewRepository.count()).thenReturn(0L);
        when(achievementRepository.existsByUserIdAndAchievementCode(anyLong(), anyString())).thenReturn(false);
    }

    @Test
    void getUserProgress_ShouldReturnExistingProgress() {
        UserProgress existingProgress = new UserProgress();
        existingProgress.setUserId(1L);
        existingProgress.setTotalXp(500);

        when(progressRepository.findByUserId(1L)).thenReturn(Optional.of(existingProgress));

        UserProgress result = progressService.getUserProgress();

        assertNotNull(result);
        assertEquals(500, result.getTotalXp());
        verify(progressRepository, never()).save(any(UserProgress.class));
    }

    @Test
    void getUserProgress_ShouldCreateNewProgress_WhenNoneExists() {
        when(progressRepository.findByUserId(1L)).thenReturn(Optional.empty());
        when(progressRepository.save(any(UserProgress.class))).thenAnswer(invocation -> invocation.getArgument(0));

        UserProgress result = progressService.getUserProgress();

        assertNotNull(result);
        assertEquals(0, result.getTotalXp());
        verify(progressRepository, times(1)).save(any(UserProgress.class));
    }

    @Test
    void awardXp_ShouldIncreaseXp_AndSave() {
        UserProgress progress = new UserProgress();
        progress.setTotalXp(100);
        progress.setLevel(2);

        when(progressRepository.findByUserId(1L)).thenReturn(Optional.of(progress));
        when(achievementRepository.existsByUserIdAndAchievementCode(eq(1L), anyString())).thenReturn(true); // Assume
                                                                                                            // all
                                                                                                            // achievements
                                                                                                            // unlocked
                                                                                                            // to
                                                                                                            // simplify

        progressService.awardXp(50, "Test Activity");

        assertEquals(150, progress.getTotalXp());
        verify(progressRepository, atLeastOnce()).save(progress);
    }

    @Test
    void awardXp_ShouldTriggerLevelUp() {
        UserProgress progress = new UserProgress();
        progress.setTotalXp(80);
        progress.setLevel(1);

        when(progressRepository.findByUserId(1L)).thenReturn(Optional.of(progress));
        // Prevent achievements from adding extra XP by pretending they are all unlocked
        when(achievementRepository.existsByUserIdAndAchievementCode(eq(1L), anyString())).thenReturn(true);

        // Adding 50 XP should push total to 130, which is Level 2 (starts at 100)
        progressService.awardXp(50, "Big Win");

        assertEquals(130, progress.getTotalXp());
        assertTrue(progress.getLevel() >= 2);
        verify(progressRepository, atLeastOnce()).save(progress);
    }

    @Test
    void updateStreak_ShouldIncrement_IfActivityYesterday() {
        UserProgress progress = new UserProgress();
        progress.setCurrentStreak(5);
        progress.setLongestStreak(5);
        progress.setLastActivityDate(LocalDate.now().minusDays(1)); // Yesterday

        when(progressRepository.findByUserId(1L)).thenReturn(Optional.of(progress));

        progressService.updateStreak();

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
        progress.setLastActivityDate(LocalDate.now().minusDays(2)); // 2 days ago

        when(progressRepository.findByUserId(1L)).thenReturn(Optional.of(progress));

        progressService.updateStreak();

        assertEquals(1, progress.getCurrentStreak());
        assertEquals(10, progress.getLongestStreak()); // Longest should persist
        assertEquals(LocalDate.now(), progress.getLastActivityDate());
        verify(progressRepository, times(1)).save(progress);
    }

    @Test
    void unlockAchievement_ShouldSave_IfNotUnlocked() {
        Achievement achievement = Achievement.FIRST_WORD;
        when(achievementRepository.existsByUserIdAndAchievementCode(1L, achievement.getCode())).thenReturn(false);

        progressService.unlockAchievement(achievement);

        verify(achievementRepository, times(1)).save(any(UserAchievement.class));
    }

    @Test
    void checkAndUnlockAchievements_ShouldUnlock_FirstWord() {
        UserProgress progress = new UserProgress();
        when(progressRepository.findByUserId(1L)).thenReturn(Optional.of(progress));

        when(wordRepository.count()).thenReturn(1L); // 1 Word exists
        when(achievementRepository.existsByUserIdAndAchievementCode(eq(1L), eq(Achievement.FIRST_WORD.getCode())))
                .thenReturn(false);

        List<Achievement> unlocked = progressService.checkAndUnlockAchievements();

        assertTrue(unlocked.contains(Achievement.FIRST_WORD));
        verify(achievementRepository, atLeastOnce()).save(any(UserAchievement.class));
    }
}
