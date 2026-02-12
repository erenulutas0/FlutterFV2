package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.entity.Message;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.UserRepository;
import com.ingilizce.calismaapp.service.ChatService;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.ingilizce.calismaapp.dto.MessageDto;
import com.ingilizce.calismaapp.dto.UserDto;

import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.stream.Collectors;

@RestController
@ConditionalOnProperty(name = "app.features.community.enabled", havingValue = "true", matchIfMissing = false)
@RequestMapping("/api/chat")
public class ChatController {

    private final ChatService chatService;
    private final UserRepository userRepository;

    public ChatController(ChatService chatService, UserRepository userRepository) {
        this.chatService = chatService;
        this.userRepository = userRepository;
    }

    private User getUserFromHeader(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new NoSuchElementException("User not found"));
    }

    private UserDto mapToUserDto(User user) {
        return new UserDto(user.getId(), user.getDisplayName(), user.getUserTag(), user.isOnline());
    }

    private MessageDto mapToMessageDto(Message message) {
        return new MessageDto(
                message.getId(),
                message.getContent(),
                message.getCreatedAt(),
                mapToUserDto(message.getSender()),
                mapToUserDto(message.getReceiver()),
                message.isRead());
    }

    @PostMapping("/send/{receiverId}")
    public ResponseEntity<?> sendMessage(
            @RequestHeader("X-User-Id") Long userId,
            @PathVariable Long receiverId,
            @RequestBody Map<String, String> payload) {
        User sender = getUserFromHeader(userId);
        String content = payload.get("content");
        Message message = chatService.sendMessage(sender, receiverId, content);
        return ResponseEntity.ok(mapToMessageDto(message));
    }

    @GetMapping("/messages/{otherUserId}")
    public ResponseEntity<List<MessageDto>> getConversation(
            @RequestHeader("X-User-Id") Long userId,
            @PathVariable Long otherUserId) {
        User user = getUserFromHeader(userId);
        List<Message> messages = chatService.getConversation(user, otherUserId);
        List<MessageDto> dtos = messages.stream().map(this::mapToMessageDto).collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    @GetMapping("/conversations")
    public ResponseEntity<List<UserDto>> getConversations(
            @RequestHeader("X-User-Id") Long userId) {

        User user = getUserFromHeader(userId);
        List<User> users = chatService.getChattedUsers(user);
        List<UserDto> dtos = users.stream().map(this::mapToUserDto).collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }
}
