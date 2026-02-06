package com.ingilizce.calismaapp.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ingilizce.calismaapp.entity.SubscriptionPlan;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.PaymentTransactionRepository;
import com.ingilizce.calismaapp.repository.SubscriptionPlanRepository;
import com.ingilizce.calismaapp.repository.UserRepository;
import com.ingilizce.calismaapp.service.IyzicoService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.Map;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@DisplayName("Subscription Controller Tests")
public class SubscriptionControllerTest {

        @Autowired
        private MockMvc mockMvc;

        @MockBean
        private SubscriptionPlanRepository planRepository;

        @MockBean
        private UserRepository userRepository;

        @MockBean
        private PaymentTransactionRepository transactionRepository;

        @MockBean
        private IyzicoService iyzicoService;

        @Autowired
        private ObjectMapper objectMapper;

        private User testUser;
        private SubscriptionPlan monthlyPlan;
        private SubscriptionPlan annualPlan;

        @BeforeEach
        void setUp() {
                testUser = new User("test@example.com", "password");
                testUser.setId(1L);

                monthlyPlan = new SubscriptionPlan("PRO_MONTHLY", new BigDecimal("149.99"), 30);
                monthlyPlan.setId(1L);

                annualPlan = new SubscriptionPlan("PRO_ANNUAL", new BigDecimal("999.99"), 365);
                annualPlan.setId(2L);
        }

        @Nested
        @DisplayName("GET /api/subscription/plans")
        class GetPlansTests {

                @Test
                @DisplayName("Should return all available plans")
                void testGetPlans() throws Exception {
                        mockMvc.perform(get("/api/subscription/plans"))
                                        .andExpect(status().isOk());
                }
        }

        @Nested
        @DisplayName("POST /api/subscription/pay/iyzico")
        class IyzicoPaymentTests {

                @Test
                @DisplayName("Should initialize iyzico payment successfully")
                void testInitializeIyzicoSuccess() throws Exception {
                        Mockito.when(userRepository.findById(1L)).thenReturn(Optional.of(testUser));
                        Mockito.when(planRepository.findById(1L)).thenReturn(Optional.of(monthlyPlan));

                        Map<String, Object> response = Map.of(
                                        "status", "success",
                                        "token", "test-token",
                                        "paymentPageUrl", "http://iyzico.com/pay",
                                        "checkoutFormContent", "<div>test</div>");

                        Mockito.when(iyzicoService.initializePayment(any(), any(), anyString())).thenReturn(response);

                        Map<String, Object> request = Map.of(
                                        "planId", 1,
                                        "callbackUrl", "http://localhost/callback");

                        mockMvc.perform(post("/api/subscription/pay/iyzico")
                                        .header("X-User-Id", "1")
                                        .contentType(MediaType.APPLICATION_JSON)
                                        .content(objectMapper.writeValueAsString(request)))
                                        .andExpect(status().isOk())
                                        .andExpect(jsonPath("$.token").value("test-token"))
                                        .andExpect(jsonPath("$.paymentPageUrl").value("http://iyzico.com/pay"));
                }

                @Test
                @DisplayName("Should return error when iyzico payment fails")
                void testInitializeIyzicoFailure() throws Exception {
                        Mockito.when(userRepository.findById(1L)).thenReturn(Optional.of(testUser));
                        Mockito.when(planRepository.findById(1L)).thenReturn(Optional.of(monthlyPlan));

                        Map<String, Object> response = Map.of(
                                        "status", "failure",
                                        "errorMessage", "Invalid request");

                        Mockito.when(iyzicoService.initializePayment(any(), any(), anyString())).thenReturn(response);

                        Map<String, Object> request = Map.of(
                                        "planId", 1,
                                        "callbackUrl", "http://localhost/callback");

                        mockMvc.perform(post("/api/subscription/pay/iyzico")
                                        .header("X-User-Id", "1")
                                        .contentType(MediaType.APPLICATION_JSON)
                                        .content(objectMapper.writeValueAsString(request)))
                                        .andExpect(status().isBadRequest())
                                        .andExpect(jsonPath("$.error").value("Invalid request"));
                }

                @Test
                @DisplayName("Should return error when user not found")
                void testInitializeIyzicoUserNotFound() throws Exception {
                        Mockito.when(userRepository.findById(99L)).thenReturn(Optional.empty());

                        Map<String, Object> request = Map.of(
                                        "planId", 1,
                                        "callbackUrl", "http://localhost/callback");

                        mockMvc.perform(post("/api/subscription/pay/iyzico")
                                        .header("X-User-Id", "99")
                                        .contentType(MediaType.APPLICATION_JSON)
                                        .content(objectMapper.writeValueAsString(request)))
                                        .andExpect(status().isBadRequest())
                                        .andExpect(jsonPath("$.error").exists());
                }

                @Test
                @DisplayName("Should return error when plan not found")
                void testInitializeIyzicoPlanNotFound() throws Exception {
                        Mockito.when(userRepository.findById(1L)).thenReturn(Optional.of(testUser));
                        Mockito.when(planRepository.findById(99L)).thenReturn(Optional.empty());

                        Map<String, Object> request = Map.of(
                                        "planId", 99,
                                        "callbackUrl", "http://localhost/callback");

                        mockMvc.perform(post("/api/subscription/pay/iyzico")
                                        .header("X-User-Id", "1")
                                        .contentType(MediaType.APPLICATION_JSON)
                                        .content(objectMapper.writeValueAsString(request)))
                                        .andExpect(status().isBadRequest())
                                        .andExpect(jsonPath("$.error").exists());
                }
        }

