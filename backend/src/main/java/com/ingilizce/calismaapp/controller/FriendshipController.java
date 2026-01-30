package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.entity.Friendship;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.service.FriendshipService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/friends")
public class FriendshipController {

    @Autowired
    private FriendshipService friendshipService;

    // Helper for temporary extraction (until Phase 4 Security)
    private Long getUserId(String userIdHeader) {
        if (userIdHeader != null) {
            try {
                return Long.parseLong(userIdHeader);
            } catch (Exception e) {
            }
        }
        return 1L;
    }

    @PostMapping("/request")
    public ResponseEntity<Map<String, String>> sendRequest(
            @RequestBody Map<String, String> request,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {

        Long userId = getUserId(userIdHeader);
        String friendEmail = request.get("email");

        try {
            String message = friendshipService.sendRequest(userId, friendEmail);
            return ResponseEntity.ok(Map.of("message", message));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/accept/{requestId}")
    public ResponseEntity<Map<String, String>> acceptRequest(
            @PathVariable Long requestId,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {

        Long userId = getUserId(userIdHeader);
        try {
            friendshipService.acceptRequest(requestId, userId);
            return ResponseEntity.ok(Map.of("message", "Arkadaşlık kabul edildi!"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/list")
    public ResponseEntity<List<Map<String, Object>>> getFriends(
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        Long userId = getUserId(userIdHeader);
        List<User> friends = friendshipService.getFriends(userId);

        // Return simple DTOs
        List<Map<String, Object>> result = friends.stream().map(u -> {
            Map<String, Object> map = new java.util.HashMap<>();
            map.put("id", u.getId());
            map.put("email", u.getEmail());
            map.put("name", u.getEmail().split("@")[0]);
            return map;
        }).collect(Collectors.toList());

        return ResponseEntity.ok(result);
    }

    @GetMapping("/requests")
    public ResponseEntity<List<Map<String, Object>>> getPendingRequests(
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        Long userId = getUserId(userIdHeader);
        List<Friendship> requests = friendshipService.getPendingRequests(userId);

        List<Map<String, Object>> result = requests.stream().map(f -> {
            Map<String, Object> map = new java.util.HashMap<>();
            map.put("requestId", f.getId());
            map.put("requesterName", f.getRequester().getEmail().split("@")[0]);
            map.put("requesterEmail", f.getRequester().getEmail());
            map.put("sentAt", f.getCreatedAt().toString());
            return map;
        }).collect(Collectors.toList());

        return ResponseEntity.ok(result);
    }
}
