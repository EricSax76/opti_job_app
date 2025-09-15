import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { login } from "../../services/authServiceCandidato"; // ✅
import "../../styles/pages/login.css";

const CandidateLogin = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();

    try {
      const data = await login({ email, password }); // ✅ Usando authService
      console.log("Login exitoso:", data);
      // Guardar solo el objeto del candidato para que DashboardCandidate pueda leer name directamente
      const candidatePayload = data?.candidato || data;
      localStorage.setItem("candidate", JSON.stringify(candidatePayload));
      navigate("/CandidateDashboard");
    } catch (err) {
      console.error(err.message);
      setError("Email o contraseña incorrectos.");
    }
  };

  return (
    <div className="login-container">
      <h2>Nombre del Candidato</h2>
      <form onSubmit={handleLogin}>
        <input
          type="email"
          placeholder="Correo electrónico"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
        />
        <input
          type="password"
          placeholder="Contraseña"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
        />
        {error && <p className="error-message">{error}</p>}
        <button type="submit">Entrar</button>
      </form>
    </div>
  );
};

export default CandidateLogin;
