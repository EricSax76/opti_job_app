// index.js
import 'dotenv/config';
import express from 'express';
import cors from 'cors';


import { connectToDatabase } from '../database/connection.js';
import jobOffersRoutes from '../routes/offerRoutes.js';
import userRoutes from '../routes/users.js';
import candidateRoutes from '../routes/candidateRoutes.js';
import companyRoutes from '../routes/companyRoutes.js';

const app = express();
const PORT = process.env.PORT || 5001;

// --- PROBES para asegurar que ejecutas ESTE archivo ---
import { fileURLToPath } from 'url';
import path from 'path';
const __filename = fileURLToPath(import.meta.url);
const __dirname  = path.dirname(__filename);
console.log('[BOOT] index.js cargado desde:', __filename);
console.log('[BOOT] cwd:', process.cwd());

// Middlewares
app.use(cors({ origin: true, credentials: true }));
app.use(express.json());


// Healthcheck
app.get('/', (_req, res) => res.send('Backend funcionando correctamente'));

// ---- LOG de montaje de rutas
console.log('[ROUTES] Montando /api/job_offers ...');
app.use('/api/job_offers',
  (req, _res, next) => { console.log('[HIT] prefix /api/job_offers', req.method, req.originalUrl); next(); },
  jobOffersRoutes
);

console.log('[ROUTES] Montando /api/candidates ...');
app.use('/api/candidates', candidateRoutes);

console.log('[ROUTES] Montando /api/companies ...');
app.use('/api/companies', companyRoutes);

console.log('[ROUTES] Montando /api/users ...');
app.use('/api/users', userRoutes);

// --- Endpoint temporal para listar rutas registradas
app.get('/__debug/routes', (_req, res) => {
  const routes = [];
  app._router.stack.forEach((m) => {
    if (m.route && m.route.path) {
      routes.push({ method: Object.keys(m.route.methods)[0].toUpperCase(), path: m.route.path });
    } else if (m.name === 'router' && m.handle.stack) {
      m.handle.stack.forEach((h) => {
        const route = h.route;
        if (route) {
          const method = Object.keys(route.methods)[0].toUpperCase();
          routes.push({ method, path: (m.regexp?.toString() || 'MOUNT') + ' ' + route.path });
        }
      });
    }
  });
  res.json(routes);
});

// 404 verbose
app.use((req, res) => {
  console.warn(`404 -> ${req.method} ${req.originalUrl}`);
  res.status(404).json({ error: 'Not Found', method: req.method, path: req.originalUrl });
});

// Error handler
app.use((err, _req, res, _next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Server error' });
});

// Conectar DB y arrancar
(async () => {
  try {
    await connectToDatabase();
    console.log('Conexión exitosa a la base de datos');
    app.listen(PORT, () => {
      console.log(`Servidor corriendo en http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('Error al conectar a la base de datos:', error);
    process.exit(1);
  }
})();

