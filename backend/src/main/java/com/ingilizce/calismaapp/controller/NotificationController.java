package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.entity.Notification;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.UserRepository;
import com.ingilizce.calismaapp.service.NotificationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationService notificationService;
    private final UserRepository userRepository;

    public NotificationController(NotificationService notificationService, UserRepository userRepository) {
        this.notificationService = notificationService;
        this.userRepository = userRepository;
    }

    private User getUserFromHeader(String userIdHeader) {
        if (userIdHeader == null)
            throw new RuntimeException("Unauthorized");
        return userRepository.findById(Long.parseLong(userIdHeader))
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    @GetMapping
    public ResponseEntity<List<Notification>> getUserNotifications(@RequestHeader("X-User-Id") String userIdHeader) {
        User user = getUserFromHeader(userIdHeader);
        return ResponseEntity.ok(notificationService.getUserNotifications(user));
    }

    @PostMapping("/{id}/read")
    public ResponseEntity<Void> markAsRead(@PathVariable Long id) {
        notificationService.markAsRead(id);
        return ResponseEntity.ok().build();
    }
}
