const API_BASE_URL = 'http://localhost:5001'; // Cambia esta URL según tu configuración

// Función genérica para solicitudes GET
const fetchGet = async (endpoint, data) => {
    try {
        const response = await fetch(`${API_BASE_URL}${endpoint}`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(data),
        });
        if (!response.ok) {
            throw new Error(`Error: ${response.status} - ${response.statusText}`);
        }
        return await response.json();
    } catch (error) {
        console.error('Fetch GET error:', error);
        throw error;
    }
};


// Función genérica para solicitudes POST
const fetchPost = async (endpoint, data) => {
    try {
        const response = await fetch(`${API_BASE_URL}${endpoint}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(data),
        });
        if (!response.ok) {
            throw new Error(`Error: ${response.status} - ${response.statusText}`);
        }
        return await response.json();
    } catch (error) {
        console.error('Fetch POST error:', error);
        throw error;
    }
};

// Función genérica para solicitudes PUT
const fetchPut = async (endpoint, data) => {
    try {
        const response = await fetch(`${API_BASE_URL}${endpoint}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(data),
        });
        if (!response.ok) {
            throw new Error(`Error: ${response.status} - ${response.statusText}`);
        }
        return await response.json();
    } catch (error) {
        console.error('Fetch PUT error:', error);
        throw error;
    }
};

// Función genérica para solicitudes DELETE
const fetchDelete = async (endpoint) => {
    try {
        const response = await fetch(`${API_BASE_URL}${endpoint}`, {
            method: 'DELETE',
        });
        if (!response.ok) {
            throw new Error(`Error: ${response.status} - ${response.statusText}`);
        }
        return await response.json();
    } catch (error) {
        console.error('Fetch DELETE error:', error);
        throw error;
    }
};

// Función para obtener ofertas de trabajo
export const getJobOffers = async () => {
    return await fetchGet('/api/job_offers');
};

// Función para obtener los detalles de una oferta específica
export const getJobOfferById = async (offerId) => {
    return await fetchGet(`/api/job_offers/${offerId}`);
};

// Función para crear una oferta de trabajo
export const createJobOffer = async (offerData) => {
    return await fetchPost('/api/job_offers', offerData);
};

// Función para actualizar una oferta de trabajo
export const updateJobOffer = async (offerId, offerData) => {
    return await fetchPut(`/api/job_offers/${offerId}`, offerData);
};

// Función para eliminar una oferta de trabajo
export const deleteJobOffer = async (offerId) => {
    return await fetchDelete(`/api/job_offers/${offerId}`);
};

// Función para obtener ofertas con parámetros opcionales
export const fetchJobOffers = async (params = '') => {
    return await fetchGet(`/api/job_offers${params}`);
};
