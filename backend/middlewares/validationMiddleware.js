export const validationMiddleware = (schema) => {
    return (req, res, next) => {
        try {
            // Validar el cuerpo de la solicitud con el esquema proporcionado
            const { error } = schema.validate(req.body, { abortEarly: false });
            
            // Formatear los errores para enviarlos como respuesta
            if (error) {
                
                const errors = error.details.map((detail) => detail.message);
                return res.status(400).json({ message: 'Errores de validación', errors });
            }
            // Continuar con la siguiente función middleware o endpoint
            next(); 
        } catch (error) {
            return res.status(500).json({ message: 'Error en el proceso de validación.', error: error.message });
        }
    };
};
