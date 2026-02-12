package com.ingilizce.calismaapp.dto;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class CreateWordRequestTest {

    @Test
    void defaultConstructorAndSetters_ShouldPopulateFields() {
        CreateWordRequest request = new CreateWordRequest();
        request.setEnglish("apple");
        request.setTurkish("elma");
        request.setAddedDate("2026-02-10");
        request.setDifficulty("medium");
        request.setNotes("daily word");

        assertEquals("apple", request.getEnglish());
        assertEquals("elma", request.getTurkish());
        assertEquals("2026-02-10", request.getAddedDate());
        assertEquals("medium", request.getDifficulty());
        assertEquals("daily word", request.getNotes());
    }

    @Test
    void allArgsConstructor_ShouldPopulateFields() {
        CreateWordRequest request = new CreateWordRequest(
                "book", "kitap", "2026-02-11", "easy", "sample");

        assertEquals("book", request.getEnglish());
        assertEquals("kitap", request.getTurkish());
        assertEquals("2026-02-11", request.getAddedDate());
        assertEquals("easy", request.getDifficulty());
        assertEquals("sample", request.getNotes());
    }

    @Test
    void nullableFields_ShouldRemainNullWhenSetNull() {
        CreateWordRequest request = new CreateWordRequest();
        request.setDifficulty(null);
        request.setNotes(null);

        assertNull(request.getDifficulty());
        assertNull(request.getNotes());
    }
}
