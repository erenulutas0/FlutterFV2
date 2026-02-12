package com.ingilizce.calismaapp.service;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;

class NoopActivityPublisherTest {

    @Test
    void publishWordAdded_ShouldNotThrow() {
        NoopActivityPublisher publisher = new NoopActivityPublisher();

        assertDoesNotThrow(() -> publisher.publishWordAdded(1L, "word"));
    }
}
