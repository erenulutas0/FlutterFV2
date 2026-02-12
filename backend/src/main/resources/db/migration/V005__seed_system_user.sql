-- V005: Seed system user (id=1) for backward compatibility
INSERT INTO users (id, display_name, email, password_hash, user_tag, created_at, role, is_active, is_email_verified, is_premium, is_online)
SELECT 1,
       'System',
       'system@local',
       'u8XmYeEGxtzY3G3RhkVML8ujxxD7TY5xpgyT6vB38HM=',
       'system',
       NOW(),
       'SYSTEM',
       true,
       true,
       false,
       false
WHERE NOT EXISTS (SELECT 1 FROM users WHERE id = 1);
