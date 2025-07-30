// angola-admin/src/services/conversationService.js

import { api } from './api';

export const conversationService = {
  // Lister toutes les conversations
  getConversations: async (params = {}) => {
    const queryString = new URLSearchParams(params).toString();
    const response = await api.get(`/admin/conversations/?${queryString}`);
    return response.data;
  },

  // Obtenir une conversation spécifique
  getConversation: async (conversationId) => {
    const response = await api.get(`/admin/conversations/${conversationId}/`);
    return response.data;
  },

  // Obtenir les messages d'une conversation
  getConversationMessages: async (conversationId) => {
    const response = await api.get(`/admin/conversations/${conversationId}/messages/`);
    return response.data;
  },

  // Marquer tous les messages d'une conversation comme lus
  markAllRead: async (conversationId) => {
    const response = await api.post(`/admin/conversations/${conversationId}/mark_all_read/`);
    return response.data;
  },

  // Ajouter un message admin
  addAdminMessage: async (conversationId, content) => {
    const response = await api.post(`/admin/conversations/${conversationId}/add_admin_message/`, {
      content
    });
    return response.data;
  },

  // Fermer une conversation
  closeConversation: async (conversationId) => {
    const response = await api.post(`/admin/conversations/${conversationId}/close_conversation/`);
    return response.data;
  },

  // Supprimer un message
  deleteMessage: async (messageId) => {
    const response = await api.delete(`/admin/messages/${messageId}/delete/`);
    return response.data;
  },

  // Marquer plusieurs conversations comme lues
  bulkMarkRead: async (conversationIds) => {
    const response = await api.post('/admin/conversations/bulk-mark-read/', {
      conversation_ids: conversationIds
    });
    return response.data;
  },

  // Obtenir les statistiques
  getStats: async () => {
    const response = await api.get('/admin/conversations/stats/');
    return response.data;
  },

  // Obtenir la vue d'ensemble pour le dashboard
  getOverview: async () => {
    const response = await api.get('/admin/conversations/overview/');
    return response.data;
  }
};