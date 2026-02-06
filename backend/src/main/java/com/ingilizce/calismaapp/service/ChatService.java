package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.Message;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.MessageRepository;
import com.ingilizce.calismaapp.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.ArrayList;

import org.springframework.transaction.annotation.Transactional;

import com.ingilizce.calismaapp.entity.Notification;

@Service
@Transactional
public class ChatService {

    private final MessageRepository messageRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    public ChatService(MessageRepository messageRepository, UserRepository userRepository,
            NotificationService notificationService) {
        this.messageRepository = messageRepository;
        this.userRepository = userRepository;
        this.notificationService = notificationService;
    }

    public Message sendMessage(User sender, Long receiverId, String content) {
        User receiver = userRepository.findById(receiverId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Message message = new Message(sender, receiver, content);
        Message savedMessage = messageRepository.save(message);

        // Alıcıya bildirim gönder (kendi kendine mesaj atmıyorsa)
        if (!sender.getId().equals(receiverId)) {
            notificationService.createNotification(
                    receiver,
                    Notification.NotificationType.MESSAGE,
                    sender.getDisplayName() + " size mesaj gönderdi: "
                            + (content.length() > 30 ? content.substring(0, 30) + "..." : content),
                    savedMessage.getId());
        }

        return savedMessage;
    }

    public List<Message> getConversation(User currentUser, Long otherUserId) {
        User otherUser = userRepository.findById(otherUserId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return messageRepository.findConversation(currentUser, otherUser);
    }

    public List<User> getChattedUsers(User currentUser) {
        // Hibernate 6.4 CASE bug'ı nedeniyle ayrı sorgularla birleştiriyoruz
        List<User> receivers = messageRepository.findReceivedMessagesPartners(currentUser);
        List<User> senders = messageRepository.findSentMessagesPartners(currentUser);

        Set<User> allUsers = new HashSet<>();
        allUsers.addAll(receivers);
        allUsers.addAll(senders);

        return new ArrayList<>(allUsers);
    }
}
