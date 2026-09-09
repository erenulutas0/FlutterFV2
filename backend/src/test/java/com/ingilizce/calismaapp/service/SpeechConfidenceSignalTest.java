package com.ingilizce.calismaapp.service;

import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The learner is misheard and never finds out until the tutor answers the wrong sentence.
 *
 * <p>Whisper hands back an {@code avg_logprob} per segment — how sure it was of the words it
 * produced. This service has been reading it for a release: the silence check uses it, and
 * {@code describeConfidence} writes it to the log every single time. None of it ever reached
 * the device. So "I am agree with you" arrives as "I am angry with you", goes straight to the
 * tutor, and comes back as a correction of a sentence the learner never said, with nothing
 * anywhere in the app suggesting the transcript was worth a second look.
 *
 * <p>The threshold is decided here and not on the device. A client should not have to know
 * what a log probability is to know whether to ask the learner "did you say this?".
 */
class SpeechConfidenceSignalTest {

    @Test
    void theThresholdSitsBetweenConfidentAndUnintelligible() {
        // Whisper's avg_logprob reads as roughly confident above -0.5 and shaky below -0.8.
        assertFalse(GroqSpeechToTextService.isLowConfidence(-0.30));
        assertFalse(GroqSpeechToTextService.isLowConfidence(-0.79));
        assertTrue(GroqSpeechToTextService.isLowConfidence(-0.81));
        assertTrue(GroqSpeechToTextService.isLowConfidence(-1.40));
    }

    @Test
    void theTwoThresholdsInThisFileAreOneScale() {
        // -0.8 flags, -1.0 (with a high no_speech_prob) discards. They have to stay in that
        // order or the service would be able to hand back a transcript it had already
        // decided was not speech, or warn about text it never returns.
        assertTrue(GroqSpeechToTextService.LOW_CONFIDENCE_AVG_LOGPROB_THRESHOLD
                        > GroqSpeechToTextService.AVG_LOGPROB_THRESHOLD,
                "Flagging must be a weaker condition than discarding");

        // A transcript poor enough to discard is, by construction, also poor enough to flag.
        assertTrue(GroqSpeechToTextService.isLowConfidence(
                GroqSpeechToTextService.AVG_LOGPROB_THRESHOLD - 0.01));
    }

    @Test
    void aStrongAccentIsNotAWarning() {
        // -0.8 rather than -0.5 for the reason the silence check already gives in this file:
        // a poor log-probability on its own fires on unusual accents, which is most of this
        // app's audience. A warning that shows on every genuine attempt is one learners stop
        // reading, and then it protects nobody.
        assertFalse(GroqSpeechToTextService.isLowConfidence(-0.55));
        assertFalse(GroqSpeechToTextService.isLowConfidence(-0.70));
    }

    @Test
    void theWorstSegmentDecidesRatherThanTheAverage() {
        // The tutor corrects the whole utterance, so one badly-heard clause is enough to make
        // the correction wrong — "I am agree with you" heard as "I am angry with you" is
        // three words inside a longer sentence. Averaging lets a long confident stretch bury
        // a short garbled one, which is precisely the case that was reported.
        assertEquals(-1.20, GroqSpeechToTextService.worstAvgLogprob(List.of(
                Map.of("no_speech_prob", 0.01, "avg_logprob", -0.20),
                Map.of("no_speech_prob", 0.02, "avg_logprob", -1.20),
                Map.of("no_speech_prob", 0.01, "avg_logprob", -0.15))));

        assertTrue(GroqSpeechToTextService.isLowConfidence(
                GroqSpeechToTextService.worstAvgLogprob(List.of(
                        Map.of("avg_logprob", -0.20),
                        Map.of("avg_logprob", -1.20)))),
                "Their mean is -0.7, which would have said nothing at all");
    }

    @Test
    void missingConfidenceDataIsNeverAWarning() {
        // Absent data is not evidence of trouble — the same rule the silence check applies in
        // the other direction. A provider that stops sending segments must make the app go
        // quiet, not make it doubt every transcript the learner produces.
        assertNull(GroqSpeechToTextService.worstAvgLogprob(null));
        assertNull(GroqSpeechToTextService.worstAvgLogprob(List.of()));
        assertNull(GroqSpeechToTextService.worstAvgLogprob(List.of(Map.of("text", "hello"))));
        assertNull(GroqSpeechToTextService.worstAvgLogprob("not-a-list"));

        assertFalse(GroqSpeechToTextService.isLowConfidence(null));
    }

    @Test
    void oneSegmentWithoutTheFieldDoesNotHideTheOneThatHasIt() {
        assertEquals(-0.95, GroqSpeechToTextService.worstAvgLogprob(List.of(
                Map.of("text", "no numbers here"),
                Map.of("avg_logprob", -0.95))));
    }

    @Test
    void theSilenceCheckStillDecidesOnItsOwnTerms() {
        // The new threshold reads the same field the silence check reads, so this pins that
        // it did not quietly become a second discard rule. A segment at -0.9 is flagged for
        // the learner to look at, and kept: no_speech_prob says there was speech, and both
        // numbers still have to trip together before anything is deleted.
        List<Map<String, Object>> shakyButRealSpeech = List.of(
                Map.of("no_speech_prob", 0.05, "avg_logprob", -0.90));

        assertTrue(GroqSpeechToTextService.isLowConfidence(
                GroqSpeechToTextService.worstAvgLogprob(shakyButRealSpeech)));
        assertFalse(GroqSpeechToTextService.segmentsLookLikeSilence(shakyButRealSpeech),
                "Flagging a transcript must never be a reason to delete it");
    }
}
