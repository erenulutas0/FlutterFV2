package com.ingilizce.calismaapp.repository;

import com.ingilizce.calismaapp.entity.Comment;
import com.ingilizce.calismaapp.entity.Post;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CommentRepository extends JpaRepository<Comment, Long> {
    List<Comment> findByPostOrderByCreatedAtAsc(Post post);

    int countByPost(Post post);
}
