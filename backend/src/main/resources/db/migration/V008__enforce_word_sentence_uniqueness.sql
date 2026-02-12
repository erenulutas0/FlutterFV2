-- Enforce idempotency at DB level for core word/sentence flows.
-- 1) Merge/remove historical duplicates.
-- 2) Add unique protections if equivalent ones do not already exist.

-- Re-point child rows from duplicate words to canonical word (lowest id).
WITH dup_map AS (
    SELECT id AS duplicate_id,
           MIN(id) OVER (PARTITION BY user_id, english_word) AS keep_id
    FROM words
)
UPDATE sentences s
SET word_id = d.keep_id
FROM dup_map d
WHERE s.word_id = d.duplicate_id
  AND d.duplicate_id <> d.keep_id;

WITH dup_map AS (
    SELECT id AS duplicate_id,
           MIN(id) OVER (PARTITION BY user_id, english_word) AS keep_id
    FROM words
)
UPDATE word_reviews wr
SET word_id = d.keep_id
FROM dup_map d
WHERE wr.word_id = d.duplicate_id
  AND d.duplicate_id <> d.keep_id;

-- Remove duplicate words after children are re-pointed.
WITH ranked_words AS (
    SELECT id,
           ROW_NUMBER() OVER (PARTITION BY user_id, english_word ORDER BY id) AS rn
    FROM words
)
DELETE FROM words w
USING ranked_words r
WHERE w.id = r.id
  AND r.rn > 1;

-- Remove duplicate sentence rows for same word/sentence/translation tuple.
WITH ranked_sentences AS (
    SELECT id,
           ROW_NUMBER() OVER (
               PARTITION BY word_id, sentence, COALESCE(translation, '')
               ORDER BY id
           ) AS rn
    FROM sentences
)
DELETE FROM sentences s
USING ranked_sentences r
WHERE s.id = r.id
  AND r.rn > 1;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_indexes
        WHERE schemaname = 'public'
          AND tablename = 'words'
          AND indexdef ILIKE '%UNIQUE INDEX%'
          AND indexdef ILIKE '%(user_id, english_word)%'
    ) THEN
        EXECUTE 'CREATE UNIQUE INDEX ux_words_user_english_word ON words (user_id, english_word)';
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_sentences_word_sentence_translation
    ON sentences (word_id, sentence, COALESCE(translation, ''));
