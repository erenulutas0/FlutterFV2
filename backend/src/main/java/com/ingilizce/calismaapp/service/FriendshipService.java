package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.Friendship;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.FriendshipRepository;
import com.ingilizce.calismaapp.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class FriendshipService {

    @Autowired
    private FriendshipRepository friendshipRepository;

    @Autowired
    private UserRepository userRepository;

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
