package com.ingilizce.calismaapp.security;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.security.auth")
public class AuthSecurityProperties {

    private long passwordResetTokenTtlSeconds = 900;
    private long emailVerificationTokenTtlSeconds = 86400;
    private boolean exposeDebugTokens = false;

    public long getPasswordResetTokenTtlSeconds() {
        return passwordResetTokenTtlSeconds;
    }

    public void setPasswordResetTokenTtlSeconds(long passwordResetTokenTtlSeconds) {
        this.passwordResetTokenTtlSeconds = passwordResetTokenTtlSeconds;
    }

    public long getEmailVerificationTokenTtlSeconds() {
        return emailVerificationTokenTtlSeconds;
    }

    public void setEmailVerificationTokenTtlSeconds(long emailVerificationTokenTtlSeconds) {
        this.emailVerificationTokenTtlSeconds = emailVerificationTokenTtlSeconds;
    }

    public boolean isExposeDebugTokens() {
        return exposeDebugTokens;
    }

    public void setExposeDebugTokens(boolean exposeDebugTokens) {
        this.exposeDebugTokens = exposeDebugTokens;
    }
}
