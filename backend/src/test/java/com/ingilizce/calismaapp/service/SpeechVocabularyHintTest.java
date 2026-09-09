package com.ingilizce.calismaapp.service;

import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The tutor correcting a sentence the learner never said.
 *
 * <p>The first real feedback this app ever received was "Really good, but audio to text
 * loses accuracy". Captured on a device behind that sentence: "I am agree with you" heard as
 * "I am angry with you", "I very like this app" as "I'm very naked", "I am married with a
 * teacher" as "married with the future". Each is worse than a plain transcription error,
 * because the correction card then explains a mistake the learner did not make, and somebody
 * learning the language has no way to tell those two apart.
 *
 * <p>Whisper's {@code prompt} is the fix that was sitting unused in this file's own comments:
 * it is not an instruction, it is vocabulary and spelling context. If "agree" is in the
 * learner's deck, the model is far less willing to hear "angry".
 *
 * <p>Which makes the shape of that hint the thing to pin. The prompt is prepended as prior
 * transcript text, so prose in it gets *continued* — that is the bug the {@code prompt}
 * field's comment records, where "English learning conversation. Transcribe the learner's
 * English speech exactly." came back as invented subtitle boilerplate with the prompt's own
 * words at the front of it. A list is safe. A sentence is the old bug again.
 */
class SpeechVocabularyHintTest {

    @Test
    void theWordsThatWereActuallyMisheardBecomeAList() {
        assertEquals("agree, married, teacher",
                GroqSpeechToTextService.vocabularyHint(List.of("agree", "married", "teacher")));
    }

    @Test
    void theHintIsNeverASentence() {
        String hint = GroqSpeechToTextService.vocabularyHint(List.of(
                "agree", "married", "teacher", "weekend", "borrow"));

        // No sentence punctuation of any kind. This is the whole point: anything the model
        // can read as an unfinished paragraph, it will finish.
        assertFalse(hint.matches(".*[.!?;:].*"), hint);
        // Commas only ever separate entries, never end one.
        assertFalse(hint.endsWith(","), hint);
        assertFalse(hint.contains(",,"), hint);
        for (String entry : hint.split(", ")) {
            assertTrue(entry.split(" ").length <= GroqSpeechToTextService.MAX_WORDS_PER_ENTRY, entry);
        }
    }

    @Test
    void aNoteSomebodyTypedIntoTheWrongBoxIsDropped() {
        // Decks contain what people put in them. A learner who pasted a whole sentence into
        // the word field must not be able to hand Whisper a paragraph to continue.
        String hint = GroqSpeechToTextService.vocabularyHint(List.of(
                "agree",
                "I am agree with you.",
                "this means to have the same opinion as somebody else",
                "look forward to",
                "married"));

        assertEquals("agree, look forward to, married", hint,
                "Short phrases are vocabulary; sentences and explanations are not");
    }

    @Test
    void theHintIsCappedToWhatWhisperWillActuallyRead() {
        // The prompt window is about 224 tokens and everything past it is silently dropped,
        // so this is a correctness property rather than a preference: a deck of two thousand
        // words must not push the useful entries off the end of the window.
        List<String> wholeDeck = new ArrayList<>();
        for (int i = 0; i < 500; i++) {
            wholeDeck.add("word" + i);
        }

        String hint = GroqSpeechToTextService.vocabularyHint(wholeDeck);

        assertEquals(GroqSpeechToTextService.MAX_VOCABULARY_HINT_WORDS, hint.split(", ").length);
        assertTrue(hint.length() <= GroqSpeechToTextService.MAX_VOCABULARY_HINT_CHARS, hint.length() + " chars");
        assertTrue(hint.startsWith("word0, word1, word2"),
                "The cap spends its budget on the front of a ranked list, not a random slice");
    }

    @Test
    void aPathologicallyLongDeckStillCannotOverrunTheWindow() {
        // The count cap is the intent; the character cap is the guarantee. A deck of long
        // compounds hits the second one first, and it has to hold.
        List<String> longEntries = new ArrayList<>();
        for (int i = 0; i < 200; i++) {
            longEntries.add("responsibility" + i);
        }

        String hint = GroqSpeechToTextService.vocabularyHint(longEntries);

        assertTrue(hint.length() <= GroqSpeechToTextService.MAX_VOCABULARY_HINT_CHARS, hint.length() + " chars");
        assertTrue(hint.split(", ").length < GroqSpeechToTextService.MAX_VOCABULARY_HINT_WORDS,
                "Long words should exhaust the character budget before the count one");
        assertFalse(hint.endsWith(","), hint);
    }

    @Test
    void aLearnerWithNothingSavedGetsNoHintAtAll() {
        // Blank, not a stray comma or an empty list rendered as punctuation. Blank is what
        // makes the request identical to the one that ships today.
        assertEquals("", GroqSpeechToTextService.vocabularyHint(null));
        assertEquals("", GroqSpeechToTextService.vocabularyHint(List.of()));
        assertEquals("", GroqSpeechToTextService.vocabularyHint(Arrays.asList("   ", null, "")));
        assertEquals("", GroqSpeechToTextService.vocabularyHint(List.of("this is clearly a whole sentence someone typed")));
    }

    @Test
    void theSameWordDoesNotSpendTheBudgetTwice() {
        assertEquals("Agree, married",
                GroqSpeechToTextService.vocabularyHint(List.of("Agree", "agree", "  AGREE ", "married")),
                "Duplicates differ only by casing and whitespace; the window is too small to pay for them twice");
    }

    @Test
    void whitespaceInsideAnEntryIsCollapsedRatherThanCarried() {
        // A tab or a newline inside an entry would put a line break in the middle of the
        // prompt, which is exactly what makes prior-transcript text look like a paragraph.
        assertEquals("look forward to",
                GroqSpeechToTextService.vocabularyHint(List.of("look\n forward\tto")));
    }

    @Test
    void theModelReadingTheHintBackIsNotSpeech() {
        // The risk this feature opens. The prompt is prior transcript text, so handed
        // silence and a list, the model can carry on writing the list — the same move that
        // turned the old prose prompt into subtitle boilerplate.
        assertTrue(GroqSpeechToTextService.isPromptEcho(
                "agree, married, teacher, weekend", "agree, married, teacher, weekend"));
        assertTrue(GroqSpeechToTextService.isPromptEcho(
                "Agree, married, teacher, weekend.", "agree, married, teacher, weekend"));
    }

    @Test
    void aLearnerSayingTheirOwnWordsIsLeftAlone() {
        // A false positive here deletes something the learner actually said, which is the
        // failure this whole file is organised around avoiding. So the guard demands an
        // exact match of a hint of at least four words: one deck word coming back as a
        // one-word transcript is a learner saying that word.
        assertFalse(GroqSpeechToTextService.isPromptEcho("agree", "agree"));
        assertFalse(GroqSpeechToTextService.isPromptEcho("agree, married", "agree, married"));
        assertFalse(GroqSpeechToTextService.isPromptEcho(
                "I agree with you", "agree, married, teacher, weekend"));
        assertFalse(GroqSpeechToTextService.isPromptEcho(
                "agree, married, teacher, weekend, borrow", "agree, married, teacher, weekend"));
        assertFalse(GroqSpeechToTextService.isPromptEcho("anything at all", ""));
        assertFalse(GroqSpeechToTextService.isPromptEcho(null, "agree, married, teacher, weekend"));
    }
}
