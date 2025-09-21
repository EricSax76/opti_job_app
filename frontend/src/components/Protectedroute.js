import { Navigate } from "react-router-dom";

const ProtectedRoute = ({ children }) => {
  const token = localStorage.getItem("token"); // Verifica si hay un token almacenado

  if (!token) {
    return <Navigate to="/login" />; // Redirige al login si no hay token
  }

  return children; // Permite el acceso si hay token
};

export default ProtectedRoute;
