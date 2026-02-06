package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.dto.UserDto;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/users")
public class UserController {

    @Autowired
    private UserService userService;

    private UserDto mapToUserDto(User user) {
        return new UserDto(user.getId(), user.getDisplayName(), user.getUserTag(), user.isOnline());
    }

    @GetMapping
    public ResponseEntity<List<UserDto>> getAllUsers(
            @RequestHeader(value = "X-User-Id", required = false) String currentUserId) {
        List<User> users = userService.getAllUsers();

        if (currentUserId != null) {
            try {
                Long id = Long.parseLong(currentUserId);
                users = users.stream()
                        .filter(u -> !u.getId().equals(id))
                        .collect(Collectors.toList());
            } catch (NumberFormatException ignored) {
            }
        }

        // Online kullanıcıları önce göster
        List<UserDto> dtos = users.stream()
                .sorted(Comparator.comparing(User::isOnline).reversed()
                        .thenComparing(u -> u.getLastSeenAt() != null ? u.getLastSeenAt() : LocalDateTime.MIN,
                                Comparator.reverseOrder()))
                .map(this::mapToUserDto)
                .collect(Collectors.toList());

        return ResponseEntity.ok(dtos);
    }

    // Get current user details (simulated by ID)
    @GetMapping("/{id}")
    public ResponseEntity<User> getUserProfile(@PathVariable Long id) {
        // In a real app, we would get ID from security context/token
        Optional<User> user = userService.getUserById(id);
        return user.map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // Heartbeat endpoint - call this periodically to update online status
    @PostMapping("/heartbeat")
    public ResponseEntity<Map<String, Object>> heartbeat(
            @RequestHeader("X-User-Id") String userIdHeader) {
        try {
            Long userId = Long.parseLong(userIdHeader);
            userService.updateLastSeen(userId);
            return ResponseEntity.ok(Map.of("status", "ok", "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("error", e.getMessage()));
        }
    }

    // Admin/Test endpoint to extend subscription
    @PostMapping("/{id}/subscription/extend")
    public ResponseEntity<Map<String, Object>> extendSubscription(@PathVariable Long id,
            @RequestBody Map<String, Integer> request) {
        Integer days = request.get("days");
        if (days == null || days <= 0) {
            return ResponseEntity.badRequest().body(Map.of("error", "Invalid days provided"));
        }

        boolean success = userService.extendSubscription(id, days);
        if (success) {
            Optional<User> updatedUser = userService.getUserById(id);
            return ResponseEntity.ok(Map.of(
                    "message", "Subscription extended successfully",
                    "newEndDate", updatedUser.get().getSubscriptionEndDate()));
        }
        return ResponseEntity.notFound().build();
    }

    @GetMapping("/{id}/subscription/status")
    public ResponseEntity<Map<String, Object>> getSubscriptionStatus(@PathVariable Long id) {
        Optional<User> user = userService.getUserById(id);
        if (user.isPresent()) {
            return ResponseEntity.ok(Map.of(
                    "userId", id,
                    "isActive", user.get().isSubscriptionActive(),
                    "endDate",
                    user.get().getSubscriptionEndDate() != null ? user.get().getSubscriptionEndDate() : "null"));
        }
        return ResponseEntity.notFound().build();
    }
}
