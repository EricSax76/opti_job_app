import Offer from '../models/jobOffersModel.js';
import Candidate from '../models/candidateModel.js';

const getDashboardData = async (_req, res) => {
    try {
        const totalOffers = await Offer.count();
        const totalCandidates = await Candidate.count();

        res.status(200).json({
            message: 'Dashboard data retrieved successfully',
            data: {
                totalOffers,
                totalCandidates,
            },
        });
    } catch (error) {
        res.status(500).json({ message: 'Error retrieving dashboard data', error });
    }
};

export { getDashboardData };
