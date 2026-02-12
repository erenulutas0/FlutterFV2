package com.ingilizce.calismaapp.entity;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class PaymentTransactionTest {

    @Test
    void defaultValues_ShouldInitializeStatusAndCreatedAt() {
        PaymentTransaction tx = new PaymentTransaction();

        assertEquals(PaymentTransaction.Status.PENDING, tx.getStatus());
        assertNotNull(tx.getCreatedAt());
        assertEquals(null, tx.getId());
    }

    @Test
    void setters_ShouldUpdateAllMutableFields() {
        PaymentTransaction tx = new PaymentTransaction();
        User user = new User();
        SubscriptionPlan plan = new SubscriptionPlan();

        tx.setTransactionId("trx-001");
        tx.setUser(user);
        tx.setPlan(plan);
        tx.setAmount(new BigDecimal("149.99"));
        tx.setStatus(PaymentTransaction.Status.SUCCESS);
        tx.setProvider("IYZICO");

        assertEquals("trx-001", tx.getTransactionId());
        assertEquals(user, tx.getUser());
        assertEquals(plan, tx.getPlan());
        assertEquals(new BigDecimal("149.99"), tx.getAmount());
        assertEquals(PaymentTransaction.Status.SUCCESS, tx.getStatus());
        assertEquals("IYZICO", tx.getProvider());
    }

    @Test
    void statusEnum_ShouldContainExpectedValues() {
        assertEquals(PaymentTransaction.Status.PENDING, PaymentTransaction.Status.valueOf("PENDING"));
        assertEquals(PaymentTransaction.Status.SUCCESS, PaymentTransaction.Status.valueOf("SUCCESS"));
        assertEquals(PaymentTransaction.Status.FAILED, PaymentTransaction.Status.valueOf("FAILED"));
        assertEquals(PaymentTransaction.Status.REFUNDED, PaymentTransaction.Status.valueOf("REFUNDED"));
    }
}
