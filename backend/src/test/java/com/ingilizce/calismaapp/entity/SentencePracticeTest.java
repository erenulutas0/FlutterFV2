package com.ingilizce.calismaapp.entity;

import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class SentencePracticeTest {

    @Test
    void defaultConstructor_ShouldInitializeDefaults() {
        SentencePractice practice = new SentencePractice();

        assertEquals(1L, practice.getUserId());
        assertNotNull(practice.getCreatedDate());
    }

    @Test
    void constructorWithArgs_ShouldSetFields() {
        SentencePractice practice = new SentencePractice(
                "How are you?",
                "Nasılsın?",
                SentencePractice.DifficultyLevel.MEDIUM);

        assertEquals("How are you?", practice.getEnglishSentence());
        assertEquals("Nasılsın?", practice.getTurkishTranslation());
        assertEquals(SentencePractice.DifficultyLevel.MEDIUM, practice.getDifficulty());
        assertNotNull(practice.getCreatedDate());
    }

    @Test
    void setters_ShouldUpdateFields() {
        SentencePractice practice = new SentencePractice();
        LocalDate date = LocalDate.of(2026, 2, 11);

        practice.setId(99L);
        practice.setUserId(7L);
        practice.setEnglishSentence("I learn every day.");
        practice.setTurkishTranslation("Her gün öğreniyorum.");
        practice.setDifficulty(SentencePractice.DifficultyLevel.HARD);
        practice.setCreatedDate(date);

        assertEquals(99L, practice.getId());
        assertEquals(7L, practice.getUserId());
        assertEquals("I learn every day.", practice.getEnglishSentence());
        assertEquals("Her gün öğreniyorum.", practice.getTurkishTranslation());
        assertEquals(SentencePractice.DifficultyLevel.HARD, practice.getDifficulty());
        assertEquals(date, practice.getCreatedDate());
    }

    @Test
    void difficultyDisplayNames_ShouldMatchExpectedValues() {
        assertEquals("Kolay", SentencePractice.DifficultyLevel.EASY.getDisplayName());
        assertEquals("Orta", SentencePractice.DifficultyLevel.MEDIUM.getDisplayName());
        assertEquals("Zor", SentencePractice.DifficultyLevel.HARD.getDisplayName());
    }
}
