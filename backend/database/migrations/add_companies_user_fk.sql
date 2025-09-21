BEGIN;

ALTER TABLE companies
    ADD COLUMN IF NOT EXISTS user_id INTEGER;

DO $$
BEGIN
    ALTER TABLE companies
        ADD CONSTRAINT companies_user_fk
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN
        NULL;
END
$$;

COMMIT;
