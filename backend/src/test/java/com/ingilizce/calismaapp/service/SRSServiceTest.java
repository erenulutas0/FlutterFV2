package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.Word;
import com.ingilizce.calismaapp.repository.WordRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

public class SRSServiceTest {

    @Mock
    private WordRepository wordRepository;

    @Mock
    private ProgressService progressService;

    @InjectMocks
    private SRSService srsService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void getWordsForReview_ShouldReturnWords() {
        List<Word> words = new ArrayList<>();
        words.add(new Word());
        when(wordRepository.findByUserIdAndNextReviewDateLessThanEqual(eq(1L), any(LocalDate.class))).thenReturn(words);

        List<Word> result = srsService.getWordsForReview(1L);
        assertEquals(1, result.size());
    }

    @Test
    void submitReview_ShouldUpdateWord() {
        Word word = new Word();
        word.setId(1L);
        word.setEnglishWord("Test");
        word.setReviewCount(1);
        word.setEaseFactor(2.5);

        when(wordRepository.findByIdAndUserId(1L, 1L)).thenReturn(Optional.of(word));
        when(wordRepository.save(any(Word.class))).thenReturn(word);

        Word updated = srsService.submitReview(1L, 1L, 5);

        assertNotNull(updated);
        assertEquals(2, updated.getReviewCount());
        assertNotNull(updated.getNextReviewDate());
        verify(progressService).awardXp(eq(1L), eq(5), anyString());
    }

    @Test
    void submitReview_WithLowQuality_ShouldResetInterval() {
        Word word = new Word();
        word.setId(1L);
        word.setReviewCount(5);
        word.setEaseFactor(2.5);

        when(wordRepository.findByIdAndUserId(1L, 1L)).thenReturn(Optional.of(word));
        when(wordRepository.save(any(Word.class))).thenReturn(word);

        Word updated = srsService.submitReview(1L, 1L, 1);

        assertEquals(LocalDate.now().plusDays(1), updated.getNextReviewDate());
        verify(progressService).awardXp(eq(1L), eq(1), anyString());
    }

    @Test
    void getStats_ShouldReturnCorrectData() {
        when(wordRepository.findByUserIdAndNextReviewDateLessThanEqual(eq(1L), any(LocalDate.class)))
                .thenReturn(new ArrayList<>());
        when(wordRepository.countByUserId(1L)).thenReturn(10L);
        when(wordRepository.findByUserIdAndReviewCountGreaterThan(1L, 0)).thenReturn(new ArrayList<>());

        var stats = srsService.getStats(1L);
        assertEquals(10L, stats.get("totalWords"));
    }

    @Test
    void submitReview_ShouldThrow_WhenQualityOutOfRange() {
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> srsService.submitReview(1L, 1L, -1));
        assertEquals("Quality must be between 0 and 5", ex.getMessage());

