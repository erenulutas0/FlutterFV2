package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.entity.Word;
import com.ingilizce.calismaapp.dto.CreateWordRequest;
import com.ingilizce.calismaapp.service.WordService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.Map;

@RestController
@RequestMapping("/api/words")
public class WordController {

    @Autowired
    private WordService wordService;

    private Long getUserId(String userIdHeader) {
        if (userIdHeader != null && !userIdHeader.isEmpty()) {
            try {
                return Long.parseLong(userIdHeader);
            } catch (NumberFormatException e) {
                return 1L;
            }
        }
        return 1L; // Default to admin/first user
    }

    @GetMapping
    public List<Word> getAllWords(@RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        return wordService.getAllWords(getUserId(userIdHeader));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Word> getWordById(@PathVariable Long id,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        Optional<Word> word = wordService.getWordByIdAndUser(id, getUserId(userIdHeader));
        return word.map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/{id}/sentences")
    public ResponseEntity<List<com.ingilizce.calismaapp.entity.Sentence>> getWordSentences(@PathVariable Long id,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        Optional<Word> word = wordService.getWordByIdAndUser(id, getUserId(userIdHeader));
        if (word.isPresent()) {
            return ResponseEntity.ok(word.get().getSentences());
        }
        return ResponseEntity.notFound().build();
    }

    @GetMapping("/date/{date}")
    public List<Word> getWordsByDate(@PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        return wordService.getWordsByDate(getUserId(userIdHeader), date);
    }

    @GetMapping("/dates")
    public List<LocalDate> getAllDistinctDates(
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        return wordService.getAllDistinctDates(getUserId(userIdHeader));
    }

    @GetMapping("/range")
    public List<Word> getWordsByDateRange(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        return wordService.getWordsByDateRange(getUserId(userIdHeader), startDate, endDate);
    }

    @PostMapping
    public Word createWord(@RequestBody Word word,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        word.setUserId(getUserId(userIdHeader));
        return wordService.saveWord(word);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Word> updateWord(@PathVariable Long id, @RequestBody Word wordDetails,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        Word updatedWord = wordService.updateWord(id, wordDetails, getUserId(userIdHeader));
        if (updatedWord != null) {
            return ResponseEntity.ok(updatedWord);
        }
        return ResponseEntity.notFound().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteWord(@PathVariable Long id,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        wordService.deleteWord(id, getUserId(userIdHeader));
        return ResponseEntity.ok().build();
    }

    // Sentence management endpoints
    @PostMapping("/{wordId}/sentences")
    public ResponseEntity<Word> addSentence(@PathVariable Long wordId, @RequestBody Map<String, String> request,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        String sentence = request.get("sentence");
        String translation = request.get("translation");
        String difficulty = request.get("difficulty");

        Word updatedWord = wordService.addSentence(wordId, sentence, translation, difficulty, getUserId(userIdHeader));
        if (updatedWord != null) {
            return ResponseEntity.ok(updatedWord);
        }
        return ResponseEntity.notFound().build();
    }

    @DeleteMapping("/{wordId}/sentences/{sentenceId}")
    public ResponseEntity<Word> deleteSentence(@PathVariable Long wordId, @PathVariable Long sentenceId,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        Word updatedWord = wordService.deleteSentence(wordId, sentenceId, getUserId(userIdHeader));
        if (updatedWord != null) {
            return ResponseEntity.ok(updatedWord);
        }
        return ResponseEntity.notFound().build();
    }
}
