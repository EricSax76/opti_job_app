import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { getJobOffers } from '../services/api';
import '../styles/pages/CandidateDasboard.css';

const DashboardCandidate = () => {
  const [job_offers, setJobOffers] = useState([]);
  const [candidate, setCandidate] = useState({});
  const navigate = useNavigate();

  // Función para obtener las ofertas de trabajo
  const fetchJobOffers = async () => {
    try {
      const data = await getJobOffers();
      setJobOffers(data);
    } catch (error) {
      console.error('Error fetching job offers:', error);
    }
  };

  // Carga inicial
  useEffect(() => {
    fetchJobOffers();
  
    const storedCandidate = localStorage.getItem('candidate');
    if (storedCandidate) {
      setCandidate(JSON.parse(storedCandidate));
    } 
  }, [navigate]); 

  

  return (
    <div className="dashboard-company-container">
      <header className="dashboard-header">
        <h1>Bienvenida, {candidate.name || ''}</h1>
        <p>Explora ofertas de trabajo y gestiona tus postulacione</p>
      </header>


      
      <section className="job-offers-section">
        <h2>Tus Ofertas de Trabajo</h2>
        {job_offers.length > 0 ? (
          <ul className="job-offers-list">
            {job_offers.map((job_offers) => (
              <li key={job_offers.id} className="job-offer-item">
                <h2>{job_offers.title}</h2>
                <p>{job_offers.description}</p>
                <p>{job_offers.location}</p>
                <p>{job_offers.salary_min}</p>
                <p>{job_offers.education}</p>
                <p>{job_offers.job_type}</p>
                <p>{job_offers.key_indicators}</p>
                <span>Solicitudes: {job_offers.applicationsCount}</span>
              </li>
            ))}
          </ul>
        ) : (
          <p>No hay ofertas publicadas aún.
          </p>
        )}
      </section>
    </div>
  );
};

export default DashboardCandidate;
