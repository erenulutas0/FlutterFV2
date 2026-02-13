package com.ingilizce.calismaapp.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.security.headers")
public class SecurityHeadersProperties {

    private boolean enabled = false;
    private String contentSecurityPolicy = "default-src 'self'; frame-ancestors 'none'; base-uri 'self'; object-src 'none'";
    private String referrerPolicy = "no-referrer";
    private String permissionsPolicy = "geolocation=(), microphone=(), camera=()";
    private boolean hstsEnabled = true;
    private long hstsMaxAgeSeconds = 31536000;
    private boolean hstsIncludeSubDomains = true;
    private boolean hstsPreload = false;

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public String getContentSecurityPolicy() {
        return contentSecurityPolicy;
    }

    public void setContentSecurityPolicy(String contentSecurityPolicy) {
        this.contentSecurityPolicy = contentSecurityPolicy;
    }

    public String getReferrerPolicy() {
        return referrerPolicy;
    }

    public void setReferrerPolicy(String referrerPolicy) {
        this.referrerPolicy = referrerPolicy;
    }

    public String getPermissionsPolicy() {
        return permissionsPolicy;
    }

    public void setPermissionsPolicy(String permissionsPolicy) {
        this.permissionsPolicy = permissionsPolicy;
    }

    public boolean isHstsEnabled() {
        return hstsEnabled;
    }

    public void setHstsEnabled(boolean hstsEnabled) {
        this.hstsEnabled = hstsEnabled;
    }

    public long getHstsMaxAgeSeconds() {
        return hstsMaxAgeSeconds;
    }

    public void setHstsMaxAgeSeconds(long hstsMaxAgeSeconds) {
        this.hstsMaxAgeSeconds = hstsMaxAgeSeconds;
    }

    public boolean isHstsIncludeSubDomains() {
        return hstsIncludeSubDomains;
    }

    public void setHstsIncludeSubDomains(boolean hstsIncludeSubDomains) {
        this.hstsIncludeSubDomains = hstsIncludeSubDomains;
    }

    public boolean isHstsPreload() {
        return hstsPreload;
    }

    public void setHstsPreload(boolean hstsPreload) {
        this.hstsPreload = hstsPreload;
    }
}
