package com.ingilizce.calismaapp.dto;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class UserDtoTest {

    @Test
    void constructorWithoutOnline_ShouldDefaultToOffline() {
        UserDto dto = new UserDto(1L, "Alice", "@alice");

        assertEquals(1L, dto.getId());
        assertEquals("Alice", dto.getDisplayName());
        assertEquals("@alice", dto.getUserTag());
        assertFalse(dto.isOnline());
    }

    @Test
    void constructorWithOnline_ShouldSetOnlineFlag() {
        UserDto dto = new UserDto(2L, "Bob", "@bob", true);

        assertEquals(2L, dto.getId());
        assertEquals("Bob", dto.getDisplayName());
        assertEquals("@bob", dto.getUserTag());
        assertTrue(dto.isOnline());
    }

    @Test
    void setters_ShouldUpdateFields() {
        UserDto dto = new UserDto(1L, "Alice", "@alice");

        dto.setId(3L);
        dto.setDisplayName("Carol");
        dto.setUserTag("@carol");
        dto.setOnline(true);

        assertEquals(3L, dto.getId());
        assertEquals("Carol", dto.getDisplayName());
        assertEquals("@carol", dto.getUserTag());
        assertTrue(dto.isOnline());
    }
}
