import React, { useEffect, useState } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import '../../styles/components/Navbar.css';

const Navbar = () => {
    const navigate = useNavigate();
    const location = useLocation();
    const [displayName, setDisplayName] = useState('');

    useEffect(() => {
        try {
            const empresa = JSON.parse(localStorage.getItem('empresa') || 'null');
            const candidate = JSON.parse(localStorage.getItem('candidate') || 'null');
            const name = (empresa && (empresa.nombre || empresa.name)) || (candidate && candidate.name) || '';
            setDisplayName(name);
        } catch (_) {
            setDisplayName('');
        }
    }, [location.pathname]);

    const handleLogout = () => {
        try {
            localStorage.removeItem('candidate');
            localStorage.removeItem('empresa');
        } catch (_) {}
        navigate('/');
    };

    return (
        <nav className="navbar" role="navigation">
            <Link to="/CandidateDashboard" className="navbar-logo">OPTIJOB</Link>
            <ul className="navbar-links">
                <li><Link to="/">Home</Link></li>
                <li><Link to="/job-offer">Job Offers</Link></li>
                {displayName && <li aria-label="Usuario autenticado">Hola, {displayName}</li>}
                <li>
                    <button className="navbar-toggle" onClick={handleLogout} aria-label="Cerrar sesión">
                        Cerrar sesión
                    </button>
                </li>
            </ul>
        </nav>
    );
};

export default Navbar;
