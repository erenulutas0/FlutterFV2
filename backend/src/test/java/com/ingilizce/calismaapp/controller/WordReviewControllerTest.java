package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.entity.WordReview;
import com.ingilizce.calismaapp.service.WordReviewService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@TestPropertySource(properties = {
        "GROQ_API_KEY=dummy-key",
        "spring.datasource.url=jdbc:h2:mem:reviewdb;DB_CLOSE_DELAY=-1;MODE=PostgreSQL",
        "spring.datasource.driver-class-name=org.h2.Driver"
})
class WordReviewControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private WordReviewService wordReviewService;

    @Test
    void addReviewReturnsOk() throws Exception {
        LocalDate date = LocalDate.of(2026, 2, 10);
        WordReview review = reviewWithId(7L, date);
        when(wordReviewService.addReview(1L, date, "daily", "note")).thenReturn(review);

        mockMvc.perform(post("/api/reviews/words/1")
                .param("reviewDate", "2026-02-10")
                .param("reviewType", "daily")
                .param("notes", "note"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(7))
                .andExpect(jsonPath("$.reviewType").value("daily"));
    }

    @Test
    void addReviewReturnsBadRequestWhenServiceThrows() throws Exception {
        LocalDate date = LocalDate.of(2026, 2, 10);
        when(wordReviewService.addReview(1L, date, "daily", "note"))
                .thenThrow(new RuntimeException("invalid"));

        mockMvc.perform(post("/api/reviews/words/1")
                .param("reviewDate", "2026-02-10")
                .param("reviewType", "daily")
                .param("notes", "note"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void getWordReviewsReturnsOk() throws Exception {
        when(wordReviewService.getWordReviews(1L))
                .thenReturn(List.of(reviewWithId(11L, LocalDate.of(2026, 2, 1))));

        mockMvc.perform(get("/api/reviews/words/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(11));
    }

    @Test
    void getReviewsByDateReturnsOk() throws Exception {
        when(wordReviewService.getReviewsByDate(LocalDate.of(2026, 2, 1)))
                .thenReturn(List.of(reviewWithId(12L, LocalDate.of(2026, 2, 1))));

        mockMvc.perform(get("/api/reviews/date/2026-02-01"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(12));
    }

    @Test
    void isWordReviewedOnDateReturnsBoolean() throws Exception {
        when(wordReviewService.isWordReviewedOnDate(3L, LocalDate.of(2026, 2, 1))).thenReturn(true);

        mockMvc.perform(get("/api/reviews/words/3/check/2026-02-01"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").value(true));
    }

    @Test
    void getReviewCountReturnsCount() throws Exception {
        when(wordReviewService.getReviewCount(8L)).thenReturn(5L);

        mockMvc.perform(get("/api/reviews/words/8/count"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").value(5));
    }

    @Test
    void getReviewDatesReturnsDates() throws Exception {
        when(wordReviewService.getReviewDates(1L))
                .thenReturn(List.of(LocalDate.of(2026, 2, 1), LocalDate.of(2026, 2, 2)));

        mockMvc.perform(get("/api/reviews/words/1/dates"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0]").value("2026-02-01"))
                .andExpect(jsonPath("$[1]").value("2026-02-02"));
    }

    @Test
    void getReviewSummaryReturnsSummaryMap() throws Exception {
        LocalDate date = LocalDate.of(2026, 2, 10);
        when(wordReviewService.getReviewSummary(5L))
                .thenReturn(Map.of(date, reviewWithId(99L, date)));

        mockMvc.perform(get("/api/reviews/words/5/summary"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.['2026-02-10'].id").value(99));
    }

    @Test
    void deleteReviewReturnsOk() throws Exception {
        mockMvc.perform(delete("/api/reviews/44"))
                .andExpect(status().isOk());

        verify(wordReviewService).deleteReview(44L);
    }

    @Test
    void deleteReviewByWordAndDateReturnsOk() throws Exception {
        mockMvc.perform(delete("/api/reviews/words/2/date/2026-02-10"))
                .andExpect(status().isOk());

        verify(wordReviewService).deleteReviewByWordAndDate(2L, LocalDate.of(2026, 2, 10));
    }

    private static WordReview reviewWithId(Long id, LocalDate date) {
        WordReview review = new WordReview();
        review.setId(id);
        review.setReviewDate(date);
        review.setReviewType("daily");
        review.setNotes("sample");
        return review;
    }
}
