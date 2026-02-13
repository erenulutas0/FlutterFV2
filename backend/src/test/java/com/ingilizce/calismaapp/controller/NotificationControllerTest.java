package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.entity.Notification;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.UserRepository;
import com.ingilizce.calismaapp.security.JwtAuthenticationFilter;
import com.ingilizce.calismaapp.security.UserHeaderConsistencyFilter;
import com.ingilizce.calismaapp.service.NotificationService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Optional;

import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = NotificationController.class)
@AutoConfigureMockMvc(addFilters = false)
@TestPropertySource(properties = "app.features.community.enabled=true")
class NotificationControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private NotificationService notificationService;

    @MockBean
    private UserRepository userRepository;

    @MockBean
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    @MockBean
    private UserHeaderConsistencyFilter userHeaderConsistencyFilter;

    @Test
    void getUserNotificationsReturnsBadRequestWhenHeaderMissing() throws Exception {
        mockMvc.perform(get("/api/notifications"))
                .andExpect(status().isBadRequest());

        verify(notificationService, never()).getUserNotifications(org.mockito.ArgumentMatchers.any(User.class));
    }

    @Test
    void getUserNotificationsReturnsBadRequestWhenHeaderInvalid() throws Exception {
        mockMvc.perform(get("/api/notifications").header("X-User-Id", "invalid"))
                .andExpect(status().isBadRequest());

        verify(notificationService, never()).getUserNotifications(org.mockito.ArgumentMatchers.any(User.class));
    }

    @Test
    void getUserNotificationsReturnsNotificationsWhenHeaderValid() throws Exception {
        User user = new User("notify@example.com", "hash", "Notify");
        user.setId(1L);

        Notification notification = new Notification(user, Notification.NotificationType.MESSAGE, "hello", 10L);
        notification.setId(77L);

        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(notificationService.getUserNotifications(user)).thenReturn(List.of(notification));

        mockMvc.perform(get("/api/notifications").header("X-User-Id", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(77))
                .andExpect(jsonPath("$[0].message").value("hello"));
    }
}
