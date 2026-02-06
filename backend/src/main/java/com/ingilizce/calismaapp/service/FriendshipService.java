package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.Friendship;
import com.ingilizce.calismaapp.entity.Notification;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.FriendshipRepository;
import com.ingilizce.calismaapp.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class FriendshipService {

    @Autowired
    private FriendshipRepository friendshipRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private NotificationService notificationService;

    // Send Friend Request (by email)
    public String sendRequest(Long requesterId, String addresseeEmail) {
        User requester = userRepository.findById(requesterId)
                .orElseThrow(() -> new RuntimeException("Requester not found"));
        User addressee = userRepository.findByEmail(addresseeEmail)
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı: " + addresseeEmail));

        if (requester.getId().equals(addressee.getId())) {
            throw new RuntimeException("Kendinize istek gönderemezsiniz.");
        }

        // Check existing
        if (friendshipRepository.findExistingFriendship(requester, addressee).isPresent()) {
            throw new RuntimeException("Zaten bir istek var veya arkadaşsınız.");
        }

        Friendship friendship = new Friendship(requester, addressee);
        friendshipRepository.save(friendship);

        // Send notification to addressee
        notificationService.createNotification(
                addressee,
                Notification.NotificationType.FRIEND_REQUEST,
                requester.getDisplayName() + " size arkadaşlık isteği gönderdi!",
                friendship.getId());

        return "Arkadaşlık isteği gönderildi!";
    }

    // Accept Request
    public void acceptRequest(Long requestId, Long userId) {
        Friendship friendship = friendshipRepository.findById(requestId)
                .orElseThrow(() -> new RuntimeException("İstek bulunamadı"));

        if (!friendship.getAddressee().getId().equals(userId)) {
            throw new RuntimeException("Bu isteği onaylama yetkiniz yok.");
        }

        friendship.setStatus(Friendship.Status.ACCEPTED);
        friendshipRepository.save(friendship);

        // Notify requester that request was accepted
        notificationService.createNotification(
                friendship.getRequester(),
                Notification.NotificationType.FRIEND_ACCEPTED,
                friendship.getAddressee().getDisplayName() + " arkadaşlık isteğinizi kabul etti!",
                friendship.getId());
    }

    // Remove Friend
    public void removeFriend(Long userId, Long friendId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı"));
        User friend = userRepository.findById(friendId)
                .orElseThrow(() -> new RuntimeException("Arkadaş bulunamadı"));

        Optional<Friendship> friendshipOpt = friendshipRepository.findExistingFriendship(user, friend);
        if (friendshipOpt.isEmpty()) {
            throw new RuntimeException("Arkadaşlık bulunamadı.");
        }

        friendshipRepository.delete(friendshipOpt.get());
    }

    // Check if two users are friends
    public boolean isFriend(Long userId, Long otherUserId) {
        User user = userRepository.findById(userId).orElse(null);
        User other = userRepository.findById(otherUserId).orElse(null);
        if (user == null || other == null)
            return false;

        Optional<Friendship> friendship = friendshipRepository.findExistingFriendship(user, other);
        return friendship.isPresent() && friendship.get().getStatus() == Friendship.Status.ACCEPTED;
    }

    // Check friendship status (NONE, PENDING, ACCEPTED)
    public String getFriendshipStatus(Long userId, Long otherUserId) {
        User user = userRepository.findById(userId).orElse(null);
        User other = userRepository.findById(otherUserId).orElse(null);
        if (user == null || other == null)
            return "NONE";

        Optional<Friendship> friendship = friendshipRepository.findExistingFriendship(user, other);
        if (friendship.isEmpty())
            return "NONE";
        return friendship.get().getStatus().name();
    }

    // List Friends
    public List<User> getFriends(Long userId) {
        User user = userRepository.findById(userId).orElseThrow();
        List<Friendship> friendships = friendshipRepository.findAllAcceptedFriends(user);

        return friendships.stream().map(f -> {
            return f.getRequester().getId().equals(userId) ? f.getAddressee() : f.getRequester();
        }).collect(Collectors.toList());
    }

    // List Pending Requests
    public List<Friendship> getPendingRequests(Long userId) {
        User user = userRepository.findById(userId).orElseThrow();
        return friendshipRepository.findByAddresseeAndStatus(user, Friendship.Status.PENDING);
    }
}
