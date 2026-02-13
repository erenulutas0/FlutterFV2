package com.ingilizce.calismaapp.repository;

import com.ingilizce.calismaapp.entity.RefreshTokenSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface RefreshTokenSessionRepository extends JpaRepository<RefreshTokenSession, Long> {

    Optional<RefreshTokenSession> findBySessionId(String sessionId);

    List<RefreshTokenSession> findByUserIdAndRevokedAtIsNullAndExpiresAtAfter(Long userId, LocalDateTime now);

    @Modifying
    @Query("""
            update RefreshTokenSession s
               set s.revokedAt = :revokedAt,
                   s.revokeReason = :reason
             where s.user.id = :userId
               and s.revokedAt is null
               and s.expiresAt > :now
            """)
    int revokeActiveSessionsForUser(@Param("userId") Long userId,
                                    @Param("revokedAt") LocalDateTime revokedAt,
                                    @Param("reason") String reason,
                                    @Param("now") LocalDateTime now);
}
