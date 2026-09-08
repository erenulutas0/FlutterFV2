package com.ingilizce.calismaapp.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/**
 * Pulling the correction out of a spoken turn's reply.
 *
 * <p>Everything here is about one asymmetry. The correction is asked for as a marked
 * final line rather than by making the whole turn JSON, because the two fail differently:
 * bad JSON costs the REPLY and leaves a conversation answering with a canned fallback,
 * while a bad marker costs only the correction. So every malformed case below has the
 * same required outcome — no correction, and a reply the learner would not know was ever
 * supposed to carry one.
 *
 * <p>The other half is that the marker must never reach the screen. A model that says
 * "[[FIX]]" out loud in the middle of a sentence has not produced a correction, but it
 * has produced something a learner will read.
 */
class ChatbotCorrectionTest {

    @Nested
    @DisplayName("a correction is found")
    class Found {

        @Test
        @DisplayName("on a final marked line")
        void trailingLine() {
            String content = "That sounds lovely! Where did you go?\n"
                    + "[[FIX]] I go to Paris yesterday -> I went to Paris yesterday";

            ChatbotService.Correction correction = ChatbotService.extractCorrection(content);

            assertNotNull(correction);
            assertEquals("I go to Paris yesterday", correction.said());
            assertEquals("I went to Paris yesterday", correction.better());
        }

        @Test
        @DisplayName("and the reply keeps none of it")
        void replyIsClean() {
            String content = "That sounds lovely! Where did you go?\n"
                    + "[[FIX]] I go -> I went";

            assertEquals("That sounds lovely! Where did you go?",
                    ChatbotService.stripCorrection(content));
        }

        @Test
        @DisplayName("even when the model repeats itself, taking the last word")
        void lastMarkerWins() {
            // A model that corrects twice has replaced its own first answer. Taking the
            // first would show the learner something the model went on to think better of.
            String content = "Nice.\n[[FIX]] a -> b\n[[FIX]] I has -> I have";

            ChatbotService.Correction correction = ChatbotService.extractCorrection(content);

            assertNotNull(correction);
            assertEquals("I have", correction.better());
            assertEquals("Nice.", ChatbotService.stripCorrection(content));
        }

        @Test
        @DisplayName("mid-line, where models often put it")
        void markerNotAtLineStart() {
            // Models put the marker after a bullet, after a space, or on the end of the
            // sentence they just finished. Refusing to read it there left the raw
            // "I go -> I went" sitting in the reply, on screen and read aloud.
            String content = "Nice work. [[FIX]] I go -> I went";

            ChatbotService.Correction correction = ChatbotService.extractCorrection(content);

            assertNotNull(correction);
            assertEquals("I go", correction.said());
            assertEquals("I went", correction.better());
            assertEquals("Nice work.", ChatbotService.stripCorrection(content));
        }
    }

    @Nested
    @DisplayName("the note that explains it")
    class Note {

        /// The note is one sentence in the learner's own language saying why the first
        /// half was wrong. It arrives after "||" because a note is free prose in a
        /// language this parser cannot read, and "||" is the one divider that does not
        /// turn up inside Turkish, Spanish or German writing.
        ///
        /// Everything here holds one line: the note is the part that may be thrown away,
        /// and the correction is the part that may not.

        @Test
        @DisplayName("is read off the end of the line")
        void noteIsParsed() {
            String content = "Oh no, that sounds dull!\n"
                    + "[[FIX]] I am boring -> I'm bored || \"I am boring\" karsindakini sikiyorsun demek.";

            ChatbotService.Correction correction = ChatbotService.extractCorrection(content);

            assertNotNull(correction);
            assertEquals("I am boring", correction.said());
            assertEquals("I'm bored", correction.better());
            assertEquals("\"I am boring\" karsindakini sikiyorsun demek.", correction.note());
        }

