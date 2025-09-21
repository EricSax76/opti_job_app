import axios from 'axios';

const API_URL = 'http://localhost:5001/api/filter_activity'; // Reemplaza con tu URL base

export const getFilters = async () => {
  try {
    const response = await axios.get(`${API_URL}`);
    return response.data;
  } catch (error) {
    console.error('Error fetching filters:', error);
    throw error;
  }
};

export const applyFilter = async (filterData) => {
  try {
    const response = await axios.post(`${API_URL}/apply`, filterData);
    return response.data;
  } catch (error) {
    console.error('Error applying filter:', error);
    throw error;
  }
};
