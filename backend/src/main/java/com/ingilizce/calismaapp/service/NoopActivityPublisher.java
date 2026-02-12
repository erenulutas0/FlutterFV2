package com.ingilizce.calismaapp.service;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name = "app.features.community.enabled", havingValue = "false", matchIfMissing = true)
public class NoopActivityPublisher implements ActivityPublisher {

    @Override
    public void publishWordAdded(Long userId, String englishWord) {
        // Intentionally noop for core-only runtime.
    }
}
