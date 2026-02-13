package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.entity.WordReview;
import com.ingilizce.calismaapp.service.WordReviewService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/reviews")
public class WordReviewController {

    private final WordReviewService wordReviewService;

    public WordReviewController(WordReviewService wordReviewService) {
        this.wordReviewService = wordReviewService;
    }

    @PostMapping("/words/{wordId}")
    public ResponseEntity<WordReview> addReview(
            @PathVariable Long wordId,
            @RequestHeader("X-User-Id") Long userId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate reviewDate,
            @RequestParam(required = false) String reviewType,
            @RequestParam(required = false) String notes) {
        try {
            WordReview review = wordReviewService.addReview(wordId, userId, reviewDate, reviewType, notes);
            return ResponseEntity.ok(review);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/words/{wordId}")
    public ResponseEntity<List<WordReview>> getWordReviews(@PathVariable Long wordId,
                                                           @RequestHeader("X-User-Id") Long userId) {
        List<WordReview> reviews = wordReviewService.getWordReviews(wordId, userId);
        return ResponseEntity.ok(reviews);
    }

    @GetMapping("/date/{date}")
    public ResponseEntity<List<WordReview>> getReviewsByDate(
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestHeader("X-User-Id") Long userId) {
        List<WordReview> reviews = wordReviewService.getReviewsByDate(date, userId);
        return ResponseEntity.ok(reviews);
    }

    @GetMapping("/words/{wordId}/check/{date}")
    public ResponseEntity<Boolean> isWordReviewedOnDate(
            @PathVariable Long wordId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestHeader("X-User-Id") Long userId) {
        boolean isReviewed = wordReviewService.isWordReviewedOnDate(wordId, date, userId);
        return ResponseEntity.ok(isReviewed);
    }

    @GetMapping("/words/{wordId}/count")
    public ResponseEntity<Long> getReviewCount(@PathVariable Long wordId,
                                               @RequestHeader("X-User-Id") Long userId) {
        long count = wordReviewService.getReviewCount(wordId, userId);
        return ResponseEntity.ok(count);
    }

    @GetMapping("/words/{wordId}/dates")
    public ResponseEntity<List<LocalDate>> getReviewDates(@PathVariable Long wordId,
                                                           @RequestHeader("X-User-Id") Long userId) {
        List<LocalDate> dates = wordReviewService.getReviewDates(wordId, userId);
        return ResponseEntity.ok(dates);
    }

    @GetMapping("/words/{wordId}/summary")
    public ResponseEntity<Map<LocalDate, WordReview>> getReviewSummary(@PathVariable Long wordId,
                                                                       @RequestHeader("X-User-Id") Long userId) {
        Map<LocalDate, WordReview> summary = wordReviewService.getReviewSummary(wordId, userId);
        return ResponseEntity.ok(summary);
    }

    @DeleteMapping("/{reviewId}")
    public ResponseEntity<Void> deleteReview(@PathVariable Long reviewId,
                                             @RequestHeader("X-User-Id") Long userId) {
        wordReviewService.deleteReview(reviewId, userId);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/words/{wordId}/date/{date}")
    public ResponseEntity<Void> deleteReviewByWordAndDate(
            @PathVariable Long wordId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestHeader("X-User-Id") Long userId) {
        wordReviewService.deleteReviewByWordAndDate(wordId, date, userId);
        return ResponseEntity.ok().build();
    }
}
