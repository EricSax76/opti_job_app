BEGIN;

ALTER TABLE job_offers
    ALTER COLUMN salary_min TYPE TEXT USING
        CASE
            WHEN salary_min IS NULL THEN NULL
            ELSE TO_CHAR(salary_min, 'FM999,999,999.00') || ' €'
        END,
    ALTER COLUMN salary_max TYPE TEXT USING
        CASE
            WHEN salary_max IS NULL THEN NULL
            ELSE TO_CHAR(salary_max, 'FM999,999,999.00') || ' €'
        END;

COMMIT;
