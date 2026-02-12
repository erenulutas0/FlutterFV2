package com.ingilizce.calismaapp.config;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class CorsPropertiesTest {

    @Test
    void defaults_ShouldMatchSecureLocalSetup() {
        CorsProperties properties = new CorsProperties();

        assertTrue(properties.getAllowedOrigins().contains("http://localhost:8080"));
        assertTrue(properties.getAllowedOrigins().contains("http://127.0.0.1:8080"));
        assertEquals(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"), properties.getAllowedMethods());
        assertEquals(List.of("*"), properties.getAllowedHeaders());
        assertTrue(properties.isAllowCredentials());
    }

    @Test
    void setters_ShouldOverrideDefaults() {
        CorsProperties properties = new CorsProperties();
        properties.setAllowedOrigins(List.of("https://app.example.com"));
        properties.setAllowedMethods(List.of("GET"));
        properties.setAllowedHeaders(List.of("Authorization", "Content-Type"));
        properties.setAllowCredentials(false);

        assertEquals(List.of("https://app.example.com"), properties.getAllowedOrigins());
        assertEquals(List.of("GET"), properties.getAllowedMethods());
        assertEquals(List.of("Authorization", "Content-Type"), properties.getAllowedHeaders());
        assertEquals(false, properties.isAllowCredentials());
    }
}
