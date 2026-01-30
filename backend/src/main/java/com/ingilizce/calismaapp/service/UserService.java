package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

@Service
@Transactional
public class UserService {

    @Autowired
    private UserRepository userRepository;

    public Optional<User> getUserById(Long id) {
        return userRepository.findById(id);
    }

    public Optional<User> getUserByEmail(String email) {
        return userRepository.findByEmail(email);
    }

    public User createUser(User user) {
        return userRepository.save(user);
    }

    public boolean extendSubscription(Long userId, int days) {
        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isPresent()) {
            User user = userOpt.get();
            LocalDateTime currentEnd = user.getSubscriptionEndDate();

            if (currentEnd == null || currentEnd.isBefore(LocalDateTime.now())) {
                user.setSubscriptionEndDate(LocalDateTime.now().plusDays(days));
            } else {
                user.setSubscriptionEndDate(currentEnd.plusDays(days));
            }

            userRepository.save(user);
            return true;
        }
        return false;
    }

    public boolean isSubscriptionActive(Long userId) {
        return userRepository.findById(userId)
                .map(User::isSubscriptionActive)
                .orElse(false);
    }
}
