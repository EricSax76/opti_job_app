import axios from 'axios';

const API_URL = 'http://localhost:5001/api/candidates'; 

export const login = async (credentials) => {
  try {
    const response = await axios.post(`${API_URL}/login`, credentials);
    return response.data;
  } catch (error) {
    console.error('Error durante login de candidato:', error);
    throw error;
  }
};
