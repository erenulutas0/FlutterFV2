package com.ingilizce.calismaapp.controller;

import java.security.MessageDigest;
import java.util.Base64;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@org.springframework.test.context.TestPropertySource(properties = "GROQ_API_KEY=dummy-key")
public class AuthControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ObjectMapper objectMapper;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll(); // Clean state
    }

    // ... existing register test ...

    @Test
    void login_ShouldReturnUser_WhenCredentialsAreCorrect() throws Exception {
        // First register a user
        User user = new User();
        user.setEmail("login@test.com");
        // Hash manually to simulate stored password
        user.setPasswordHash(hashPassword("password123"));
        userRepository.save(user);

        java.util.Map<String, String> loginRequest = new java.util.HashMap<>();
        loginRequest.put("email", "login@test.com");
        loginRequest.put("password", "password123");

        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("login@test.com"));
    }

    private String hashPassword(String password) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] encodedhash = digest.digest(password.getBytes());
            return Base64.getEncoder().encodeToString(encodedhash);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
