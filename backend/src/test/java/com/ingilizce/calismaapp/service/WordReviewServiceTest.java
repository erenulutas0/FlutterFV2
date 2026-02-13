package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.Word;
import com.ingilizce.calismaapp.entity.WordReview;
import com.ingilizce.calismaapp.repository.WordRepository;
import com.ingilizce.calismaapp.repository.WordReviewRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class WordReviewServiceTest {

    @Mock
    private WordReviewRepository wordReviewRepository;

    @Mock
    private WordRepository wordRepository;

    @InjectMocks
    private WordReviewService wordReviewService;

    private Word testWord;
    private WordReview testReview;
    private LocalDate today;
    private final Long userId = 1L;

    @BeforeEach
    void setUp() {
        today = LocalDate.now();

        testWord = new Word();
        testWord.setId(100L);
        testWord.setUserId(userId);
        testWord.setEnglishWord("Test");

        testReview = new WordReview(testWord, today);
        testReview.setId(1L);
        testReview.setReviewType("HARD");
    }

    @Test
    void addReview_ShouldSaveReview_WhenValid() {
        when(wordRepository.findByIdAndUserId(100L, userId)).thenReturn(Optional.of(testWord));
        when(wordReviewRepository.existsByWordIdAndReviewDateAndWordUserId(100L, today, userId)).thenReturn(false);
        when(wordReviewRepository.save(any(WordReview.class))).thenReturn(testReview);

        WordReview result = wordReviewService.addReview(100L, userId, today, "HARD", "Note");

        assertNotNull(result);
        assertEquals(testWord, result.getWord());
        assertEquals(today, result.getReviewDate());
        verify(wordReviewRepository).save(any(WordReview.class));
    }

    @Test
    void addReview_ShouldThrowException_WhenWordNotFound() {
        when(wordRepository.findByIdAndUserId(999L, userId)).thenReturn(Optional.empty());

        assertThrows(RuntimeException.class, () -> wordReviewService.addReview(999L, userId, today, "EASY", ""));
    }

    @Test
    void addReview_ShouldThrowException_WhenAlreadyReviewed() {
        when(wordRepository.findByIdAndUserId(100L, userId)).thenReturn(Optional.of(testWord));
        when(wordReviewRepository.existsByWordIdAndReviewDateAndWordUserId(100L, today, userId)).thenReturn(true);

        assertThrows(RuntimeException.class, () -> wordReviewService.addReview(100L, userId, today, "EASY", ""));
        verify(wordReviewRepository, never()).save(any(WordReview.class));
    }

    @Test
    void getWordReviews_ShouldReturnList() {
        when(wordReviewRepository.findByWordIdAndWordUserIdOrderByReviewDateDesc(100L, userId))
                .thenReturn(Arrays.asList(testReview));

        List<WordReview> result = wordReviewService.getWordReviews(100L, userId);

        assertFalse(result.isEmpty());
        assertEquals(1, result.size());
    }

    @Test
    void getReviewsByDate_ShouldReturnList() {
        when(wordReviewRepository.findByReviewDateAndWordUserId(today, userId))
                .thenReturn(Arrays.asList(testReview));

        List<WordReview> result = wordReviewService.getReviewsByDate(today, userId);

        assertFalse(result.isEmpty());
        assertEquals(today, result.get(0).getReviewDate());
    }

    @Test
    void getReviewSummary_ShouldReturnMap() {
        when(wordReviewRepository.findByWordIdAndWordUserIdOrderByReviewDateDesc(100L, userId))
                .thenReturn(Arrays.asList(testReview));

        Map<LocalDate, WordReview> summary = wordReviewService.getReviewSummary(100L, userId);

        assertNotNull(summary);
        assertTrue(summary.containsKey(today));
        assertEquals("HARD", summary.get(today).getReviewType());
    }

    @Test
    void deleteReview_ShouldCallDelete() {
        when(wordReviewRepository.findByIdAndWordUserId(1L, userId)).thenReturn(Optional.of(testReview));

        wordReviewService.deleteReview(1L, userId);
        verify(wordReviewRepository).delete(testReview);
    }

    @Test
    void isWordReviewedOnDate_ShouldReturnRepositoryValue() {
        when(wordReviewRepository.existsByWordIdAndReviewDateAndWordUserId(100L, today, userId)).thenReturn(true);

        boolean reviewed = wordReviewService.isWordReviewedOnDate(100L, today, userId);

        assertTrue(reviewed);
    }

    @Test
    void getReviewCount_ShouldReturnRepositoryCount() {
        when(wordReviewRepository.countByWordIdAndWordUserId(100L, userId)).thenReturn(5L);

        long count = wordReviewService.getReviewCount(100L, userId);

        assertEquals(5L, count);
    }

    @Test
    void getReviewDates_ShouldReturnDateListInOrderProvidedByRepository() {
        LocalDate older = today.minusDays(1);
        WordReview olderReview = new WordReview(testWord, older);
        when(wordReviewRepository.findByWordIdAndWordUserIdOrderByReviewDateDesc(100L, userId))
                .thenReturn(Arrays.asList(testReview, olderReview));

        List<LocalDate> dates = wordReviewService.getReviewDates(100L, userId);

        assertEquals(Arrays.asList(today, older), dates);
    }

    @Test
    void deleteReviewByWordAndDate_ShouldDeleteAllMatchedReviews() {
        WordReview second = new WordReview(testWord, today);
        second.setId(2L);
        List<WordReview> reviews = Arrays.asList(testReview, second);
        when(wordReviewRepository.findByWordIdAndReviewDateAndWordUserId(100L, today, userId)).thenReturn(reviews);

        wordReviewService.deleteReviewByWordAndDate(100L, today, userId);

        verify(wordReviewRepository).deleteAll(reviews);
    }
}
