import React, { useState, useEffect } from 'react';
import axios from 'axios';



const CandidateDashboard = () => {
    const [candidate, setCandidate] = useState({});
    const [jobOffers, setJobOffers] = useState([]);

    

    useEffect(() => {
        // Cargar información del candidato
        const fetchCandidate = async () => {
            try {
                const response = await axios.get(`/api/candidates/${candidate}`);
                setCandidate(response.data);
            } catch (error) {
                console.error('Error al obtener la información del candidato:', error);
            }
        };

        // Cargar ofertas de trabajo
        const fetchJobOffers = async () => {
            try {
                const response = await axios.get('/api/job_offers');
                setJobOffers(response.data);
            } catch (error) {
                console.error('Error al obtener ofertas de trabajo:', error);
            }
        };

        fetchCandidate();
        fetchJobOffers();
    }, [candidate]);

    return (
        <div className="Candidatedashboard-container">
            <header className="Candidatedashboard-header">
                <h1>Bienvenido, {candidate.name || 'Candidato'}</h1>
                <p>Explora ofertas de trabajo y gestiona tus postulaciones</p>
            </header>

            <section className="dashboard-info">
                <div className="candidate-info">
                    <h2>Tu Información</h2>
                    <p><strong>Nombre:</strong> {candidate.full_name}</p>
                    <p><strong>Email:</strong> {candidate.email}</p>
                    <p><strong>Resumen:</strong> {candidate.resume || 'No has subido un resumen aún'}</p>
                </div>
            </section>

            <section className="dashboard-offers">
                <h2>Ofertas de Trabajo Disponibles</h2>
                <div className="offers-list">
                    {jobOffers.length === 0 ? (
                        <p>No hay ofertas disponibles por el momento.</p>
                    ) : (
                        jobOffers.map((offer) => (
                            <div key={offer.id} className="offer-card">
                                <h3>{offer.title}</h3>
                                <p>{offer.description}</p>
                                <button className="apply-button">Postular</button>
                            </div>
                        ))
                    )}
                </div>
            </section>
        </div>
    );
};

export default CandidateDashboard;
