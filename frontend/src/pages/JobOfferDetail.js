import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { getJobOfferById } from '../services/api';
import '../styles/pages/JobOfferPage.css';

const JobOfferDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [offer, setOffer] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!id) {
      setError('Identificador de oferta no válido.');
      setIsLoading(false);
      return;
    }

    const loadOffer = async () => {
      try {
        const data = await getJobOfferById(id);
        if (!data) {
          setError('No se encontró la oferta solicitada.');
          return;
        }
        setOffer(data);
      } catch (err) {
        console.error('Error al cargar la oferta:', err);
        setError('No se pudo cargar la oferta. Inténtalo nuevamente.');
      } finally {
        setIsLoading(false);
      }
    };

    loadOffer();
  }, [id]);

  if (isLoading) {
    return <div className="job-offer-page"><p>Cargando oferta...</p></div>;
  }

  if (error) {
    return (
      <div className="job-offer-page">
        <p className="error-message">{error}</p>
        <button className="apply-button" type="button" onClick={() => navigate(-1)}>
          Volver
        </button>
      </div>
    );
  }

  return (
    <div className="job-offer-page">
      <header className="job-offer-header">
        <h1>{offer.title}</h1>
        <p>{offer.location}</p>
      </header>
      <main className="job-offer-card">
        <p>{offer.description}</p>
        <p><strong>Jornada</strong> {offer.job_type}</p>
        <p><strong>Titulación requerida:</strong> {offer.education}</p>
        {offer.salary_min && (
          <p>
            <strong>Salario</strong> {offer.salary_min}
            {offer.salary_max ? ` - ${offer.salary_max}` : ''}
          </p>
        )}
        <button className="apply-button" type="button">
          Postularme
        </button>
        <button className="apply-button" type="button" onClick={() => navigate(-1)}>
          Volver
        </button>
      </main>
    </div>
  );
};

export default JobOfferDetail;
