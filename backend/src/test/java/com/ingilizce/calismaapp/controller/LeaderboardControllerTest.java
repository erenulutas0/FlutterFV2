package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.UserRepository;
import com.ingilizce.calismaapp.service.LeaderboardService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Map;

import static org.mockito.ArgumentMatchers.anyIterable;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = LeaderboardController.class)
@AutoConfigureMockMvc(addFilters = false)
@TestPropertySource(properties = "app.features.community.enabled=true")
class LeaderboardControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private LeaderboardService leaderboardService;

    @MockBean
    private UserRepository userRepository;

    @Test
    void testGetTopUsersEnriched() throws Exception {
        when(leaderboardService.getTopUsers(2)).thenReturn(List.of(
                Map.of("userId", "1", "score", 50.0),
                Map.of("userId", "2", "score", 25.0)));

        User user1 = new User("first@example.com", "hash");
        user1.setId(1L);
        User user2 = new User("second@example.com", "hash");
        user2.setId(2L);
        when(userRepository.findAllById(anyIterable())).thenReturn(List.of(user1, user2));

        mockMvc.perform(get("/api/leaderboard/top").param("limit", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].userId").value(1))
                .andExpect(jsonPath("$[0].displayName").value("first"))
                .andExpect(jsonPath("$[1].userId").value(2))
                .andExpect(jsonPath("$[1].displayName").value("second"));

        verify(leaderboardService).getTopUsers(2);
        verify(userRepository).findAllById(anyIterable());
    }

    @Test
    void testGetTopUsersFallbackDisplayNameForMissingOrInvalidEmail() throws Exception {
        when(leaderboardService.getTopUsers(2)).thenReturn(List.of(
                Map.of("userId", "1", "score", 50.0),
                Map.of("userId", "2", "score", 25.0)));

        User invalidEmailUser = new User("no-at-symbol", "hash");
        invalidEmailUser.setId(1L);
        when(userRepository.findAllById(anyIterable())).thenReturn(List.of(invalidEmailUser));

        mockMvc.perform(get("/api/leaderboard/top").param("limit", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].displayName").value("Unknown"))
                .andExpect(jsonPath("$[1].displayName").value("Unknown"));
    }

    @Test
    void testGetMyRankWithHeader() throws Exception {
        when(leaderboardService.getUserRank(12L)).thenReturn(3L);
        when(leaderboardService.getUserScore(12L)).thenReturn(99.5);

        mockMvc.perform(get("/api/leaderboard/my-rank").header("X-User-Id", "12"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userId").value(12))
                .andExpect(jsonPath("$.rank").value(3))
                .andExpect(jsonPath("$.score").value(99.5));

        verify(leaderboardService).getUserRank(12L);
        verify(leaderboardService).getUserScore(12L);
    }

    @Test
    void testGetMyRankReturnsBadRequestForInvalidHeader() throws Exception {
        mockMvc.perform(get("/api/leaderboard/my-rank").header("X-User-Id", "abc"))
                .andExpect(status().isBadRequest());

        verify(leaderboardService, never()).getUserRank(anyLong());
        verify(leaderboardService, never()).getUserScore(anyLong());
    }

    @Test
    void testGetMyRankReturnsBadRequestWhenHeaderMissing() throws Exception {
        mockMvc.perform(get("/api/leaderboard/my-rank"))
                .andExpect(status().isBadRequest());
    }
}
