// Dans src/pages/Login.js

import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const Login = () => {
  const [credentials, setCredentials] = useState({
    email: '',
    password: '',
  });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleChange = (e) => {
    const { name, value } = e.target;
    setCredentials((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const result = await login(credentials);
      if (result.success) {
        navigate('/dashboard');
      } else {
        setError(result.message);
      }
    } catch (err) {
      setError('Une erreur est survenue. Veuillez réessayer.');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-background py-12 px-4 sm:px-6 lg:px-8">
      <div className="w-full max-w-md">
        <div className="card shadow-xl bg-white rounded-xl p-8 border border-gray-200">
          <div className="text-center">
            <h1 className="text-3xl font-bold text-primary mb-2">Angola Admin</h1>
            <h2 className="text-xl text-text-secondary mb-6">Connectez-vous à votre compte</h2>
          </div>
          
          {error && (
            <div className="rounded-md bg-error/10 p-4 mb-6">
              <div className="flex">
                <div className="ml-3">
                  <h3 className="text-sm font-medium text-error">Erreur</h3>
                  <div className="mt-2 text-sm text-error">{error}</div>
                </div>
              </div>
            </div>
          )}

          <form className="space-y-6" onSubmit={handleSubmit}>
            <div className="space-y-4">
              <div>
                <label htmlFor="email" className="label block text-text-primary font-medium mb-2">
                  Adresse e-mail
                </label>
                <input
                  id="email"
                  name="email"
                  type="email"
                  autoComplete="email"
                  required
                  className="input w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent transition-all"
                  placeholder="email@example.com"
                  value={credentials.email}
                  onChange={handleChange}
                />
              </div>
              <div>
                <label htmlFor="password" className="label block text-text-primary font-medium mb-2">
                  Mot de passe
                </label>
                <input
                  id="password"
                  name="password"
                  type="password"
                  autoComplete="current-password"
                  required
                  className="input w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent transition-all"
                  placeholder="••••••••"
                  value={credentials.password}
                  onChange={handleChange}
                />
              </div>
            </div>

            <div className="flex items-center justify-between">
              <div className="flex items-center">
                <input
                  id="remember-me"
                  name="remember-me"
                  type="checkbox"
                  className="h-4 w-4 rounded border-gray-300 text-primary focus:ring-primary"
                />
                <label htmlFor="remember-me" className="ml-2 block text-sm text-text-secondary">
                  Se souvenir de moi
                </label>
              </div>

              <div className="text-sm">
                <a href="#" className="font-medium text-primary hover:text-primary-dark">
                  Mot de passe oublié?
                </a>
              </div>
            </div>

            <div>
              <button
                type="submit"
                className="btn btn-primary w-full py-3 bg-primary hover:bg-primary-dark text-white font-semibold rounded-lg transition-colors"
                disabled={loading}
              >
                {loading ? 'Chargement...' : 'Se connecter'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default Login;