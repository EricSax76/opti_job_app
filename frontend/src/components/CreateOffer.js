import React, { useState } from 'react';
import axios from 'axios';
import '../styles/CreateOffer.css'; // Asegúrate de tener este archivo CSS para los estilos

const CreateOffer = () => {
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    user_id: '', // ID del usuario que crea la oferta
    location: '',
    salary_min: '',
    education: '',
    job_type: '',
  });

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({ ...formData, [name]: value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const response = await axios.post('http://localhost:5001/api/job_offers', formData); // URL del backend
      if (response.status === 201) {
        alert('Oferta creada exitosamente');
        // Limpia el formulario
        setFormData({
          title: '',
          description: '',
          user_id: '',
          location: '',
          salary_min: '',
          salary_max: '',
          education: '',
          job_type: '',
        });
      } else {
        alert('Error inesperado al crear la oferta');
      }
    } catch (error) {
      console.error('Error al crear la oferta:', error);
      alert('Hubo un problema al crear la oferta. Revisa los detalles e inténtalo nuevamente.');
    }
  };

  return (
    <form onSubmit={handleSubmit} className="create-offer-form">
      <h2>Crear Oferta de Trabajo</h2>
      <label>
        Título:
        <input
          type="text"
          name="title"
          value={formData.title}
          onChange={handleChange}
          placeholder="Título de la oferta"
          required
        />
      </label>
      <label>
        Descripción:
        <textarea
          name="description"
          value={formData.description}
          onChange={handleChange}
          placeholder="Descripción de la oferta"
          required
        />
      </label>
      <label>
        ID del Usuario:
        <input
          type="number"
          name="user_id"
          value={formData.user_id}
          onChange={handleChange}
          placeholder="ID del usuario creador"
          required
        />
      </label>
      <label>
        Ubicación:
        <input
          type="text"
          name="location"
          value={formData.location}
          onChange={handleChange}
          placeholder="Ubicación de la oferta"
        />
      </label>
      <label>
        Salario Mínimo:
        <input
          type="number"
          name="salary_min"
          value={formData.salary_min}
          onChange={handleChange}
          placeholder="Salario mínimo"
        />
        <input
          type="number"
          name="salary_max"
          value={formData.salary_max}
          onChange={handleChange}
          placeholder="Salario máximo"
        />
      </label>
      <label>
        Educación Requerida:
        <input
          type="text"
          name="education"
          value={formData.education}
          onChange={handleChange}
          placeholder="Educación requerida"
        />
      </label>
      <label>
        Tipo de Trabajo:
        <select
          name="job_type"
          value={formData.job_type}
          onChange={handleChange}
        >
          <option value="">Seleccionar</option>
          <option value="Full-time">Full-time</option>
          <option value="Part-time">Part-time</option>
          <option value="Contrato">Contrato</option>
        </select>
      </label>
      <button type="submit">Crear Oferta</button>
    </form>
  );
};

export default CreateOffer;

