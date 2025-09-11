import pkg from 'pg'; // Importa el módulo completo como un objeto
const { Pool } = pkg; // Extrae Pool del objeto importado

const pool = new Pool({
    user: 'ericmoscoso',
    host: 'localhost',
    database: 'concertador_db',
    password: 'Megustaelsaxo.76',
    port: 5432, 
});

const query = async (text, params) => {
    const client = await pool.connect();
    try {
        const res = await client.query(text, params);
        return res;
    } catch (err) {
        console.error('Database query error:', err);
        throw err;
    } finally {
        client.release();
    }
};

export default {
    query,
};
