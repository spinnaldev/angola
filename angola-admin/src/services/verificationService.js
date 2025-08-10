// ✅ CORRECTION COMPLÈTE : angola-admin/src/services/verificationService.js

// ✅ Utiliser la même logique que api.js
const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8001/api';

class VerificationService {
  constructor() {
    // ✅ CORRIGÉ : Construction d'URL cohérente avec api.js
    // Nettoyer les slashes pour éviter les doubles slashes
    const baseUrl = API_URL.endsWith('/') ? API_URL.slice(0, -1) : API_URL;
    this.baseURL = `${baseUrl}/admin/provider-verification`;
    
    // ✅ Debug pour vérifier l'URL construite
    console.log('🌐 VerificationService baseURL:', this.baseURL);
  }

  // ✅ Méthode utilitaire pour obtenir les headers d'authentification
  getAuthHeaders() {
    const token = localStorage.getItem('token');
    
    if (!token) {
      console.warn('⚠️ Aucun token trouvé dans localStorage');
      throw new Error('Token d\'authentification manquant');
    }
    
    console.log('🔑 Token trouvé pour auth headers');
    
    return {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    };
  }

  // Méthode utilitaire pour gérer les erreurs
  async handleResponse(response) {
    console.log(`📡 Réponse API: ${response.status} ${response.statusText}`);
    
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      
      console.error('❌ Erreur API:', {
        status: response.status,
        statusText: response.statusText,
        url: response.url,
        errorData
      });
      
      throw new Error(errorData.detail || errorData.message || 'Une erreur est survenue');
    }
    return response.json();
  }

  // Récupérer toutes les vérifications avec filtres
  async getVerifications(filters = {}) {
    try {
      const params = new URLSearchParams();
      
      if (filters.status) params.append('status', filters.status);
      if (filters.is_business !== undefined) params.append('is_business', filters.is_business);
      if (filters.search) params.append('search', filters.search);
      if (filters.days) params.append('days', filters.days);
      if (filters.page) params.append('page', filters.page);
      if (filters.page_size) params.append('page_size', filters.page_size);
      
      const url = `${this.baseURL}/?${params}`;
      console.log('🌐 Appel API getVerifications:', url);
      
      const response = await fetch(url, {
        headers: this.getAuthHeaders(),
      });
      
      return this.handleResponse(response);
    } catch (error) {
      console.error('Erreur lors du chargement des vérifications:', error);
      throw error;
    }
  }

  // Récupérer les vérifications en attente
  async getPendingVerifications() {
    try {
      const url = `${this.baseURL}/pending/`;
      console.log('🌐 Appel API getPendingVerifications:', url);
      
      const response = await fetch(url, {
        headers: this.getAuthHeaders(),
      });
      
      return this.handleResponse(response);
    } catch (error) {
      console.error('Erreur lors du chargement des vérifications en attente:', error);
      throw error;
    }
  }

  // Récupérer une vérification spécifique
  async getVerification(id) {
    try {
      const url = `${this.baseURL}/${id}/`;
      console.log('🌐 Appel API getVerification:', url);
      
      const response = await fetch(url, {
        headers: this.getAuthHeaders(),
      });
      
      return this.handleResponse(response);
    } catch (error) {
      console.error(`Erreur lors du chargement de la vérification ${id}:`, error);
      throw error;
    }
  }

  // Approuver une vérification
  async approve(id, adminNotes = '') {
    try {
      const url = `${this.baseURL}/${id}/approve/`;
      console.log('🌐 Appel API approve:', url);
      
      const response = await fetch(url, {
        method: 'POST',
        headers: this.getAuthHeaders(),
        body: JSON.stringify({ admin_notes: adminNotes }),
      });
      
      return this.handleResponse(response);
    } catch (error) {
      console.error(`Erreur lors de l'approbation de la vérification ${id}:`, error);
      throw error;
    }
  }

  // Rejeter une vérification
  async reject(id, rejectionReason, adminNotes = '') {
    try {
      if (!rejectionReason?.trim()) {
        throw new Error('La raison du rejet est obligatoire');
      }

      const url = `${this.baseURL}/${id}/reject/`;
      console.log('🌐 Appel API reject:', url);

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
      console.error(`Erreur lors du rejet de la vérification ${id}:`, error);
      throw error;
    }
  }

  // Approbation en lot
  async bulkApprove(verificationIds, adminNotes = '') {
    try {
      if (!Array.isArray(verificationIds) || verificationIds.length === 0) {
        throw new Error('Au moins une vérification doit être sélectionnée');
      }

      const url = `${this.baseURL}/bulk-approve/`;
      console.log('🌐 Appel API bulkApprove:', url);

      const response = await fetch(url, {
        method: 'POST',
        headers: this.getAuthHeaders(),
        body: JSON.stringify({ 
          verification_ids: verificationIds,
          admin_notes: adminNotes 
        }),
      });
      
      return this.handleResponse(response);
    } catch (error) {
      console.error('Erreur lors de l\'approbation en lot:', error);
      throw error;
    }
  }

  // Rejet en lot
  async bulkReject(verificationIds, rejectionReason, adminNotes = '') {
    try {
      if (!Array.isArray(verificationIds) || verificationIds.length === 0) {
        throw new Error('Au moins une vérification doit être sélectionnée');
      }

      if (!rejectionReason?.trim()) {
        throw new Error('La raison du rejet est obligatoire');
      }

      const url = `${this.baseURL}/bulk-reject/`;
      console.log('🌐 Appel API bulkReject:', url);

      const response = await fetch(url, {
        method: 'POST',
        headers: this.getAuthHeaders(),
        body: JSON.stringify({ 
          verification_ids: verificationIds,
          rejection_reason: rejectionReason,
          admin_notes: adminNotes 
        }),
      });
      
      return this.handleResponse(response);
    } catch (error) {
      console.error('Erreur lors du rejet en lot:', error);
      throw error;
    }
  }

  // Obtenir les statistiques
  async getStatistics() {
    try {
      const url = `${this.baseURL}/statistics/`;
      console.log('🌐 Appel API getStatistics:', url);
      
      const response = await fetch(url, {
        headers: this.getAuthHeaders(),
      });
      
      return this.handleResponse(response);
    } catch (error) {
      console.error('Erreur lors du chargement des statistiques:', error);
      throw error;
    }
  }

  // Obtenir le dashboard des vérifications
  async getDashboard() {
    try {
      // ✅ CORRIGÉ : Utiliser la même base URL
      const baseUrl = API_URL.endsWith('/') ? API_URL.slice(0, -1) : API_URL;
      const url = `${baseUrl}/dashboard/`;
      console.log('🌐 Appel API getDashboard:', url);
      
      const response = await fetch(url, {
        headers: this.getAuthHeaders(),
      });
      
      return this.handleResponse(response);
    } catch (error) {
      console.error('Erreur lors du chargement du dashboard:', error);
      throw error;
    }
  }

  // Exporter les données de vérification
  async exportVerifications(format = 'csv', filters = {}) {
    try {
      const params = new URLSearchParams();
      params.append('format', format);
      
      Object.keys(filters).forEach(key => {
        if (filters[key] !== undefined && filters[key] !== '') {
          params.append(key, filters[key]);
        }
      });

      // ✅ CORRIGÉ : Utiliser la même base URL
      const baseUrl = API_URL.endsWith('/') ? API_URL.slice(0, -1) : API_URL;
      const url = `${baseUrl}/export/?${params}`;
      console.log('🌐 Appel API exportVerifications:', url);

      const response = await fetch(url, {
        headers: this.getAuthHeaders(),
      });

      if (!response.ok) {
        throw new Error('Erreur lors de l\'export');
      }

      return response.blob();
    } catch (error) {
      console.error('Erreur lors de l\'export:', error);
      throw error;
    }
  }

  // Obtenir les rapports détaillés
  async getReports(filters = {}) {
    try {
      const params = new URLSearchParams();
      
      Object.keys(filters).forEach(key => {
        if (filters[key] !== undefined && filters[key] !== '') {
          params.append(key, filters[key]);
        }
      });

      // ✅ CORRIGÉ : Utiliser la même base URL
      const baseUrl = API_URL.endsWith('/') ? API_URL.slice(0, -1) : API_URL;
      const url = `${baseUrl}/reports/?${params}`;
      console.log('🌐 Appel API getReports:', url);

      const response = await fetch(url, {
        headers: this.getAuthHeaders(),
      });
      
      return this.handleResponse(response);
    } catch (error) {
      console.error('Erreur lors du chargement des rapports:', error);
      throw error;
    }
  }

  // Méthodes utilitaires pour le cache (optionnel)
  setCacheItem(key, data, expirationMinutes = 5) {
    const item = {
      data,
      timestamp: Date.now(),
      expiration: expirationMinutes * 60 * 1000
    };
    localStorage.setItem(`verification_cache_${key}`, JSON.stringify(item));
  }

  getCacheItem(key) {
    try {
      const item = JSON.parse(localStorage.getItem(`verification_cache_${key}`));
      
      if (!item) return null;
      
      if (Date.now() - item.timestamp > item.expiration) {
        localStorage.removeItem(`verification_cache_${key}`);
        return null;
      }
      
      return item.data;
    } catch {
      return null;
    }
  }

  clearCache() {
    const keys = Object.keys(localStorage);
    keys.forEach(key => {
      if (key.startsWith('verification_cache_')) {
        localStorage.removeItem(key);
      }
    });
  }
}

// Instance singleton du service
const verificationService = new VerificationService();

export default verificationService;