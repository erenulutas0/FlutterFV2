package com.ingilizce.calismaapp.entity;

import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;

class WordReviewTest {

    @Test
    void constructor_ShouldSetWordAndReviewDate() {
        Word word = new Word();
        LocalDate reviewDate = LocalDate.of(2026, 2, 11);

        WordReview review = new WordReview(word, reviewDate);

        assertSame(word, review.getWord());
        assertEquals(reviewDate, review.getReviewDate());
    }

    @Test
    void setters_ShouldUpdateAllFields() {
        WordReview review = new WordReview();
        Word word = new Word();
        LocalDate reviewDate = LocalDate.of(2026, 2, 12);

        review.setId(7L);
        review.setWord(word);
        review.setReviewDate(reviewDate);
        review.setReviewType("weekly");
        review.setNotes("Good retention");

        assertEquals(7L, review.getId());
        assertSame(word, review.getWord());
        assertEquals(reviewDate, review.getReviewDate());
        assertEquals("weekly", review.getReviewType());
        assertEquals("Good retention", review.getNotes());
    }
}
