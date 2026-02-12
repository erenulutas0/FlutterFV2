package com.ingilizce.calismaapp.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;
import org.springframework.stereotype.Service;

import java.util.Set;
import java.util.stream.Collectors;
import java.util.List;
import java.util.Map;
import java.util.ArrayList;

@Service
public class LeaderboardService {

    private static final String LEADERBOARD_KEY = "leaderboard:weekly";

    @Autowired
    private RedisTemplate<String, String> redisTemplate;

    // Increment user score (e.g., when learning a word)
    public void incrementScore(Long userId, double scoreDelta) {
        redisTemplate.opsForZSet().incrementScore(LEADERBOARD_KEY, String.valueOf(userId), scoreDelta);
    }

    // Get top N users (High score is better, so reverse range)
    public List<Map<String, Object>> getTopUsers(int limit) {
        Set<ZSetOperations.TypedTuple<String>> topUsers = redisTemplate.opsForZSet()
                .reverseRangeWithScores(LEADERBOARD_KEY, 0, limit - 1);

        if (topUsers == null)
            return new ArrayList<>();

        return topUsers.stream().map(tuple -> {
            Map<String, Object> map = new java.util.HashMap<>();
            map.put("userId", tuple.getValue());
            map.put("score", tuple.getScore());
            return map;
        }).collect(Collectors.toList());
    }

    // Get specific user's rank
    public Long getUserRank(Long userId) {
        Long rank = redisTemplate.opsForZSet().reverseRank(LEADERBOARD_KEY, String.valueOf(userId));
        return (rank != null) ? rank + 1 : -1; // 1-based index
    }

    // Get specific user's score
    public Double getUserScore(Long userId) {
        Double score = redisTemplate.opsForZSet().score(LEADERBOARD_KEY, String.valueOf(userId));
        return (score != null) ? score : 0.0;
    }
}
