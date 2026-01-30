package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.Friendship;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.FriendshipRepository;
import com.ingilizce.calismaapp.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class FriendshipServiceTest {

    @InjectMocks
    private FriendshipService friendshipService;

    @Mock
    private FriendshipRepository friendshipRepository;

    @Mock
    private UserRepository userRepository;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void sendRequest_ShouldCreatePendingFriendship() {
        // Arrange
        Long requesterId = 1L;
        String addresseeEmail = "friend@example.com";

        User requester = new User();
        requester.setId(requesterId);
        requester.setEmail("me@example.com");

        User addressee = new User();
        addressee.setId(2L);
        addressee.setEmail(addresseeEmail);

        when(userRepository.findById(requesterId)).thenReturn(Optional.of(requester));
        when(userRepository.findByEmail(addresseeEmail)).thenReturn(Optional.of(addressee));
        when(friendshipRepository.findExistingFriendship(requester, addressee)).thenReturn(Optional.empty());

        // Act
        friendshipService.sendRequest(requesterId, addresseeEmail);

        // Assert
        verify(friendshipRepository, times(1)).save(any(Friendship.class));
    }

    @Test
    void sendRequest_ShouldFail_IfSelfRequest() {
        // Arrange
        Long requesterId = 1L;
        String addresseeEmail = "me@example.com";

        User requester = new User();
        requester.setId(requesterId);
        requester.setEmail("me@example.com");

        User addressee = new User(); // Same user mock
        addressee.setId(requesterId);
        addressee.setEmail("me@example.com");

        when(userRepository.findById(requesterId)).thenReturn(Optional.of(requester));
        when(userRepository.findByEmail(addresseeEmail)).thenReturn(Optional.of(addressee));

        // Act & Assert
        Exception exception = assertThrows(RuntimeException.class, () -> {
            friendshipService.sendRequest(requesterId, addresseeEmail);
        });

        assertEquals("Kendinize istek gönderemezsiniz.", exception.getMessage());
        verify(friendshipRepository, never()).save(any());
    }

    @Test
    void acceptRequest_ShouldUpdateStatus() {
        // Arrange
        Long requestId = 10L;
        Friendship pendingFriendship = new Friendship();
        pendingFriendship.setId(requestId);
        pendingFriendship.setStatus(Friendship.Status.PENDING);

        User addressee = new User();
        addressee.setId(50L); // Matches the ID passed in acceptRequest
        pendingFriendship.setAddressee(addressee);

        when(friendshipRepository.findById(requestId)).thenReturn(Optional.of(pendingFriendship));

        // Act
        friendshipService.acceptRequest(requestId, 50L);

        // Assert
        assertEquals(Friendship.Status.ACCEPTED, pendingFriendship.getStatus());
        verify(friendshipRepository, times(1)).save(pendingFriendship);
    }
}
