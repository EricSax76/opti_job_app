import express from 'express';
import bcrypt from 'bcryptjs';
import pool from '../models/dbClient.js';

const router = express.Router();


router.post('/', async (req, res) => {
  const { name, email, password } = req.body;

  try {
    const hashedPassword = await bcrypt.hash(password, 10);

    const userResult = await pool.query(
      `INSERT INTO users (name, email, password_hash, role)
       VALUES ($1, $2, $3, 'candidate')
       RETURNING id, name, email, role`,
      [name, email, hashedPassword]
    );

    const user = userResult.rows[0];

    const candidateResult = await pool.query(
      `INSERT INTO candidates (user_id)
       VALUES ($1)
       RETURNING id, user_id`,
      [user.id]
    );

    res.status(201).json({
      message: 'Candidato registrado correctamente',
      candidate: {
        ...candidateResult.rows[0],
        user: user
      }
    });
  } catch (error) {
    console.error('Error al registrar el candidato:', error);
    res.status(500).json({ error: 'Error al registrar el candidato' });
  }
});


router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    const result = await pool.query(
      'SELECT * FROM users WHERE email = $1 AND role = $2',
      [email, 'candidate']
    );

    const user = result.rows[0];

    if (!user) {
      return res.status(401).json({ error: 'Email o contraseña incorrectos' });
    }

    const match = await bcrypt.compare(password, user.password_hash);
    if (!match) {
      return res.status(401).json({ error: 'Email o contraseña incorrectos' });
    }

    const displayName = (user.name && user.name.trim()) || (user.email ? user.email.split('@')[0] : 'Candidato');

    res.status(200).json({
      message: 'Login exitoso',
      candidate: {
        id: user.id,
        name: displayName,
        email: user.email,
        role: user.role
      }
    });
  } catch (error) {
    console.error('Error al hacer login del candidato:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});


router.get('/', async (_req, res) => {
  try {
    const result = await pool.query(`
      SELECT c.id AS candidate_id, u.id AS user_id, u.name, u.email, u.role
      FROM candidates c
      JOIN users u ON c.user_id = u.id
    `);
    res.status(200).json(result.rows);
  } catch (error) {
    console.error('Error al obtener candidatos:', error);
    res.status(500).json({ error: 'Error al obtener candidatos' });
  }
});


router.get('/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      `SELECT c.id AS candidate_id, u.id AS user_id, u.name, u.email, u.role
       FROM candidates c
       JOIN users u ON c.user_id = u.id
       WHERE c.id = $1`,
      [id]
    );

    const candidate = result.rows[0];

    if (!candidate) {
      return res.status(404).json({ error: 'Candidato no encontrado' });
    }

    res.status(200).json(candidate);
  } catch (error) {
    console.error('Error al obtener candidato por ID:', error);
    res.status(500).json({ error: 'Error al obtener candidato' });
  }
});

export default router;
