package com.ingilizce.calismaapp.controller;

import java.security.MessageDigest;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

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

    @Test
    void register_ShouldCreateUser_WhenPayloadValid() throws Exception {
        Map<String, String> registerRequest = new HashMap<>();
        registerRequest.put("email", "register@test.com");
        registerRequest.put("password", "password123");
        registerRequest.put("displayName", "Register User");

        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.user.email").value("register@test.com"));
    }

    @Test
    void register_ShouldReturnBadRequest_WhenEmailMissing() throws Exception {
        Map<String, String> registerRequest = new HashMap<>();
        registerRequest.put("password", "password123");

        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Email and password required"));
    }

    @Test
    void register_ShouldReturnBadRequest_WhenEmailAlreadyExists() throws Exception {
        userRepository.save(new User("dup@test.com", hashPassword("password123"), "Dup User"));

        Map<String, String> registerRequest = new HashMap<>();
        registerRequest.put("email", "dup@test.com");
        registerRequest.put("password", "newpass");

        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Email already in use"));
    }

    @Test
    void login_ShouldReturnUser_WhenCredentialsAreCorrect() throws Exception {
        // First register a user
        User user = new User("login@test.com", hashPassword("password123"));
        // Hash manually to simulate stored password
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

    @Test
    void login_ShouldReturnUnauthorized_WhenPasswordWrong() throws Exception {
        userRepository.save(new User("login@test.com", hashPassword("password123")));

        Map<String, String> loginRequest = new HashMap<>();
        loginRequest.put("email", "login@test.com");
        loginRequest.put("password", "wrong-password");

        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void login_ShouldAcceptEmailOrTagField() throws Exception {
        userRepository.save(new User("logintag@test.com", hashPassword("password123")));

        Map<String, String> loginRequest = new HashMap<>();
        loginRequest.put("emailOrTag", "logintag@test.com");
        loginRequest.put("password", "password123");

        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("logintag@test.com"));
    }

    @Test
    void googleLogin_ShouldCreateUser_WhenNotExists() throws Exception {
        Map<String, String> googleRequest = new HashMap<>();
        googleRequest.put("email", "google-new@test.com");
        googleRequest.put("displayName", "Google User");
        googleRequest.put("googleId", "gid-123");

        mockMvc.perform(post("/api/auth/google-login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(googleRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.email").value("google-new@test.com"));
    }

    @Test
    void googleLogin_ShouldUpdateDisplayName_WhenUserExistsWithDefaultName() throws Exception {
        User existing = new User("google-existing@test.com", hashPassword("x"));
        existing.setDisplayName("User");
        userRepository.save(existing);

        Map<String, String> googleRequest = new HashMap<>();
        googleRequest.put("email", "google-existing@test.com");
        googleRequest.put("displayName", "Updated Google Name");
        googleRequest.put("googleId", "gid-456");

        mockMvc.perform(post("/api/auth/google-login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(googleRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.displayName").value("Updated Google Name"));
    }

    @Test
    void googleLogin_ShouldReturnBadRequest_WhenEmailMissing() throws Exception {
        Map<String, String> googleRequest = new HashMap<>();
        googleRequest.put("displayName", "No Email");

        mockMvc.perform(post("/api/auth/google-login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(googleRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Email is required"));
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
