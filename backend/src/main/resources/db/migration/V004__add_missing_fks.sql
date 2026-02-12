-- V004: Add missing FK constraints for user-owned tables
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_sentence_practices_user') THEN
        ALTER TABLE sentence_practices
            ADD CONSTRAINT fk_sentence_practices_user
            FOREIGN KEY (user_id) REFERENCES users(id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_user_achievements_user') THEN
        ALTER TABLE user_achievements
            ADD CONSTRAINT fk_user_achievements_user
            FOREIGN KEY (user_id) REFERENCES users(id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_user_progress_user') THEN
        ALTER TABLE user_progress
            ADD CONSTRAINT fk_user_progress_user
            FOREIGN KEY (user_id) REFERENCES users(id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_words_user') THEN
        ALTER TABLE words
            ADD CONSTRAINT fk_words_user
            FOREIGN KEY (user_id) REFERENCES users(id)
            ON DELETE CASCADE;
    END IF;
END $$;
