package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.config.AiTokenQuotaProperties;
import com.ingilizce.calismaapp.config.ComplimentaryAccessProperties;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AiEntitlementServiceTest {

    @Mock
    private UserRepository userRepository;

    private AiEntitlementService aiEntitlementService;
    private ComplimentaryAccessProperties complimentaryAccess;

    @BeforeEach
    void setUp() {
        AiTokenQuotaProperties properties = new AiTokenQuotaProperties();
        properties.setTrialDurationDays(7);
        properties.setTrialDailyTokenQuotaPerUser(5_000);
        properties.setFreeDailyTokenQuotaPerUser(1_500);
        properties.setPremiumDailyTokenQuotaPerUser(30_000);
        properties.setPremiumPlusDailyTokenQuotaPerUser(60_000);
        // Empty by default: every existing test below describes an account that is not
        // on the list, which is every account in production but a couple of testers.
        complimentaryAccess = new ComplimentaryAccessProperties();
        aiEntitlementService =
                new AiEntitlementService(userRepository, properties, complimentaryAccess);
    }

    @Test
    void resolve_ShouldReturnTrialPlan_WhenUserIsInsideTrialWindow() {
        User user = new User();
        user.setCreatedAt(LocalDateTime.now().minusDays(2));
        user.setSubscriptionEndDate(LocalDateTime.now().minusDays(1));
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));

        AiEntitlementService.Entitlement entitlement = aiEntitlementService.resolve(1L);

        assertEquals(AiPlanTier.FREE_TRIAL_7D, entitlement.planTier());
        assertTrue(entitlement.aiAccessEnabled());
        assertEquals(5_000, entitlement.dailyTokenLimit());
        assertTrue(entitlement.trialActive());
        assertTrue(entitlement.trialDaysRemaining() > 0);
    }

    @Test
    void resolve_ShouldReturnFreeWithDailyTokens_WhenTrialExpiredAndNoSubscription() {
        User user = new User();
        user.setCreatedAt(LocalDateTime.now().minusDays(20));
        user.setSubscriptionEndDate(LocalDateTime.now().minusDays(1));
        when(userRepository.findById(2L)).thenReturn(Optional.of(user));

        AiEntitlementService.Entitlement entitlement = aiEntitlementService.resolve(2L);

        assertEquals(AiPlanTier.FREE, entitlement.planTier());
        assertTrue(entitlement.aiAccessEnabled());
        assertEquals(1_500, entitlement.dailyTokenLimit());
        assertFalse(entitlement.trialActive());
        assertEquals(0, entitlement.trialDaysRemaining());
    }

    @Test
    void resolve_ShouldReturnFree_WhenTrialIsMarkedIneligible() {
        User user = new User();
        user.setTrialEligible(false);
        user.setCreatedAt(LocalDateTime.now().minusDays(2));
        user.setSubscriptionEndDate(LocalDateTime.now().minusDays(1));
        when(userRepository.findById(22L)).thenReturn(Optional.of(user));

        AiEntitlementService.Entitlement entitlement = aiEntitlementService.resolve(22L);

        assertEquals(AiPlanTier.FREE, entitlement.planTier());
        assertTrue(entitlement.aiAccessEnabled());
        assertEquals(1_500, entitlement.dailyTokenLimit());
        assertFalse(entitlement.trialActive());
        assertEquals(0, entitlement.trialDaysRemaining());
    }

    @Test
    void resolve_ShouldReturnPremiumPlus_WhenSubscriptionActiveAndPlanPlus() {
        User user = new User();
        user.setAiPlanCode("PREMIUM_PLUS");
        user.setCreatedAt(LocalDateTime.now().minusDays(100));
        user.setSubscriptionEndDate(LocalDateTime.now().plusDays(10));
        when(userRepository.findById(3L)).thenReturn(Optional.of(user));

        AiEntitlementService.Entitlement entitlement = aiEntitlementService.resolve(3L);

        assertEquals(AiPlanTier.PREMIUM_PLUS, entitlement.planTier());
        assertTrue(entitlement.aiAccessEnabled());
        assertEquals(60_000, entitlement.dailyTokenLimit());
    }

    @Test
    void resolve_ShouldFallbackToPremium_WhenSubscriptionActiveButPlanMissing() {
        User user = new User();
        user.setAiPlanCode("FREE");
        user.setCreatedAt(LocalDateTime.now().minusDays(50));
        user.setSubscriptionEndDate(LocalDateTime.now().plusDays(7));
        when(userRepository.findById(4L)).thenReturn(Optional.of(user));

        AiEntitlementService.Entitlement entitlement = aiEntitlementService.resolve(4L);

        assertEquals(AiPlanTier.PREMIUM, entitlement.planTier());
        assertTrue(entitlement.aiAccessEnabled());
        assertEquals(30_000, entitlement.dailyTokenLimit());
    }

    // --- complimentary access ------------------------------------------------------
    //
    // The developer's own account kept falling to FREE mid-session: the licence-tester
    // subscription it relied on expires in minutes, and reconciliation writes the end
    // date back to now on its next half-hourly run. These pin that the list holds in
    // exactly that state, and that it reaches nobody else.

    @Test
    void resolve_ShouldGrantPaidTier_WhenListedEvenWithNoSubscriptionAndTrialGone() {
        complimentaryAccess.setEmails(java.util.List.of("beta@klioai.com"));
        User user = new User();
        user.setEmail("beta@klioai.com");
        user.setAiPlanCode("FREE");
        user.setTrialEligible(false);
        user.setCreatedAt(LocalDateTime.now().minusDays(200));
        // What a reconciliation downgrade leaves behind.
        user.setSubscriptionEndDate(LocalDateTime.now().minusMinutes(1));
        when(userRepository.findById(9L)).thenReturn(Optional.of(user));

        AiEntitlementService.Entitlement entitlement = aiEntitlementService.resolve(9L);

        assertEquals(AiPlanTier.PREMIUM_PLUS, entitlement.planTier());
        assertEquals(60_000, entitlement.dailyTokenLimit());
        assertFalse(entitlement.trialActive());
    }

    @Test
    void resolve_ShouldHonourConfiguredPlan_WhenListAsksForPremium() {
        complimentaryAccess.setEmails(java.util.List.of("beta@klioai.com"));
        complimentaryAccess.setPlan("PREMIUM");
        User user = new User();
        user.setEmail("beta@klioai.com");
        user.setCreatedAt(LocalDateTime.now().minusDays(200));
        when(userRepository.findById(10L)).thenReturn(Optional.of(user));

        assertEquals(AiPlanTier.PREMIUM, aiEntitlementService.resolve(10L).planTier());
    }

    @Test
    void resolve_ShouldMatchRegardlessOfCaseAndSurroundingSpace() {
        // Addresses arrive from Google sign-in in whatever case the account has, and
        // an env var is typed by hand. Neither should decide whether this works.
        complimentaryAccess.setEmails(java.util.List.of("  Beta@KlioAI.com  "));
        User user = new User();
        user.setEmail("BETA@klioai.COM");
        user.setCreatedAt(LocalDateTime.now().minusDays(200));
        when(userRepository.findById(11L)).thenReturn(Optional.of(user));

        assertEquals(AiPlanTier.PREMIUM_PLUS, aiEntitlementService.resolve(11L).planTier());
    }

    @Test
    void resolve_ShouldLeaveEveryoneElseOnTheirOwnTier() {
        complimentaryAccess.setEmails(java.util.List.of("beta@klioai.com"));
        User user = new User();
        user.setEmail("someone.else@example.com");
        user.setTrialEligible(false);
        user.setCreatedAt(LocalDateTime.now().minusDays(200));
        when(userRepository.findById(12L)).thenReturn(Optional.of(user));

        // The list is not a back door: a paying product needs everyone off it to pay.
        assertEquals(AiPlanTier.FREE, aiEntitlementService.resolve(12L).planTier());
        assertEquals(1_500, aiEntitlementService.resolve(12L).dailyTokenLimit());
    }

    @Test
    void resolve_ShouldGrantNothing_WhenListIsEmptyAndEmailIsNull() {
        // Production before this feature is configured, and legacy rows with no email.
        User user = new User();
        user.setTrialEligible(false);
        user.setCreatedAt(LocalDateTime.now().minusDays(200));
        when(userRepository.findById(13L)).thenReturn(Optional.of(user));

        assertEquals(AiPlanTier.FREE, aiEntitlementService.resolve(13L).planTier());
    }
}
