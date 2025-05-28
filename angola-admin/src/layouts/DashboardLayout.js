import React from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

// Importez des icônes si nécessaire
// import DashboardIcon from '@mui/icons-material/Dashboard';
// etc.

const DashboardLayout = ({ children }) => {
  const { user, logout } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const menuItems = [
    { path: '/dashboard', label: 'Tableau de bord', icon: 'Dashboard' },
    { path: '/users', label: 'Utilisateurs', icon: 'Person' },
    { path: '/providers', label: 'Prestataires', icon: 'Handyman' },
    { path: '/disputes', label: 'Litiges', icon: 'Gavel' },
    { path: '/reports', label: 'Signalements', icon: 'Flag' },
    { path: '/categories', label: 'Catégories', icon: 'Category' },
    { path: '/settings', label: 'Paramètres', icon: 'Settings' },
  ];

  return (
    <div className="flex h-screen bg-background">
      {/* Sidebar */}
      <div className="w-64 bg-white shadow-lg">
        <div className="flex h-16 items-center justify-center border-b">
          <h1 className="text-xl font-bold text-primary">Angola Admin</h1>
        </div>
        <nav className="mt-6">
          <ul>
            {menuItems.map((item) => (
              <li key={item.path}>
                <Link
                  to={item.path}
                  className={`flex items-center px-6 py-3 text-sm font-medium ${
                    location.pathname === item.path
                      ? 'bg-primary/10 text-primary'
                      : 'text-text-secondary hover:bg-gray-50'
                  }`}
                >
                  {/* Vous pouvez ajouter des icônes ici si nécessaire */}
                  <span>{item.label}</span>
                </Link>
              </li>
            ))}
          </ul>
        </nav>
      </div>

      {/* Main content */}
      <div className="flex flex-1 flex-col overflow-hidden">
        {/* Header */}
        <header className="flex h-16 items-center justify-between border-b bg-white px-6">
          <div></div>
          <div className="flex items-center">
            {user && (
              <div className="flex items-center">
                <span className="mr-2 text-text-secondary">
                  {user.first_name ? `${user.first_name} ${user.last_name}` : user.username}
                </span>
                <button
                  onClick={handleLogout}
                  className="rounded-md px-3 py-1 text-text-secondary hover:bg-gray-100"
                >
                  Déconnexion
                </button>
              </div>
            )}
          </div>
        </header>

        {/* Page content */}
        <main className="flex-1 overflow-y-auto p-6">
          {children}
        </main>
      </div>
    </div>
  );
};

export default DashboardLayout;