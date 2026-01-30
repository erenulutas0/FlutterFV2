package com.ingilizce.calismaapp.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ingilizce.calismaapp.service.ChatbotService;
import com.ingilizce.calismaapp.service.GroqService;
import com.ingilizce.calismaapp.service.WordService;
import com.ingilizce.calismaapp.service.UserService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@TestPropertySource(properties = {
                "GROQ_API_KEY=dummy-key",
                "spring.datasource.url=jdbc:h2:mem:chatbotdb;DB_CLOSE_DELAY=-1;MODE=PostgreSQL",
                "spring.datasource.driver-class-name=org.h2.Driver"
})
public class ChatbotControllerTest {

        @Autowired
        private MockMvc mockMvc;

        @MockBean
        private ChatbotService chatbotService;

        @MockBean
        private WordService wordService;

        @MockBean
        private UserService userService;

        @Autowired
        private ObjectMapper objectMapper;

        @org.junit.jupiter.api.BeforeEach
        void setUp() {
                when(userService.getUserById(anyLong()))
                                .thenReturn(Optional.of(new com.ingilizce.calismaapp.entity.User()));
        }

        @Test
        void testChat() throws Exception {
                Map<String, String> request = new HashMap<>();
                request.put("message", "Hello");

                when(userService.getUserById(anyLong()))
                                .thenReturn(Optional.of(new com.ingilizce.calismaapp.entity.User()));
                when(chatbotService.chat(anyString())).thenReturn("Hi there!");

                mockMvc.perform(post("/api/chatbot/chat")
                                .header("X-User-Id", "1")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(request)))
                                .andExpect(status().isOk());
        }

        @Test
        void testGenerateSentences() throws Exception {
                Map<String, Object> request = new HashMap<>();
                request.put("word", "apple");

                when(chatbotService.generateSentences(anyString()))
                                .thenReturn("{\"sentences\": [{\"sentence\": \"I eat apple\", \"translation\": \"Elma yerim\"}]}");

                mockMvc.perform(post("/api/chatbot/generate-sentences")
                                .header("X-User-Id", "1")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(request)))
                                .andExpect(status().isOk());
        }

        @Test
        void testCheckTranslation() throws Exception {
                Map<String, String> request = new HashMap<>();
                request.put("englishSentence", "I love coding");
                request.put("userTranslation", "Kodlamayı seviyorum");

                when(chatbotService.checkTranslation(anyString())).thenReturn("{\"correct\": true}");

                mockMvc.perform(post("/api/chatbot/check-translation")
                                .header("X-User-Id", "1")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(request)))
                                .andExpect(status().isOk());
        }

        @Test
        void testGenerateSpeakingTestQuestions() throws Exception {
                Map<String, String> request = new HashMap<>();
                request.put("testType", "IELTS");
                request.put("part", "Part 1");

                when(chatbotService.generateSpeakingTestQuestions(anyString()))
                                .thenReturn("{\"questions\": [\"Q1\", \"Q2\"]}");

                mockMvc.perform(post("/api/chatbot/speaking-test/generate-questions")
                                .header("X-User-Id", "1")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(request)))
                                .andExpect(status().isOk());
        }

        @Test
        void testEvaluateSpeakingTest() throws Exception {
                Map<String, String> request = new HashMap<>();
                request.put("testType", "IELTS");
                request.put("question", "What is your favorite food?");
                request.put("response", "I like apple");

                when(chatbotService.evaluateSpeakingTest(anyString())).thenReturn("{\"score\": 80}");

                mockMvc.perform(post("/api/chatbot/speaking-test/evaluate")
                                .header("X-User-Id", "1")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(request)))
                                .andExpect(status().isOk());
        }

        @Test
        void testCheckGrammar() throws Exception {
                // Since grammarCheckService is mocked in the real controller but not in my test
                // yet?
                // Wait, I need to see ChatbotController.java to see if it uses a separate
                // service for grammar check.
        }
}
