import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import DashboardCompany from './pages/DashboardCompany.js';
import CandidateLogin from "./pages/auth/CandidateLogin.js"
import JobOfferPage from './pages/JobOfferPage.js';
import LandingPage from "./pages/LandingPage.js";
import CompanyLogin from "./pages/auth/CompanyLogin.js";
import Companyregister from "./pages/auth/Companyregister.js";
import Candidateregister from "./pages/auth/Candidateregister.js";
import CandidateDashboard from "./pages/DashboardCandidate.js";
import { AuthProvider } from './context/AuthContext'; 


function App() {
    return (
        <AuthProvider>
            <Router>
                <Routes>
                    <Route path="/" element={<LandingPage />} />
                    <Route path="/JobOfferPage" element={<JobOfferPage />} />
                    <Route path="Candidateregister" element={<Candidateregister />} />
                    <Route path="/CandidateLogin" element={<CandidateLogin />} />
                    <Route path='/CandidateDashboard' element={<CandidateDashboard />} />
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





