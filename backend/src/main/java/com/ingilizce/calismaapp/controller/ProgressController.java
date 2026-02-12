package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.model.Achievement;
import com.ingilizce.calismaapp.service.ProgressService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * REST Controller for user progress and achievements
 */
@RestController
@RequestMapping("/api/progress")
public class ProgressController {

    @Autowired
    private ProgressService progressService;

    /**
     * Get user progress stats (XP, level, streak)
     */
    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getStats(@RequestHeader("X-User-Id") Long userId) {
        try {
            Map<String, Object> stats = progressService.getStats(userId);
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * Get all achievements (locked and unlocked)
     */
    @GetMapping("/achievements")
    public ResponseEntity<List<Map<String, Object>>> getAllAchievements(@RequestHeader("X-User-Id") Long userId) {
        try {
            List<Map<String, Object>> achievements = progressService.getAllAchievements(userId);
            return ResponseEntity.ok(achievements);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * Get only unlocked achievements
     */
    @GetMapping("/achievements/unlocked")
    public ResponseEntity<List<Map<String, Object>>> getUnlockedAchievements(@RequestHeader("X-User-Id") Long userId) {
        try {
            List<Map<String, Object>> achievements = progressService.getUnlockedAchievements(userId);
            return ResponseEntity.ok(achievements);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * Check for new achievements and unlock them
     * Returns list of newly unlocked achievements
     */
    @PostMapping("/check-achievements")
    public ResponseEntity<List<Achievement>> checkAchievements(@RequestHeader("X-User-Id") Long userId) {
        try {
            List<Achievement> newAchievements = progressService.checkAndUnlockAchievements(userId);
            return ResponseEntity.ok(newAchievements);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * Award XP to user (for testing or manual awards)
     */
    @PostMapping("/award-xp")
    public ResponseEntity<Map<String, Object>> awardXp(@RequestHeader("X-User-Id") Long userId,
            @RequestBody Map<String, Object> request) {
        try {
            int xp = Integer.parseInt(request.get("xp").toString());
            String reason = request.getOrDefault("reason", "Manual award").toString();

            progressService.awardXp(userId, xp, reason);
            Map<String, Object> stats = progressService.getStats(userId);

            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
}
