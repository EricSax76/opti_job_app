import axios from 'axios';

const API_URL = 'https://http://localhost:5001'; 

export const getDashboardData = async () => {
  try {
    const response = await axios.get(`${API_URL}`);
    return response.data;
  } catch (error) {
    console.error('Error fetching dashboard data:', error);
    throw error;
  }
};

export const updateDashboard = async (dashboardData) => {
  try {
    const response = await axios.put(`${API_URL}/update`, dashboardData);
    return response.data;
  } catch (error) {
    console.error('Error updating dashboard:', error);
    throw error;
  }
};
