import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import DashboardCompany from './pages/DashboardCompany.js';
import CandidateLogin from "./pages/auth/CandidateLogin.js";
import JobOfferPage from './pages/JobOfferPage.js';
import JobOfferDetail from './pages/JobOfferDetail.js';
import LandingPage from "./pages/LandingPage.js";
import CompanyLogin from "./pages/auth/CompanyLogin.js";
import Companyregister from "./pages/auth/Companyregister.js";
import Candidateregister from "./pages/auth/Candidateregister.js";
import CandidateDashboard from "./pages/DashboardCandidate.js";
import Navbar from './components/common/Navbar.js';



function App() {
    return (
        <Router>
            <Navbar />
            <Routes>
                <Route path="/" element={<LandingPage />} />
                <Route path="/job-offer" element={<JobOfferPage />} />
                <Route path="/job-offer/:id" element={<JobOfferDetail />} />
                <Route path="/candidateregister" element={<Candidateregister />} />
                <Route path="/CandidateLogin" element={<CandidateLogin />} />
                <Route path="/CandidateDashboard" element={<CandidateDashboard />} />
                <Route path="/companyregister" element={<Companyregister />} />
                <Route path="/CompanyLogin" element={<CompanyLogin />} />
                <Route path="/DashboardCompany" element={<DashboardCompany />} />
                <Route path="/dashboard-company" element={<DashboardCompany />} />
            </Routes>
        </Router>
    );
}

export default App;


