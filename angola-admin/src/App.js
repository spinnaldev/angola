// src/App.js - Version mise à jour
import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';

// Layout
import DashboardLayout from './layouts/DashboardLayout';

// Pages existantes
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
import NotificationsPage from './pages/NotificationsPage';

// Pages Conversations
import ConversationsList from './pages/ConversationsList';
import ConversationDetail from './pages/ConversationDetail';

// 🆕 NOUVELLE PAGE: Vérification des utilisateurs
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
        <div className="App">
          <Routes>
            {/* Route publique */}
            <Route path="/login" element={<Login />} />

            {/* Routes protégées avec layout */}
            <Route 
              path="/dashboard" 
              element={
                <ProtectedPageWithLayout>
                  <Dashboard />
                </ProtectedPageWithLayout>
              } 
            />
            
            <Route 
              path="/users" 
              element={
                <ProtectedPageWithLayout>
                  <Users />
                </ProtectedPageWithLayout>
              } 
            />

            {/* 🆕 NOUVELLE ROUTE: Vérification des utilisateurs */}
            <Route 
              path="/user-verification" 
              element={
                <ProtectedPageWithLayout>
                  <UserVerification />
                </ProtectedPageWithLayout>
              } 
            />
            
            <Route 
              path="/providers" 
              element={
                <ProtectedPageWithLayout>
                  <Providers />
                </ProtectedPageWithLayout>
              } 
            />
            
            <Route 
              path="/categories" 
              element={
                <ProtectedPageWithLayout>
                  <Categories />
                </ProtectedPageWithLayout>
              } 
            />
            
            <Route 
              path="/projects" 
              element={
                <ProtectedPageWithLayout>
                  <Projects />
                </ProtectedPageWithLayout>
              } 
            />
            
            <Route 
              path="/projects/:id" 
              element={
                <ProtectedPageWithLayout>
                  <ProjectDetail />
                </ProtectedPageWithLayout>
              } 
            />
            
            <Route 
              path="/disputes" 
              element={
                <ProtectedPageWithLayout>
                  <Disputes />
                </ProtectedPageWithLayout>
              } 
            />
            
            <Route 
              path="/disputes/:id" 
              element={
                <ProtectedPageWithLayout>
                  <DisputeDetail />
                </ProtectedPageWithLayout>
              } 
            />
            
            <Route 
              path="/conversations" 
              element={
                <ProtectedPageWithLayout>
                  <ConversationsList />
                </ProtectedPageWithLayout>
              } 
            />
            
            <Route 
              path="/conversations/:id" 
              element={
                <ProtectedPageWithLayout>
                  <ConversationDetail />
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
              path="/reports" 
              element={
                <ProtectedPageWithLayout>
                  <Reports />
                </ProtectedPageWithLayout>
              } 
            />
            
            <Route 
              path="/settings" 
              element={
                <ProtectedPageWithLayout>
                  <Settings />
                </ProtectedPageWithLayout>
              } 
            />

            {/* Redirection par défaut */}
            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            
            {/* Page 404 */}
            <Route path="*" element={<NotFound />} />
          </Routes>
        </div>
      </Router>
    </AuthProvider>
  );
}

export default App;