package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.UserActivity;
import org.junit.jupiter.api.Test;

import static org.mockito.Mockito.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.mock;

class FeedActivityPublisherTest {

    @Test
    void publishWordAdded_ShouldDelegateToFeedService() {
        FeedService feedService = mock(FeedService.class);
        FeedActivityPublisher publisher = new FeedActivityPublisher(feedService);

        publisher.publishWordAdded(9L, "resilience");

        verify(feedService).logActivity(
                eq(9L),
                eq(UserActivity.ActivityType.WORD_ADDED),
                eq("Learned a new word: resilience")
        );
    }
}
