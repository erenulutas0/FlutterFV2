package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.service.GrammarCheckService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Map;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@TestPropertySource(properties = {
        "GROQ_API_KEY=dummy-key",
        "spring.datasource.url=jdbc:h2:mem:grammardb;DB_CLOSE_DELAY=-1;MODE=PostgreSQL",
        "spring.datasource.driver-class-name=org.h2.Driver"
})
class GrammarControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private GrammarCheckService grammarCheckService;

    @Test
    void checkGrammarReturnsOk() throws Exception {
        when(grammarCheckService.checkGrammar("I goes to school"))
                .thenReturn(Map.of("hasErrors", true, "errorCount", 1, "errors", List.of(Map.of("message", "err"))));

        mockMvc.perform(post("/api/grammar/check")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"sentence\":\"I goes to school\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.hasErrors").value(true))
                .andExpect(jsonPath("$.errorCount").value(1));
    }

    @Test
    void checkGrammarReturnsBadRequestForEmptySentence() throws Exception {
        mockMvc.perform(post("/api/grammar/check")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"sentence\":\"   \"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Empty sentence provided"));
    }

    @Test
    void checkGrammarReturnsInternalServerErrorWhenServiceThrows() throws Exception {
        when(grammarCheckService.checkGrammar(any())).thenThrow(new RuntimeException("broken"));

        mockMvc.perform(post("/api/grammar/check")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"sentence\":\"Test\"}"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.message").value("Grammar check failed: broken"));
    }

    @Test
    void checkMultipleSentencesReturnsOk() throws Exception {
        when(grammarCheckService.checkMultipleSentences(List.of("One", "Two")))
                .thenReturn(Map.of("One", List.of(Map.of("message", "m1"))));

        mockMvc.perform(post("/api/grammar/check-multiple")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"sentences\":[\"One\",\"Two\"]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.One[0].message").value("m1"));
    }

    @Test
    void checkMultipleSentencesReturnsBadRequestForEmptyList() throws Exception {
        mockMvc.perform(post("/api/grammar/check-multiple")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"sentences\":[]}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void checkMultipleSentencesReturnsInternalServerErrorWhenServiceThrows() throws Exception {
        when(grammarCheckService.checkMultipleSentences(any())).thenThrow(new RuntimeException("broken"));

        mockMvc.perform(post("/api/grammar/check-multiple")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"sentences\":[\"One\"]}"))
                .andExpect(status().isInternalServerError());
    }

    @Test
    void getStatusReturnsOk() throws Exception {
        when(grammarCheckService.isEnabled()).thenReturn(true);

        mockMvc.perform(get("/api/grammar/status"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.enabled").value(true))
                .andExpect(jsonPath("$.service").value("JLanguageTool"));
    }

    @Test
    void toggleGrammarCheckUpdatesValue() throws Exception {
        when(grammarCheckService.isEnabled()).thenReturn(true);

        mockMvc.perform(post("/api/grammar/toggle")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"enabled\":true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.enabled").value(true))
                .andExpect(jsonPath("$.message").value("Grammar checking enabled"));

        verify(grammarCheckService).setEnabled(eq(true));
    }

    @Test
    void toggleGrammarCheckHandlesMissingEnabledField() throws Exception {
        when(grammarCheckService.isEnabled()).thenReturn(false);

        mockMvc.perform(post("/api/grammar/toggle")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.enabled").value(false))
                .andExpect(jsonPath("$.message").value("Grammar checking disabled"));

        verify(grammarCheckService, never()).setEnabled(anyBoolean());
    }
}
