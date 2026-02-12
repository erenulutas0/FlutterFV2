package com.ingilizce.calismaapp.config;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
@EnableConfigurationProperties(CorsProperties.class)
public class CorsConfig {

    private final CorsProperties corsProperties;

    public CorsConfig(CorsProperties corsProperties) {
        this.corsProperties = corsProperties;
    }

    @Bean
    public WebMvcConfigurer corsConfigurer() {
        validateCorsConfig();
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/**")
                        .allowedOrigins(corsProperties.getAllowedOrigins().toArray(String[]::new))
                        .allowedMethods(corsProperties.getAllowedMethods().toArray(String[]::new))
                        .allowedHeaders(corsProperties.getAllowedHeaders().toArray(String[]::new))
                        .allowCredentials(corsProperties.isAllowCredentials());
            }
        };
    }

    private void validateCorsConfig() {
        if (corsProperties.getAllowedOrigins() == null || corsProperties.getAllowedOrigins().isEmpty()) {
            throw new IllegalStateException("app.cors.allowed-origins must contain at least one origin");
        }

        if (corsProperties.isAllowCredentials() && corsProperties.getAllowedOrigins().contains("*")) {
            throw new IllegalStateException("app.cors.allowed-origins cannot contain '*' when allow-credentials=true");
        }
    }
}
