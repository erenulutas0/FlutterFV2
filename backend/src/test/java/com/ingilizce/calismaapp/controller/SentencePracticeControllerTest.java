package com.ingilizce.calismaapp.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ingilizce.calismaapp.entity.SentencePractice;
import com.ingilizce.calismaapp.service.SentencePracticeService;
import com.ingilizce.calismaapp.repository.SentenceRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@TestPropertySource(properties = {
        "GROQ_API_KEY=dummy-key",
        "spring.datasource.url=jdbc:h2:mem:practicedb;DB_CLOSE_DELAY=-1;MODE=PostgreSQL",
        "spring.datasource.driver-class-name=org.h2.Driver"
})
public class SentencePracticeControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private SentencePracticeService sentencePracticeService;

    @MockBean
    private SentenceRepository sentenceRepository;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void testGetAllSentences() throws Exception {
        when(sentencePracticeService.getAllSentences(anyLong())).thenReturn(new ArrayList<>());

        mockMvc.perform(get("/api/sentences")
                .header("X-User-Id", "1"))
                .andExpect(status().isOk());
    }

    @Test
    void testCreateSentence() throws Exception {
        SentencePractice sp = new SentencePractice();
        sp.setEnglishSentence("Test");
        sp.setDifficulty(SentencePractice.DifficultyLevel.EASY);

        when(sentencePracticeService.saveSentence(any(SentencePractice.class))).thenReturn(sp);

        mockMvc.perform(post("/api/sentences")
                .header("X-User-Id", "1")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(sp)))
                .andExpect(status().isOk());
    }

    @Test
    void testGetStatistics() throws Exception {
        when(sentencePracticeService.getTotalSentenceCount(anyLong())).thenReturn(10L);

        mockMvc.perform(get("/api/sentences/stats")
                .header("X-User-Id", "1"))
                .andExpect(status().isOk());
    }
}
