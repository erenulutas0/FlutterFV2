package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.SentencePractice;
import com.ingilizce.calismaapp.repository.SentencePracticeRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

public class SentencePracticeServiceTest {

    @Mock
    private SentencePracticeRepository sentencePracticeRepository;

    @InjectMocks
    private SentencePracticeService sentencePracticeService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void testGetAllSentences() {
        when(sentencePracticeRepository.findByUserIdOrderByCreatedDateDesc(1L)).thenReturn(new ArrayList<>());
        List<SentencePractice> result = sentencePracticeService.getAllSentences(1L);
        assertNotNull(result);
    }

    @Test
    void testGetSentenceByIdAndUser() {
        SentencePractice sp = new SentencePractice();
        sp.setUserId(1L);
        when(sentencePracticeRepository.findByIdAndUserId(1L, 1L)).thenReturn(Optional.of(sp));
        when(sentencePracticeRepository.findByIdAndUserId(1L, 2L)).thenReturn(Optional.empty());

        Optional<SentencePractice> result = sentencePracticeService.getSentenceByIdAndUser(1L, 1L);
        assertTrue(result.isPresent());

        Optional<SentencePractice> resultWrongUser = sentencePracticeService.getSentenceByIdAndUser(1L, 2L);
        assertFalse(resultWrongUser.isPresent());
    }

    @Test
    void testSaveSentence() {
        SentencePractice sp = new SentencePractice();
        sp.setUserId(1L);
        when(sentencePracticeRepository.save(any())).thenReturn(sp);

        SentencePractice saved = sentencePracticeService.saveSentence(sp);
        assertEquals(1L, saved.getUserId());
        verify(sentencePracticeRepository).save(sp);
    }

    @Test
    void testSaveSentence_WithExistingUserId_ShouldKeepUserId() {
        SentencePractice sp = new SentencePractice();
        sp.setUserId(9L);
        when(sentencePracticeRepository.save(any())).thenReturn(sp);

        SentencePractice saved = sentencePracticeService.saveSentence(sp);

        assertEquals(9L, saved.getUserId());
        verify(sentencePracticeRepository).save(sp);
    }

    @Test
    void testSaveSentence_WithNullUserId_ShouldThrow() {
        SentencePractice sp = new SentencePractice();
        sp.setUserId(null);

        assertThrows(IllegalArgumentException.class, () -> sentencePracticeService.saveSentence(sp));
        verify(sentencePracticeRepository, never()).save(any());
    }

    @Test
    void testUpdateSentence() {
        SentencePractice sp = new SentencePractice();
        sp.setUserId(1L);
        sp.setEnglishSentence("Old");

        SentencePractice updated = new SentencePractice();
        updated.setEnglishSentence("New");

        when(sentencePracticeRepository.findByIdAndUserId(1L, 1L)).thenReturn(Optional.of(sp));
        when(sentencePracticeRepository.save(any())).thenReturn(sp);

        SentencePractice result = sentencePracticeService.updateSentence(1L, updated, 1L);
        assertNotNull(result);
        assertEquals("New", result.getEnglishSentence());
    }

    @Test
    void testUpdateSentence_NotFound() {
        when(sentencePracticeRepository.findByIdAndUserId(44L, 1L)).thenReturn(Optional.empty());

        SentencePractice result = sentencePracticeService.updateSentence(44L, new SentencePractice(), 1L);

        assertNull(result);
        verify(sentencePracticeRepository, never()).save(any());
    }

    @Test
    void testDeleteSentence() {
        SentencePractice sp = new SentencePractice();
        sp.setUserId(1L);
        when(sentencePracticeRepository.findByIdAndUserId(1L, 1L)).thenReturn(Optional.of(sp));

        boolean deleted = sentencePracticeService.deleteSentence(1L, 1L);
        assertTrue(deleted);
        verify(sentencePracticeRepository).deleteById(1L);
    }

    @Test
    void testDeleteSentence_NotFound() {
        when(sentencePracticeRepository.findByIdAndUserId(2L, 1L)).thenReturn(Optional.empty());

        boolean deleted = sentencePracticeService.deleteSentence(2L, 1L);

        assertFalse(deleted);
        verify(sentencePracticeRepository, never()).deleteById(anyLong());
    }

    @Test
    void testGetPracticeSentencesPage() {
        Page<SentencePractice> page = new PageImpl<>(List.of(new SentencePractice()));
        when(sentencePracticeRepository.findByUserIdOrderByCreatedDateDesc(1L, PageRequest.of(0, 10))).thenReturn(page);

        Page<SentencePractice> result = sentencePracticeService.getPracticeSentencesPage(1L, 0, 10);

        assertEquals(1, result.getTotalElements());
    }

    @Test
    void testGetSentencesByDifficulty() {
        when(sentencePracticeRepository.findByUserIdAndDifficultyOrderByCreatedDateDesc(1L, SentencePractice.DifficultyLevel.EASY))
                .thenReturn(List.of(new SentencePractice()));

        List<SentencePractice> result = sentencePracticeService.getSentencesByDifficulty(1L, SentencePractice.DifficultyLevel.EASY);

        assertEquals(1, result.size());
    }

    @Test
    void testGetSentencesByDateAndRangeAndDistinctDates() {
        LocalDate date = LocalDate.of(2026, 2, 10);
        when(sentencePracticeRepository.findByUserIdAndCreatedDateOrderByCreatedDateDesc(1L, date))
                .thenReturn(List.of(new SentencePractice()));
        when(sentencePracticeRepository.findDistinctCreatedDatesByUserId(1L))
                .thenReturn(List.of(date));
        when(sentencePracticeRepository.findByUserIdAndDateRange(1L, date.minusDays(1), date.plusDays(1)))
                .thenReturn(List.of(new SentencePractice(), new SentencePractice()));

        List<SentencePractice> byDate = sentencePracticeService.getSentencesByDate(1L, date);
        List<LocalDate> distinctDates = sentencePracticeService.getAllDistinctDates(1L);
        List<SentencePractice> byRange = sentencePracticeService.getSentencesByDateRange(1L, date.minusDays(1), date.plusDays(1));

        assertEquals(1, byDate.size());
        assertEquals(1, distinctDates.size());
        assertEquals(2, byRange.size());
    }

    @Test
    void testStats() {
        when(sentencePracticeRepository.countByUserId(1L)).thenReturn(7L);
        assertEquals(7L, sentencePracticeService.getTotalSentenceCount(1L));

        when(sentencePracticeRepository.countByUserIdAndDifficulty(1L, SentencePractice.DifficultyLevel.EASY))
                .thenReturn(5L);
        assertEquals(5L,
                sentencePracticeService.getSentenceCountByDifficulty(1L, SentencePractice.DifficultyLevel.EASY));
    }
}
