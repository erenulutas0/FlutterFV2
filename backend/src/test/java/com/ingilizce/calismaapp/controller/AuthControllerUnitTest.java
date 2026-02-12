package com.ingilizce.calismaapp.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.Map;
import java.util.Optional;

import static org.hamcrest.Matchers.containsString;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class AuthControllerUnitTest {

    private MockMvc mockMvc;
    private UserRepository userRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        AuthController controller = new AuthController();
        userRepository = mock(UserRepository.class);
        ReflectionTestUtils.setField(controller, "userRepository", userRepository);
        mockMvc = MockMvcBuilders.standaloneSetup(controller).build();
    }

    @Test
    void register_ShouldReturnBadRequest_WhenPasswordMissing() throws Exception {
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("email", "a@test.com"))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Email and password required"));
    }

    @Test
    void register_ShouldReturnInternalServerError_WhenRepositorySaveFails() throws Exception {
        when(userRepository.existsByEmail("a@test.com")).thenReturn(false);
        when(userRepository.save(any(User.class))).thenThrow(new RuntimeException("db down"));

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "email", "a@test.com",
                                "password", "pass123",
                                "displayName", "A User"))))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error", containsString("db down")));
    }

    @Test
    void login_ShouldReturnUnauthorized_WhenUserDoesNotExist() throws Exception {
        when(userRepository.findByEmail("missing@test.com")).thenReturn(Optional.empty());

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "email", "missing@test.com",
                                "password", "pass123"))))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error").value("Invalid credentials"));
    }

    @Test
    void login_ShouldReturnInternalServerError_WhenRepositoryThrows() throws Exception {
        when(userRepository.findByEmail(anyString())).thenThrow(new RuntimeException("db down"));

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "email", "user@test.com",
                                "password", "pass123"))))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error").value("Internal login error"));
    }

    @Test
    void googleLogin_ShouldNotSave_WhenExistingUserHasCustomDisplayName() throws Exception {
        User user = new User("google@test.com", "hash", "Custom Name");
        user.setId(10L);
        when(userRepository.findByEmail("google@test.com")).thenReturn(Optional.of(user));

        mockMvc.perform(post("/api/auth/google-login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "email", "google@test.com",
                                "displayName", "Incoming Name",
                                "googleId", "gid-1"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.displayName").value("Custom Name"));

        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void googleLogin_ShouldReturnInternalServerError_WhenRepositoryThrows() throws Exception {
        when(userRepository.findByEmail("google@test.com")).thenThrow(new RuntimeException("db down"));

        mockMvc.perform(post("/api/auth/google-login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "email", "google@test.com",
                                "displayName", "Name"))))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error", containsString("Google login error")));
    }

    @Test
    void googleLogin_ShouldCreateUser_WhenGoogleIdMissingForNewUser() throws Exception {
        when(userRepository.findByEmail("new@test.com")).thenReturn(Optional.empty());
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User u = invocation.getArgument(0);
            u.setId(42L);
            return u;
        });

        mockMvc.perform(post("/api/auth/google-login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "email", "new@test.com",
                                "displayName", "New User"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.userId").value(42))
                .andExpect(jsonPath("$.email").value("new@test.com"));
    }
}
