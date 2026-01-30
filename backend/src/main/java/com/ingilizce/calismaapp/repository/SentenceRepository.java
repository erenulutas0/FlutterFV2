package com.ingilizce.calismaapp.repository;

import com.ingilizce.calismaapp.entity.Sentence;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SentenceRepository extends JpaRepository<Sentence, Long> {

    @Query("SELECT s FROM Sentence s WHERE s.word.id = :wordId")
    List<Sentence> findByWordId(@Param("wordId") Long wordId);

    @Modifying
    @Query("DELETE FROM Sentence s WHERE s.word.id = :wordId")
    void deleteByWordId(@Param("wordId") Long wordId);

    // Global stats (Admin/Legacy)
    long countByDifficulty(String difficulty);

    // User Scoped Stats
    @Query("SELECT COUNT(s) FROM Sentence s WHERE s.difficulty = :difficulty AND s.word.userId = :userId")
    long countByDifficultyAndUserId(@Param("difficulty") String difficulty, @Param("userId") Long userId);

    @Query("SELECT COUNT(s) FROM Sentence s WHERE s.word.userId = :userId")
    long countByUserId(@Param("userId") Long userId);

    @Query("SELECT s FROM Sentence s JOIN FETCH s.word w")
    List<Sentence> findAllWithWord();

    @Query("SELECT s FROM Sentence s JOIN FETCH s.word w WHERE w.userId = :userId")
    List<Sentence> findAllWithWordByUserId(@Param("userId") Long userId);
}
