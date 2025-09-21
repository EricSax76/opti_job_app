const API_BASE_URL = 'http://localhost:5001'; 


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


export const getJobOffers = async () => {
    return await fetchGet('/api/job_offers');
};


export const getJobOfferById = async (offerId) => {
    return await fetchGet(`/api/job_offers/${offerId}`);
};


export const createJobOffer = async (offerData) => {
    return await fetchPost('/api/job_offers', offerData);
};

export const updateJobOffer = async (offerId, offerData) => {
    return await fetchPut(`/api/job_offers/${offerId}`, offerData);
};


export const deleteJobOffer = async (offerId) => {
    return await fetchDelete(`/api/job_offers/${offerId}`);
};


export const fetchJobOffers = async (params = '') => {
    return await fetchGet(`/api/job_offers${params}`);
};
