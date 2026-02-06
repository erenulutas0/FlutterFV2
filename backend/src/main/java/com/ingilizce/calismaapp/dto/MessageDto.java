package com.ingilizce.calismaapp.dto;

import java.time.LocalDateTime;

public class MessageDto {
    private Long id;
    private String content;
    private LocalDateTime createdAt;
    private UserDto sender;
    private UserDto receiver;
    private boolean isRead;

    public MessageDto(Long id, String content, LocalDateTime createdAt, UserDto sender, UserDto receiver,
            boolean isRead) {
        this.id = id;
        this.content = content;
        this.createdAt = createdAt;
        this.sender = sender;
        this.receiver = receiver;
        this.isRead = isRead;
    }

    // Getters
    public Long getId() {
        return id;
    }

    public String getContent() {
        return content;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public UserDto getSender() {
        return sender;
    }

    public UserDto getReceiver() {
        return receiver;
    }

    public boolean isRead() {
        return isRead;
    }
}
