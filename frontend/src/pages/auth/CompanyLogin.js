import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { login } from "../../services/authService";
import "../../styles/pages/login.css"

const CompanyLogin = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();

    try {
      const data = await login({ email, password }); // ✅ Usando authService
      console.log("Login exitoso:", data);
      const empresa = data?.empresa || data;
      // Guardar solo campos necesarios y no sensibles
      localStorage.setItem("empresa", JSON.stringify({ id: empresa.id, nombre: empresa.nombre, email: empresa.email }));
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
