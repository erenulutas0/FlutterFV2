package com.ingilizce.calismaapp.repository;

import com.ingilizce.calismaapp.entity.Notification;
import com.ingilizce.calismaapp.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface NotificationRepository extends JpaRepository<Notification, Long> {
    List<Notification> findByUserOrderByCreatedAtDesc(User user);

    long countByUserAndIsReadFalse(User user);
}
