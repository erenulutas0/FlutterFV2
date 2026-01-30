package com.ingilizce.calismaapp.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_activities", indexes = {
        @Index(name = "idx_activity_user", columnList = "user_id"),
        @Index(name = "idx_activity_date", columnList = "created_at")
})
public class UserActivity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ActivityType type; // WORD_ADDED, EXAM_COMPLETED, LEVEL_UP

    @Column(nullable = false)
    private String description; // e.g. "Learned 'Serendipity'"

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    public enum ActivityType {
        WORD_ADDED,
        EXAM_COMPLETED,
        ACHIEVEMENT_UNLOCKED
    }

    public UserActivity() {
        this.createdAt = LocalDateTime.now();
    }

    public UserActivity(Long userId, ActivityType type, String description) {
        this.userId = userId;
        this.type = type;
        this.description = description;
        this.createdAt = LocalDateTime.now();
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public Long getUserId() {
        return userId;
    }

    public ActivityType getType() {
        return type;
    }

    public String getDescription() {
        return description;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}
