package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.UserActivity;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name = "app.features.community.enabled", havingValue = "true", matchIfMissing = false)
public class FeedActivityPublisher implements ActivityPublisher {

    private final FeedService feedService;

    public FeedActivityPublisher(FeedService feedService) {
        this.feedService = feedService;
    }

    @Override
    public void publishWordAdded(Long userId, String englishWord) {
        feedService.logActivity(
                userId,
                UserActivity.ActivityType.WORD_ADDED,
                "Learned a new word: " + englishWord
        );
    }
}
