import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { login } from "../../services/authService";



const CompanyLogin = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();

    try {
          const data = await login({ email, password }); 
          console.log("Login exitoso:", data);
          // Guardar solo el objeto del candidato para que DashboardCandidate pueda leer name directamente
          const companyPayload = data?.company || data;
          localStorage.setItem("company", JSON.stringify(companyPayload));
          navigate("/DashboardCompany");
        } catch (err) {
          console.error(err.message);
          setError("Email o contraseña incorrectos.");
        }
      };

  return (
    <div className="auth-container">
      <h2>Login de Empresa</h2>
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

export default CompanyLogin;
