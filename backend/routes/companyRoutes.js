import express from 'express';
import pool from '../database/connection.js'; 
import bcrypt from 'bcryptjs';

const router = express.Router();

router.post('/', async (req, res) => {
  const { nombre, cif, sector, tamano, email, password } = req.body;

  const client = await pool.connect();

  try {
    // Wrap inserts in a transaction to avoid orphan rows on failure
    await client.query('BEGIN');

    const hashedPassword = await bcrypt.hash(password, 10);

    const userInsert = await client.query(
      `INSERT INTO users (name, email, password_hash, role)
       VALUES ($1, $2, $3, 'company')
       RETURNING id, name, email, role`,
      [nombre, email, hashedPassword]
    );

    const user = userInsert.rows[0];

    const companyInsert = await client.query(
      `INSERT INTO companies (nombre, cif, sector, tamano, email, password, user_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING id, nombre, email, user_id`,
      [nombre, cif, sector, tamano, email, hashedPassword, user.id]
    );

    await client.query('COMMIT');

    res.status(201).json({
      message: 'Empresa registrada correctamente',
      empresa: {
        ...companyInsert.rows[0],
        user
      }
    });
  } catch (error) {
    try {
      await client.query('ROLLBACK');
    } catch (rollbackError) {
      console.error('Error al hacer rollback del registro de empresa:', rollbackError);
    }
    if (error.code === '23505') {
      return res.status(409).json({ error: 'El email ya está registrado' });
    }
    console.error('Error al registrar la empresa:', error);
    res.status(500).json({ error: 'Error al registrar la empresa' });
  } finally {
    client.release();
  }
});

router.post('/login', async (req, res) => {
  const { email, password } = req.body;

   try {
      const result = await pool.query(
        'SELECT * FROM users WHERE email = $1 AND role = $2',
        [email, 'company']
      );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Email o contraseña incorrectos' });
    }

    const empresa = result.rows[0];
    const storedHash = empresa.password_hash;

    if (!storedHash) {
      console.error('Company user missing password hash for email:', email);
      return res.status(500).json({ error: 'Error interno del servidor' });
    }

    const isMatch = await bcrypt.compare(password, storedHash);

    if (!isMatch) {
      return res.status(401).json({ error: 'Email o contraseña incorrectos' });
    }

    const { password_hash, ...empresaSinPassword } = empresa;

    res.status(200).json({ message: 'Login exitoso', empresa: empresaSinPassword });
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
