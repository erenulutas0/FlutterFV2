package com.ingilizce.calismaapp.repository;

import com.ingilizce.calismaapp.entity.SentencePractice;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface SentencePracticeRepository extends JpaRepository<SentencePractice, Long> {

    // Global support (Admin/Legacy)
    List<SentencePractice> findAllByOrderByCreatedDateDesc();

    // User Scoped Methods
    List<SentencePractice> findByUserIdOrderByCreatedDateDesc(Long userId);
    Page<SentencePractice> findByUserIdOrderByCreatedDateDesc(Long userId, Pageable pageable);
    Optional<SentencePractice> findByIdAndUserId(Long id, Long userId);

    // Find sentences by difficulty level (User Scoped)
    List<SentencePractice> findByUserIdAndDifficultyOrderByCreatedDateDesc(Long userId,
            SentencePractice.DifficultyLevel difficulty);

    // Find sentences by date range (User Scoped)
    @Query("SELECT sp FROM SentencePractice sp WHERE sp.userId = :userId AND sp.createdDate BETWEEN :startDate AND :endDate ORDER BY sp.createdDate DESC")
    List<SentencePractice> findByUserIdAndDateRange(@Param("userId") Long userId,
            @Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);

    // Find sentences by specific date (User Scoped)
    List<SentencePractice> findByUserIdAndCreatedDateOrderByCreatedDateDesc(Long userId, LocalDate date);

    // Count sentences by difficulty (User Scoped)
    long countByUserId(Long userId);
    long countByUserIdAndDifficulty(Long userId, SentencePractice.DifficultyLevel difficulty);

    // Get all distinct dates when sentences were created (User Scoped)
    @Query("SELECT DISTINCT sp.createdDate FROM SentencePractice sp WHERE sp.userId = :userId ORDER BY sp.createdDate DESC")
    List<LocalDate> findDistinctCreatedDatesByUserId(@Param("userId") Long userId);
}
