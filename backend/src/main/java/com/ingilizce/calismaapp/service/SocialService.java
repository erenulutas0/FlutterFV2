package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.Comment;
import com.ingilizce.calismaapp.entity.Notification;
import com.ingilizce.calismaapp.entity.Post;
import com.ingilizce.calismaapp.entity.PostLike;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.CommentRepository;
import com.ingilizce.calismaapp.repository.PostLikeRepository;
import com.ingilizce.calismaapp.repository.PostRepository;
import org.springframework.stereotype.Service;

import java.util.List;

import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class SocialService {

    private final PostRepository postRepository;
    private final CommentRepository commentRepository;
    private final PostLikeRepository postLikeRepository;
    private final NotificationService notificationService;

    public SocialService(PostRepository postRepository,
            CommentRepository commentRepository,
            PostLikeRepository postLikeRepository,
            NotificationService notificationService) {
        this.postRepository = postRepository;
        this.commentRepository = commentRepository;
        this.postLikeRepository = postLikeRepository;
        this.notificationService = notificationService;
    }

    public Post createPost(User user, String content, String mediaUrl) {
        Post post = new Post(user, content);
        post.setMediaUrl(mediaUrl);
        return postRepository.save(post);
    }

    public List<Post> getGlobalFeed() {
        // In a real app, this would be paginated and filtered
        return postRepository.findAllByOrderByCreatedAtDesc();
    }

    public List<Post> getUserPosts(User user) {
        return postRepository.findByUserOrderByCreatedAtDesc(user);
    }

    // Reddit-tarzı beğeni milestone'ları: sadece bu sayılarda bildirim gönder
    private static final int[] LIKE_MILESTONES = { 5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000 };

    private boolean isMilestone(int likeCount) {
        for (int milestone : LIKE_MILESTONES) {
            if (likeCount == milestone) {
                return true;
            }
        }
        return false;
    }

    public Post getPost(Long postId) {
        return postRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));
    }

    // Toggle like: beğenilmişse kaldır, beğenilmemişse ekle
    // Returns: true=artık beğenildi, false=beğeni kaldırıldı
    public boolean toggleLike(User user, Long postId) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        var existingLike = postLikeRepository.findByUserAndPost(user, post);

        if (existingLike.isPresent()) {
            // Unlike: beğeniyi kaldır
            postLikeRepository.delete(existingLike.get());
            post.setLikeCount(Math.max(0, post.getLikeCount() - 1));
            postRepository.save(post);
            return false;
        } else {
            // Like: beğeni ekle
            PostLike like = new PostLike(user, post);
            postLikeRepository.save(like);

            int newLikeCount = post.getLikeCount() + 1;
            post.setLikeCount(newLikeCount);
            postRepository.save(post);

            // Milestone beğeni bildirimi (Reddit tarzı: 5, 10, 25, 50, 100...)
            if (!post.getUser().getId().equals(user.getId()) && isMilestone(newLikeCount)) {
                notificationService.createNotification(
                        post.getUser(),
                        Notification.NotificationType.LIKE,
                        "🎉 Gönderiniz " + newLikeCount + " beğeniye ulaştı!",
                        postId);
            }
            return true;
        }
    }

    // Unlike method could vary, for simplicity just toggle or specific endpoint?
    // Let's stick to like only for MVP as requested "Social Feed". Unlike logic can
    // be added later.

    public Comment commentPost(User user, Long postId, String content) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        Comment comment = new Comment(user, post, content);
        Comment savedComment = commentRepository.save(comment);

        post.setCommentCount(post.getCommentCount() + 1);
        postRepository.save(post);

        // Notify post owner if not self-comment
        if (!post.getUser().getId().equals(user.getId())) {
            notificationService.createNotification(
                    post.getUser(),
                    Notification.NotificationType.COMMENT,
                    user.getDisplayName() + " gönderine yorum yaptı: " + content,
                    postId);
        }

        return savedComment;
    }

    public List<Comment> getComments(Long postId) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        return commentRepository.findByPostOrderByCreatedAtAsc(post);
    }
}
