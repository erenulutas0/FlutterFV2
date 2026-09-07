package com.ingilizce.calismaapp.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * Accounts that get the paid tier without paying for it.
 *
 * <p>The developer's own account is one of them. It had been kept premium by buying the
 * subscription through a Play licence-tester card, and that does not hold: a test
 * subscription's real expiry is minutes away, the reconciliation job runs every thirty
 * minutes, finds it expired, and drops the account to FREE mid-session. The visible
 * result was a quota of 8,000 tokens against 14,221 already spent, and a re-purchase
 * needed several times a night.
 *
 * <p>Deliberately a config list of emails rather than a column or an endpoint. There is
 * no request that can grant it, so no client, session or replayed purchase can reach it;
 * granting and revoking is one environment variable on the server; and the reconciliation
 * job cannot take it away, because it only ever writes {@code subscriptionEndDate} and
 * {@code aiPlanCode} and this is neither. Everyone not on the list pays as before.
 */
@Component
@ConfigurationProperties(prefix = "app.subscription.complimentary-access")
public class ComplimentaryAccessProperties {

    private List<String> emails = new ArrayList<>();

    /** Tier the listed accounts get. Any {@link com.ingilizce.calismaapp.service.AiPlanTier} name. */
    private String plan = "PREMIUM_PLUS";

    private Set<String> normalized = Set.of();

    public List<String> getEmails() {
        return emails;
    }

    public void setEmails(List<String> emails) {
        this.emails = emails == null ? new ArrayList<>() : emails;
        Set<String> next = new LinkedHashSet<>();
        for (String email : this.emails) {
            String value = normalize(email);
            if (!value.isEmpty()) {
                next.add(value);
            }
        }
        this.normalized = Set.copyOf(next);
    }

    public String getPlan() {
        return plan;
    }

    public void setPlan(String plan) {
        this.plan = (plan == null || plan.isBlank()) ? "PREMIUM_PLUS" : plan.trim();
    }

    /**
     * Whether this address is on the list.
     *
     * <p>Compared lowercased under {@link Locale#ROOT}: the server runs in Türkiye, and a
     * Turkish-locale lowercase turns the I in an address into a dotless ı, which would
     * quietly stop matching the very account this exists for.
     */
    public boolean covers(String email) {
        String value = normalize(email);
        return !value.isEmpty() && normalized.contains(value);
    }

    private static String normalize(String email) {
        return email == null ? "" : email.trim().toLowerCase(Locale.ROOT);
    }
}
