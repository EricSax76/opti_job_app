import express from 'express';
const router = express.Router();

// Ruta para obtener estadísticas del dashboard
router.get('/stats', (_req, _res) => {
    // Lógica para estadísticas del dashboard
});

// Ruta para obtener la lista de empresas
router.get('/companies', (_req, _res) => {
    // Lógica para obtener empresas
});

export default router;
