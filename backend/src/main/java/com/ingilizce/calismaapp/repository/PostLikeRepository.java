package com.ingilizce.calismaapp.repository;

import com.ingilizce.calismaapp.entity.Post;
import com.ingilizce.calismaapp.entity.PostLike;
import com.ingilizce.calismaapp.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PostLikeRepository extends JpaRepository<PostLike, Long> {
    Optional<PostLike> findByUserAndPost(User user, Post post);

    boolean existsByUserAndPost(User user, Post post);

    int countByPost(Post post);
}
