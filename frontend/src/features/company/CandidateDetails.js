// CandidateDetails.js - Vista detallada de un candidato

import React from 'react';
import '../../styles/features/company/CandidateDetails.css'; // Archivo de estilos para CandidateDetails

const CandidateDetails = ({ candidate }) => {
    return (
        <div className="candidate-details-container">
            <h2>Detalles del Candidato</h2>
            <div className="candidate-info">
                <p><strong>Nombre:</strong> {candidate.name}</p>
                <p><strong>Email:</strong> {candidate.email}</p>
                <p><strong>Experiencia:</strong> {candidate.experience} años</p>
                <p><strong>Habilidades:</strong> {candidate.skills.join(', ')}</p>
            </div>
            <button className="interview-button">Programar Entrevista</button>
        </div>
    );
};

export default CandidateDetails;
