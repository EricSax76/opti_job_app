// filterRoutes.js
import express from 'express';
const router = express.Router();

// Ruta para filtrar ofertas por criterios
router.post('/job_offers', (_req, _res) => {
    // Lógica para filtrar ofertas
});

// Ruta para filtrar candidatos por criterios
router.post('/candidates', (_req, _res) => {
    // Lógica para filtrar candidatos
});

export default router;
