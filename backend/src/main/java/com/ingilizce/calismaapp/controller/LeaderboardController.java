package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.service.LeaderboardService;
import com.ingilizce.calismaapp.repository.UserRepository;
import com.ingilizce.calismaapp.entity.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/leaderboard")
public class LeaderboardController {

    @Autowired
    private LeaderboardService leaderboardService;

    @Autowired
    private UserRepository userRepository;

    @GetMapping("/top")
    public ResponseEntity<List<Map<String, Object>>> getTopUsers(@RequestParam(defaultValue = "10") int limit) {
        List<Map<String, Object>> topIds = leaderboardService.getTopUsers(limit);

        // Enrich with User info (Name/Email) from DB
        // In a real high-scale app, we would cache user display names in Redis too to
        // avoid this loop.
        // For now, fetching from DB is fine.
        List<Map<String, Object>> richLeaderboard = topIds.stream().map(entry -> {
            String userIdStr = (String) entry.get("userId");
            Long userId = Long.parseLong(userIdStr);
            User user = userRepository.findById(userId).orElse(new User("Unknown", ""));

            return Map.of(
                    "userId", userId,
                    "displayName", user.getEmail().split("@")[0], // Simple display name from email
                    "score", entry.get("score"));
        }).collect(Collectors.toList());

        return ResponseEntity.ok(richLeaderboard);
    }

    @GetMapping("/my-rank")
    public ResponseEntity<Map<String, Object>> getMyRank(
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        // Fallback for secure context later
        Long userId = 1L;
        if (userIdHeader != null) {
            try {
                userId = Long.parseLong(userIdHeader);
            } catch (Exception e) {
            }
        }

        Long rank = leaderboardService.getUserRank(userId);
        Double score = leaderboardService.getUserScore(userId);

        return ResponseEntity.ok(Map.of(
                "userId", userId,
                "rank", rank,
                "score", score));
    }
}
