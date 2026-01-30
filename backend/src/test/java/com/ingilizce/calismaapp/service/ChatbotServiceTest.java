package com.ingilizce.calismaapp.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.when;

public class ChatbotServiceTest {

    @Mock
    private GroqService groqService;

    @InjectMocks
    private ChatbotService chatbotService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void testGenerateSentences() {
        when(groqService.chatCompletion(anyList(), anyBoolean())).thenReturn("{\"sentences\": []}");
        String response = chatbotService.generateSentences("apple");
        assertNotNull(response);
    }

    @Test
    void testCheckTranslation() {
        when(groqService.chatCompletion(anyList(), anyBoolean())).thenReturn("{\"correct\": true}");
        String response = chatbotService.checkTranslation("sentence");
        assertNotNull(response);
    }

    @Test
    void testChat() {
        when(groqService.chatCompletion(anyList(), anyBoolean())).thenReturn("Hello human");
        String response = chatbotService.chat("hi");
        assertNotNull(response);
    }

    @Test
    void testSpeakingTest() {
        when(groqService.chatCompletion(anyList(), anyBoolean())).thenReturn("Questions");
        String q = chatbotService.generateSpeakingTestQuestions("topic");
        assertNotNull(q);

        when(groqService.chatCompletion(anyList(), anyBoolean())).thenReturn("Evaluation");
        String e = chatbotService.evaluateSpeakingTest("answer");
        assertNotNull(e);
    }
}
