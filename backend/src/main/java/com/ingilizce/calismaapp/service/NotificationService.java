package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.Notification;
import com.ingilizce.calismaapp.entity.User;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class NotificationService {

    private final com.ingilizce.calismaapp.repository.NotificationRepository notificationRepository;

    public NotificationService(com.ingilizce.calismaapp.repository.NotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
    }

    public void createNotification(User recipient, Notification.NotificationType type, String message, Long contextId) {
        // Kendi kendine bildirim atma
        // (Bunu controller/service seviyesinde kontrol etmek daha iyi ama burada da
        // engelleyebiliriz eğer recipient == sender ise context'ten)
        // Şimdilik basit tutalım.

        Notification notification = new Notification(recipient, type, message, contextId);
        notificationRepository.save(notification);
    }

    public List<Notification> getUserNotifications(User user) {
        return notificationRepository.findByUserOrderByCreatedAtDesc(user);
    }

    public void markAsRead(Long notificationId, Long userId) {
        notificationRepository.findByIdAndUserId(notificationId, userId).ifPresent(notification -> {
            notification.setRead(true);
            notificationRepository.save(notification);
        });
    }

    public long getUnreadCount(User user) {
        return notificationRepository.countByUserAndIsReadFalse(user);
    }
}
