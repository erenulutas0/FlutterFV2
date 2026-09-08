package com.ingilizce.calismaapp.service;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Properties;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * What the annual subscription is booked against.
 *
 * <p>The Play product {@code pro_annual_subscription} was mapped to PREMIUM_PLUS, a row
 * that says 999.99 for 30 days, while the store charges 1199.99 for a year. Two things
 * followed: every annual sale was recorded 200 lira light, because the transaction takes
 * its amount from the mapped plan; and the duration floor used when Google reports no
 * usable expiry -- a grace-period edge, or trust-verified-expiry turned off -- would have
 * given a year's buyer thirty days.
 *
 * <p>PRO_ANNUAL is the row V030 set to 1199.99 and 365 days for exactly this purpose, and
 * nothing pointed at it. It also resolves to the PREMIUM tier rather than PREMIUM_PLUS,
 * which is what the paywall already advertises: both cards list the same three features,
 * and V030 settled that annual buys a discount, not a bigger allowance.
 *
 * <p>Read from the shipped properties on disk rather than the classpath: the test tree has
 * an application.properties of its own that would shadow the one being asserted about, and
 * it is the file that gets deployed that this is a claim about.
 */
class AnnualPlanIsAYearTest {

    private static String mappedPlan(String profileFile, String productId) throws IOException {
        Path path = Path.of("src", "main", "resources", profileFile);
        assertTrue(Files.exists(path), "missing " + path);
        Properties properties = new Properties();
        try (Reader reader = Files.newBufferedReader(path, StandardCharsets.UTF_8)) {
            properties.load(reader);
        }
        String raw = properties.getProperty(
                "app.subscription.google-play.product-plan-map." + productId);
        assertNotNull(raw, productId + " is not mapped in " + profileFile);
        // "${ENV_VAR:default}" -- the default is what ships when nothing overrides it.
        int colon = raw.lastIndexOf(':');
        int brace = raw.lastIndexOf('}');
        return colon > 0 && brace > colon ? raw.substring(colon + 1, brace) : raw;
    }

    @Test
    @DisplayName("the annual product books against the plan that is a year long")
    void annualMapsToTheYearLongPlan() throws IOException {
        for (String profile : new String[]{
                "application-prod.properties",
                "application.properties",
                "application-docker.properties"}) {
            assertEquals("PRO_ANNUAL", mappedPlan(profile, "pro_annual_subscription"),
                    "annual mapping in " + profile);
            assertEquals("PREMIUM", mappedPlan(profile, "pro_monthly_subscription"),
                    "monthly mapping in " + profile);
        }
    }

    @Test
    @DisplayName("the annual plan resolves to the same tier the paywall advertises")
    void annualAndMonthlyShareATier() {
        // Both paywall cards list the same three features. A tier that quietly differed
        // is a promise the screen does not make and a price the screen does not explain.
        assertEquals(AiPlanTier.PREMIUM, AiPlanTier.fromSubscriptionPlanName("PRO_ANNUAL"));
        assertEquals(AiPlanTier.PREMIUM, AiPlanTier.fromSubscriptionPlanName("PREMIUM"));
        assertEquals(AiPlanTier.PREMIUM, AiPlanTier.fromSubscriptionPlanName("PRO_MONTHLY"));
        // PREMIUM_PLUS is still a real tier; it just is not what a year of PRO buys.
        assertEquals(AiPlanTier.PREMIUM_PLUS,
                AiPlanTier.fromSubscriptionPlanName("PREMIUM_PLUS"));
    }
}
