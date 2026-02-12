-- V006: Normalize legacy SYSTEM seed role and repair users id sequence.

UPDATE users
SET role = 'USER'
WHERE role = 'SYSTEM';

DO $$
DECLARE
    seq_name TEXT;
BEGIN
    seq_name := pg_get_serial_sequence('users', 'id');

    IF seq_name IS NOT NULL THEN
        EXECUTE format(
            'SELECT setval(%L, COALESCE((SELECT MAX(id) FROM users), 1), true)',
            seq_name
        );
    END IF;
END $$;
