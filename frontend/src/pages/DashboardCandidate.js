import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { getJobOffers } from '../services/api';
import '../styles/pages/CandidateDasboard.css';

const DashboardCandidate = () => {
  const [job_offers, setJobOffers] = useState([]);
  const [candidate, setCandidate] = useState({});
  const navigate = useNavigate();

  const handleJobOfferClick = (offerId) => {
    navigate(`/job-offer/${offerId}`);
  };

  
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
        <p>Encuentra tu próxim aventura laboral</p>
      </header>


      
      <section className="job-offers-section">
        <h2>Ofertas destacadas</h2>
        {job_offers.length > 0 ? (
          <ul className="job-offers-list">
            {job_offers.map((offer) => (
              <li
                key={offer.id}
                className="job-offer-item"
                role="button"
                tabIndex={0}
                onClick={() => handleJobOfferClick(offer.id)}
                onKeyDown={(event) => {
                  if (event.key === 'Enter' || event.key === ' ') {
                    event.preventDefault();
                    handleJobOfferClick(offer.id);
                  }
                }}
              >
                <h2>{offer.title}</h2>
                <p>{offer.description}</p>
                <p>{offer.location}</p>
                <p>{offer.salary_min}</p>
                <p>{offer.education}</p>
                <p>{offer.job_type}</p>
                <p>{offer.key_indicators}</p>
                <span>Solicitudes: {offer.applicationsCount}</span>
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
