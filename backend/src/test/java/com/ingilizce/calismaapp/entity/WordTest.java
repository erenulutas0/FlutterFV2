package com.ingilizce.calismaapp.entity;

import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertTrue;

class WordTest {

    @Test
    void defaultConstructor_ShouldSetDefaults() {
        Word word = new Word();

        assertEquals(1L, word.getUserId());
        assertEquals(0, word.getReviewCount());
        assertEquals(2.5, word.getEaseFactor());
        assertTrue(word.getSentences().isEmpty());
    }

    @Test
    void argsConstructor_ShouldSetCoreFields() {
        LocalDate learnedDate = LocalDate.of(2026, 2, 11);
        Word word = new Word("serendipity", "tesaduf", learnedDate);

        assertEquals("serendipity", word.getEnglishWord());
        assertEquals("tesaduf", word.getTurkishMeaning());
        assertEquals(learnedDate, word.getLearnedDate());
    }

    @Test
    void setters_ShouldUpdateAllFields() {
        Word word = new Word();
        LocalDate date = LocalDate.of(2026, 2, 12);
        List<Sentence> sentences = new ArrayList<>();

        word.setId(3L);
        word.setUserId(7L);
        word.setEnglishWord("focus");
        word.setTurkishMeaning("odak");
        word.setLearnedDate(date);
        word.setNotes("B2");
        word.setDifficulty("medium");
        word.setNextReviewDate(date.plusDays(1));
        word.setReviewCount(4);
        word.setEaseFactor(2.1);
        word.setLastReviewDate(date.minusDays(1));
        word.setSentences(sentences);

        assertEquals(3L, word.getId());
        assertEquals(7L, word.getUserId());
        assertEquals("focus", word.getEnglishWord());
        assertEquals("odak", word.getTurkishMeaning());
        assertEquals(date, word.getLearnedDate());
        assertEquals("B2", word.getNotes());
        assertEquals("medium", word.getDifficulty());
        assertEquals(date.plusDays(1), word.getNextReviewDate());
        assertEquals(4, word.getReviewCount());
        assertEquals(2.1, word.getEaseFactor());
        assertEquals(date.minusDays(1), word.getLastReviewDate());
        assertSame(sentences, word.getSentences());
    }

    @Test
    void addAndRemoveSentence_ShouldKeepBidirectionalReferenceConsistent() {
        Word word = new Word();
        Sentence sentence = new Sentence();

        word.addSentence(sentence);
        assertEquals(1, word.getSentences().size());
        assertSame(word, sentence.getWord());

        word.removeSentence(sentence);
        assertTrue(word.getSentences().isEmpty());
        assertNull(sentence.getWord());
    }
}
