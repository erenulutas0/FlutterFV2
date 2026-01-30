package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.UserActivity;
import com.ingilizce.calismaapp.entity.Word;
import com.ingilizce.calismaapp.repository.WordRepository;
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

class WordServiceTest {

    @InjectMocks
    private WordService wordService;

    @Mock
    private WordRepository wordRepository;

    @Mock
    private LeaderboardService leaderboardService;

    @Mock
    private FeedService feedService;

    // We mock other dependencies to avoid NPEs during context load if they are
    // autowired
    @Mock
    private ProgressService progressService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void saveWord_ShouldSaveWord_And_TriggerGamificationAndSocial() {
        // Arrange
        Long userId = 100L;
        Word newWord = new Word();
        newWord.setUserId(userId);
        newWord.setEnglishWord("Serendipity");
        newWord.setTurkishMeaning("Mutlu Tesadüf");
        newWord.setLearnedDate(LocalDate.now());

        Word savedWord = new Word();
        savedWord.setId(1L);
        savedWord.setUserId(userId);
        savedWord.setEnglishWord("Serendipity");

        // Mock Repository Behavior
        when(wordRepository.save(any(Word.class))).thenReturn(savedWord);

        // Act
        Word result = wordService.saveWord(newWord);

        // Assert
        assertNotNull(result);
        assertEquals(1L, result.getId());
        assertEquals("Serendipity", result.getEnglishWord());

        // Verify Repository was called
        verify(wordRepository, times(1)).save(newWord);

        // Verify Leaderboard was updated (+10 points)
        verify(leaderboardService, times(1)).incrementScore(eq(userId), eq(10.0));

        // Verify Social Feed logged the activity
        verify(feedService, times(1)).logActivity(
                eq(userId),
                eq(com.ingilizce.calismaapp.entity.UserActivity.ActivityType.WORD_ADDED),
                contains("Serendipity"));
    }

    @Test
    void saveWord_ShouldNotFail_IfLeaderboardServiceFails() {
        // Arrange: Simulate Leaderboard acting up (e.g. Redis down)
        Word word = new Word();
        word.setUserId(1L);
        word.setEnglishWord("Test");

        when(wordRepository.save(any(Word.class))).thenReturn(word);
        doThrow(new RuntimeException("Redis Down")).when(leaderboardService).incrementScore(anyLong(), anyDouble());

        // Act & Assert: Should NOT throw exception
        assertDoesNotThrow(() -> wordService.saveWord(word));

        // Verify essential save still happened
        verify(wordRepository, times(1)).save(word);
    }

    @Test
    void testGetMethods() {
        when(wordRepository.findByUserId(1L)).thenReturn(new java.util.ArrayList<>());
        assertNotNull(wordService.getAllWords(1L));

        when(wordRepository.findById(1L)).thenReturn(Optional.of(new Word()));
        assertTrue(wordService.getWordById(1L).isPresent());
    }

    @Test
    void testUpdateWord() {
        Word existing = new Word();
        existing.setUserId(1L);
        existing.setEnglishWord("Old");

        Word details = new Word();
        details.setEnglishWord("New");

        when(wordRepository.findById(1L)).thenReturn(Optional.of(existing));
        when(wordRepository.save(any())).thenReturn(existing);

        Word result = wordService.updateWord(1L, details, 1L);
        assertEquals("New", result.getEnglishWord());
    }

    @Test
    void testDeleteWord() {
        Word existing = new Word();
        existing.setUserId(1L);
        when(wordRepository.findById(1L)).thenReturn(Optional.of(existing));

        wordService.deleteWord(1L, 1L);
        verify(wordRepository).deleteById(1L);
    }

    @Test
    void testAddSentence() {
        Word word = new Word();
        word.setUserId(1L);
        word.setId(1L);

        when(wordRepository.findById(1L)).thenReturn(Optional.of(word));
        when(wordRepository.save(any())).thenReturn(word);

        Word result = wordService.addSentence(1L, "Test", "Test TR", "easy", 1L);
        assertNotNull(result);
        verify(progressService).awardXp(eq(3), anyString());
    }
}
