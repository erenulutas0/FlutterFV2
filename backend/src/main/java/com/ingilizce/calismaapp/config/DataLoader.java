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
            if (repository.count() == 0) {
                repository.save(new SubscriptionPlan("FREE", BigDecimal.ZERO, 3650)); // 10 years free tier

                SubscriptionPlan monthly = new SubscriptionPlan("PRO_MONTHLY", new BigDecimal("149.99"), 30);
                monthly.setFeatures("Unlimited AI Chat, IELTS Speaking Tests, Grammar Check");
                repository.save(monthly);

                SubscriptionPlan annual = new SubscriptionPlan("PRO_ANNUAL", new BigDecimal("999.99"), 365);
                annual.setFeatures("All PRO Features, 40% Discount, Priority Support");
                repository.save(annual);

                log.info("Default subscription plans seeded.");
            }
        };
    }
}
