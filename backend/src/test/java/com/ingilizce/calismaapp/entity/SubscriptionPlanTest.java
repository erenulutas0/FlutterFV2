package com.ingilizce.calismaapp.entity;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;

class SubscriptionPlanTest {

    @Test
    void constructor_ShouldSetCoreFieldsAndDefaultCurrency() {
        SubscriptionPlan plan = new SubscriptionPlan("PRO_MONTHLY", new BigDecimal("99.90"), 30);

        assertEquals("PRO_MONTHLY", plan.getName());
        assertEquals(new BigDecimal("99.90"), plan.getPrice());
        assertEquals(30, plan.getDurationDays());
        assertEquals("TRY", plan.getCurrency());
    }

    @Test
    void setters_ShouldUpdateFields() {
        SubscriptionPlan plan = new SubscriptionPlan();

        plan.setId(5L);
        plan.setName("IELTS_PREMIUM");
        plan.setPrice(new BigDecimal("199.50"));
        plan.setCurrency("USD");
        plan.setDurationDays(90);
        plan.setFeatures("{\"aiCoach\":true}");

        assertEquals(5L, plan.getId());
        assertEquals("IELTS_PREMIUM", plan.getName());
        assertEquals(new BigDecimal("199.50"), plan.getPrice());
        assertEquals("USD", plan.getCurrency());
        assertEquals(90, plan.getDurationDays());
        assertEquals("{\"aiCoach\":true}", plan.getFeatures());
    }
}
