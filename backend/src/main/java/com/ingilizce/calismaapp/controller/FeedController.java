package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.entity.UserActivity;
import com.ingilizce.calismaapp.service.FeedService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/feed")
public class FeedController {

    @Autowired
    private FeedService feedService;

    // Helper for userId extraction
    private Long getUserId(String userIdHeader) {
        if (userIdHeader != null) {
            try {
                return Long.parseLong(userIdHeader);
            } catch (Exception e) {
            }
        }
        return 1L;
    }

    @GetMapping
    public ResponseEntity<List<Map<String, Object>>> getFeed(
            @RequestParam(defaultValue = "20") int limit,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {

        Long userId = getUserId(userIdHeader);
        List<UserActivity> activities = feedService.getFeed(userId, limit);

        // Convert to DTO/Map
        List<Map<String, Object>> result = activities.stream().map(a -> {
            Map<String, Object> map = new java.util.HashMap<>();
            map.put("id", a.getId());
            map.put("userId", a.getUserId());
            map.put("type", a.getType().toString());
            map.put("description", a.getDescription());
            map.put("createdAt", a.getCreatedAt().toString());
            return map;
        }).collect(Collectors.toList());

        return ResponseEntity.ok(result);
    }
}
