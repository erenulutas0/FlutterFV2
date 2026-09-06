package com.ingilizce.calismaapp.service;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Field;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * The paragraph that asks the model for the correction card.
 *
 * <p>Found in use: a B2 learner said "Can you open the light?" and got a cheerful reply and
 * no card. The card line had been tied to the same "one error every few messages" policy
 * that keeps Amy's spoken reply from lecturing, and the model obeyed it. These pin the two
 * things that fix that -- the line is declared independent of that policy, and a Turkish
 * calque is named as a mistake -- and the one thing that must not change with it.
 *
 * <p>Read by reflection for the same reason the recall test is: the instructions are a
 * private constant, and widening the service for a test is the worse trade.
 */
class ChatbotFixInstructionsTest {

    private String fixInstructions() throws Exception {
        Field field = ChatbotService.class.getDeclaredField("FIX_INSTRUCTIONS");
        field.setAccessible(true);
        return (String) field.get(null);
    }

    @Test
    @DisplayName("the card is not subject to the reply's correction frequency")
    void cardIsIndependentOfReplyFrequency() throws Exception {
        String text = fixInstructions();

        assertThat(text).contains("does not govern this line");
        assertThat(text).contains("every clear mistake at B1 and above");
        // The old wording that bound them, gone.
        assertThat(text).doesNotContain("Follow the correction frequency above");
        assertThat(text).doesNotContain("worth showing");
    }

    @Test
    @DisplayName("word choice a native speaker would not use counts as a mistake")
    void calquesAreMistakes() throws Exception {
        String text = fixInstructions();

        // The exact sentence that slipped through, and the reason it slipped.
        assertThat(text).contains("open the light");
        assertThat(text).contains("meaning being clear does not");
    }

    @Test
    @DisplayName("beginners are still not corrected")
    void beginnersStillGetNoCard() throws Exception {
        // Confidence before accuracy at A1/A2 is a product decision that predates the
        // card; decoupling the card from the frequency rule must not quietly reverse it.
        assertThat(fixInstructions()).contains("At A1 and A2 omit the line entirely");
    }

    @Test
    @DisplayName("the line's shape is still the marker, the words, the separator, the fix")
    void shapeIsUnchanged() throws Exception {
        // extractCorrection parses exactly this; a reworded instruction that moved the
        // marker would cost every correction silently.
        assertThat(fixInstructions()).contains("[[FIX]] their exact words -> the corrected words");
    }
}
