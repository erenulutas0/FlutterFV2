package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.entity.Comment;
import com.ingilizce.calismaapp.entity.Post;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.PostLikeRepository;
import com.ingilizce.calismaapp.repository.UserRepository;
import com.ingilizce.calismaapp.service.SocialService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.ingilizce.calismaapp.dto.PostDto;
import com.ingilizce.calismaapp.dto.UserDto;
import java.util.stream.Collectors;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/social")
public class SocialController {

    private final SocialService socialService;
    private final UserRepository userRepository;
    private final PostLikeRepository postLikeRepository;

    public SocialController(SocialService socialService, UserRepository userRepository,
            PostLikeRepository postLikeRepository) {
        this.socialService = socialService;
        this.userRepository = userRepository;
        this.postLikeRepository = postLikeRepository;
    }

    private User getUserFromHeader(String userIdHeader) {
        if (userIdHeader == null)
            throw new RuntimeException("Unauthorized");
        return userRepository.findById(Long.parseLong(userIdHeader))
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    private UserDto mapToUserDto(User user) {
        return new UserDto(user.getId(), user.getDisplayName(), user.getUserTag());
    }

    private PostDto mapToPostDto(Post post, User currentUser) {
        boolean liked = postLikeRepository.existsByUserAndPost(currentUser, post);
        return new PostDto(
                post.getId(),
                post.getContent(),
                post.getMediaUrl(),
                post.getLikeCount(),
                post.getCommentCount(),
                post.getCreatedAt(),
                mapToUserDto(post.getUser()),
                liked);
    }

    @PostMapping("/posts")
    public ResponseEntity<?> createPost(
            @RequestHeader("X-User-Id") String userIdHeader,
            @RequestBody Map<String, String> payload) {

        try {
            User user = getUserFromHeader(userIdHeader);
            String content = payload.get("content");
            String mediaUrl = payload.get("mediaUrl"); // Optional

            Post post = socialService.createPost(user, content, mediaUrl);
            return ResponseEntity.ok(mapToPostDto(post, user));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().body("Error: " + e.getMessage());
        }
    }

    @GetMapping("/feed")
    public ResponseEntity<List<PostDto>> getGlobalFeed(@RequestHeader("X-User-Id") String userIdHeader) {
        User currentUser = getUserFromHeader(userIdHeader);
        List<Post> posts = socialService.getGlobalFeed();
        return ResponseEntity.ok(posts.stream().map(p -> mapToPostDto(p, currentUser)).collect(Collectors.toList()));
    }

    @GetMapping("/posts/user/{userId}")
    public ResponseEntity<List<PostDto>> getUserPosts(
            @RequestHeader("X-User-Id") String userIdHeader,
            @PathVariable Long userId) {
        User currentUser = getUserFromHeader(userIdHeader);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        List<Post> posts = socialService.getUserPosts(user);
        return ResponseEntity.ok(posts.stream().map(p -> mapToPostDto(p, currentUser)).collect(Collectors.toList()));
    }

    // Toggle like - beğenilmişse kaldır, beğenilmemişse ekle
    @PostMapping("/posts/{id}/like")
    public ResponseEntity<Map<String, Object>> toggleLike(
            @RequestHeader("X-User-Id") String userIdHeader,
            @PathVariable Long id) {

        User user = getUserFromHeader(userIdHeader);
        boolean nowLiked = socialService.toggleLike(user, id);
        Post post = socialService.getPost(id);

        return ResponseEntity.ok(Map.of(
                "liked", nowLiked,
                "likeCount", post.getLikeCount()));
    }

    @PostMapping("/posts/{id}/comment")
    public ResponseEntity<Comment> commentPost(
            @RequestHeader("X-User-Id") String userIdHeader,
            @PathVariable Long id,
            @RequestBody Map<String, String> payload) {

        User user = getUserFromHeader(userIdHeader);
        String content = payload.get("content");

        return ResponseEntity.ok(socialService.commentPost(user, id, content));
    }

    @GetMapping("/posts/{id}/comments")
    public ResponseEntity<List<Comment>> getComments(@PathVariable Long id) {
        return ResponseEntity.ok(socialService.getComments(id));
    }
}
