package com.ingilizce.calismaapp.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ingilizce.calismaapp.entity.Message;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.UserRepository;
import com.ingilizce.calismaapp.security.JwtAuthenticationFilter;
import com.ingilizce.calismaapp.security.UserHeaderConsistencyFilter;
import com.ingilizce.calismaapp.service.ChatService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = ChatController.class)
@AutoConfigureMockMvc(addFilters = false)
@TestPropertySource(properties = "app.features.community.enabled=true")
class ChatControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private ChatService chatService;

    @MockBean
    private UserRepository userRepository;

    @MockBean
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    @MockBean
    private UserHeaderConsistencyFilter userHeaderConsistencyFilter;

    @Test
    void sendMessageReturnsBadRequestWhenHeaderMissing() throws Exception {
        mockMvc.perform(post("/api/chat/send/2")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("content", "hello"))))
                .andExpect(status().isBadRequest());

        verify(chatService, never()).sendMessage(any(User.class), anyLong(), anyString());
    }

    @Test
    void sendMessageReturnsBadRequestWhenHeaderInvalid() throws Exception {
        mockMvc.perform(post("/api/chat/send/2")
                        .header("X-User-Id", "abc")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("content", "hello"))))
                .andExpect(status().isBadRequest());

        verify(chatService, never()).sendMessage(any(User.class), anyLong(), anyString());
    }

    @Test
    void sendMessageReturnsOkWhenValid() throws Exception {
        User sender = new User("sender@example.com", "hash", "Sender");
        sender.setId(1L);
        User receiver = new User("receiver@example.com", "hash", "Receiver");
        receiver.setId(2L);

        Message savedMessage = new Message(sender, receiver, "hello");
        savedMessage.setId(99L);

        when(userRepository.findById(1L)).thenReturn(Optional.of(sender));
        when(chatService.sendMessage(eq(sender), eq(2L), eq("hello"))).thenReturn(savedMessage);

        mockMvc.perform(post("/api/chat/send/2")
                        .header("X-User-Id", "1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("content", "hello"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(99))
                .andExpect(jsonPath("$.content").value("hello"))
                .andExpect(jsonPath("$.sender.id").value(1))
                .andExpect(jsonPath("$.receiver.id").value(2));
    }

    @Test
    void getConversationReturnsBadRequestWhenHeaderMissing() throws Exception {
        mockMvc.perform(get("/api/chat/messages/2"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void getConversationReturnsConversationWhenHeaderValid() throws Exception {
        User currentUser = new User("current@example.com", "hash", "Current");
        currentUser.setId(1L);
        User otherUser = new User("other@example.com", "hash", "Other");
        otherUser.setId(2L);
        Message message = new Message(currentUser, otherUser, "hey");
        message.setId(11L);

        when(userRepository.findById(1L)).thenReturn(Optional.of(currentUser));
        when(chatService.getConversation(currentUser, 2L)).thenReturn(List.of(message));

        mockMvc.perform(get("/api/chat/messages/2").header("X-User-Id", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(11))
                .andExpect(jsonPath("$[0].content").value("hey"));
    }
}
