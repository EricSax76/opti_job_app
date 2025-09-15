// OfferList.js - Lista de ofertas filtradas

import React from 'react';
import '../../styles/features/candidate/OfferList.css'; // Archivo de estilos para OfferList

const OfferList = ({ offers }) => {
    return (
        <div className="offer-list-container">
            <h2>Lista de Ofertas de Trabajo</h2>
            {offers.length > 0 ? (
                <ul className="offer-list">
                    {offers.map((offer) => (
                        <li key={offer.id} className="offer-item">
                            <h3>{offer.title}</h3>
                            <p><strong>Ubicación:</strong> {offer.location}</p>
                            <p><strong>Tipo:</strong> {offer.jobType}</p>
                            <p><strong>Experiencia:</strong> {offer.experienceLevel}</p>
                            <button className="apply-button">Aplicar</button>
                        </li>
                    ))}
                </ul>
            ) : (
                <p>No hay ofertas disponibles con los filtros seleccionados.</p>
            )}
        </div>
    );
};

export default OfferList;
