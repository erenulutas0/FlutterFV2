package com.ingilizce.calismaapp.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@TestPropertySource(properties = {
        "GROQ_API_KEY=dummy-key",
        "app.features.community.enabled=false",
        "app.socketio.enabled=false"
})
class CommunityDisabledContractTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void communityEndpointsShouldReturnNotFoundWhenFeatureDisabled() throws Exception {
        mockMvc.perform(get("/api/friends/list").header("X-User-Id", "1"))
                .andExpect(status().isNotFound());

        mockMvc.perform(post("/api/friends/request")
                        .header("X-User-Id", "1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("email", "a@test.com"))))
                .andExpect(status().isNotFound());

        mockMvc.perform(get("/api/feed").header("X-User-Id", "1"))
                .andExpect(status().isNotFound());

        mockMvc.perform(get("/api/leaderboard/my-rank").header("X-User-Id", "1"))
                .andExpect(status().isNotFound());

        mockMvc.perform(get("/api/social/feed").header("X-User-Id", "1"))
                .andExpect(status().isNotFound());

        mockMvc.perform(post("/api/social/posts")
                        .header("X-User-Id", "1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("content", "test"))))
                .andExpect(status().isNotFound());

        mockMvc.perform(get("/api/chat/conversations").header("X-User-Id", "1"))
                .andExpect(status().isNotFound());

        mockMvc.perform(post("/api/chat/send/2")
                        .header("X-User-Id", "1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("content", "hello"))))
                .andExpect(status().isNotFound());

        mockMvc.perform(get("/api/notifications").header("X-User-Id", "1"))
                .andExpect(status().isNotFound());
    }

    @Test
    void coreEndpointsShouldRemainAvailableWhenCommunityFeatureDisabled() throws Exception {
        mockMvc.perform(get("/api/subscription/plans"))
                .andExpect(status().isOk());
    }
}
