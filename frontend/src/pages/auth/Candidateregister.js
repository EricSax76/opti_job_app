import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import "./register.css"

const Candidateregister = () => {
  const [candidato, setCandidato] = useState({
    nombre: "",
    apellidos: "",
    email: "",
    password: "",
  });

  const navigate = useNavigate();

  const handleChange = (e) => {
    const { name, value } = e.target;
    setCandidato({ ...candidato, [name]: value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    try {
      const response = await fetch("http://localhost:5001/api/candidates", { // Cambia la URL por la de tu backend
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(candidato),
      });
      
      if (response.ok) {
        console.log("Candidato registrado con éxito");
        navigate("/CandidateLogin"); // Redirigir solo si el registro fue exitoso
      } else {
        console.error("Error al registrar el candidato");
      }
    } catch (error) {
      console.error("Error en la solicitud:", error);
    }
  };
  

  return (
    <div className="register-container">
      <h2>Regístrate como Candidato</h2>
      <form onSubmit={handleSubmit}>
        <label>
          Nombre:
          <input
            type="text"
            name="nombre"
            value={candidato.nombre}
            onChange={handleChange}
            required
          />
        </label>
        <label>
          Apellidos:
          <input
            type="text"
            name="apellidos"
            value={candidato.apellidos}
            onChange={handleChange}
            required
          />
        </label>
        
        <label>
          Email:
          <input
            type="email"
            name="email"
            value={candidato.email}
            onChange={handleChange}
            required
          />
        </label>
        <label>
          Contraseña:
          <input
            type="password"
            name="password"
            value={candidato.password}
            onChange={handleChange}
            required
          />
        </label>
        <button type="submit" className="btn-submit">
          Registrarse
        </button>
      </form>
    </div>
  );
};

export default Candidateregister;
