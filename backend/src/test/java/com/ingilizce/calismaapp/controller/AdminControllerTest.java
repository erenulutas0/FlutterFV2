package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.repository.SentencePracticeRepository;
import com.ingilizce.calismaapp.repository.SentenceRepository;
import com.ingilizce.calismaapp.repository.WordRepository;
import com.ingilizce.calismaapp.repository.WordReviewRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = AdminController.class)
@AutoConfigureMockMvc(addFilters = false)
class AdminControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private WordReviewRepository wordReviewRepository;

    @MockBean
    private SentencePracticeRepository sentencePracticeRepository;

    @MockBean
    private SentenceRepository sentenceRepository;

    @MockBean
    private WordRepository wordRepository;

    @Test
    void resetData_ShouldDeleteRepositoriesAndReturnSuccessMessage() throws Exception {
        mockMvc.perform(post("/api/admin/reset-data"))
                .andExpect(status().isOk())
                .andExpect(content().string("Mock data (Words, Sentences, Reviews) reset successful."));

        verify(wordReviewRepository).deleteAll();
        verify(sentencePracticeRepository).deleteAll();
        verify(sentenceRepository).deleteAll();
        verify(wordRepository).deleteAll();
    }

    @Test
    void resetData_ShouldReturnErrorMessage_WhenDeleteFails() throws Exception {
        doThrow(new RuntimeException("db-fail")).when(wordReviewRepository).deleteAll();

        mockMvc.perform(post("/api/admin/reset-data"))
                .andExpect(status().isOk())
                .andExpect(content().string("Error resetting data: db-fail"));
    }
}
