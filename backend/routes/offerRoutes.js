// offerRoutes.js
import express from 'express';

const router = express.Router();

// Ruta para obtener todas las ofertas
router.get('/api/job_offers', (_req, res) => {
    // Lógica para listar ofertas
    res.status(200).json([
        {
            id: 1,
            title: "Frontend Developer",
            description: "Work on React projects",
            location: "Remote",
            salary: 60000
        }, 
    ]);
});

// Ruta para crear una nueva oferta
router.post('/', (_req, res) => {
    // Lógica para crear una oferta
    res.status(201).json({ message: 'Oferta creada' });
});

// Ruta para obtener una oferta por ID
router.get('/:id', (req, res) => {
    const { id } = req.params;
    // Lógica para obtener una oferta específica
    res.status(200).json({
        id: id,
        title: "Frontend Developer",
        description: "Work on React projects",
        location: "Remote",
        salary: 60000
    });
});

export default router;
