package com.ingilizce.calismaapp.repository;

import com.ingilizce.calismaapp.entity.Post;
import com.ingilizce.calismaapp.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PostRepository extends JpaRepository<Post, Long> {
    List<Post> findAllByOrderByCreatedAtDesc();

    List<Post> findByUserOrderByCreatedAtDesc(User user);
}
