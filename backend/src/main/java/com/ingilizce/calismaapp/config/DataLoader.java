package com.ingilizce.calismaapp.config;

import com.ingilizce.calismaapp.entity.SubscriptionPlan;
import com.ingilizce.calismaapp.repository.SubscriptionPlanRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.math.BigDecimal;

@Configuration
public class DataLoader {
    private static final Logger log = LoggerFactory.getLogger(DataLoader.class);

    @Bean
    CommandLineRunner initDatabase(SubscriptionPlanRepository repository) {
        return args -> {
            ensurePlan(
                    repository,
                    "FREE",
                    BigDecimal.ZERO,
                    "USD",
                    3650,
                    "Base app access with 8k daily AI token quota.");

            // The numbers below must agree with V030__align_plan_quota_metadata_with
            // _enforcement.sql. Flyway runs before this CommandLineRunner, so on an
            // empty database V030's UPDATEs match no rows and whatever is written here
            // is what a fresh environment ships with. When these drifted, PRO_ANNUAL was
            // seeded at 999.99 against a store that charges 1199.99 -- the price bug
            // V030 exists to fix, waiting to return on the next restored backup.
            ensurePlan(
                    repository,
                    "PREMIUM",
                    new BigDecimal("149.99"),
                    "TRY",
                    30,
                    "AI access with 100k daily token quota.");

            ensurePlan(
                    repository,
                    "PREMIUM_PLUS",
                    new BigDecimal("999.99"),
                    "TRY",
                    30,
                    "AI access with 250k daily token quota.");

            // Keep legacy plans for backward compatibility with existing clients.
            ensurePlan(
                    repository,
                    "PRO_MONTHLY",
                    new BigDecimal("149.99"),
                    "TRY",
                    30,
                    "AI access with 100k daily token quota.");

            ensurePlan(
                    repository,
                    "PRO_ANNUAL",
                    new BigDecimal("1199.99"),
                    "TRY",
                    365,
                    "AI access with 100k daily token quota.");

            log.info("Subscription plans verified/sealed.");
        };
    }

    private void ensurePlan(SubscriptionPlanRepository repository,
                            String name,
                            BigDecimal price,
                            String currency,
                            int durationDays,
                            String features) {
        repository.findByName(name).orElseGet(() -> {
            SubscriptionPlan plan = new SubscriptionPlan(name, price, durationDays);
            plan.setCurrency(currency);
            plan.setFeatures(features);
            return repository.save(plan);
        });
    }
}
