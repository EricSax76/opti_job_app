import dbClient from './dbClient.js';

export const getAllJobOffers = async () => {
    const query = `
        SELECT
            id,
            title,
            description,
            user_id,
            location,
            CASE
                WHEN salary_min IS NULL THEN NULL
                ELSE TO_CHAR(salary_min, 'FM999,999,999') || ' €'
            END AS salary_min,
            CASE
                WHEN salary_max IS NULL THEN NULL
                ELSE TO_CHAR(salary_max, 'FM999,999,999') || ' €'
            END AS salary_max,
            education,
            job_type,
            created_at
        FROM job_offers
        ORDER BY id DESC;
    `;
    const result = await dbClient.query(query);
    return result.rows;
};


export const getJobOfferById = async (id) => {
    const query = `
        SELECT
            id,
            title,
            description,
            user_id,
            location,
            CASE
                WHEN salary_min IS NULL THEN NULL
                ELSE TO_CHAR(salary_min, 'FM999,999,999') || ' €'
            END AS salary_min,
            CASE
                WHEN salary_max IS NULL THEN NULL
                ELSE TO_CHAR(salary_max, 'FM999,999,999') || ' €'
            END AS salary_max,
            education,
            job_type,
            created_at
        FROM job_offers
        WHERE id = $1
    `;
    const result = await dbClient.query(query, [id]);
    return result.rows[0];
};

export const createJobOffer = async (jobOffer) => {
    const { title, description, user_id, location, salary_min, salary_max, education, job_type } = jobOffer;
    const query = `
        INSERT INTO job_offers (title, description, user_id, location, salary_min, salary_max, education, job_type)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING
            id,
            title,
            description,
            user_id,
            location,
            CASE
                WHEN salary_min IS NULL THEN NULL
                ELSE TO_CHAR(salary_min, 'FM999,999,999') || ' €'
            END AS salary_min,
            CASE
                WHEN salary_max IS NULL THEN NULL
                ELSE TO_CHAR(salary_max, 'FM999,999,999') || ' €'
            END AS salary_max,
            education,
            job_type,
            created_at;
    `;
    const values = [title, description, user_id, location, salary_min, salary_max, education, job_type];
    const result = await dbClient.query(query, values);
    return result.rows[0];
}; 
