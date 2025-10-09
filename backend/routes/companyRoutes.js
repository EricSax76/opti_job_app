import express from 'express';
import pool from '../database/connection.js'; // usa el pool directamente
import bcrypt from 'bcrypt';

const router = express.Router();

router.post('/', async (req, res) => {
  const {
    nombre,
    name,
    cif,
    sector,
    tamano,
    size,
    email,
    password
  } = req.body;

  const companyName = nombre ?? name;
  const companySize = tamano ?? size;
  const companyCif = (cif ?? '').toString().trim();
  const companySector = (sector ?? '').toString().trim();
  const normalizedSize = companySize != null && companySize.toString().trim().isNotEmpty
      ? companySize.toString().trim()
      : 'N/D';

  try {
    if (!companyName) {
      return res.status(400).json({ error: 'El nombre de la empresa es obligatorio.' });
    }

    if (!email || !password) {
      return res.status(400).json({ error: 'Email y contraseña son obligatorios.' });
    }

    const hashedPassword = await bcrypt.hash(password, 10); // ← aquí

    const result = await pool.query(
      `INSERT INTO companies (nombre, cif, sector, tamano, email, password)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, nombre AS name, email, 'company' AS role`,
      [companyName, companyCif, companySector, normalizedSize, email, hashedPassword]
    );

    res.status(201).json({
      message: 'Empresa registrada correctamente',
      empresa: result.rows[0]
    });
  } catch (error) {
    console.error('Error al registrar la empresa:', error);

    if (error.code === '23505') {
      return res.status(409).json({ error: 'La empresa ya existe.' });
    }

    if (error.code === '23502') {
      return res.status(400).json({
        error: `Falta el campo obligatorio: ${error.column ?? 'desconocido'}`,
      });
    }

    res.status(500).json({
      error: 'Error al registrar la empresa',
      detail: error.message,
    });
  }
});

router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    const result = await pool.query(
      `SELECT id, nombre AS name, email, 'company' AS role, password
         FROM companies
        WHERE email = $1`,
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

    const { password: _password, ...safeEmpresa } = empresa;

    res.status(200).json({ message: 'Login exitoso', empresa: safeEmpresa });
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
