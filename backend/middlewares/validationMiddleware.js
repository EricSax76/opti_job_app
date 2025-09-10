export const validationMiddleware = (schema) => {
    return (req, res, next) => {
        try {
            // Validar el cuerpo de la solicitud con el esquema proporcionado
            const { error } = schema.validate(req.body, { abortEarly: false });

            if (error) {
                // Formatear los errores para enviarlos como respuesta
                const errors = error.details.map((detail) => detail.message);
                return res.status(400).json({ message: 'Errores de validación', errors });
            }

            next(); // Continuar con la siguiente función middleware o endpoint
        } catch (error) {
            return res.status(500).json({ message: 'Error en el proceso de validación.', error: error.message });
        }
    };
};
