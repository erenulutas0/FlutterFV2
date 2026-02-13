package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.Word;
import com.ingilizce.calismaapp.entity.WordReview;
import com.ingilizce.calismaapp.repository.WordRepository;
import com.ingilizce.calismaapp.repository.WordReviewRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class WordReviewService {
    
    @Autowired
    private WordReviewRepository wordReviewRepository;
    
    @Autowired
    private WordRepository wordRepository;
    
    // Add a review for a word on a specific date
    public WordReview addReview(Long wordId, Long userId, LocalDate reviewDate, String reviewType, String notes) {
        Word word = wordRepository.findByIdAndUserId(wordId, userId)
                .orElseThrow(() -> new RuntimeException("Word not found"));
        
        // Check if already reviewed on this date
        if (wordReviewRepository.existsByWordIdAndReviewDateAndWordUserId(wordId, reviewDate, userId)) {
            throw new RuntimeException("Word already reviewed on this date");
        }
        
        WordReview review = new WordReview(word, reviewDate);
        review.setReviewType(reviewType);
        review.setNotes(notes);
        
        return wordReviewRepository.save(review);
    }
    
    // Get all reviews for a word
    public List<WordReview> getWordReviews(Long wordId, Long userId) {
        return wordReviewRepository.findByWordIdAndWordUserIdOrderByReviewDateDesc(wordId, userId);
    }
    
    // Get reviews for a specific date
    public List<WordReview> getReviewsByDate(LocalDate date, Long userId) {
        return wordReviewRepository.findByReviewDateAndWordUserId(date, userId);
    }
    
    // Check if a word was reviewed on a specific date
    public boolean isWordReviewedOnDate(Long wordId, LocalDate date, Long userId) {
        return wordReviewRepository.existsByWordIdAndReviewDateAndWordUserId(wordId, date, userId);
    }
    
    // Get review count for a word
    public long getReviewCount(Long wordId, Long userId) {
        return wordReviewRepository.countByWordIdAndWordUserId(wordId, userId);
    }
    
    // Get review dates for a word (for calendar display)
    public List<LocalDate> getReviewDates(Long wordId, Long userId) {
        return wordReviewRepository.findByWordIdAndWordUserIdOrderByReviewDateDesc(wordId, userId)
                .stream()
                .map(WordReview::getReviewDate)
                .collect(Collectors.toList());
    }
    
    // Get review summary for a word (date -> review info)
    public Map<LocalDate, WordReview> getReviewSummary(Long wordId, Long userId) {
        return wordReviewRepository.findByWordIdAndWordUserIdOrderByReviewDateDesc(wordId, userId)
                .stream()
                .collect(Collectors.toMap(
                    WordReview::getReviewDate,
                    review -> review
                ));
    }
    
    // Delete a review
    public void deleteReview(Long reviewId, Long userId) {
        wordReviewRepository.findByIdAndWordUserId(reviewId, userId)
                .ifPresent(wordReviewRepository::delete);
    }
    
    // Delete review for a word on a specific date
    public void deleteReviewByWordAndDate(Long wordId, LocalDate date, Long userId) {
        List<WordReview> reviews = wordReviewRepository.findByWordIdAndReviewDateAndWordUserId(wordId, date, userId);
        wordReviewRepository.deleteAll(reviews);
    }
}
