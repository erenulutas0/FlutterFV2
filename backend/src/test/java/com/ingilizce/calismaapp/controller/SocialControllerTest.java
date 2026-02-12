package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.entity.Post;
import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.PostLikeRepository;
import com.ingilizce.calismaapp.repository.UserRepository;
import com.ingilizce.calismaapp.service.SocialService;
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

@WebMvcTest(controllers = SocialController.class)
@AutoConfigureMockMvc(addFilters = false)
@TestPropertySource(properties = "app.features.community.enabled=true")
class SocialControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private SocialService socialService;

    @MockBean
    private UserRepository userRepository;

    @MockBean
    private PostLikeRepository postLikeRepository;

    @Test
    void getGlobalFeedReturnsBadRequestWhenHeaderMissing() throws Exception {
        mockMvc.perform(get("/api/social/feed"))
                .andExpect(status().isBadRequest());

        verify(socialService, never()).getGlobalFeed();
    }

    @Test
    void getGlobalFeedReturnsBadRequestWhenHeaderInvalid() throws Exception {
        mockMvc.perform(get("/api/social/feed").header("X-User-Id", "abc"))
                .andExpect(status().isBadRequest());

        verify(socialService, never()).getGlobalFeed();
    }

    @Test
    void getGlobalFeedReturnsMappedPostsWhenHeaderValid() throws Exception {
        User currentUser = new User("current@example.com", "hash", "Current");
        currentUser.setId(1L);
        User author = new User("author@example.com", "hash", "Author");
        author.setId(2L);

        Post post = new Post(author, "hello community");
        post.setId(10L);

        when(userRepository.findById(1L)).thenReturn(Optional.of(currentUser));
        when(socialService.getGlobalFeed()).thenReturn(List.of(post));
        when(postLikeRepository.existsByUserAndPost(currentUser, post)).thenReturn(false);

        mockMvc.perform(get("/api/social/feed").header("X-User-Id", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(10))
                .andExpect(jsonPath("$[0].content").value("hello community"))
                .andExpect(jsonPath("$[0].liked").value(false))
                .andExpect(jsonPath("$[0].user.id").value(2));

        verify(userRepository).findById(1L);
        verify(socialService).getGlobalFeed();
        verify(postLikeRepository).existsByUserAndPost(currentUser, post);
    }
}
