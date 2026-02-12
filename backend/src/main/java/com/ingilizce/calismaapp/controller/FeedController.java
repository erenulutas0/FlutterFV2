package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.entity.UserActivity;
import com.ingilizce.calismaapp.service.FeedService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@ConditionalOnProperty(name = "app.features.community.enabled", havingValue = "true", matchIfMissing = false)
@RequestMapping("/api/feed")
public class FeedController {

    @Autowired
    private FeedService feedService;

    @GetMapping
    public ResponseEntity<List<Map<String, Object>>> getFeed(
            @RequestParam(defaultValue = "20") int limit,
            @RequestHeader("X-User-Id") Long userId) {
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
