// JobOfferFilters.js - Página principal con filtros

import React, { useState } from 'react';
import '../../styles/features/candidate/JobOfferFilters.css'; // Archivo de estilos para los filtros

const JobOfferFilters = ({ onFilter }) => {
    const [filters, setFilters] = useState({
        location: '',
        jobType: '',
        experienceLevel: '',
    });

    const handleInputChange = (e) => {
        const { name, value } = e.target;
        setFilters({ ...filters, [name]: value });
    };

    const applyFilters = () => {
        onFilter(filters);
    };

    return (
        <div className="filters-container">
            <h2>Filtrar Ofertas de Trabajo</h2>
            <div className="filter-group">
                <label htmlFor="location">Ubicación:</label>
                <input
                    type="text"
                    id="location"
                    name="location"
                    value={filters.location}
                    onChange={handleInputChange}
                />
            </div>
            <div className="filter-group">
                <label htmlFor="jobType">Tipo de Trabajo:</label>
                <select
                    id="jobType"
                    name="jobType"
                    value={filters.jobType}
                    onChange={handleInputChange}
                >
                    <option value="">Selecciona</option>
                    <option value="full-time">Tiempo Completo</option>
                    <option value="part-time">Medio Tiempo</option>
                    <option value="freelance">Freelance</option>
                </select>
            </div>
            <div className="filter-group">
                <label htmlFor="experienceLevel">Nivel de Experiencia:</label>
                <select
                    id="experienceLevel"
                    name="experienceLevel"
                    value={filters.experienceLevel}
                    onChange={handleInputChange}
                >
                    <option value="">Selecciona</option>
                    <option value="junior">Junior</option>
                    <option value="mid">Intermedio</option>
                    <option value="senior">Senior</option>
                </select>
            </div>
            <button className="apply-filters-button" onClick={applyFilters}>Aplicar Filtros</button>
        </div>
    );
};

export default JobOfferFilters;
