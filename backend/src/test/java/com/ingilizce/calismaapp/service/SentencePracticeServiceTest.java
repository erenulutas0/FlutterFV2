package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.SentencePractice;
import com.ingilizce.calismaapp.repository.SentencePracticeRepository;
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
        when(sentencePracticeRepository.findById(1L)).thenReturn(Optional.of(sp));

        Optional<SentencePractice> result = sentencePracticeService.getSentenceByIdAndUser(1L, 1L);
        assertTrue(result.isPresent());

        Optional<SentencePractice> resultWrongUser = sentencePracticeService.getSentenceByIdAndUser(1L, 2L);
        assertFalse(resultWrongUser.isPresent());
    }

    @Test
    void testSaveSentence() {
        SentencePractice sp = new SentencePractice();
        when(sentencePracticeRepository.save(any())).thenReturn(sp);

        SentencePractice saved = sentencePracticeService.saveSentence(sp);
        assertEquals(1L, saved.getUserId());
        verify(sentencePracticeRepository).save(sp);
    }

    @Test
    void testUpdateSentence() {
        SentencePractice sp = new SentencePractice();
        sp.setUserId(1L);
        sp.setEnglishSentence("Old");

        SentencePractice updated = new SentencePractice();
        updated.setEnglishSentence("New");

        when(sentencePracticeRepository.findById(1L)).thenReturn(Optional.of(sp));
        when(sentencePracticeRepository.save(any())).thenReturn(sp);

        SentencePractice result = sentencePracticeService.updateSentence(1L, updated, 1L);
        assertNotNull(result);
        assertEquals("New", result.getEnglishSentence());
    }

    @Test
    void testDeleteSentence() {
        SentencePractice sp = new SentencePractice();
        sp.setUserId(1L);
        when(sentencePracticeRepository.findById(1L)).thenReturn(Optional.of(sp));

        boolean deleted = sentencePracticeService.deleteSentence(1L, 1L);
        assertTrue(deleted);
        verify(sentencePracticeRepository).deleteById(1L);
    }

    @Test
    void testStats() {
        when(sentencePracticeRepository.findByUserIdOrderByCreatedDateDesc(1L)).thenReturn(new ArrayList<>());
        assertEquals(0, sentencePracticeService.getTotalSentenceCount(1L));

        when(sentencePracticeRepository.countByUserIdAndDifficulty(1L, SentencePractice.DifficultyLevel.EASY))
                .thenReturn(5L);
        assertEquals(5L,
                sentencePracticeService.getSentenceCountByDifficulty(1L, SentencePractice.DifficultyLevel.EASY));
    }
}
