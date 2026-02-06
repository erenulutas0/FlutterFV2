package com.ingilizce.calismaapp.dto;

public class UserDto {
    private Long id;
    private String displayName;
    private String userTag;
    private boolean online;

    public UserDto(Long id, String displayName, String userTag) {
        this.id = id;
        this.displayName = displayName;
        this.userTag = userTag;
        this.online = false;
    }

    public UserDto(Long id, String displayName, String userTag, boolean online) {
        this.id = id;
        this.displayName = displayName;
        this.userTag = userTag;
        this.online = online;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getDisplayName() {
        return displayName;
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    public String getUserTag() {
        return userTag;
    }

    public void setUserTag(String userTag) {
        this.userTag = userTag;
    }

    public boolean isOnline() {
        return online;
    }

    public void setOnline(boolean online) {
        this.online = online;
    }
}
