package com.ingilizce.calismaapp.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.nullable;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * What the tapped-word lookup asks for.
 *
 * <p>The answer is stored as that word's meaning and shown in review with the word on the
 * front, so a definition that is really a translation of the sentence is a flashcard that
 * teaches nothing. That is what shipped: tapping "planning" in "Oh, what are you planning
 * to add there?" put "Eklemek istediğin şey ne?" in a learner's deck, and tapping "to" in
 * the same line returned a gloss with the sentence's meaning stapled on.
 *
 * <p>The old prompt said "explain the meaning of the word inside this specific sentence"
 * and allowed fifteen words, which is a sentence about a sentence with room to paraphrase
 * one. This pins the instructions that replaced it. Not the whole string -- a golden here
 * would fail on every wording change and teach a reviewer to update it without reading --
 * but the four things it must not stop saying, each of which the model needs told.
 */
@ExtendWith(MockitoExtension.class)
class DictionaryExplainPromptTest {

    @Mock
    private AiCompletionProvider aiCompletionProvider;

    private AiProxyService aiProxyService;

    @BeforeEach
    void setUp() {
        aiProxyService = new AiProxyService(aiCompletionProvider);
    }

    /** The user-role prompt sent for one lookup. */
    private String promptFor(String word, String sentence, LearningLanguageProfile profile) {
        when(aiCompletionProvider.chatCompletionWithUsage(anyList(), eq(true), any(), any(),
                nullable(String.class)))
                .thenReturn(AiCompletionProvider.CompletionResult.of(
                        "{\"definition\":\"tasarlamak\"}", 10, 5, 15));

        aiProxyService.dictionaryExplainWordInSentence(word, sentence, profile);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<Map<String, String>>> messages =
                ArgumentCaptor.forClass((Class<List<Map<String, String>>>) (Class<?>) List.class);
        verify(aiCompletionProvider).chatCompletionWithUsage(messages.capture(), eq(true), any(),
                any(), nullable(String.class));

        return messages.getValue().stream()
                .filter(message -> "user".equals(message.get("role")))
                .map(message -> message.get("content"))
                .findFirst()
                .orElseThrow(() -> new AssertionError("no user message was sent"));
    }

    @Test
    @DisplayName("it forbids the answer that shipped")
    void refusesToTranslateOrAnswerTheSentence() {
        String prompt = promptFor("planning", "Oh, what are you planning to add there?",
                LearningLanguageProfile.defaultProfile());

        // Naming the mistake is what stops it. The previous wording described the job
        // correctly and the model did the other thing anyway.
        assertTrue(prompt.contains("Do not translate the sentence"),
                "nothing stops the model translating the line the word was tapped in");
        assertTrue(prompt.contains("Do not paraphrase it"));
        assertTrue(prompt.contains("Do not answer a question it asks"),
                "a word tapped inside a question came back as the question's answer");
    }

    @Test
    @DisplayName("it asks for a gloss, not a sentence")
    void asksForTheShapeOfADictionaryEntry() {
        String prompt = promptFor("planning", "Oh, what are you planning to add there?",
                LearningLanguageProfile.defaultProfile());

        // Fifteen words is enough room to restate a sentence; eight is not, and saying
        // what the shape is beats saying only how long it may be.
        assertTrue(prompt.contains("At most 8 words"));
        assertTrue(prompt.contains("a dictionary gloss, not a sentence"));
    }

    @Test
    @DisplayName("grammatical words get told what they do")
    void coversWordsThatHaveNoTranslation() {
        // "to", "the", "of". A learner can tap any word in a line, and half of what is
        // there has no gloss in the usual sense; without this the model reaches for the
        // sentence to have something to say.
        String prompt = promptFor("to", "Oh, what are you planning to add there?",
                LearningLanguageProfile.defaultProfile());

        assertTrue(prompt.contains("grammatical rather than lexical"));
    }

    @Test
    @DisplayName("the sentence is context, the word is the question")
    void putsTheSentenceFirstAndTheWordSecond() {
        String prompt = promptFor("planning", "Oh, what are you planning to add there?",
                LearningLanguageProfile.defaultProfile());

        int sentence = prompt.indexOf("Sentence: \"Oh, what are you planning to add there?\"");
        int word = prompt.indexOf("Word: \"planning\"");

        assertTrue(sentence >= 0, "the sentence is no longer labelled as context");
        assertTrue(word > sentence,
                "the word must come after the sentence: whichever is stated last is what "
                        + "the model treats as the thing being asked about");
    }

    @Test
    @DisplayName("the definition is written in the learner's own language")
    void namesTheOutputLanguageOnBothInstructions() {
        LearningLanguageProfile german = new LearningLanguageProfile(
                "German", "English", "German", "B1", "Speaking");

        String prompt = promptFor("planning", "Oh, what are you planning to add there?", german);

        // Twice, once beside each instruction. The grammatical-word branch is a separate
        // sentence in the prompt and a model that has drifted by then will answer it in
        // the language it is reading rather than the one the learner set.
        assertTrue(prompt.split("German", -1).length - 1 >= 2,
                "the output language is named once; the second instruction can drift");
        assertFalse(prompt.contains("Turkish"),
                "a hardcoded language would define German learners' words in Turkish");
    }
}
