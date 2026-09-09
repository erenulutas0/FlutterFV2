package com.ingilizce.calismaapp.repository;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.Query;

import java.lang.reflect.Method;
import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The order the Whisper vocabulary hint is read in.
 *
 * <p>Every held mic button now sends the learner's own saved words to Whisper so that it
 * expects them: "I am agree with you" came back from a device as "I am angry with you",
 * and "agree" had been in that learner's deck the whole time. The hint is capped at a few
 * dozen entries, so the ORDER decides which words get the budget -- due for review first,
 * because that is what the app is about to drill, then most recently added, because a word
 * saved this week is one the learner is still trying to use.
 *
 * <p>That ordering used to be a Java comparator in the controller, applied to every row of
 * the deck with each word's example sentences hydrated, on the latency path between
 * releasing the microphone and hearing an answer. It is a query now.
 *
 * <p>This suite has no database, so the clauses are asserted as text. That is a weaker
 * test than running the query and an honest one: it cannot prove the right rows come back,
 * but it does stop the ordering being dropped or reversed by someone editing the string,
 * which is how this would actually be lost -- silently, with every other test still green
 * and only the hint quietly getting worse.
 */
class WordRepositoryVocabularyHintTest {

    private static Method hintMethod() throws NoSuchMethodException {
        return WordRepository.class.getMethod(
                "findVocabularyHintWords", Long.class, Long.class, LocalDate.class, Pageable.class);
    }

    private static String hintQuery() throws NoSuchMethodException {
        Query query = hintMethod().getAnnotation(Query.class);
        assertNotNull(query, "the hint lookup stopped being a query; this test is out of date");
        return query.value();
    }

    @Test
    @DisplayName("it reads one column, not the whole deck")
    void projectsOnlyTheEnglishWord() throws Exception {
        assertTrue(hintQuery().startsWith("SELECT w.englishWord FROM Word w "),
                "the hint must project the word; loading entities brings the sentences with them");
    }

    @Test
    @DisplayName("due for review first, then newest, then alphabetical")
    void ordersByWhatTheLearnerIsLikeliestToSay() throws Exception {
        String query = hintQuery();

        int due = query.indexOf("w.nextReviewDate <= :today");
        int newest = query.indexOf("w.learnedDate DESC");
        int alphabetical = query.indexOf("w.englishWord ASC");

        assertTrue(due > 0, "due-for-review words no longer come first");
        assertTrue(newest > due, "recently added words must break the tie after the due ones");
        assertTrue(alphabetical > newest, "the alphabet is the last resort, not the first");
    }

    @Test
    @DisplayName("a word with no date does not jump the queue")
    void nullsSortLast() throws Exception {
        // Postgres puts NULLs first on a DESC ordering by default, so a row that never
        // recorded a learned date would outrank every word saved this week.
        assertTrue(hintQuery().contains("w.learnedDate DESC NULLS LAST"));
    }

    @Test
    @DisplayName("it stays inside one learner's own profile")
    void scopedToTheUserAndTheirActiveProfile() throws Exception {
        String query = hintQuery();

        // The deck is per language profile. Hinting Whisper with another profile's
        // vocabulary would push the learner toward words they are not studying.
        assertTrue(query.contains("w.userId = :userId"));
        assertTrue(query.contains("w.languageProfile.id = :profileId"));
    }

    @Test
    @DisplayName("blank words never reach the prompt")
    void emptyWordsAreExcludedInSql() throws Exception {
        // A blank entry costs a slot in a budget of a few dozen and teaches Whisper nothing.
        String query = hintQuery();

        assertTrue(query.contains("w.englishWord IS NOT NULL"));
        assertTrue(query.contains("w.englishWord <> ''"));
    }

    @Test
    @DisplayName("the method hands back words, not rows")
    void returnsStrings() throws Exception {
        Method method = hintMethod();

        assertEquals(List.class, method.getReturnType());
        assertTrue(method.getGenericReturnType().getTypeName().contains("java.lang.String"),
                "returning entities here would undo the projection the query exists for");
    }
}
