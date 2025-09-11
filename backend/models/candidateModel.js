import dbClient from './dbClient.js';

export const createCandidate = async ({ userId, skills, experience }) => {
  const query = `
    INSERT INTO candidates (user_id, cv_data, key_indicators)
    VALUES ($1, $2, $3)
    RETURNING *;
  `;
  const values = [userId, { experience }, { skills }];
  const result = await dbClient.query(query, values);
  return result.rows[0];
};

export const getAllCandidates = async () => {
  const result = await dbClient.query('SELECT * FROM candidates');
  return result.rows;
};

export const getCandidateById = async (id) => {
  const result = await dbClient.query('SELECT * FROM candidates WHERE id = $1', [id]);
  return result.rows[0];
};
