import express from 'express';
import { createJobOffer } from '../models/jobOffersModel.js';

const router = express.Router();


router.post('/', async (req, res) => {
    const newJobOffer = req.body; 
    try {
        const createdOffer = await createJobOffer(newJobOffer);
        res.status(201).json(createdOffer); // Devolvemos la oferta creada
    } catch (error) {
        console.error('Error al crear la oferta de trabajo:', error);
        res.status(500).json({ error: 'Error al crear la oferta de trabajo' });
    }
});

export default router;
