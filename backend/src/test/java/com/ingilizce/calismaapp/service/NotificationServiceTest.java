package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.Notification;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.NotificationRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class NotificationServiceTest {

    @Mock
    private NotificationRepository notificationRepository;

    @InjectMocks
    private NotificationService notificationService;

    private User user;

    @BeforeEach
    void setUp() {
        user = new User("notify@test.com", "hash", "Notify");
        user.setId(1L);
    }

    @Test
    void createNotification_ShouldPersistNotification() {
        notificationService.createNotification(
                user,
                Notification.NotificationType.MESSAGE,
                "new message",
                99L);

        ArgumentCaptor<Notification> captor = ArgumentCaptor.forClass(Notification.class);
        verify(notificationRepository).save(captor.capture());

        Notification saved = captor.getValue();
        assertEquals(user, saved.getUser());
        assertEquals(Notification.NotificationType.MESSAGE, saved.getType());
        assertEquals("new message", saved.getMessage());
        assertEquals(99L, saved.getContextId());
        assertFalse(saved.isRead());
    }

    @Test
    void getUserNotifications_ShouldReturnRepositoryResult() {
        Notification n1 = new Notification(user, Notification.NotificationType.LIKE, "liked", 1L);
        Notification n2 = new Notification(user, Notification.NotificationType.COMMENT, "commented", 2L);
        when(notificationRepository.findByUserOrderByCreatedAtDesc(user)).thenReturn(List.of(n1, n2));

        List<Notification> result = notificationService.getUserNotifications(user);

        assertEquals(2, result.size());
        assertEquals("liked", result.get(0).getMessage());
    }

    @Test
    void markAsRead_ShouldUpdateAndSave_WhenNotificationExists() {
        Notification n = new Notification(user, Notification.NotificationType.MESSAGE, "msg", 7L);
        n.setId(7L);
        n.setRead(false);
        when(notificationRepository.findById(7L)).thenReturn(Optional.of(n));

        notificationService.markAsRead(7L);

        assertTrue(n.isRead());
        verify(notificationRepository).save(n);
    }

    @Test
    void markAsRead_ShouldDoNothing_WhenNotificationMissing() {
        when(notificationRepository.findById(77L)).thenReturn(Optional.empty());

        notificationService.markAsRead(77L);

        verify(notificationRepository, never()).save(any(Notification.class));
    }

    @Test
    void getUnreadCount_ShouldReturnRepositoryCount() {
        when(notificationRepository.countByUserAndIsReadFalse(user)).thenReturn(4L);

        long count = notificationService.getUnreadCount(user);

        assertEquals(4L, count);
    }
}
