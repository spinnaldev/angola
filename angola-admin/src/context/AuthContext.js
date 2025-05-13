import React, { createContext, useState, useEffect, useContext } from 'react'; 
import { Navigate } from 'react-router-dom';
import { authService } from '../services/api';  

const AuthContext = createContext(null);  

export const AuthProvider = ({ children }) => {   
  const [user, setUser] = useState(null);   
  const [loading, setLoading] = useState(true);    

  useEffect(() => {     
    // Vérifier si l'utilisateur est déjà connecté     
    const currentUser = authService.getCurrentUser();     
    setUser(currentUser);     
    setLoading(false);   
  }, []);    

  const login = async (credentials) => {     
    try {       
      const data = await authService.login(credentials);       
      setUser(data.user);       
      return { success: true, user: data.user };     
    } catch (error) {       
      return {          
        success: false,          
        message: error.response?.data?.detail || 'Une erreur est survenue lors de la connexion'       
      };     
    }   
  };    

  const logout = () => {     
    authService.logout();     
    setUser(null);   
  };    

  const isAdmin = () => {     
    return user && user.role === 'admin';   
  };    

  return (     
    <AuthContext.Provider value={{ user, login, logout, loading, isAdmin }}>       
      {children}     
    </AuthContext.Provider>   
  ); 
};  

// Hook personnalisé pour utiliser le contexte d'authentification 
export const useAuth = () => {   
  const context = useContext(AuthContext);   
  if (!context) {     
    throw new Error('useAuth doit être utilisé à l\'intérieur d\'un AuthProvider');   
  }   
  return context; 
};  

// Composant HOC pour les routes protégées - VERSION CORRIGÉE
export const withAuth = (Component) => {   
  // Donnez un nom à cette fonction pour faciliter le débogage
  function WithAuthComponent(props) {     
    const { user, loading } = useAuth();     
         
    if (loading) {       
      return (
        <div className="flex h-screen items-center justify-center">
          <div className="text-center">
            <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-primary"></div>
            <p className="mt-2 text-text-secondary">Chargement...</p>
          </div>
        </div>
      );     
    }     
         
    if (!user) {       
      return <Navigate to="/login" replace />;     
    }     
         
    return <Component {...props} />;   
  }

  // Ajouter un displayName pour le débogage
  WithAuthComponent.displayName = `withAuth(${Component.displayName || Component.name || 'Component'})`;
  
  return WithAuthComponent;
};