// JobOfferPage.js
import { useEffect, useMemo, useState } from 'react';
import { fetchJobOffers } from '../services/api';
import '../styles/pages/JobOfferPage.css';

const JobOfferPage = () => {
    const [jobOffers, setJobOffers] = useState([]);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState(null);
    const [selectedJobType, setSelectedJobType] = useState('');

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

    const jobTypes = useMemo(() => {
        const types = jobOffers
            .map((offer) => offer.job_type)
            .filter((type) => type && type.trim().length > 0);
        return Array.from(new Set(types));
    }, [jobOffers]);

    const filteredOffers = useMemo(() => {
        if (!selectedJobType) {
            return jobOffers;
        }

        return jobOffers.filter((offer) => offer.job_type === selectedJobType);
    }, [jobOffers, selectedJobType]);

    return (
        <div className="job-offer-page">
            <header className="job-offer-header">
                <h1>OFERTAS ACTIVAS</h1>
                <p>Encuentra tu próximo trabajo</p>
            </header>
            <section className="job-offer-filters">
                <label className="filter-label" htmlFor="jobTypeFilter">Filtrar por tipología:</label>
                <select
                    id="jobTypeFilter"
                    className="filter-select"
                    value={selectedJobType}
                    onChange={(event) => setSelectedJobType(event.target.value)}
                >
                    <option value="">Todas</option>
                    {jobTypes.map((type) => (
                        <option key={type} value={type}>
                            {type}
                        </option>
                    ))}
                </select>
            </section>
            <main className="job-offer-list">
                {isLoading ? (
                    <p>Cargando ofertas...</p>
                ) : error ? (
                    <p className="error-message">{error}</p>
                ) : filteredOffers.length > 0 ? (
                    filteredOffers.map((job_offers) => (
                        <div key={job_offers.id} className="job-offer-card">
                            <h2>{job_offers.title}</h2>
                            <p>{job_offers.description}</p>
                            <p><strong>Ubicación</strong> {job_offers.location}</p>
                            <p><strong>Tipología</strong> {job_offers.job_type || 'No especificado'}</p>
                            <p><strong>Salario mínimo</strong> {job_offers.salary_min || 'No disponible'}</p>
                            <p><strong>Salario máximo</strong> {job_offers.salary_max || 'No disponible'}</p>
                            <p><strong>Educación requerida</strong> {job_offers.education || 'No especificada'}</p>
                            <button className="apply-button">Apply Now</button>
                        </div>
                    ))
                ) : (
                    <p>No hay ofertas que coincidan con la tipología seleccionada.</p>
                )}
            </main>
        </div>
    );
};

export default JobOfferPage;
