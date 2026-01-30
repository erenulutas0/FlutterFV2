package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.Word;
import com.ingilizce.calismaapp.entity.Sentence;
import com.ingilizce.calismaapp.dto.CreateWordRequest;
import com.ingilizce.calismaapp.repository.WordRepository;
import com.ingilizce.calismaapp.repository.SentenceRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class WordService {

    @Autowired
    private WordRepository wordRepository;

    @Autowired
    private SentenceRepository sentenceRepository;

    @Autowired
    private LeaderboardService leaderboardService;

    @Autowired
    private ProgressService progressService;

    @Autowired
    private FeedService feedService;

    // Legacy method for backward compatibility (defaults to user 1)
    public List<Word> getAllWords() {
        return getAllWords(1L);
    }

    public List<Word> getAllWords(Long userId) {
        return wordRepository.findByUserId(userId);
    }

    public List<Word> getWordsByDate(Long userId, LocalDate date) {
        return wordRepository.findByUserIdAndLearnedDate(userId, date);
    }

    public List<Word> getWordsByDateRange(Long userId, LocalDate startDate, LocalDate endDate) {
        return wordRepository.findByUserIdAndDateRange(userId, startDate, endDate);
    }

    public List<LocalDate> getAllDistinctDates(Long userId) {
        return wordRepository.findDistinctDatesByUserId(userId);
    }

    @Transactional
    public Word saveWord(Word word) {
        // Ensure userId is set (default to 1 if null for safety)
        if (word.getUserId() == null) {
            word.setUserId(1L);
        }

        boolean isNew = (word.getId() == null);
        Word savedWord = wordRepository.save(word);

        if (isNew) {
            // Gamification: Add 10 points
            try {
                // Note: incrementScore expects double, so passing 10.0
                leaderboardService.incrementScore(savedWord.getUserId(), 10.0);
            } catch (Exception e) {
                System.err.println("Leaderboard error: " + e.getMessage());
            }

            // Social: Log Activity
            try {
                // Using fully qualified name or import for ActivityType
                feedService.logActivity(savedWord.getUserId(),
                        com.ingilizce.calismaapp.entity.UserActivity.ActivityType.WORD_ADDED,
                        "Learned a new word: " + savedWord.getEnglishWord());
            } catch (Exception e) {
                System.err.println("Feed logging error: " + e.getMessage());
            }

            // Note: ProgressService might need updating to be user-aware too,
            // but for now we assume it handles the current context or we pass userId later.
            // Currently assuming ProgressService uses a default user or context.
            progressService.awardXp(5, "New Word: " + word.getEnglishWord());
            progressService.updateStreak();
        }

        return savedWord;
    }

    // Overload for convenience if needed, though usually verification happens at
    // controller
    public Word createWord(CreateWordRequest request, Long userId) {
        Word word = new Word();
        word.setUserId(userId);
        word.setEnglishWord(request.getEnglish());
        word.setTurkishMeaning(request.getTurkish());
        word.setLearnedDate(LocalDate.parse(request.getAddedDate()));
        word.setNotes(request.getNotes());
        if (request.getDifficulty() != null) {
            word.setDifficulty(request.getDifficulty());
        }
        return saveWord(word);
    }

    public Optional<Word> getWordById(Long id) {
        return wordRepository.findById(id);
    }

    // Secure get method ensuring user owns the word
    public Optional<Word> getWordByIdAndUser(Long id, Long userId) {
        Optional<Word> word = wordRepository.findById(id);
        if (word.isPresent() && word.get().getUserId().equals(userId)) {
            return word;
        }
        return Optional.empty();
    }

    public void deleteWord(Long id, Long userId) {
        Optional<Word> word = getWordByIdAndUser(id, userId);
        if (word.isPresent()) {
            wordRepository.deleteById(id);
        }
        // If not found or not owned, do nothing (or throw exception)
    }

    @Transactional
    public Word updateWord(Long id, Word wordDetails, Long userId) {
        Optional<Word> optionalWord = getWordByIdAndUser(id, userId);
        if (optionalWord.isPresent()) {
            Word word = optionalWord.get();
            word.setEnglishWord(wordDetails.getEnglishWord());
            word.setTurkishMeaning(wordDetails.getTurkishMeaning());
            word.setLearnedDate(wordDetails.getLearnedDate());
            word.setNotes(wordDetails.getNotes());
            return wordRepository.save(word);
        }
        return null;
    }

    // Sentence management methods
    @Transactional
    public Word addSentence(Long wordId, String sentence, String translation, String difficulty, Long userId) {
        Optional<Word> wordOpt = getWordByIdAndUser(wordId, userId);
        if (wordOpt.isPresent()) {
            Word word = wordOpt.get();
            Sentence newSentence = new Sentence(sentence, translation, difficulty != null ? difficulty : "easy", word);
            word.addSentence(newSentence);
            progressService.awardXp(3, "New Sentence for: " + word.getEnglishWord());
            return wordRepository.save(word);
        }
        return null;
    }

    @Transactional
    public Word deleteSentence(Long wordId, Long sentenceId, Long userId) {
        Optional<Word> wordOpt = getWordByIdAndUser(wordId, userId);
        Optional<Sentence> sentenceOpt = sentenceRepository.findById(sentenceId);

        if (wordOpt.isPresent() && sentenceOpt.isPresent()) {
            Word word = wordOpt.get();
            Sentence sentence = sentenceOpt.get();

            // Check if sentence belongs to the word AND user owns the word
            if (sentence.getWord().getId().equals(wordId) && word.getUserId().equals(userId)) {
                word.removeSentence(sentence);
                sentenceRepository.delete(sentence);
                return wordRepository.save(word);
            }
        }
        return null;
    }
}
