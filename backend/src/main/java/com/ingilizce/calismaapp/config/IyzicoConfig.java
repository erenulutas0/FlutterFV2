package com.ingilizce.calismaapp.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

@Configuration
public class IyzicoConfig {

    @Value("${iyzico.api.key:sandbox-your-key}")
    private String apiKey;

    @Value("${iyzico.api.secret:sandbox-your-secret}")
    private String secretKey;

    @Value("${iyzico.api.base.url:https://sandbox-api.iyzipay.com}")
    private String baseUrl;

    public String getApiKey() {
        return apiKey;
    }

    public String getSecretKey() {
        return secretKey;
    }

    public String getBaseUrl() {
        return baseUrl;
    }
}
