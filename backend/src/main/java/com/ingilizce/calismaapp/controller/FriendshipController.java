package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.entity.Friendship;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.service.FriendshipService;
import com.ingilizce.calismaapp.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/friends")
public class FriendshipController {

    @Autowired
    private FriendshipService friendshipService;

    @Autowired
    private UserRepository userRepository;

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

    @DeleteMapping("/remove/{friendId}")
    public ResponseEntity<Map<String, String>> removeFriend(
            @PathVariable Long friendId,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {

        Long userId = getUserId(userIdHeader);
        try {
            friendshipService.removeFriend(userId, friendId);
            return ResponseEntity.ok(Map.of("message", "Arkadaşlıktan çıkarıldı."));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/status/{otherUserId}")
    public ResponseEntity<Map<String, Object>> getFriendshipStatus(
            @PathVariable Long otherUserId,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {

        Long userId = getUserId(userIdHeader);
        String status = friendshipService.getFriendshipStatus(userId, otherUserId);
        return ResponseEntity.ok(Map.of("status", status, "isFriend", status.equals("ACCEPTED")));
    }

    @GetMapping("/list")
    public ResponseEntity<List<Map<String, Object>>> getFriends(
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        Long userId = getUserId(userIdHeader);
        List<User> friends = friendshipService.getFriends(userId);

        // Return simple DTOs with online status
        List<Map<String, Object>> result = friends.stream().map(u -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", u.getId());
            map.put("email", u.getEmail());
            map.put("displayName", u.getDisplayName());
            map.put("userTag", u.getUserTag());
            map.put("online", u.isOnline());
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
            Map<String, Object> map = new HashMap<>();
            map.put("requestId", f.getId());
            map.put("requesterId", f.getRequester().getId());
            map.put("requesterName", f.getRequester().getDisplayName());
            map.put("requesterEmail", f.getRequester().getEmail());
            map.put("requesterTag", f.getRequester().getUserTag());
            map.put("sentAt", f.getCreatedAt().toString());
            return map;
        }).collect(Collectors.toList());

        return ResponseEntity.ok(result);
    }

    // Get user profile by ID
    @GetMapping("/profile/{profileUserId}")
    public ResponseEntity<Map<String, Object>> getUserProfile(
            @PathVariable Long profileUserId,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {

        Long currentUserId = getUserId(userIdHeader);

        User profileUser = userRepository.findById(profileUserId).orElse(null);
        if (profileUser == null) {
            return ResponseEntity.notFound().build();
        }

        String friendshipStatus = friendshipService.getFriendshipStatus(currentUserId, profileUserId);

        Map<String, Object> profile = new HashMap<>();
        profile.put("id", profileUser.getId());
        profile.put("displayName", profileUser.getDisplayName());
        profile.put("userTag", profileUser.getUserTag());
        profile.put("email", profileUser.getEmail());
        profile.put("createdAt", profileUser.getCreatedAt().toString());
        profile.put("online", profileUser.isOnline());
        profile.put("friendshipStatus", friendshipStatus);
        profile.put("isFriend", friendshipStatus.equals("ACCEPTED"));
        profile.put("isCurrentUser", currentUserId.equals(profileUserId));
        // Level placeholder - can be calculated from word count or stats later
        profile.put("level", 1);

        return ResponseEntity.ok(profile);
    }
}
