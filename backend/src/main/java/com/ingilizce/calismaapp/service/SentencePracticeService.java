package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.SentencePractice;
import com.ingilizce.calismaapp.repository.SentencePracticeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Service
public class SentencePracticeService {

    @Autowired
    private SentencePracticeRepository sentencePracticeRepository;

    // Get all sentences for user
    public List<SentencePractice> getAllSentences(Long userId) {
        return sentencePracticeRepository.findByUserIdOrderByCreatedDateDesc(userId);
    }

    // Get sentence by ID and User
    public Optional<SentencePractice> getSentenceByIdAndUser(Long id, Long userId) {
        Optional<SentencePractice> sentence = sentencePracticeRepository.findById(id);
        if (sentence.isPresent() && sentence.get().getUserId().equals(userId)) {
            return sentence;
        }
        return Optional.empty();
    }

    // Save a new sentence
    public SentencePractice saveSentence(SentencePractice sentencePractice) {
        // Ensure userId is set
        if (sentencePractice.getUserId() == null) {
            sentencePractice.setUserId(1L);
        }
        return sentencePracticeRepository.save(sentencePractice);
    }

    // Update an existing sentence
    public SentencePractice updateSentence(Long id, SentencePractice updatedSentence, Long userId) {
        Optional<SentencePractice> existingSentence = getSentenceByIdAndUser(id, userId);
        if (existingSentence.isPresent()) {
            SentencePractice sentence = existingSentence.get();
            sentence.setEnglishSentence(updatedSentence.getEnglishSentence());
            sentence.setTurkishTranslation(updatedSentence.getTurkishTranslation());
            sentence.setDifficulty(updatedSentence.getDifficulty());
            return sentencePracticeRepository.save(sentence);
        }
        return null;
    }

    // Delete a sentence
    public boolean deleteSentence(Long id, Long userId) {
        Optional<SentencePractice> sentence = getSentenceByIdAndUser(id, userId);
        if (sentence.isPresent()) {
            sentencePracticeRepository.deleteById(id);
            return true;
        }
        return false;
    }

    // Get sentences by difficulty
    public List<SentencePractice> getSentencesByDifficulty(Long userId, SentencePractice.DifficultyLevel difficulty) {
        return sentencePracticeRepository.findByUserIdAndDifficultyOrderByCreatedDateDesc(userId, difficulty);
    }

    // Get sentences by date
    public List<SentencePractice> getSentencesByDate(Long userId, LocalDate date) {
        return sentencePracticeRepository.findByUserIdAndCreatedDateOrderByCreatedDateDesc(userId, date);
    }

    // Get all distinct dates
    public List<LocalDate> getAllDistinctDates(Long userId) {
        return sentencePracticeRepository.findDistinctCreatedDatesByUserId(userId);
    }

    // Get sentences by date range
    public List<SentencePractice> getSentencesByDateRange(Long userId, LocalDate startDate, LocalDate endDate) {
        return sentencePracticeRepository.findByUserIdAndDateRange(userId, startDate, endDate);
    }

    // Get statistics
    public long getTotalSentenceCount(Long userId) {
        // Currently generic count, should implement countByUserId if needed
        // For now, estimating or adding countByUserId to repo
        return getAllSentences(userId).size();
    }

    public long getSentenceCountByDifficulty(Long userId, SentencePractice.DifficultyLevel difficulty) {
        return sentencePracticeRepository.countByUserIdAndDifficulty(userId, difficulty);
    }
}
