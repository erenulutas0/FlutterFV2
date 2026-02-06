package com.ingilizce.calismaapp.dto;

import java.time.LocalDateTime;

public class PostDto {
    private Long id;
    private String content;
    private String mediaUrl;
    private int likeCount;
    private int commentCount;
    private LocalDateTime createdAt;
    private UserDto user;
    private boolean liked; // Kullanıcı bu postu beğenmiş mi?

    public PostDto(Long id, String content, String mediaUrl, int likeCount, int commentCount, LocalDateTime createdAt,
            UserDto user, boolean liked) {
        this.id = id;
        this.content = content;
        this.mediaUrl = mediaUrl;
        this.likeCount = likeCount;
        this.commentCount = commentCount;
        this.createdAt = createdAt;
        this.user = user;
        this.liked = liked;
    }

    // Getters
    public Long getId() {
        return id;
    }

    public String getContent() {
        return content;
    }

    public String getMediaUrl() {
        return mediaUrl;
    }

    public int getLikeCount() {
        return likeCount;
    }

    public int getCommentCount() {
        return commentCount;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public UserDto getUser() {
        return user;
    }

    public boolean isLiked() {
        return liked;
    }
}
