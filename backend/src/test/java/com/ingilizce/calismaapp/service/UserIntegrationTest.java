package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@Transactional // Rollback after each test
class UserIntegrationTest {

    @Autowired
    private UserService userService;

    @Autowired
    private UserRepository userRepository;

    @Test
    void shouldCreateAndRetrieveUser() {
        User user = new User();
        user.setEmail("integration@test.com");
        user.setPasswordHash("hashed123");
        user.setDisplayName("IntegrationUser");

        User savedUser = userService.createUser(user);

        assertNotNull(savedUser.getId());

        Optional<User> retrieved = userService.getUserById(savedUser.getId());
        assertTrue(retrieved.isPresent());
        assertEquals("integration@test.com", retrieved.get().getEmail());
    }

    @Test
    void shouldUpdateLastSeenInDatabase() {
        User user = new User();
        user.setEmail("lastseen@test.com");
        user.setPasswordHash("pass");
        user.setDisplayName("LastSeenUser");
        user = userRepository.save(user);

        userService.updateLastSeen(user.getId());

        // Clear cache/context to ensure we read from DB (Transaction handles this but
        // good to be sure)
        // In @Transactional test, changes are flushed but not committed. FindById gets
        // from context/L1 cache.
        User updatedUser = userRepository.findById(user.getId()).get();

        assertNotNull(updatedUser.getLastSeenAt());
    }
}
