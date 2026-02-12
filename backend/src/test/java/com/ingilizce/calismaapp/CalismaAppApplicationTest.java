package com.ingilizce.calismaapp;

import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.springframework.boot.SpringApplication;
import org.springframework.context.ConfigurableApplicationContext;

class CalismaAppApplicationTest {

    @Test
    void main_ShouldDelegateToSpringApplicationRun() {
        try (MockedStatic<SpringApplication> springApplication = Mockito.mockStatic(SpringApplication.class)) {
            ConfigurableApplicationContext context = Mockito.mock(ConfigurableApplicationContext.class);
            springApplication.when(() -> SpringApplication.run(Mockito.eq(CalismaAppApplication.class), Mockito.any(String[].class)))
                    .thenReturn(context);

            CalismaAppApplication.main(new String[]{"--spring.main.banner-mode=off"});

            springApplication.verify(() -> SpringApplication.run(Mockito.eq(CalismaAppApplication.class), Mockito.any(String[].class)));
        }
    }
}
