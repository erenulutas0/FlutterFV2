package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.config.IyzicoConfig;
import com.ingilizce.calismaapp.entity.SubscriptionPlan;
import com.ingilizce.calismaapp.entity.User;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
public class IyzicoService {

    private final IyzicoConfig iyzicoConfig;

    public IyzicoService(IyzicoConfig iyzicoConfig) {
        this.iyzicoConfig = iyzicoConfig;
    }

    public Map<String, Object> initializePayment(User user, SubscriptionPlan plan, String callbackUrl) {
        Map<String, Object> request = new HashMap<>();
        request.put("locale", "tr");
        request.put("conversationId", UUID.randomUUID().toString());
        request.put("price", plan.getPrice().toString());
        request.put("paidPrice", plan.getPrice().toString());
        request.put("currency", "TRY");
        request.put("basketId", "B" + System.currentTimeMillis());
        request.put("paymentGroup", "SUBSCRIPTION");
        request.put("callbackUrl", callbackUrl);
        request.put("enabledInstallments", List.of(1, 2, 3, 6, 9));

        // Buyer Info
        Map<String, Object> buyer = new HashMap<>();
        buyer.put("id", user.getId().toString());
        buyer.put("name", user.getEmail().split("@")[0]);
        buyer.put("surname", "User");
        buyer.put("gsmNumber", "+905000000000");
        buyer.put("email", user.getEmail());
        buyer.put("identityNumber", "11111111111");
        buyer.put("registrationAddress", "Istanbul Turkey");
        buyer.put("ip", "85.34.78.112");
        buyer.put("city", "Istanbul");
        buyer.put("country", "Turkey");
        request.put("buyer", buyer);

        // Shipping/Billing Info
        Map<String, Object> address = new HashMap<>();
        address.put("contactName", buyer.get("name") + " " + buyer.get("surname"));
        address.put("city", "Istanbul");
        address.put("country", "Turkey");
        address.put("address", "Istanbul Turkey");
        request.put("shippingAddress", address);
        request.put("billingAddress", address);

        // Basket Items
        List<Map<String, Object>> basketItems = new ArrayList<>();
        Map<String, Object> item = new HashMap<>();
        item.put("id", plan.getId().toString());
        item.put("name", plan.getName());
        item.put("category1", "Education");
        item.put("itemType", "VIRTUAL");
        item.put("price", plan.getPrice().toString());
        basketItems.add(item);
        request.put("basketItems", basketItems);

        // In a real scenario, we would generate a signature here.
        // For the sake of this environment, we will use a simplified mock response.

        try {
            Map<String, Object> mockResult = new HashMap<>();
            mockResult.put("status", "success");
            mockResult.put("token", UUID.randomUUID().toString());
            mockResult.put("paymentPageUrl", iyzicoConfig.getBaseUrl() + "/mock-pay-page");
            mockResult.put("checkoutFormContent", "<div>Mock Iyzico Form</div>");
            return mockResult;

        } catch (Exception e) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "failure");
            error.put("errorMessage", e.getMessage());
            return error;
        }
    }
}
