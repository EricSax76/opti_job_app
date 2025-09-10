import Offer from '../models/jobOfferModel.js';

const filterOffers = async (req, res) => {
    try {
        const { keywords, location, salaryRange } = req.query;

        const filters = {};
        if (keywords) filters.title = { $like: `%${keywords}%` };
        if (location) filters.location = location;
        if (salaryRange) filters.salaryRange = salaryRange;

        const offers = await Offer.findAll({ where: filters });
        res.status(200).json({ message: 'Offers filtered successfully', offers });
    } catch (error) {
        res.status(500).json({ message: 'Error filtering offers', error });
    }
};

export { filterOffers };
