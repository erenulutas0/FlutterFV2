package com.ingilizce.calismaapp.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

public class MatchmakingServiceTest {

    private MatchmakingService matchmakingService;

    @BeforeEach
    void setUp() {
        matchmakingService = new MatchmakingService();
    }

    @Test
    void testMatchmakingFlow() {
        // First user joins
        MatchmakingService.MatchInfo match1 = matchmakingService.joinQueue("user1");
        assertNull(match1);
        assertEquals(1, matchmakingService.getQueueSize());

        // Second user joins
        MatchmakingService.MatchInfo match2 = matchmakingService.joinQueue("user2");
        assertNotNull(match2);
        assertEquals("user1", match2.user1.equals("user2") ? match2.user2 : match2.user1);
        assertEquals(0, matchmakingService.getQueueSize());

        // Check active match
        assertNotNull(matchmakingService.getMatch("user1"));
        assertNotNull(matchmakingService.getMatch("user2"));

        // End match
        matchmakingService.endMatch("user1");
        assertNull(matchmakingService.getMatch("user1"));
        assertNull(matchmakingService.getMatch("user2"));
    }

    @Test
    void testLeaveQueue() {
        matchmakingService.joinQueue("user1");
        matchmakingService.leaveQueue("user1");
        assertEquals(0, matchmakingService.getQueueSize());
    }

    @Test
    void testRoomIdConsistency() {
        // Room ID should be same regardless of order
        MatchmakingService.MatchInfo m1 = matchmakingService.joinQueue("A");
        MatchmakingService.MatchInfo m2 = matchmakingService.joinQueue("B");

        matchmakingService.endMatch("A");

        MatchmakingService.MatchInfo m3 = matchmakingService.joinQueue("B");
        MatchmakingService.MatchInfo m4 = matchmakingService.joinQueue("A");

        assertEquals(m2.roomId, m4.roomId);
    }
}
