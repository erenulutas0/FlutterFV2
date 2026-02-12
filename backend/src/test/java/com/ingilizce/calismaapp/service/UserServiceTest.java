package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.List;
import java.util.Arrays;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserService userService;

    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = new User();
        testUser.setId(1L);
        testUser.setEmail("test@example.com");
        testUser.setDisplayName("TestUser");
        testUser.setPasswordHash("hashedpassword");
    }

    @Test
    void getUserById_ShouldReturnUser_WhenUserExists() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(testUser));

        Optional<User> found = userService.getUserById(1L);

        assertTrue(found.isPresent());
        assertEquals("test@example.com", found.get().getEmail());
    }

    @Test
    void getUserByEmail_ShouldReturnUser_WhenUserExists() {
        when(userRepository.findByEmail("test@example.com")).thenReturn(Optional.of(testUser));

        Optional<User> found = userService.getUserByEmail("test@example.com");

        assertTrue(found.isPresent());
        assertEquals(1L, found.get().getId());
    }

    @Test
    void getAllUsers_ShouldReturnList() {
        when(userRepository.findAll()).thenReturn(Arrays.asList(testUser, new User()));

        List<User> users = userService.getAllUsers();

        assertEquals(2, users.size());
    }

    @Test
    void createUser_ShouldSaveAndReturnUser() {
        when(userRepository.save(any(User.class))).thenReturn(testUser);

        User created = userService.createUser(testUser);

        assertNotNull(created);
        assertEquals(1L, created.getId());
        verify(userRepository).save(testUser);
    }

    @Test
    void extendSubscription_ShouldSetEndDateFromNow_WhenNoActiveSubscription() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(testUser));
        // Mevcut bitiş tarihi yok veya geçmişte
        testUser.setSubscriptionEndDate(LocalDateTime.now().minusDays(1));

        userService.extendSubscription(1L, 30);

        assertNotNull(testUser.getSubscriptionEndDate());
        // Yaklaşık olarak now + 30 gün olmalı. Unit testte tam zamanı tutturmak zordur,
        // range kontrol edilebilir
        // veya mock User kullanılabilir ama POJO kullanıyoruz.
        // Basitçe gelecekte olduğunu kontrol edelim.
        assertTrue(testUser.getSubscriptionEndDate().isAfter(LocalDateTime.now().plusDays(29)));
        verify(userRepository).save(testUser);
    }

    @Test
    void extendSubscription_ShouldAddDaysToExistingDate_WhenSubscriptionActive() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(testUser));
        LocalDateTime existingEnd = LocalDateTime.now().plusDays(10);
        testUser.setSubscriptionEndDate(existingEnd);

        userService.extendSubscription(1L, 30);

        // existingEnd + 30 gün olmalı
        assertEquals(existingEnd.plusDays(30), testUser.getSubscriptionEndDate());
        verify(userRepository).save(testUser);
    }

    @Test
    void isSubscriptionActive_ShouldReturnTrue_WhenActive() {
        testUser.setSubscriptionEndDate(LocalDateTime.now().plusDays(5));
        when(userRepository.findById(1L)).thenReturn(Optional.of(testUser));

        assertTrue(userService.isSubscriptionActive(1L));
    }

    @Test
    void isSubscriptionActive_ShouldReturnFalse_WhenExpired() {
        testUser.setSubscriptionEndDate(LocalDateTime.now().minusDays(1));
        when(userRepository.findById(1L)).thenReturn(Optional.of(testUser));

        assertFalse(userService.isSubscriptionActive(1L));
    }

    @Test
    void isSubscriptionActive_ShouldReturnFalse_WhenUserNotFound() {
        when(userRepository.findById(99L)).thenReturn(Optional.empty());
        assertFalse(userService.isSubscriptionActive(99L));
    }

    @Test
    void updateLastSeen_ShouldUpdateTimestamp() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(testUser));

        userService.updateLastSeen(1L);

        assertNotNull(testUser.getLastSeenAt());
        // Check if reasonably recent
        assertTrue(testUser.getLastSeenAt().isAfter(LocalDateTime.now().minusMinutes(1)));
        verify(userRepository).save(testUser);
    }

    @Test
    void extendSubscription_ShouldReturnFalse_WhenUserNotFound() {
        when(userRepository.findById(404L)).thenReturn(Optional.empty());

        boolean extended = userService.extendSubscription(404L, 30);

        assertFalse(extended);
        verify(userRepository, never()).save(any(User.class));
    }
}
