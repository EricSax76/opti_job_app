import dbClient from './dbClient.js';
import bcrypt from 'bcryptjs'; // asegúrate de tener esto arriba

export const createUser = async ({ name, email, password, role = 'candidate' }) => {
  const hashedPassword = await bcrypt.hash(password, 10);
  const query = `
    INSERT INTO users (name, email, password_hash, role)
    VALUES ($1, $2, $3, $4)
    RETURNING *;
  `;
  const values = [name, email, hashedPassword, role];
  const result = await dbClient.query(query, values);
  return result.rows[0];
};

export const getAllUsers = async () => {
  const result = await dbClient.query('SELECT id, name, email, role FROM users');
  return result.rows;
};

export const getUserById = async (id) => {
  const result = await dbClient.query('SELECT id, name, email, role FROM users WHERE id = $1', [id]);
  return result.rows[0];
};
