package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.entity.UserActivity;
import com.ingilizce.calismaapp.repository.UserActivityRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class FeedService {

    @Autowired
    private UserActivityRepository activityRepository;

    @Autowired
    private FriendshipService friendshipService;

    // Log an activity
    public void logActivity(Long userId, UserActivity.ActivityType type, String description) {
        UserActivity activity = new UserActivity(userId, type, description);
        activityRepository.save(activity);
    }

    // Get Social Feed (Activities of my friends)
    public List<UserActivity> getFeed(Long userId, int limit) {
        // 1. Get List of Friend IDs
        List<User> friends = friendshipService.getFriends(userId);
        List<Long> friendIds = friends.stream().map(User::getId).collect(Collectors.toList());

        // Include self? Optional. Let's include self for now.
        friendIds.add(userId);

        if (friendIds.isEmpty())
            return List.of();

        // 2. Fetch Activities
        return activityRepository.findActivitiesByUserIds(friendIds, PageRequest.of(0, limit));
    }
}
