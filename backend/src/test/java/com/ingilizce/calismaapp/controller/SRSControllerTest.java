package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.service.SRSService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@TestPropertySource(properties = {
        "GROQ_API_KEY=dummy-key",
        "spring.datasource.url=jdbc:h2:mem:srsdb;DB_CLOSE_DELAY=-1;MODE=PostgreSQL",
        "spring.datasource.driver-class-name=org.h2.Driver"
})
public class SRSControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private SRSService srsService;

    @Test
    void testGetDueWords() throws Exception {
        when(srsService.getWordsForReview()).thenReturn(new ArrayList<>());

        mockMvc.perform(get("/api/srs/review-words")
                .header("X-User-Id", "1"))
                .andExpect(status().isOk());
    }

    @Test
    void testEvaluateWord() throws Exception {
        mockMvc.perform(post("/api/srs/submit-review")
                .header("X-User-Id", "1")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"wordId\":1, \"quality\":4}"))
                .andExpect(status().isOk());
    }

    @Test
    void testGetStats() throws Exception {
        when(srsService.getStats()).thenReturn(new HashMap<>());

        mockMvc.perform(get("/api/srs/stats")
                .header("X-User-Id", "1"))
                .andExpect(status().isOk());
    }
}