        @Test
        @DisplayName("and the reply keeps none of it either")
        void noteNeverReachesTheReply() {
            // The note is the longest thing on the line and the most obviously not-English.
            // Left behind, it is read out loud in a Turkish accent by an American voice.
            String content = "Oh no, that sounds dull!\n"
                    + "[[FIX]] I am boring -> I'm bored || sikildigini anlatmak icin \"I'm bored\" denir.";

            assertEquals("Oh no, that sounds dull!", ChatbotService.stripCorrection(content));
        }

        @Test
        @DisplayName("is absent, not empty, when the model did not write one")
        void missingNoteIsNormal() {
            // Every correction that predates the note looks like this, and the model is
            // free to leave it off above A2. It must not cost the correction, and it must
            // not arrive as "" -- a blank line under a fix reads as a card that failed.
            ChatbotService.Correction correction =
                    ChatbotService.extractCorrection("Nice.\n[[FIX]] I go -> I went");

            assertNotNull(correction);
            assertEquals("I go", correction.said());
            assertEquals("I went", correction.better());
            assertNull(correction.note());
        }

        @Test
        @DisplayName("is absent when the separator is there and the note is not")
        void emptyNoteIsAbsent() {
            ChatbotService.Correction correction =
                    ChatbotService.extractCorrection("Nice.\n[[FIX]] I go -> I went ||   ");

            assertNotNull(correction);
            assertEquals("I went", correction.better());
            assertNull(correction.note());
        }

        @Test
        @DisplayName("is dropped when it runs away, and the correction survives")
        void runawayNoteCostsOnlyItself() {
            // A model asked for one sentence that delivers a grammar lecture has stopped
            // following the format, and the first 160 characters of a lecture are not an
            // explanation. Truncating would show the learner half a sentence; dropping
            // the whole card would cost them the fix because the explanation was bad.
            String lecture = "y".repeat(161);
            String content = "Sure.\n[[FIX]] I go -> I went || " + lecture;

            ChatbotService.Correction correction = ChatbotService.extractCorrection(content);

            assertNotNull(correction);
            assertEquals("I go", correction.said());
            assertEquals("I went", correction.better());
            assertNull(correction.note());
            assertEquals("Sure.", ChatbotService.stripCorrection(content));
        }

        @Test
        @DisplayName("is kept at exactly the cap")
        void noteAtTheCapSurvives() {
            String justFits = "y".repeat(160);

            ChatbotService.Correction correction =
                    ChatbotService.extractCorrection("Sure.\n[[FIX]] I go -> I went || " + justFits);

            assertNotNull(correction);
            assertEquals(justFits, correction.note());
        }

        @Test
        @DisplayName("may contain an arrow without confusing the halves")
        void arrowInsideTheNote() {
            // The reason the note is split off FIRST. "Exactly one arrow or nothing" is
            // what stops an ambiguous line producing a confident wrong split, and a
            // sentence explaining a correction is exactly where a second arrow shows up.
            String content = "Right.\n[[FIX]] I go -> I went || gecmis zaman: go -> went.";

            ChatbotService.Correction correction = ChatbotService.extractCorrection(content);

            assertNotNull(correction);
            assertEquals("I go", correction.said());
            assertEquals("I went", correction.better());
            assertEquals("gecmis zaman: go -> went.", correction.note());
        }

        @Test
        @DisplayName("keeps a second separator, because that one is prose")
        void firstSeparatorWins() {
            String content = "Right.\n[[FIX]] I go -> I went || once soyle || sonra boyle";

            ChatbotService.Correction correction = ChatbotService.extractCorrection(content);

            assertNotNull(correction);
            assertEquals("I went", correction.better());
            assertEquals("once soyle || sonra boyle", correction.note());
        }

        @Test
        @DisplayName("cannot rescue a line that has no correction in it")
        void noteWithoutACorrection() {
            // The note explains a fix. Without the fix there is nothing to explain, and
            // this degrades like every other malformed case.
            assertNull(ChatbotService.extractCorrection("Nice.\n[[FIX]] || bu yanlis."));
            assertNull(ChatbotService.extractCorrection("Nice.\n[[FIX]] I go || bu yanlis."));
            assertNull(ChatbotService.extractCorrection(
                    "Nice.\n[[FIX]] the sign say A -> B -> the sign says A -> B || iki ok var."));
        }
    }

