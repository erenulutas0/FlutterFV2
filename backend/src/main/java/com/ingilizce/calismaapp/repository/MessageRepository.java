package com.ingilizce.calismaapp.repository;

import com.ingilizce.calismaapp.entity.Message;
import com.ingilizce.calismaapp.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface MessageRepository extends JpaRepository<Message, Long> {

    @Query("SELECT m FROM Message m WHERE (m.sender = :user1 AND m.receiver = :user2) OR (m.sender = :user2 AND m.receiver = :user1) ORDER BY m.createdAt ASC")
    List<Message> findConversation(@Param("user1") User user1, @Param("user2") User user2);

    // Hibernate 6.4 CASE + Entity bug'ını önlemek için ayrı sorgular kullan
    @Query("SELECT DISTINCT m.receiver FROM Message m WHERE m.sender = :user")
    List<User> findReceivedMessagesPartners(@Param("user") User user);

    @Query("SELECT DISTINCT m.sender FROM Message m WHERE m.receiver = :user")
    List<User> findSentMessagesPartners(@Param("user") User user);
}
