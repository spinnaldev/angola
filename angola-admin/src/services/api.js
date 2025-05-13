import axios from 'axios';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8001/api';

// Créer une instance axios
const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Intercepteur pour ajouter le token d'autorisation à chaque requête
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Intercepteur pour gérer les erreurs d'authentification
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      // Si le token est expiré ou invalide, déconnectez l'utilisateur
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Services d'API
const authService = {
  login: async (credentials) => {
    const response = await api.post('/auth/login/', credentials);
    if (response.data.access) {
      localStorage.setItem('token', response.data.access);
      localStorage.setItem('user', JSON.stringify(response.data.user));
    }
    return response.data;
  },
  
  logout: () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
  },
  
  getCurrentUser: () => {
    const user = localStorage.getItem('user');
    return user ? JSON.parse(user) : null;
  }
};

const userService = {
  getAll: async (page = 1, limit = 10) => {
    return api.get(`/users/?page=${page}&page_size=${limit}`);
  },
  
  getById: async (id) => {
    return api.get(`/users/${id}/`);
  },
  
  update: async (id, data) => {
    return api.put(`/users/${id}/`, data);
  },
  
  delete: async (id) => {
    return api.delete(`/users/${id}/`);
  }
};

const providerService = {
  getAll: async (page = 1, limit = 10) => {
    return api.get(`/providers/?page=${page}&page_size=${limit}`);
  },
  
  getById: async (id) => {
    return api.get(`/providers/${id}/`);
  },
  
  verify: async (id) => {
    return api.put(`/providers/${id}/`, { is_verified: true });
  },
  
  unverify: async (id) => {
    return api.put(`/providers/${id}/`, { is_verified: false });
  }
};

const disputeService = {
  getAll: async (page = 1, limit = 10) => {
    return api.get(`/disputes/?page=${page}&page_size=${limit}`);
  },
  
  getById: async (id) => {
    return api.get(`/disputes/${id}/`);
  },
  
  updateStatus: async (id, status, resolution_note) => {
    return api.post(`/disputes/${id}/update_status/`, { status, resolution_note });
  }
};

const reportService = {
  getAll: async (page = 1, limit = 10) => {
    return api.get(`/reports/?page=${page}&page_size=${limit}`);
  },
  
  getById: async (id) => {
    return api.get(`/reports/${id}/`);
  },
  
  updateStatus: async (id, status, admin_notes) => {
    return api.post(`/reports/${id}/update_status/`, { status, admin_notes });
  }
};

const dashboardService = {
  getStats: async () => {
    return api.get('/dashboard/stats/');
  }
};

export {
  api,
  authService,
  userService,
  providerService,
  disputeService,
  reportService,
  dashboardService
};