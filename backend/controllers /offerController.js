import { createJobOffer } from '../models/jobOfferModel.js';


export const getOffers = async (_req, res) => {
    try {
        const offers = await getAllJobOffers();
        res.status(200).json(offers);
    } catch (error) {
        console.error('Error al obtener ofertas:', error);
        res.status(500).json({ error: 'Error al obtener ofertas' });
    }
};

export const createOffer = async (req, res) => {
    try {
        const newOffer = await createJobOffer(req.body); 
        res.status(201).json(newOffer); 
    } catch (error) {
        console.error('Error al crear oferta:', error);
        res.status(500).json({ error: 'Error al crear oferta' });
    }
};


export const getOfferById = async (req, res) => {
    try {
        const offer = await getJobOfferById(req.params.id);
        if (offer) {
            res.status(200).json(offer);
        } else {
            res.status(404).json({ error: 'Oferta no encontrada' });
        }
    } catch (error) {
        console.error('Error al obtener oferta:', error);
        res.status(500).json({ error: 'Error al obtener oferta' });
    }
};