        @Nested
        @DisplayName("POST /api/subscription/callback/iyzico")
        class IyzicoCallbackTests {

                @Test
                @DisplayName("Should handle successful callback")
                void testHandleCallbackSuccess() throws Exception {
                        com.ingilizce.calismaapp.entity.PaymentTransaction transaction = new com.ingilizce.calismaapp.entity.PaymentTransaction();
                        transaction.setUser(testUser);
                        transaction.setPlan(monthlyPlan);
                        transaction.setTransactionId("test-token");

                        Mockito.when(transactionRepository.findByTransactionId("test-token"))
                                        .thenReturn(Optional.of(transaction));

                        mockMvc.perform(post("/api/subscription/callback/iyzico")
                                        .param("token", "test-token"))
                                        .andExpect(status().isOk())
                                        .andExpect(content().string("Payment successful and subscription updated."));

                        Mockito.verify(transactionRepository).save(any());
                        Mockito.verify(userRepository).save(any());
                }

                @Test
                @DisplayName("Should return error for invalid token")
                void testHandleCallbackNotFound() throws Exception {
                        Mockito.when(transactionRepository.findByTransactionId("wrong-token"))
                                        .thenReturn(Optional.empty());

                        mockMvc.perform(post("/api/subscription/callback/iyzico")
                                        .param("token", "wrong-token"))
                                        .andExpect(status().isBadRequest());
                }
        }

        @Nested
        @DisplayName("POST /api/subscription/verify/google")
        class GoogleIAPTests {

                @Test
                @DisplayName("Should verify Google Play purchase and update subscription")
                void testVerifyGooglePurchaseSuccess() throws Exception {
                        Mockito.when(userRepository.findById(1L)).thenReturn(Optional.of(testUser));
                        Mockito.when(planRepository.findByName("PRO_MONTHLY")).thenReturn(Optional.of(monthlyPlan));

                        Map<String, String> request = Map.of(
                                        "planName", "PRO_MONTHLY",
                                        "purchaseToken", "google-purchase-token-123",
                                        "productId", "pro_monthly_subscription");

                        mockMvc.perform(post("/api/subscription/verify/google")
                                        .header("X-User-Id", "1")
                                        .contentType(MediaType.APPLICATION_JSON)
                                        .content(objectMapper.writeValueAsString(request)))
                                        .andExpect(status().isOk())
                                        .andExpect(jsonPath("$.message").value("Google IAP verified"));

                        Mockito.verify(userRepository).save(any());
                }

                @Test
                @DisplayName("Should return error when Google plan not found")
                void testVerifyGooglePurchasePlanNotFound() throws Exception {
                        Mockito.when(userRepository.findById(1L)).thenReturn(Optional.of(testUser));
                        Mockito.when(planRepository.findByName("INVALID_PLAN")).thenReturn(Optional.empty());

                        Map<String, String> request = Map.of(
                                        "planName", "INVALID_PLAN",
                                        "purchaseToken", "google-token");

                        mockMvc.perform(post("/api/subscription/verify/google")
                                        .header("X-User-Id", "1")
                                        .contentType(MediaType.APPLICATION_JSON)
                                        .content(objectMapper.writeValueAsString(request)))
                                        .andExpect(status().is5xxServerError());
                }
        }

        @Nested
        @DisplayName("POST /api/subscription/verify/apple")
        class AppleIAPTests {

                @Test
                @DisplayName("Should verify Apple purchase and update subscription")
                void testVerifyApplePurchaseSuccess() throws Exception {
                        Mockito.when(userRepository.findById(1L)).thenReturn(Optional.of(testUser));
                        Mockito.when(planRepository.findByName("PRO_ANNUAL")).thenReturn(Optional.of(annualPlan));

                        Map<String, String> request = Map.of(
                                        "planName", "PRO_ANNUAL",
                                        "receiptData", "apple-receipt-data-base64");

                        mockMvc.perform(post("/api/subscription/verify/apple")
                                        .header("X-User-Id", "1")
                                        .contentType(MediaType.APPLICATION_JSON)
                                        .content(objectMapper.writeValueAsString(request)))
                                        .andExpect(status().isOk())
                                        .andExpect(jsonPath("$.message").value("Apple IAP verified"));

                        Mockito.verify(userRepository).save(any());
                }

                @Test
                @DisplayName("Should return error when Apple plan not found")
                void testVerifyApplePurchasePlanNotFound() throws Exception {
                        Mockito.when(userRepository.findById(1L)).thenReturn(Optional.of(testUser));
                        Mockito.when(planRepository.findByName("INVALID_PLAN")).thenReturn(Optional.empty());

                        Map<String, String> request = Map.of(
                                        "planName", "INVALID_PLAN",
                                        "receiptData", "receipt");

                        mockMvc.perform(post("/api/subscription/verify/apple")
                                        .header("X-User-Id", "1")
                                        .contentType(MediaType.APPLICATION_JSON)
                                        .content(objectMapper.writeValueAsString(request)))
                                        .andExpect(status().is5xxServerError());
                }
        }
}
