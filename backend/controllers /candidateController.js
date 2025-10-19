import bcrypt from 'bcryptjs';
import { createUser } from '../models/userModel.js';
import { createCandidate, getAllCandidates, getCandidateById } from '../models/candidateModel.js';

export const loginCandidateController = async (req, res) => {
  const { email, password } = req.body;
  try {
    const result = await dbClient.query(
      'SELECT * FROM users WHERE email = $1 AND role = $2',
      [email, 'candidate']
    );
    const user = result.rows[0];

    if (!user) {
      return res.status(401).json({ message: 'Usuario no encontrado' });
    }

    const match = await bcrypt.compare(password, user.password_hash);
    if (!match) {
      return res.status(401).json({ message: 'Contraseña incorrecta' });
    }

    res.status(200).json({
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role
    });
  } catch (error) {
    console.error('Error en loginCandidateController:', error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

export const createCandidateController = async (req, res) => {
  try {
    const { name, email, password} = req.body;
    const user = await createUser({ name, email, password });
    const candidate = await createCandidate({
      userId: user.id,
    });
    res.status(201).json({ message: 'Candidate created successfully', candidate });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error creating candidate', error });
  }
};

export const getCandidatesController = async (_req, res) => {
  try {
    const candidates = await getAllCandidates();
    res.status(200).json({ message: 'Candidates retrieved successfully', candidates });
  } catch (error) {
    res.status(500).json({ message: 'Error retrieving candidates', error });
  }
};

export const getCandidateByIdController = async (req, res) => {
  try {
    const { id } = req.params;
    const candidate = await getCandidateById(id);
    if (!candidate) {
      return res.status(404).json({ message: 'Candidate not found' });
    }
    res.status(200).json({ message: 'Candidate retrieved successfully', candidate });
  } catch (error) {
    res.status(500).json({ message: 'Error retrieving candidate', error });
  }
};
