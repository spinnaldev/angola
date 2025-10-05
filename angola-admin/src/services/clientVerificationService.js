// angola-admin/src/services/clientVerificationService.js
// ⚠️ CRÉER CE NOUVEAU FICHIER

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8001/api';

class ClientVerificationService {
  constructor() {
    const baseUrl = API_URL.endsWith('/') ? API_URL.slice(0, -1) : API_URL;
    this.baseURL = `${baseUrl}/admin/client-verification`;
    console.log('🌐 ClientVerificationService baseURL:', this.baseURL);
  }

  getAuthHeaders() {
    const token = localStorage.getItem('token');
    if (!token) {
      throw new Error('Token d\'authentification manquant');
    }
    return {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    };
  }

  async handleResponse(response) {
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.detail || errorData.message || 'Une erreur est survenue');
    }
    return response.json();
  }

  async getVerifications(filters = {}) {
    try {
      const params = new URLSearchParams();
      if (filters.status) params.append('verification_status', filters.status);
      if (filters.document_type) params.append('document_type', filters.document_type);
      if (filters.search) params.append('search', filters.search);
      
      const url = `${this.baseURL}/?${params}`;
      const response = await fetch(url, {
        headers: this.getAuthHeaders(),
      });
      
      return this.handleResponse(response);
    } catch (error) {
      console.error('Erreur getVerifications:', error);
      throw error;
    }
  }

  async getStatistics() {
    try {
      const url = `${this.baseURL}/stats/`;
      const response = await fetch(url, {
        headers: this.getAuthHeaders(),
      });
      
      return this.handleResponse(response);
    } catch (error) {
      console.error('Erreur getStatistics:', error);
      throw error;
    }
  }

  async getVerification(id) {
    try {
      const url = `${this.baseURL}/${id}/`;
      const response = await fetch(url, {
        headers: this.getAuthHeaders(),
      });
      
      return this.handleResponse(response);
    } catch (error) {
      console.error('Erreur getVerification:', error);
      throw error;
    }
  }

  async approve(id, adminNotes = '') {
    try {
      const url = `${this.baseURL}/${id}/approve/`;
      const response = await fetch(url, {
        method: 'POST',
        headers: this.getAuthHeaders(),
        body: JSON.stringify({ admin_notes: adminNotes }),
      });
      
      return this.handleResponse(response);
    } catch (error) {
      console.error('Erreur approve:', error);
      throw error;
    }
  }

  async reject(id, rejectionReason, adminNotes = '') {
    try {
      if (!rejectionReason?.trim()) {
        throw new Error('La raison du rejet est obligatoire');
      }

      const url = `${this.baseURL}/${id}/reject/`;
      const response = await fetch(url, {
        method: 'POST',
        headers: this.getAuthHeaders(),
        body: JSON.stringify({ 
          rejection_reason: rejectionReason,
          admin_notes: adminNotes 
        }),
      });
      
      return this.handleResponse(response);
    } catch (error) {
      console.error('Erreur reject:', error);
      throw error;
    }
  }

  async reset(id) {
    try {
      const url = `${this.baseURL}/${id}/reset/`;
      const response = await fetch(url, {
        method: 'POST',
        headers: this.getAuthHeaders(),
      });
      
      return this.handleResponse(response);
    } catch (error) {
      console.error('Erreur reset:', error);
      throw error;
    }
  }
}

const clientVerificationService = new ClientVerificationService();
export default clientVerificationService;