import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';

// Layout
import DashboardLayout from './layouts/DashboardLayout';

// Pages
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Users from './pages/Users';
import { Disputes, DisputeDetail } from './pages/Disputes';
import Providers from './pages/Providers';
import Categories from './pages/Categories';
import Reports from './pages/Reports';
import Settings from './pages/Settings';
import NotFound from './pages/NotFound';
import Projects from './pages/Projects';
import ProjectDetail from './pages/ProjectDetail';
import NotificationsPage from './pages/NotificationsPage'
// Pages Conversations (nouvelles)
import ConversationsList from './pages/ConversationsList';
import ConversationDetail from './pages/ConversationDetail';
import UserVerification from './pages/UserVerification';

// Route protégée SANS layout automatique
const ProtectedRoute = ({ children }) => {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <div className="flex h-screen items-center justify-center">
        <div className="text-center">
          <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-blue-600"></div>
          <p className="mt-2 text-gray-600">Chargement...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  // Retourne seulement les enfants sans layout automatique
  return children;
};

// Wrapper pour les pages qui ONT BESOIN du DashboardLayout
const ProtectedPageWithLayout = ({ children }) => {
  return (
    <ProtectedRoute>
      <DashboardLayout>
        {children}
      </DashboardLayout>
    </ProtectedRoute>
  );
};

function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          {/* Route publique (sans layout) */}
          <Route path="/login" element={<Login />} />

          {/* Routes protégées - Pages qui ont DÉJÀ leur propre layout */}
          <Route
            path="/"
            element={
              <ProtectedRoute>
                <Navigate to="/dashboard" replace />
              </ProtectedRoute>
            }
          />
          
          <Route
            path="/dashboard"
            element={
              <ProtectedRoute>
                <Dashboard />
              </ProtectedRoute>
            }
          />
          
          <Route
            path="/users"
            element={
              <ProtectedRoute>
                <Users />
              </ProtectedRoute>
            }
          />
          <Route 
              path="/user-verification" 
              element={
                <ProtectedRoute>
                  <UserVerification />
                </ProtectedRoute>
              } 
            />
          <Route
            path="/providers"
            element={
              <ProtectedRoute>
                <Providers />
              </ProtectedRoute>
            }
          />

          <Route
            path="/projects"
            element={
              <ProtectedRoute>
                <Projects />
              </ProtectedRoute>
            }
          />
          
          <Route
            path="/projects/:id"
            element={
              <ProtectedRoute>
                <ProjectDetail />
              </ProtectedRoute>
            }
          />

          <Route
            path="/disputes"
            element={
              <ProtectedRoute>
                <Disputes />
              </ProtectedRoute>
            }
          />
          
          <Route
            path="/disputes/:id"
            element={
              <ProtectedRoute>
                <DisputeDetail />
              </ProtectedRoute>
            }
          />
          
          <Route
            path="/reports"
            element={
              <ProtectedRoute>
                <Reports />
              </ProtectedRoute>
            }
          />
          
          <Route
            path="/categories"
            element={
              <ProtectedRoute>
                <Categories />
              </ProtectedRoute>
            }
          />
          
          <Route
            path="/settings"
            element={
              <ProtectedRoute>
                <Settings />
              </ProtectedRoute>
            }
          />

          {/* Routes Conversations - AVEC layout explicite car elles n'en ont pas */}
          <Route
            path="/conversations"
            element={
              <ProtectedPageWithLayout>
                <ConversationsList />
              </ProtectedPageWithLayout>
            }
          />
          <Route
            path="/notifications"
            element={
              <ProtectedPageWithLayout>
                <NotificationsPage />
              </ProtectedPageWithLayout>
            }
          />
          <Route
            path="/conversations/:conversationId"
            element={
              <ProtectedPageWithLayout>
                <ConversationDetail />
              </ProtectedPageWithLayout>
            }
          />

          {/* Route 404 */}
          <Route path="*" element={<NotFound />} />
        </Routes>
      </Router>
    </AuthProvider>
  );
}

export default App;