    @Nested
    @DisplayName("nothing is invented")
    class NotFound {

        @Test
        @DisplayName("when the model simply did not correct")
        void noMarker() {
            String content = "That sounds lovely! Where did you go?";

            assertNull(ChatbotService.extractCorrection(content));
            assertEquals(content, ChatbotService.stripCorrection(content));
        }

        @Test
        @DisplayName("when the marker line has no arrow")
        void noSeparator() {
            String content = "Nice.\n[[FIX]] I went to Paris yesterday";

            assertNull(ChatbotService.extractCorrection(content));
            assertEquals("Nice.", ChatbotService.stripCorrection(content),
                    "a malformed marker must still not reach the screen");
        }

        @Test
        @DisplayName("when a second arrow makes the halves ambiguous")
        void twoArrows() {
            // "the sign say A -> B" corrected to "the sign says A -> B" is a real
            // sentence a learner could say, and nothing in the line says which arrow
            // divides it. Either split produces a confident wrong answer, so this
            // degrades like every other malformed case: no correction.
            //
            // The test that stood here asserted only the half that happened to come
            // out right, which is how the other half stayed wrong.
            String content = "Sure.\n[[FIX]] the sign say A -> B -> the sign says A -> B";

            assertNull(ChatbotService.extractCorrection(content));
            assertEquals("Sure.", ChatbotService.stripCorrection(content),
                    "an unreadable correction must still not reach the screen");
        }

        @Test
        @DisplayName("when either half is empty")
        void emptyHalf() {
            assertNull(ChatbotService.extractCorrection("Nice.\n[[FIX]]  -> I went"));
            assertNull(ChatbotService.extractCorrection("Nice.\n[[FIX]] I go -> "));
        }

        @Test
        @DisplayName("when the two halves are the same")
        void nothingChanged() {
            // "Corrected" to what they already said. Showing that teaches nothing and
            // tells the learner they were wrong when they were not.
            assertNull(ChatbotService.extractCorrection("Nice.\n[[FIX]] I went -> I went"));
        }

        @Test
        @DisplayName("when the line runs away")
        void tooLong() {
            String runaway = "x".repeat(400);
            assertNull(ChatbotService.extractCorrection("Nice.\n[[FIX]] I go -> " + runaway));
        }

        @Test
        @DisplayName("on a null completion")
        void nullContent() {
            assertNull(ChatbotService.extractCorrection(null));
            assertNull(ChatbotService.stripCorrection(null));
        }
    }

    @Nested
    @DisplayName("the marker never reaches the learner")
    class NeverLeaks {

        @Test
        @DisplayName("with nothing usable after it")
        void markerWithoutACorrection() {
            String content = "You could say [[FIX]] here, but it is fine.";

            assertNull(ChatbotService.extractCorrection(content));
            // Everything from the marker onward is dropped, including the words after
            // it. The model lost the thread at the marker, and half a sentence beats a
            // sentence with a correction format in the middle of it.
            assertEquals("You could say", ChatbotService.stripCorrection(content));
        }

        @Test
        @DisplayName("when the whole reply is the marker and nothing else")
        void onlyAMarker() {
            // The reply is then empty. This comment used to say the speaking screen
            // handled that. It did not: it appended a blank bubble with a play button
            // that read out nothing. The screen skips it now, and this assertion is
            // only about what this method returns.
            assertEquals("", ChatbotService.stripCorrection("[[FIX]] a -> b"));
        }

        @Test
        @DisplayName("with indentation in front of it")
        void indentedMarker() {
            String content = "Nice.\n   [[FIX]] I go -> I went";

            assertNotNull(ChatbotService.extractCorrection(content));
            assertTrue(ChatbotService.stripCorrection(content).equals("Nice."));
        }
    }
}
