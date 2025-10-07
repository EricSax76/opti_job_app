BEGIN;

DO $$
BEGIN
    ALTER TABLE job_offers
        DROP CONSTRAINT IF EXISTS job_offers_company_fk;
EXCEPTION
    WHEN undefined_object THEN
        NULL;
END
$$;

ALTER TABLE job_offers
    DROP COLUMN IF EXISTS user_id;

COMMIT;
