// Dashboard.js - Dashboard de empresas

import React from 'react';
import '../../styles/features/company/Dashboard.css'; // Archivo de estilos para el Dashboard

const Dashboard = () => {
    return (
        <div className="dashboard-container">
            <h1>Bienvenido al Dashboard de Empresas</h1>
            <p>Aquí podrás gestionar tus ofertas de trabajo, revisar candidatos y organizar entrevistas.</p>
            <div className="dashboard-actions">
                <button className="dashboard-button">Crear nueva oferta</button>
                <button className="dashboard-button">Ver candidatos</button>
                <button className="dashboard-button">Configurar entrevistas</button>
            </div>
        </div>
    );
};

export default Dashboard;
