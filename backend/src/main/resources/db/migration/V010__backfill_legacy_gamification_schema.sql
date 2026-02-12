-- V010: Backfill legacy gamification tables for environments baselined at V003.
-- This is forward-only and keeps previously applied migrations immutable.

DO $$
BEGIN
    IF to_regclass('public.user_profiles') IS NULL THEN
        EXECUTE '
            CREATE TABLE user_profiles (
                id SERIAL PRIMARY KEY,
                username VARCHAR(50) UNIQUE NOT NULL,
                email VARCHAR(100),
                total_xp INT DEFAULT 0,
                level INT DEFAULT 1,
                streak_days INT DEFAULT 0,
                last_activity_date DATE,
                avatar_url VARCHAR(255),
                bio TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )';
    END IF;

    IF to_regclass('public.badges') IS NULL THEN
        EXECUTE '
            CREATE TABLE badges (
                id SERIAL PRIMARY KEY,
                name VARCHAR(50) NOT NULL,
                description TEXT,
                icon_name VARCHAR(50),
                xp_required INT DEFAULT 0,
                category VARCHAR(20),
                rarity VARCHAR(20) DEFAULT ''common'',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )';
    END IF;

    IF to_regclass('public.user_badges') IS NULL THEN
        EXECUTE '
            CREATE TABLE user_badges (
                id SERIAL PRIMARY KEY,
                user_id BIGINT REFERENCES user_profiles(id) ON DELETE CASCADE,
                badge_id BIGINT REFERENCES badges(id) ON DELETE CASCADE,
                earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(user_id, badge_id)
            )';
    END IF;

    IF to_regclass('public.weekly_scores') IS NULL THEN
        EXECUTE '
            CREATE TABLE weekly_scores (
                id SERIAL PRIMARY KEY,
                user_id BIGINT REFERENCES user_profiles(id) ON DELETE CASCADE,
                week_start_date DATE NOT NULL,
                weekly_xp INT DEFAULT 0,
                league VARCHAR(20) DEFAULT ''bronze'',
                rank INT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(user_id, week_start_date)
            )';
    END IF;

    IF to_regclass('public.xp_transactions') IS NULL THEN
        EXECUTE '
            CREATE TABLE xp_transactions (
                id SERIAL PRIMARY KEY,
                user_id BIGINT REFERENCES user_profiles(id) ON DELETE CASCADE,
                amount INT NOT NULL,
                reason VARCHAR(100),
                source VARCHAR(50),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'public' AND indexname = 'idx_user_profiles_xp'
    ) THEN
        EXECUTE 'CREATE INDEX idx_user_profiles_xp ON user_profiles(total_xp DESC)';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'public' AND indexname = 'idx_user_profiles_level'
    ) THEN
        EXECUTE 'CREATE INDEX idx_user_profiles_level ON user_profiles(level DESC)';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'public' AND indexname = 'idx_user_profiles_streak'
    ) THEN
        EXECUTE 'CREATE INDEX idx_user_profiles_streak ON user_profiles(streak_days DESC)';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'public' AND indexname = 'idx_weekly_scores_week'
    ) THEN
        EXECUTE 'CREATE INDEX idx_weekly_scores_week ON weekly_scores(week_start_date, weekly_xp DESC)';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'public' AND indexname = 'idx_xp_transactions_user'
    ) THEN
        EXECUTE 'CREATE INDEX idx_xp_transactions_user ON xp_transactions(user_id, created_at DESC)';
    END IF;
END $$;

INSERT INTO user_profiles (username, email, total_xp, level)
SELECT 'demo_user', 'demo@vocabmaster.com', 0, 1
WHERE NOT EXISTS (SELECT 1 FROM user_profiles WHERE username = 'demo_user');
