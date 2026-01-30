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
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
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
        when(wordRepository.findByNextReviewDateLessThanEqual(any(LocalDate.class))).thenReturn(words);

        List<Word> result = srsService.getWordsForReview();
        assertEquals(1, result.size());
    }

    @Test
    void submitReview_ShouldUpdateWord() {
        Word word = new Word();
        word.setId(1L);
        word.setEnglishWord("Test");
        word.setReviewCount(1);
        word.setEaseFactor(2.5);

        when(wordRepository.findById(1L)).thenReturn(Optional.of(word));
        when(wordRepository.save(any(Word.class))).thenReturn(word);

        Word updated = srsService.submitReview(1L, 5);

        assertNotNull(updated);
        assertEquals(2, updated.getReviewCount());
        assertNotNull(updated.getNextReviewDate());
        verify(progressService).awardXp(eq(5), anyString());
    }

    @Test
    void submitReview_WithLowQuality_ShouldResetInterval() {
        Word word = new Word();
        word.setId(1L);
        word.setReviewCount(5);
        word.setEaseFactor(2.5);

        when(wordRepository.findById(1L)).thenReturn(Optional.of(word));
        when(wordRepository.save(any(Word.class))).thenReturn(word);

        Word updated = srsService.submitReview(1L, 1);

        assertEquals(LocalDate.now().plusDays(1), updated.getNextReviewDate());
        verify(progressService).awardXp(eq(1), anyString());
    }

    @Test
    void getStats_ShouldReturnCorrectData() {
        when(wordRepository.findByNextReviewDateLessThanEqual(any(LocalDate.class))).thenReturn(new ArrayList<>());
        when(wordRepository.count()).thenReturn(10L);
        when(wordRepository.findByReviewCountGreaterThan(0)).thenReturn(new ArrayList<>());

        var stats = srsService.getStats();
        assertEquals(10L, stats.get("totalWords"));
    }
}
