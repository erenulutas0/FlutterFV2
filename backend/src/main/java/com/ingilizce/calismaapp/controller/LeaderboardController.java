package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.service.LeaderboardService;
import com.ingilizce.calismaapp.repository.UserRepository;
import com.ingilizce.calismaapp.entity.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.stream.Collectors;

@RestController
@ConditionalOnProperty(name = "app.features.community.enabled", havingValue = "true", matchIfMissing = false)
@RequestMapping("/api/leaderboard")
public class LeaderboardController {

    @Autowired
    private LeaderboardService leaderboardService;

    @Autowired
    private UserRepository userRepository;

    @GetMapping("/top")
    public ResponseEntity<List<Map<String, Object>>> getTopUsers(@RequestParam(defaultValue = "10") int limit) {
        List<Map<String, Object>> topIds = leaderboardService.getTopUsers(limit);
        List<Long> userIds = topIds.stream()
                .map(entry -> Long.parseLong((String) entry.get("userId")))
                .toList();
        Map<Long, User> usersById = new HashMap<>();
        userRepository.findAllById(userIds).forEach(user -> usersById.put(user.getId(), user));

        List<Map<String, Object>> richLeaderboard = topIds.stream().map(entry -> {
            String userIdStr = (String) entry.get("userId");
            Long userId = Long.parseLong(userIdStr);
            User user = usersById.get(userId);
            String displayName = "Unknown";
            if (user != null && user.getEmail() != null && user.getEmail().contains("@")) {
                displayName = user.getEmail().split("@")[0];
            }

            return Map.of(
                    "userId", userId,
                    "displayName", displayName,
                    "score", entry.get("score"));
        }).collect(Collectors.toList());

        return ResponseEntity.ok(richLeaderboard);
    }

    @GetMapping("/my-rank")
    public ResponseEntity<Map<String, Object>> getMyRank(
            @RequestHeader("X-User-Id") Long userId) {
        Long rank = leaderboardService.getUserRank(userId);
        Double score = leaderboardService.getUserScore(userId);

        return ResponseEntity.ok(Map.of(
                "userId", userId,
                "rank", rank,
                "score", score));
    }
}
