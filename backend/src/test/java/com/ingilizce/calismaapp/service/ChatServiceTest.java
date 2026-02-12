package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.Message;
import com.ingilizce.calismaapp.entity.Notification;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.MessageRepository;
import com.ingilizce.calismaapp.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ChatServiceTest {

    @Mock
    private MessageRepository messageRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private NotificationService notificationService;

    @InjectMocks
    private ChatService chatService;

    private User sender;
    private User receiver;

    @BeforeEach
    void setUp() {
        sender = new User("sender@test.com", "hash", "Sender");
        sender.setId(1L);

        receiver = new User("receiver@test.com", "hash", "Receiver");
        receiver.setId(2L);
    }

    @Test
    void sendMessage_ShouldSaveAndNotify_WhenReceiverIsDifferentUser() {
        when(userRepository.findById(2L)).thenReturn(Optional.of(receiver));
        when(messageRepository.save(any(Message.class))).thenAnswer(invocation -> {
            Message m = invocation.getArgument(0);
            m.setId(99L);
            return m;
        });

        Message result = chatService.sendMessage(sender, 2L, "hello");

        assertEquals(99L, result.getId());
        assertEquals("hello", result.getContent());
        verify(notificationService).createNotification(
                eq(receiver),
                eq(Notification.NotificationType.MESSAGE),
                contains("Sender size mesaj gönderdi: hello"),
                eq(99L));
    }

    @Test
    void sendMessage_ShouldTruncateNotificationText_WhenContentLongerThan30() {
        String longText = "123456789012345678901234567890XYZ";
        when(userRepository.findById(2L)).thenReturn(Optional.of(receiver));
        when(messageRepository.save(any(Message.class))).thenAnswer(invocation -> {
            Message m = invocation.getArgument(0);
            m.setId(33L);
            return m;
        });

        chatService.sendMessage(sender, 2L, longText);

        verify(notificationService).createNotification(
                eq(receiver),
                eq(Notification.NotificationType.MESSAGE),
                contains("123456789012345678901234567890..."),
                eq(33L));
    }

    @Test
    void sendMessage_ShouldNotNotify_WhenSenderSendsToSelf() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(sender));
        when(messageRepository.save(any(Message.class))).thenAnswer(invocation -> invocation.getArgument(0));

        chatService.sendMessage(sender, 1L, "self");

        verify(notificationService, never()).createNotification(any(), any(), any(), any());
    }

    @Test
    void sendMessage_ShouldThrow_WhenReceiverNotFound() {
        when(userRepository.findById(2L)).thenReturn(Optional.empty());

        RuntimeException ex = assertThrows(RuntimeException.class, () -> chatService.sendMessage(sender, 2L, "hello"));
        assertEquals("User not found", ex.getMessage());
    }

    @Test
    void getConversation_ShouldReturnMessages_WhenOtherUserExists() {
        Message m = new Message(sender, receiver, "hi");
        when(userRepository.findById(2L)).thenReturn(Optional.of(receiver));
        when(messageRepository.findConversation(sender, receiver)).thenReturn(List.of(m));

        List<Message> result = chatService.getConversation(sender, 2L);

        assertEquals(1, result.size());
        assertEquals("hi", result.get(0).getContent());
    }

    @Test
    void getConversation_ShouldThrow_WhenOtherUserMissing() {
        when(userRepository.findById(2L)).thenReturn(Optional.empty());

        RuntimeException ex = assertThrows(RuntimeException.class, () -> chatService.getConversation(sender, 2L));
        assertEquals("User not found", ex.getMessage());
    }

    @Test
    void getChattedUsers_ShouldMergeDistinctUsersFromBothDirections() {
        User shared = receiver;
        User onlySenderSide = new User("a@test.com", "hash", "A");
        onlySenderSide.setId(3L);
        User onlyReceiverSide = new User("b@test.com", "hash", "B");
        onlyReceiverSide.setId(4L);

        when(messageRepository.findReceivedMessagesPartners(sender)).thenReturn(List.of(shared, onlySenderSide));
        when(messageRepository.findSentMessagesPartners(sender)).thenReturn(List.of(shared, onlyReceiverSide));

        List<User> result = chatService.getChattedUsers(sender);

        assertEquals(3, result.size());
        assertTrue(result.contains(shared));
        assertTrue(result.contains(onlySenderSide));
        assertTrue(result.contains(onlyReceiverSide));
    }
}
