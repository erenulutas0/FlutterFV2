-- Query-plan driven index tuning for active core endpoints:
-- 1) /api/sentences/difficulty/{difficulty}
-- 2) /api/reviews/date/{date}

CREATE INDEX IF NOT EXISTS idx_sentence_practices_user_difficulty_created_date
    ON sentence_practices(user_id, difficulty, created_date DESC);

CREATE INDEX IF NOT EXISTS idx_word_reviews_review_date
    ON word_reviews(review_date);
