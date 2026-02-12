package com.ingilizce.calismaapp.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;

import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

class LeaderboardServiceTest {

    @InjectMocks
    private LeaderboardService leaderboardService;

    @Mock
    private RedisTemplate<String, String> redisTemplate;

    @Mock
    private ZSetOperations<String, String> zSetOperations;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        when(redisTemplate.opsForZSet()).thenReturn(zSetOperations);
    }

    @Test
    void incrementScore_ShouldCallRedisZIncrBy() {
        // Arrange
        Long userId = 100L;
        double score = 10.0;

        // Act
        leaderboardService.incrementScore(userId, score);

        // Assert
        verify(zSetOperations, times(1)).incrementScore(anyString(), eq(userId.toString()), eq(score));
    }

    @Test
    void getTopUsers_ShouldReturnMappedResults() {
        // Arrange
        String leaderboardKey = "leaderboard:weekly"; // Key MUST match service constant
        Set<ZSetOperations.TypedTuple<String>> topUsersSet = new HashSet<>();

        // Mock TypedTuple
        ZSetOperations.TypedTuple<String> tuple1 = mock(ZSetOperations.TypedTuple.class);
        when(tuple1.getValue()).thenReturn("100");
        when(tuple1.getScore()).thenReturn(50.0);
        topUsersSet.add(tuple1);

        when(zSetOperations.reverseRangeWithScores(eq(leaderboardKey), eq(0L), eq(9L))).thenReturn(topUsersSet);

        // Act
        // Note: verify the method uses the correct key
        List<Map<String, Object>> result = leaderboardService.getTopUsers(10);

        // Assert
        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("100", result.get(0).get("userId"));
        assertEquals(50.0, result.get(0).get("score"));
    }

    @Test
    void getTopUsers_ShouldReturnEmptyList_WhenRedisReturnsNull() {
        when(zSetOperations.reverseRangeWithScores(eq("leaderboard:weekly"), eq(0L), eq(4L))).thenReturn(null);

        List<Map<String, Object>> result = leaderboardService.getTopUsers(5);

        assertNotNull(result);
        assertEquals(0, result.size());
    }

    @Test
    void getUserRank_ShouldReturnOneBasedRank_WhenPresent() {
        when(zSetOperations.reverseRank("leaderboard:weekly", "77")).thenReturn(0L);

        Long rank = leaderboardService.getUserRank(77L);

        assertEquals(1L, rank);
    }

    @Test
    void getUserRank_ShouldReturnMinusOne_WhenMissing() {
        when(zSetOperations.reverseRank("leaderboard:weekly", "77")).thenReturn(null);

        Long rank = leaderboardService.getUserRank(77L);

        assertEquals(-1L, rank);
    }

    @Test
    void getUserScore_ShouldReturnScore_WhenPresent() {
        when(zSetOperations.score("leaderboard:weekly", "99")).thenReturn(42.5);

        Double score = leaderboardService.getUserScore(99L);

        assertEquals(42.5, score);
    }

    @Test
    void getUserScore_ShouldReturnZero_WhenMissing() {
        when(zSetOperations.score("leaderboard:weekly", "99")).thenReturn(null);

        Double score = leaderboardService.getUserScore(99L);

        assertEquals(0.0, score);
    }
}
