package com.ingilizce.calismaapp.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ingilizce.calismaapp.entity.Word;
import com.ingilizce.calismaapp.service.WordService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.util.ArrayList;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@TestPropertySource(properties = {
                "GROQ_API_KEY=dummy-key",
                "spring.datasource.url=jdbc:h2:mem:worddb;DB_CLOSE_DELAY=-1;MODE=PostgreSQL",
                "spring.datasource.driver-class-name=org.h2.Driver"
})
public class WordControllerTest {

        @Autowired
        private MockMvc mockMvc;

        @MockBean
        private WordService wordService;

        @Autowired
        private ObjectMapper objectMapper;

        @Test
        void testGetAllWords() throws Exception {
                when(wordService.getAllWords(anyLong())).thenReturn(new ArrayList<>());

                mockMvc.perform(get("/api/words")
                                .header("X-User-Id", "1"))
                                .andExpect(status().isOk());
        }

        @Test
        void testCreateWord() throws Exception {
                Word word = new Word();
                word.setEnglishWord("Apple");
                word.setTurkishMeaning("Elma");

                when(wordService.saveWord(any())).thenReturn(word);

                mockMvc.perform(post("/api/words")
                                .header("X-User-Id", "1")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(word)))
                                .andExpect(status().isOk());
        }

        @Test
        void testDeleteWord() throws Exception {
                mockMvc.perform(delete("/api/words/1")
                                .header("X-User-Id", "1"))
                                .andExpect(status().isOk());
        }

        @Test
        void testAddSentence() throws Exception {
                when(wordService.addSentence(anyLong(), anyString(), anyString(), any(), anyLong()))
                                .thenReturn(new Word());

                mockMvc.perform(post("/api/words/1/sentences")
                                .header("X-User-Id", "1")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"sentence\":\"Test\", \"translation\":\"Test TR\"}"))
                                .andExpect(status().isOk());
        }
}
