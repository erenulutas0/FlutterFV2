package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.config.IyzicoConfig;
import com.ingilizce.calismaapp.entity.SubscriptionPlan;
import com.ingilizce.calismaapp.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.math.BigDecimal;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.when;

public class IyzicoServiceTest {

    @Mock
    private IyzicoConfig iyzicoConfig;

    @InjectMocks
    private IyzicoService iyzicoService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        when(iyzicoConfig.getApiKey()).thenReturn("test-api-key");
        when(iyzicoConfig.getSecretKey()).thenReturn("test-secret");
        when(iyzicoConfig.getBaseUrl()).thenReturn("https://sandbox-api.iyzipay.com");
    }

    @Test
    void testInitializePaymentObjectCreation() {
        User user = new User("test@example.com", "pass");
        user.setId(1L);

        SubscriptionPlan plan = new SubscriptionPlan("PRO", new BigDecimal("100"), 30);
        plan.setId(1L);

        Map<String, Object> result = iyzicoService.initializePayment(user, plan, "http://callback");
        assertNotNull(result);
        assertNotNull(result.get("status"));
    }
}
