package com.ingilizce.calismaapp.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class GroqServiceTest {

    @Mock
    private RestTemplate restTemplate;

    @InjectMocks
    private GroqService groqService;

    @BeforeEach
    void setUp() {
        // Inject Private Fields manually due to bad dependency injection practice in
        // source code
        ReflectionTestUtils.setField(groqService, "apiKey", "test-api-key");
        ReflectionTestUtils.setField(groqService, "apiUrl", "http://api.groq.com/test");
        ReflectionTestUtils.setField(groqService, "model", "llama3-8b");
        ReflectionTestUtils.setField(groqService, "restTemplate", restTemplate);
    }

    @Test
    void chatCompletion_ShouldReturnContent_WhenResponseIsSuccessful() {
        // Prepare Mock Response
        Map<String, Object> messageMap = new HashMap<>();
        messageMap.put("content", "Hello AI");

        Map<String, Object> choiceMap = new HashMap<>();
        choiceMap.put("message", messageMap);

        List<Map<String, Object>> choices = new ArrayList<>();
        choices.add(choiceMap);

        Map<String, Object> bodyMap = new HashMap<>();
        bodyMap.put("choices", choices);

        ResponseEntity<Map> responseEntity = new ResponseEntity<>(bodyMap, HttpStatus.OK);

        when(restTemplate.postForEntity(eq("http://api.groq.com/test"), any(HttpEntity.class), eq(Map.class)))
                .thenReturn(responseEntity);

        // Call method
        List<Map<String, String>> messages = new ArrayList<>();
        Map<String, String> userMsg = new HashMap<>();
        userMsg.put("role", "user");
        userMsg.put("content", "Hi");
        messages.add(userMsg);

        String result = groqService.chatCompletion(messages, false);

        assertEquals("Hello AI", result);
        verify(restTemplate).postForEntity(eq("http://api.groq.com/test"), any(HttpEntity.class), eq(Map.class));
    }

    @Test
    void chatCompletion_ShouldThrowException_WhenApiFails() {
        when(restTemplate.postForEntity(anyString(), any(HttpEntity.class), eq(Map.class)))
                .thenThrow(new RuntimeException("Connection Refused"));

        List<Map<String, String>> messages = new ArrayList<>();

        Exception ignored = assertThrows(RuntimeException.class, () -> groqService.chatCompletion(messages, false));
    }
}
