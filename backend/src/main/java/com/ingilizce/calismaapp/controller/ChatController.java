package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.entity.Message;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.UserRepository;
import com.ingilizce.calismaapp.service.ChatService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.ingilizce.calismaapp.dto.MessageDto;
import com.ingilizce.calismaapp.dto.UserDto;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/chat")
public class ChatController {

    private final ChatService chatService;
    private final UserRepository userRepository;

    public ChatController(ChatService chatService, UserRepository userRepository) {
        this.chatService = chatService;
        this.userRepository = userRepository;
    }

    private User getUserFromHeader(String userIdHeader) {
        if (userIdHeader == null)
            throw new RuntimeException("Unauthorized");
        return userRepository.findById(Long.parseLong(userIdHeader))
                .orElseThrow(() -> new RuntimeException("User not found"));
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
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader,
            @PathVariable Long receiverId,
            @RequestBody Map<String, String> payload) {

        try {
            if (userIdHeader == null)
                return ResponseEntity.status(401).body("Unauthorized");
            User sender = getUserFromHeader(userIdHeader);
            String content = payload.get("content");
            Message message = chatService.sendMessage(sender, receiverId, content);
            return ResponseEntity.ok(mapToMessageDto(message));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().body("Error: " + e.getMessage());
        }
    }

    @GetMapping("/messages/{otherUserId}")
    public ResponseEntity<List<MessageDto>> getConversation(
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader,
            @PathVariable Long otherUserId) {

        User user = getUserFromHeader(userIdHeader);
        List<Message> messages = chatService.getConversation(user, otherUserId);
        List<MessageDto> dtos = messages.stream().map(this::mapToMessageDto).collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    @GetMapping("/conversations")
    public ResponseEntity<List<UserDto>> getConversations(
            @RequestHeader("X-User-Id") String userIdHeader) {

        User user = getUserFromHeader(userIdHeader);
        List<User> users = chatService.getChattedUsers(user);
        List<UserDto> dtos = users.stream().map(this::mapToUserDto).collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }
}
