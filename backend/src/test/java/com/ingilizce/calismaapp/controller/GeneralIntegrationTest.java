package com.ingilizce.calismaapp.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.entity.Word;
import com.ingilizce.calismaapp.repository.UserRepository;
import com.ingilizce.calismaapp.repository.WordRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.util.HashMap;
import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.hamcrest.Matchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@TestPropertySource(properties = {
                "GROQ_API_KEY=dummy-key",
                "spring.data.redis.port=6379",
                "spring.datasource.url=jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1;MODE=PostgreSQL",
                "spring.datasource.driver-class-name=org.h2.Driver",
                "spring.datasource.username=sa",
                "spring.datasource.password=",
                "spring.jpa.hibernate.ddl-auto=create-drop",
                "app.features.community.enabled=false"
})
public class GeneralIntegrationTest {

        @Autowired
        private MockMvc mockMvc;

        @Autowired
        private UserRepository userRepository;

        @Autowired
        private WordRepository wordRepository;

        @Autowired
        private ObjectMapper objectMapper;

        @org.springframework.boot.test.mock.mockito.MockBean
        private org.springframework.data.redis.core.RedisTemplate<String, String> redisTemplate;

        @org.springframework.boot.test.mock.mockito.MockBean
        private org.springframework.data.redis.core.ZSetOperations<String, String> zSetOperations;

        @BeforeEach
        void setUp() {
                // Mock Redis ops
                org.mockito.Mockito.when(redisTemplate.opsForZSet()).thenReturn(zSetOperations);

                // Clean DB
                wordRepository.deleteAll();
                userRepository.deleteAll();
        }

        @Test
        void fullFlow_ShouldWorkSmoothly_WhenCommunityFeaturesDisabled() throws Exception {
                // 1. Create User A
                User userA = new User("userA@test.com", "pass");
                userA = userRepository.save(userA);

                // 2. Create User B
                User userB = new User("userB@test.com", "pass");
                userB = userRepository.save(userB);

                // 3. User A adds a word
                Word word = new Word();
                word.setEnglishWord("Integration");
                word.setTurkishMeaning("Entegrasyon");
                word.setLearnedDate(java.time.LocalDate.now());
                // UserId is set by controller via header in this test setup (simplified)
                // Adjusting logic: Controller uses X-User-Id header for ID.

                mockMvc.perform(post("/api/words")
                                .header("X-User-Id", userA.getId().toString())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(word)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.englishWord").value("Integration"));

                // 4. Verify Word List
                mockMvc.perform(get("/api/words")
                                .header("X-User-Id", userA.getId().toString()))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$", hasSize(1)));

                // 5. Community endpoints are disabled for the release scope
                Map<String, String> friendRequest = new HashMap<>();
                friendRequest.put("email", "userB@test.com");

                mockMvc.perform(post("/api/friends/request")
                                .header("X-User-Id", userA.getId().toString())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(friendRequest)))
                                .andExpect(status().isNotFound());

                // 6. Friend request listing is also disabled
                mockMvc.perform(get("/api/friends/requests")
                                .header("X-User-Id", userB.getId().toString()))
                                .andExpect(status().isNotFound());

                // 7. Leaderboard endpoint is disabled
                mockMvc.perform(get("/api/leaderboard/my-rank")
                                .header("X-User-Id", userA.getId().toString()))
                                .andExpect(status().isNotFound());

                // 8. Feed endpoint is disabled
                mockMvc.perform(get("/api/feed")
                                .header("X-User-Id", userA.getId().toString()))
                                .andExpect(status().isNotFound());

                // 9. Check User Profile
                mockMvc.perform(get("/api/users/" + userA.getId()))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.email").value("userA@test.com"));

                // 10. Check Subscription Status
                mockMvc.perform(get("/api/users/" + userA.getId() + "/subscription/status"))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.isActive").exists());
        }
}
