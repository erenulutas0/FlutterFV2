package com.ingilizce.calismaapp.repository;

import com.ingilizce.calismaapp.entity.Friendship;
import com.ingilizce.calismaapp.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FriendshipRepository extends JpaRepository<Friendship, Long> {

    // Check if friendship exists (in either direction)
    @Query("SELECT f FROM Friendship f WHERE (f.requester = :user1 AND f.addressee = :user2) OR (f.requester = :user2 AND f.addressee = :user1)")
    Optional<Friendship> findExistingFriendship(User user1, User user2);

    // List pending requests for a user (where they are the addressee)
    List<Friendship> findByAddresseeAndStatus(User addressee, Friendship.Status status);

    // List active friends (either direction, status ACCEPTED)
    @Query("SELECT f FROM Friendship f WHERE (f.requester = :user OR f.addressee = :user) AND f.status = 'ACCEPTED'")
    List<Friendship> findAllAcceptedFriends(User user);
}
