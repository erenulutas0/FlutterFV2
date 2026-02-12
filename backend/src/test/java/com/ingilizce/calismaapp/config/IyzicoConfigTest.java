package com.ingilizce.calismaapp.config;

import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.assertEquals;

class IyzicoConfigTest {

    @Test
    void getters_ShouldReturnConfiguredValues() {
        IyzicoConfig config = new IyzicoConfig();
        ReflectionTestUtils.setField(config, "apiKey", "k");
        ReflectionTestUtils.setField(config, "secretKey", "s");
        ReflectionTestUtils.setField(config, "baseUrl", "https://u");

        assertEquals("k", config.getApiKey());
        assertEquals("s", config.getSecretKey());
        assertEquals("https://u", config.getBaseUrl());
    }
}
