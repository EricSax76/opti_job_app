import { Router } from 'express';
import { getAllJobOffers, getJobOfferById, createJobOffer } from '../models/jobOffersModel.js';

const router = Router();


router.get('/', async (req, res, next) => {
  try {
    const offers = await getAllJobOffers();
    res.json(offers);
  } catch (err) {
    next(err);
  }
});

router.get('/:id', async (req, res, next) => {
  try {
    const offer = await getJobOfferById(req.params.id);
    if (!offer) return res.status(404).json({ error: 'Offer not found' });
    res.json(offer);
  } catch (err) {
    next(err);
  }
});


router.post('/', async (req, res, next) => {
  try {
    const newOffer = await createJobOffer(req.body);
    res.status(201).json(newOffer);
  } catch (err) {
    next(err);
  }
});

export default router;

