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

    @BeforeEach
    void setUp() {
        today = LocalDate.now();

        testWord = new Word();
        testWord.setId(100L);
        testWord.setEnglishWord("Test");

        testReview = new WordReview(testWord, today);
        testReview.setId(1L);
        testReview.setReviewType("HARD");
    }

    @Test
    void addReview_ShouldSaveReview_WhenValid() {
        when(wordRepository.findById(100L)).thenReturn(Optional.of(testWord));
        when(wordReviewRepository.existsByWordIdAndReviewDate(100L, today)).thenReturn(false);
        when(wordReviewRepository.save(any(WordReview.class))).thenReturn(testReview);

        WordReview result = wordReviewService.addReview(100L, today, "HARD", "Note");

        assertNotNull(result);
        assertEquals(testWord, result.getWord());
        assertEquals(today, result.getReviewDate());
        verify(wordReviewRepository).save(any(WordReview.class));
    }

    @Test
    void addReview_ShouldThrowException_WhenWordNotFound() {
        when(wordRepository.findById(999L)).thenReturn(Optional.empty());

        assertThrows(RuntimeException.class, () -> wordReviewService.addReview(999L, today, "EASY", ""));
    }

    @Test
    void addReview_ShouldThrowException_WhenAlreadyReviewed() {
        when(wordRepository.findById(100L)).thenReturn(Optional.of(testWord));
        when(wordReviewRepository.existsByWordIdAndReviewDate(100L, today)).thenReturn(true);

        assertThrows(RuntimeException.class, () -> wordReviewService.addReview(100L, today, "EASY", ""));
        verify(wordReviewRepository, never()).save(any(WordReview.class));
    }

    @Test
    void getWordReviews_ShouldReturnList() {
        when(wordReviewRepository.findByWordIdOrderByReviewDateDesc(100L))
                .thenReturn(Arrays.asList(testReview));

        List<WordReview> result = wordReviewService.getWordReviews(100L);

        assertFalse(result.isEmpty());
        assertEquals(1, result.size());
    }

    @Test
    void getReviewsByDate_ShouldReturnList() {
        when(wordReviewRepository.findByReviewDate(today))
                .thenReturn(Arrays.asList(testReview));

        List<WordReview> result = wordReviewService.getReviewsByDate(today);

        assertFalse(result.isEmpty());
        assertEquals(today, result.get(0).getReviewDate());
    }

    @Test
    void getReviewSummary_ShouldReturnMap() {
        when(wordReviewRepository.findByWordIdOrderByReviewDateDesc(100L))
                .thenReturn(Arrays.asList(testReview));

        Map<LocalDate, WordReview> summary = wordReviewService.getReviewSummary(100L);

        assertNotNull(summary);
        assertTrue(summary.containsKey(today));
        assertEquals("HARD", summary.get(today).getReviewType());
    }

    @Test
    void deleteReview_ShouldCallDelete() {
        wordReviewService.deleteReview(1L);
        verify(wordReviewRepository).deleteById(1L);
    }

    @Test
    void isWordReviewedOnDate_ShouldReturnRepositoryValue() {
        when(wordReviewRepository.existsByWordIdAndReviewDate(100L, today)).thenReturn(true);

        boolean reviewed = wordReviewService.isWordReviewedOnDate(100L, today);

        assertTrue(reviewed);
    }

    @Test
    void getReviewCount_ShouldReturnRepositoryCount() {
        when(wordReviewRepository.countByWordId(100L)).thenReturn(5L);

        long count = wordReviewService.getReviewCount(100L);

        assertEquals(5L, count);
    }

    @Test
    void getReviewDates_ShouldReturnDateListInOrderProvidedByRepository() {
        LocalDate older = today.minusDays(1);
        WordReview olderReview = new WordReview(testWord, older);
        when(wordReviewRepository.findByWordIdOrderByReviewDateDesc(100L))
                .thenReturn(Arrays.asList(testReview, olderReview));

        List<LocalDate> dates = wordReviewService.getReviewDates(100L);

        assertEquals(Arrays.asList(today, older), dates);
    }

    @Test
    void deleteReviewByWordAndDate_ShouldDeleteAllMatchedReviews() {
        WordReview second = new WordReview(testWord, today);
        second.setId(2L);
        List<WordReview> reviews = Arrays.asList(testReview, second);
        when(wordReviewRepository.findByWordIdAndReviewDate(100L, today)).thenReturn(reviews);

        wordReviewService.deleteReviewByWordAndDate(100L, today);

        verify(wordReviewRepository).deleteAll(reviews);
    }
}
