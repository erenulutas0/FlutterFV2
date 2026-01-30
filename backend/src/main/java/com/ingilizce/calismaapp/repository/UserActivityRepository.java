package com.ingilizce.calismaapp.repository;

import com.ingilizce.calismaapp.entity.UserActivity;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface UserActivityRepository extends JpaRepository<UserActivity, Long> {

    // Fetch activities of specific users (my friends)
    @Query("SELECT a FROM UserActivity a WHERE a.userId IN :userIds ORDER BY a.createdAt DESC")
    List<UserActivity> findActivitiesByUserIds(List<Long> userIds, Pageable pageable);
}
