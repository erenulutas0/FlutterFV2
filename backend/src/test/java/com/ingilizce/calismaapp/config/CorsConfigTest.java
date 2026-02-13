package com.ingilizce.calismaapp.config;

import org.junit.jupiter.api.Test;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

class CorsConfigTest {

    @Test
    void corsConfigurer_ShouldBuildConfigurer_WhenConfigurationIsValid() {
        CorsProperties properties = new CorsProperties();
        properties.setAllowedOrigins(List.of("https://app.example.com"));
        properties.setAllowedMethods(List.of("GET", "POST"));
        properties.setAllowedHeaders(List.of("Authorization"));
        properties.setAllowCredentials(true);

        CorsConfig config = new CorsConfig(properties);
        WebMvcConfigurer webMvcConfigurer = config.corsConfigurer();

        assertNotNull(webMvcConfigurer);
        webMvcConfigurer.addCorsMappings(new CorsRegistry());
    }

    @Test
    void corsConfigurer_ShouldRejectEmptyOrigins() {
        CorsProperties properties = new CorsProperties();
        properties.setAllowedOrigins(List.of());

        CorsConfig config = new CorsConfig(properties);

        assertThrows(IllegalStateException.class, config::corsConfigurer);
    }

    @Test
    void corsConfigurer_ShouldRejectWildcardWithCredentials() {
        CorsProperties properties = new CorsProperties();
        properties.setAllowedOrigins(List.of("*"));
        properties.setAllowCredentials(true);

        CorsConfig config = new CorsConfig(properties);

        assertThrows(IllegalStateException.class, config::corsConfigurer);
    }

    @Test
    void corsConfigurer_ShouldAllowWildcard_WhenCredentialsDisabled() {
        CorsProperties properties = new CorsProperties();
        properties.setAllowedOrigins(List.of("*"));
        properties.setAllowCredentials(false);

        CorsConfig config = new CorsConfig(properties);
        WebMvcConfigurer webMvcConfigurer = config.corsConfigurer();

        assertNotNull(webMvcConfigurer);
        webMvcConfigurer.addCorsMappings(new CorsRegistry());
    }

    @Test
    void corsConfigurer_ShouldRejectLoopbackOrigins_WhenStrictValidationEnabled() {
        CorsProperties properties = new CorsProperties();
        properties.setStrictOriginValidation(true);
        properties.setAllowedOrigins(List.of("http://localhost:8080"));

        CorsConfig config = new CorsConfig(properties);

        assertThrows(IllegalStateException.class, config::corsConfigurer);
    }

    @Test
    void corsConfigurer_ShouldRejectWildcard_WhenStrictValidationEnabled() {
        CorsProperties properties = new CorsProperties();
        properties.setStrictOriginValidation(true);
        properties.setAllowCredentials(false);
        properties.setAllowedOrigins(List.of("*"));

        CorsConfig config = new CorsConfig(properties);

        assertThrows(IllegalStateException.class, config::corsConfigurer);
    }

    @Test
    void corsConfigurer_ShouldAllowExplicitHttpsOrigins_WhenStrictValidationEnabled() {
        CorsProperties properties = new CorsProperties();
        properties.setStrictOriginValidation(true);
        properties.setAllowedOrigins(List.of("https://app.example.com", "https://admin.example.com"));

        CorsConfig config = new CorsConfig(properties);
        WebMvcConfigurer webMvcConfigurer = config.corsConfigurer();

        assertNotNull(webMvcConfigurer);
        webMvcConfigurer.addCorsMappings(new CorsRegistry());
    }
}
