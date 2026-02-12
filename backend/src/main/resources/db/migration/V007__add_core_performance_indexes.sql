-- Performance indexes for active core flows (words, sentence practices, reviews).
-- Safe to run repeatedly because of IF NOT EXISTS guards.

CREATE INDEX IF NOT EXISTS idx_words_user_learned_date
    ON words(user_id, learned_date);

CREATE INDEX IF NOT EXISTS idx_sentence_practices_user_created_date
    ON sentence_practices(user_id, created_date);

CREATE INDEX IF NOT EXISTS idx_word_reviews_word_review_date
    ON word_reviews(word_id, review_date);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_user_created_at
    ON payment_transactions(user_id, created_at);

CREATE INDEX IF NOT EXISTS idx_users_last_seen_at
    ON users(last_seen_at);
