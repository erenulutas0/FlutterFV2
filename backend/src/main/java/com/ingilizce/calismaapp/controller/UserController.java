package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/users")
public class UserController {

    @Autowired
    private UserService userService;

    // Get current user details (simulated by ID)
    @GetMapping("/{id}")
    public ResponseEntity<User> getUserProfile(@PathVariable Long id) {
        // In a real app, we would get ID from security context/token
        Optional<User> user = userService.getUserById(id);
        return user.map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
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
