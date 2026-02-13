package com.ingilizce.calismaapp.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import com.ingilizce.calismaapp.repository.WordRepository;
import com.ingilizce.calismaapp.repository.WordReviewRepository;
import com.ingilizce.calismaapp.repository.SentenceRepository;
import com.ingilizce.calismaapp.repository.SentencePracticeRepository;
import com.ingilizce.calismaapp.security.CurrentUserContext;
import org.springframework.http.HttpStatus;

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    @Autowired
    private WordReviewRepository wordReviewRepository;

    @Autowired
    private SentencePracticeRepository sentencePracticeRepository;

    @Autowired
    private SentenceRepository sentenceRepository;

    @Autowired
    private WordRepository wordRepository;

    @Autowired
    private CurrentUserContext currentUserContext;

    @PostMapping("/reset-data")
    public String resetData() {
        if (currentUserContext.shouldEnforceAuthz() && !currentUserContext.hasRole("ADMIN")) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Admin role required");
        }
        try {
            wordReviewRepository.deleteAll();
            sentencePracticeRepository.deleteAll();
            sentenceRepository.deleteAll();
            wordRepository.deleteAll();
            return "Mock data (Words, Sentences, Reviews) reset successful.";
        } catch (Exception e) {
            return "Error resetting data: " + e.getMessage();
        }
    }
}
