import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import DashboardCompany from './pages/DashboardCompany.js';
import CandidateLogin from "./pages/auth/CandidateLogin.js"
import JobOfferPage from './pages/JobOfferPage';
import LandingPage from "./pages/LandingPage";
import CompanyLogin from "./pages/auth/CompanyLogin";
import Companyregister from "./pages/auth/Companyregister";
import Candidateregister from "./pages/auth/Candidateregister.js";
import CandidateDashboard from "./pages/DashboardCandidate.js";
import { AuthProvider } from './context/AuthContext'; // Asegúrate de importar el AuthProvider



function App() {
    return (
        <AuthProvider>
            <Router>
                <Routes>
                    <Route path="/" element={<LandingPage />} />
                    <Route path="Candidateregister" element={<Candidateregister />} />
                    <Route path="/CandidateLogin" element={<CandidateLogin />} />
                    <Route path='/CandidateDashboard' element={<CandidateDashboard />} />
                    <Route path="/job-offer" element={<JobOfferPage />} />
                    <Route path="Companyregister" element={<Companyregister />} />
                    <Route path="/CompanyLogin" element={<CompanyLogin />} />
                    <Route path="/DashboardCompany" element={<DashboardCompany />} />
                    <Route path="/job-offer" element={<JobOfferPage />} />
                    
                    
                </Routes>
            </Router>
        </AuthProvider>
    );
}

export default App;





