package com.ingilizce.calismaapp.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "friendships", uniqueConstraints = {
        @UniqueConstraint(columnNames = { "requester_id", "addressee_id" })
})
public class Friendship {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "requester_id", nullable = false)
    private User requester;

    @ManyToOne
    @JoinColumn(name = "addressee_id", nullable = false)
    private User addressee;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Status status;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    public enum Status {
        PENDING,
        ACCEPTED,
        REJECTED
    }

    public Friendship() {
        this.createdAt = LocalDateTime.now();
        this.status = Status.PENDING;
    }

    public Friendship(User requester, User addressee) {
        this.requester = requester;
        this.addressee = addressee;
        this.status = Status.PENDING;
        this.createdAt = LocalDateTime.now();
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public User getRequester() {
        return requester;
    }

    public void setRequester(User requester) {
        this.requester = requester;
    }

    public User getAddressee() {
        return addressee;
    }

    public void setAddressee(User addressee) {
        this.addressee = addressee;
    }

    public Status getStatus() {
        return status;
    }

    public void setStatus(Status status) {
        this.status = status;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
