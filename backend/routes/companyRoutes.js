import express from 'express';
import pool from '../database/connection.js'; 
import bcrypt from 'bcryptjs';

const router = express.Router();

router.post('/', async (req, res) => {
  const { nombre, cif, sector, tamano, email, password } = req.body;

  try {
    const hashedPassword = await bcrypt.hash(password, 10); 

    const result = await pool.query(
      `INSERT INTO companies (nombre, cif, sector, tamano, email, password)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, nombre, email`,
      [nombre, cif, sector, tamano, email, hashedPassword]
    );

    res.status(201).json({
      message: 'Empresa registrada correctamente',
      empresa: result.rows[0]
    });
  } catch (error) {
    console.error('Error al registrar la empresa:', error);
    res.status(500).json({ error: 'Error al registrar la empresa' });
  }
});

router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    const result = await pool.query(
      'SELECT * FROM companies WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Email o contraseña incorrectos' });
    }

    const empresa = result.rows[0];

    const isMatch = await bcrypt.compare(password, empresa.password);

    if (!isMatch) {
      return res.status(401).json({ error: 'Email o contraseña incorrectos' });
    }

    res.status(200).json({ message: 'Login exitoso', empresa });
  } catch (error) {
    console.error('Error en login:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

router.get('/', async (_req, res) => {
    try {
      const result = await pool.query('SELECT * FROM companies');
      res.status(200).json(result.rows);
    } catch (error) {
      console.error('Error al obtener empresas:', error);
      res.status(500).json({ error: 'Error al obtener empresas' });
    }
  });

export default router;
