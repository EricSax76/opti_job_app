import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { getJobOffers } from '../services/api';
import CreateJobOffer from '../components/CreateOffer';
import Navbar from '../components/common/Navbar.js';
import '../styles/pages/DashboardCompany.css';

const DashboardCompany = () => {
  const [jobOffers, setJobOffers] = useState([]);
  const [empresa, setEmpresa] = useState(null);
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

    const storedEmpresa = localStorage.getItem('empresa');
    if (storedEmpresa) {
      setEmpresa(JSON.parse(storedEmpresa));
    } else {
      navigate('/CompanyLogin');
    }
  }, [navigate]);

  if (!empresa) return null; // o puedes poner un loader

  return (
    <>
      <Navbar />
      <div className="dashboard-company-container">
        <header className="dashboard-header">
          <h1>Bienvenida, {empresa.nombre}</h1>
          <p>Gestiona tus ofertas y encuentra talento.</p>
        </header>

        {/* Sección para crear nuevas ofertas */}
        <section className="create-job-offer-section">
          <CreateJobOffer onOfferCreated={fetchJobOffers} />
        </section>

        {/* Sección para listar las ofertas de trabajo */}
        <section className="job-offers-section">
          <h2>Tus Ofertas de Trabajo</h2>
          {jobOffers.length > 0 ? (
            <ul className="job-offers-list">
              {jobOffers.map((offer) => (
                <li key={offer.id} className="job-offer-item">
                  <h2>{offer.title}</h2>
                  <p>{offer.description}</p>
                  <span>Solicitudes: {offer.applicationsCount}</span>
                </li>
              ))}
            </ul>
          ) : (
            <p>No hay ofertas publicadas aún. ¡Crea una nueva para comenzar!</p>
          )}
        </section>
      </div>
    </>
  );
};

export default DashboardCompany;