        IllegalArgumentException ex2 = assertThrows(IllegalArgumentException.class,
                () -> srsService.submitReview(1L, 1L, 6));
        assertEquals("Quality must be between 0 and 5", ex2.getMessage());
    }

    @Test
    void submitReview_ShouldThrow_WhenWordNotFound() {
        when(wordRepository.findByIdAndUserId(99L, 1L)).thenReturn(Optional.empty());

        RuntimeException ex = assertThrows(RuntimeException.class, () -> srsService.submitReview(1L, 99L, 4));
        assertEquals("Word not found for user: 99", ex.getMessage());
    }

    @Test
    void submitReview_ShouldAwardFourXp_WhenQualityIsFour() {
        Word word = new Word();
        word.setId(1L);
        word.setEnglishWord("apple");
        word.setReviewCount(1); // becomes 2 -> second interval branch
        word.setEaseFactor(2.5);

        when(wordRepository.findByIdAndUserId(1L, 1L)).thenReturn(Optional.of(word));
        when(wordRepository.save(any(Word.class))).thenReturn(word);

        Word updated = srsService.submitReview(1L, 1L, 4);

        assertEquals(2, updated.getReviewCount());
        assertEquals(LocalDate.now().plusDays(6), updated.getNextReviewDate());
        verify(progressService).awardXp(eq(1L), eq(4), contains("Quality: 4"));
        verify(progressService).updateStreak(1L);
    }

    @Test
    void submitReview_ShouldAwardTwoXp_WhenQualityIsThree() {
        Word word = new Word();
        word.setId(1L);
        word.setEnglishWord("banana");
        word.setReviewCount(2); // becomes 3 -> formula branch
        word.setEaseFactor(2.5);

        when(wordRepository.findByIdAndUserId(1L, 1L)).thenReturn(Optional.of(word));
        when(wordRepository.save(any(Word.class))).thenReturn(word);

        Word updated = srsService.submitReview(1L, 1L, 3);

        assertEquals(3, updated.getReviewCount());
        assertEquals(LocalDate.now().plusDays(14), updated.getNextReviewDate());
        verify(progressService).awardXp(eq(1L), eq(2), contains("Quality: 3"));
    }

    @Test
    void submitReview_ShouldKeepEaseFactorAtMinimum_WhenVeryLowQuality() {
        Word word = new Word();
        word.setId(1L);
        word.setEnglishWord("minimum");
        word.setReviewCount(2);
        word.setEaseFactor(1.3);

        when(wordRepository.findByIdAndUserId(1L, 1L)).thenReturn(Optional.of(word));
        when(wordRepository.save(any(Word.class))).thenReturn(word);

        Word updated = srsService.submitReview(1L, 1L, 0);

        assertEquals(1.3, updated.getEaseFactor());
        assertEquals(LocalDate.now().plusDays(1), updated.getNextReviewDate());
        verify(progressService).awardXp(eq(1L), eq(1), contains("Quality: 0"));
    }

    @Test
    void submitReview_ShouldInitializeSrsFields_WhenFirstReview() {
        Word word = new Word();
        word.setId(1L);
        word.setEnglishWord("init");
        word.setReviewCount(0);
        word.setEaseFactor(null);
        word.setNextReviewDate(null);

        when(wordRepository.findByIdAndUserId(1L, 1L)).thenReturn(Optional.of(word));
        when(wordRepository.save(any(Word.class))).thenReturn(word);

        Word updated = srsService.submitReview(1L, 1L, 5);

        assertEquals(1, updated.getReviewCount());
        assertEquals(2.6, updated.getEaseFactor());
        assertEquals(LocalDate.now().plusDays(1), updated.getNextReviewDate());
        assertNotNull(updated.getLastReviewDate());
    }

    @Test
    void initializeWordForSRS_ShouldNotOverwriteExistingValues() {
        Word word = new Word();
        word.setEnglishWord("keep");
        word.setNextReviewDate(LocalDate.now().plusDays(4));
        word.setReviewCount(2);
        word.setEaseFactor(2.1);

        srsService.initializeWordForSRS(word);

        assertEquals(2, word.getReviewCount());
        assertEquals(2.1, word.getEaseFactor());
        assertEquals(LocalDate.now().plusDays(4), word.getNextReviewDate());
    }

    @Test
    void initializeWordForSRS_ShouldSetDefaultReviewCount_WhenNull() {
        Word word = new Word();
        word.setEnglishWord("nullable-review-count");
        word.setReviewCount(null);
        word.setEaseFactor(2.3);
        word.setNextReviewDate(LocalDate.now().plusDays(2));

        srsService.initializeWordForSRS(word);

        assertEquals(0, word.getReviewCount());
        assertEquals(2.3, word.getEaseFactor());
        assertEquals(LocalDate.now().plusDays(2), word.getNextReviewDate());
    }

    @Test
    void getStats_ShouldReturnAllKeysWithExpectedCounts() {
        when(wordRepository.findByUserIdAndNextReviewDateLessThanEqual(eq(1L), any(LocalDate.class)))
                .thenReturn(List.of(new Word(), new Word()));
        when(wordRepository.countByUserId(1L)).thenReturn(7L);
        when(wordRepository.findByUserIdAndReviewCountGreaterThan(1L, 0)).thenReturn(List.of(new Word()));

        Map<String, Object> stats = srsService.getStats(1L);

        assertEquals(2, stats.get("dueToday"));
        assertEquals(7L, stats.get("totalWords"));
        assertEquals(1, stats.get("reviewedWords"));
    }
}
