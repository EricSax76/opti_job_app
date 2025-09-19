import jwt from "jsonwebtoken"; 


export const authMiddleware = (req, res, next) => {
  try {
    
    const authHeader = req.headers["authorization"];
    const token = authHeader?.split(" ")[1]; // Extrae el token después de "Bearer"

    if (!token) {
      return res.status(401).json({ message: "No se proporcionó un token." });
    }

   
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Agregar la información del usuario al objeto `req` (puedes agregar más datos si los necesitas)
    req.user = decoded;

    // Continuar con la siguiente función middleware o endpoint
    next();
  } catch (error) {
    return res.status(401).json({
      message: "Token inválido o expirado.",
      error: error.message,
    });
  }
};
