BEGIN;

DO $$
BEGIN
    ALTER TABLE job_offers
        ADD CONSTRAINT job_offers_company_fk
        FOREIGN KEY (user_id)
        REFERENCES companies(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN
        NULL;
END
$$;

COMMIT;
