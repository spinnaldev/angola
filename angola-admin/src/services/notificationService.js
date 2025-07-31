// notificationService.js
import { api } from './api';

export const notificationService = {
  // Récupérer toutes les notifications (admin)
  getAllNotifications: async (params = {}) => {
    const queryString = new URLSearchParams(params).toString();
    const response = await api.get(`/admin/notifications/?${queryString}`);
    return response.data;
  },

  // Récupérer les notifications avec pagination
  getNotifications: async (params = {}) => {
    const queryString = new URLSearchParams(params).toString();
    const response = await api.get(`/notifications/?${queryString}`);
    return response.data;
  },

  // Obtenir une notification spécifique
  getNotification: async (notificationId) => {
    const response = await api.get(`/notifications/${notificationId}/`);
    return response.data;
  },

  // Créer une nouvelle notification (admin)
  createNotification: async (notificationData) => {
    const response = await api.post('/admin/notifications/', notificationData);
    return response.data;
  },

  // Mettre à jour une notification
  updateNotification: async (notificationId, data) => {
    const response = await api.patch(`/notifications/${notificationId}/`, data);
    return response.data;
  },

  // Supprimer une notification
  deleteNotification: async (notificationId) => {
    const response = await api.delete(`/notifications/${notificationId}/`);
    return response.data;
  },

  // Marquer une notification comme lue
  markAsRead: async (notificationId) => {
    const response = await api.post(`/notifications/${notificationId}/mark_read/`);
    return response.data;
  },

  // Marquer toutes les notifications comme lues
  markAllAsRead: async (userId = null) => {
    const data = userId ? { user_id: userId } : {};
    const response = await api.post('/notifications/mark_all_read/', data);
    return response.data;
  },

  // Supprimer plusieurs notifications (admin)
  bulkDelete: async (notificationIds) => {
    const response = await api.post('/notifications/bulk_delete/', {
      notification_ids: notificationIds
    });
    return response.data;
  },

  // Obtenir le nombre de notifications non lues
  getUnreadCount: async (userId = null) => {
    const params = userId ? { user_id: userId } : {};
    const queryString = new URLSearchParams(params).toString();
    const response = await api.get(`/notifications/count/?${queryString}`);
    return response.data;
  },

  // Obtenir les statistiques des notifications (admin)
  getStats: async () => {
    const response = await api.get('/admin/notifications/stats/');
    return response.data;
  },

  // Envoyer une notification à un utilisateur spécifique (admin)
  sendNotificationToUser: async (userId, notificationData) => {
    const response = await api.post('/admin/notifications/send/', {
      user_id: userId,
      ...notificationData
    });
    return response.data;
  },

  // Envoyer une notification à tous les utilisateurs (admin)
  broadcastNotification: async (notificationData) => {
    const response = await api.post('/admin/broadcast/notifications', notificationData);
    return response.data;
  },

  // Obtenir les types de notifications disponibles
  getNotificationTypes: () => {
    return [
      { value: 'message', label: 'Nouveau message', color: 'blue' },
      { value: 'review', label: 'Nouvel avis', color: 'yellow' },
      { value: 'favorite', label: 'Nouveau favoris', color: 'pink' },
      { value: 'dispute', label: 'Litige', color: 'red' },
      { value: 'system', label: 'Notification système', color: 'gray' },
      { value: 'quote_request', label: 'Demande de devis', color: 'purple' },
      { value: 'quote_accepted', label: 'Devis accepté', color: 'green' },
      { value: 'quote_rejected', label: 'Devis rejeté', color: 'red' },
      { value: 'quote_completed', label: 'Devis terminé', color: 'blue' },
      { value: 'new_offer', label: 'Nouvelle offre', color: 'indigo' },
      { value: 'offer_accepted', label: 'Offre acceptée', color: 'green' },
      { value: 'offer_rejected', label: 'Offre rejetée', color: 'red' },
    ];
  },

  // Obtenir l'icône pour un type de notification
  getNotificationIcon: (type) => {
    const icons = {
      'message': 'FiMessageSquare',
      'review': 'FiStar',
      'favorite': 'FiHeart',
      'dispute': 'FiAlertTriangle',
      'system': 'FiInfo',
      'quote_request': 'FiFileText',
      'quote_accepted': 'FiCheckCircle',
      'quote_rejected': 'FiXCircle',
      'quote_completed': 'FiCheck',
      'new_offer': 'FiBriefcase',
      'offer_accepted': 'FiCheckCircle',
      'offer_rejected': 'FiXCircle',
    };
    return icons[type] || 'FiBell';
  },

  // Obtenir la couleur pour un type de notification
  getNotificationColor: (type) => {
    const colors = {
      'message': 'blue',
      'review': 'yellow',
      'favorite': 'pink',
      'dispute': 'red',
      'system': 'gray',
      'quote_request': 'purple',
      'quote_accepted': 'green',
      'quote_rejected': 'red',
      'quote_completed': 'blue',
      'new_offer': 'indigo',
      'offer_accepted': 'green',
      'offer_rejected': 'red',
    };
    return colors[type] || 'gray';
  },

  // Formater une date de notification
  formatNotificationDate: (dateString) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffInMinutes = (now - date) / (1000 * 60);
    
    if (diffInMinutes < 1) {
      return 'À l\'instant';
    } else if (diffInMinutes < 60) {
      return `Il y a ${Math.floor(diffInMinutes)} minutes`;
    } else if (diffInMinutes < 1440) { // 24 heures
      return `Il y a ${Math.floor(diffInMinutes / 60)} heures`;
    } else {
      return date.toLocaleDateString('fr-FR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
    }
  },

  // Obtenir le résumé d'une notification
  getNotificationSummary: (notification) => {
    const type = notificationService.getNotificationTypes().find(t => t.value === notification.notification_type);
    return {
      id: notification.id,
      title: notification.title,
      message: notification.message,
      type: type?.label || 'Notification',
      color: type?.color || 'gray',
      icon: notificationService.getNotificationIcon(notification.notification_type),
      isRead: notification.is_read,
      createdAt: notification.created_at,
      formattedDate: notificationService.formatNotificationDate(notification.created_at),
      user: notification.user,
      relatedObjectId: notification.related_object_id,
    };
  }
};