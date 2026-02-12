package com.ingilizce.calismaapp.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ChatbotServiceTest {

    @Mock
    private GroqService groqService;

    private ChatbotService chatbotService;

    @BeforeEach
    void setUp() {
        chatbotService = new ChatbotService(groqService);
    }

    @Test
    void generateSentences_ShouldUseJsonModeAndNormalizeArrayFromCodeFence() {
        when(groqService.chatCompletion(anyList(), anyBoolean()))
                .thenReturn("```json\n[{\"englishSentence\":\"A\"}]\n```");

        String response = chatbotService.generateSentences("apple");

        assertEquals("[{\"englishSentence\":\"A\"}]", response);

        ArgumentCaptor<List<Map<String, String>>> messagesCaptor = ArgumentCaptor.forClass(List.class);
        verify(groqService).chatCompletion(messagesCaptor.capture(), org.mockito.ArgumentMatchers.eq(true));
        List<Map<String, String>> messages = messagesCaptor.getValue();
        assertEquals(2, messages.size());
        assertEquals("system", messages.get(0).get("role"));
        assertEquals("user", messages.get(1).get("role"));
        assertNotNull(messages.get(0).get("content"));
        assertEquals("Target word: 'apple'. Return ONLY pure, minified JSON. No other text.", messages.get(1).get("content"));
    }

    @Test
    void checkEnglishTranslation_ShouldNormalizeJsonObjectFromCodeFence() {
        when(groqService.chatCompletion(anyList(), anyBoolean()))
                .thenReturn("```json\n{\"isCorrect\":true}\n```");

        String response = chatbotService.checkEnglishTranslation("Merhaba");

        assertEquals("{\"isCorrect\":true}", response);
        verify(groqService).chatCompletion(anyList(), org.mockito.ArgumentMatchers.eq(true));
    }

    @Test
    void chat_ShouldUseTextModeAndReturnRaw() {
        when(groqService.chatCompletion(anyList(), anyBoolean())).thenReturn("Hello human");

        String response = chatbotService.chat("hi");

        assertEquals("Hello human", response);
        verify(groqService).chatCompletion(anyList(), org.mockito.ArgumentMatchers.eq(false));
    }

    @Test
    void generateSentences_ShouldAcceptObjectWithSentencesList_WhenOutputIsArray() {
        String raw = "{\"sentences\":[{\"englishSentence\":\"A\"}]}";
        when(groqService.chatCompletion(anyList(), anyBoolean())).thenReturn(raw);

        String response = chatbotService.generateSentences("apple");

        assertEquals(raw, response);
    }

    @Test
    void generateSentences_ShouldReturnRaw_WhenArrayValidationFails() {
        String raw = "{\"foo\":1}";
        when(groqService.chatCompletion(anyList(), anyBoolean())).thenReturn(raw);

        String response = chatbotService.generateSentences("apple");

        assertEquals(raw, response);
    }

    @Test
    void generateSpeakingTestQuestions_ShouldReturnRaw_WhenObjectValidationFails() {
        String raw = "[\"q1\",\"q2\"]";
        when(groqService.chatCompletion(anyList(), anyBoolean())).thenReturn(raw);

        String response = chatbotService.generateSpeakingTestQuestions("IELTS Part 1");

        assertEquals(raw, response);
    }

    @Test
    void checkTranslation_ShouldReturnNull_WhenGroqReturnsNull() {
        when(groqService.chatCompletion(anyList(), anyBoolean())).thenReturn(null);

        String response = chatbotService.checkTranslation("text");

        assertNull(response);
    }

    @Test
    void evaluateSpeakingTest_ShouldAppendJsonInstructionToUserMessage() {
        when(groqService.chatCompletion(anyList(), anyBoolean())).thenReturn("{\"overallScore\":7}");

        String response = chatbotService.evaluateSpeakingTest("my answer");

        assertEquals("{\"overallScore\":7}", response);

        ArgumentCaptor<List<Map<String, String>>> messagesCaptor = ArgumentCaptor.forClass(List.class);
        verify(groqService).chatCompletion(messagesCaptor.capture(), org.mockito.ArgumentMatchers.eq(true));
        List<Map<String, String>> messages = messagesCaptor.getValue();
        assertEquals("my answer Return ONLY JSON.", messages.get(1).get("content"));
    }
}
