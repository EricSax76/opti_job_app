// JobOfferPage.js
import { useEffect, useState } from 'react';
import { fetchJobOffers } from '../services/api';
import '../styles/pages/JobOfferPage.css';

const JobOfferPage = () => {
    const [jobOffers, setJobOffers] = useState([]);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        const loadJobOffers = async () => {
            try {
                const offers = await fetchJobOffers();
                setJobOffers(offers);
            } catch (err) {
                console.error('Error loading job offers:', err);
                setError('Failed to load job offers. Please try again later.');
            } finally {
                setIsLoading(false);
            }
        };

        loadJobOffers();
    }, []);

    return (
        <div className="job-offer-page">
            <header className="job-offer-header">
                <h1>OFERTAS ACTIVAS</h1>
                <p>Encuentra tu próximo trabajo</p>
            </header>
            <main className="job-offer-card">
                {isLoading ? (
                    <p>Cargando ofertas...</p>
                ) : error ? (
                    <p className="error-message">{error}</p>
                ) : jobOffers.length > 0 ? (
                    jobOffers.map((job_offers) => (
                        <div key={job_offers.id} className="job-offer-card">
                            <h2>{job_offers.title}</h2>
                            <p>{job_offers.description}</p>
                            <p><strong>Ubicación</strong> {job_offers.location}</p>
                            <p><strong>Salario</strong> {job_offers.salary}</p>
                            <button className="apply-button">Apply Now</button>
                        </div>
                    ))
                ) : (
                    <p>No job offers available at the moment. Please check back later!</p>
                )}
            </main>
        </div>
    );
};

export default JobOfferPage;


