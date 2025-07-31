// angola-admin/src/pages/ConversationsList.js

import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../services/api';
import { 
  FiMessageSquare, 
  FiSearch, 
  FiEye, 
  FiCheckCircle, 
  FiClock,
  FiUser,
  FiUsers
} from 'react-icons/fi';

const ConversationsList = () => {
  const [conversations, setConversations] = useState([]);
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [filters, setFilters] = useState({
    has_unread: '',
    period: '',
    client: '',
    provider: ''
  });
  const [selectedConversations, setSelectedConversations] = useState([]);

  useEffect(() => {
    const loadData = async () => {
      try {
        setLoading(true);
        const params = new URLSearchParams();
        
        if (searchTerm) params.append('search', searchTerm);
        if (filters.has_unread) params.append('has_unread', filters.has_unread);
        if (filters.period) params.append('period', filters.period);
        if (filters.client) params.append('client', filters.client);
        if (filters.provider) params.append('provider', filters.provider);
        
        const [conversationsResponse, statsResponse] = await Promise.all([
          api.get(`/admin/conversations/?${params}`),
          api.get('/admin/conversations/stats/')
        ]);
        
        setConversations(conversationsResponse.data.results || conversationsResponse.data);
        setStats(statsResponse.data);
      } catch (error) {
        console.error('Erreur lors du chargement des données:', error);
      } finally {
        setLoading(false);
      }
    };

    loadData();
  }, [searchTerm, filters]);

  const fetchConversations = async () => {
    try {
      const params = new URLSearchParams();
      
      if (searchTerm) params.append('search', searchTerm);
      if (filters.has_unread) params.append('has_unread', filters.has_unread);
      if (filters.period) params.append('period', filters.period);
      if (filters.client) params.append('client', filters.client);
      if (filters.provider) params.append('provider', filters.provider);
      
      const response = await api.get(`/admin/conversations/?${params}`);
      setConversations(response.data.results || response.data);
    } catch (error) {
      console.error('Erreur lors du chargement des conversations:', error);
    }
  };

  const fetchStats = async () => {
    try {
      const response = await api.get('/admin/conversations/stats/');
      setStats(response.data);
    } catch (error) {
      console.error('Erreur lors du chargement des statistiques:', error);
    }
  };

  const handleFilterChange = (key, value) => {
    setFilters(prev => ({ ...prev, [key]: value }));
  };

  const handleSelectConversation = (conversationId) => {
    setSelectedConversations(prev => 
      prev.includes(conversationId)
        ? prev.filter(id => id !== conversationId)
        : [...prev, conversationId]
    );
  };

  const handleSelectAll = () => {
    if (selectedConversations.length === conversations.length) {
      setSelectedConversations([]);
    } else {
      setSelectedConversations(conversations.map(c => c.id));
    }
  };

  const handleBulkMarkRead = async () => {
    if (selectedConversations.length === 0) return;
    
    try {
      await api.post('/admin/conversations/bulk-mark-read/', {
        conversation_ids: selectedConversations
      });
      setSelectedConversations([]);
      fetchConversations();
      fetchStats();
    } catch (error) {
      console.error('Erreur lors du marquage en lot:', error);
    }
  };

  const getStatusBadge = (status, unreadCount) => {
    if (unreadCount > 0) {
      return (
        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
          <FiMessageSquare className="w-3 h-3 mr-1" />
          {unreadCount} non lu{unreadCount > 1 ? 's' : ''}
        </span>
      );
    }
    
    switch (status) {
      case 'active':
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
            <FiClock className="w-3 h-3 mr-1" />
            Active
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
            <FiCheckCircle className="w-3 h-3 mr-1" />
            Lu
          </span>
        );
    }
  };

  const getSenderTypeIcon = (senderType) => {
    switch (senderType) {
      case 'admin':
        return <FiUsers className="w-4 h-4 text-purple-500" />;
      case 'provider':
        return <FiUser className="w-4 h-4 text-blue-500" />;
      case 'client':
        return <FiUser className="w-4 h-4 text-green-500" />;
      default:
        return <FiUser className="w-4 h-4 text-gray-500" />;
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="p-6">
      {/* Header avec statistiques */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900 mb-4">
          Gestion des Conversations
        </h1>
        
        {stats && (
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
            <div className="bg-white p-4 rounded-lg shadow border-l-4 border-blue-500">
              <div className="flex items-center">
                <FiMessageSquare className="h-8 w-8 text-blue-500" />
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-500">Total</p>
                  <p className="text-2xl font-bold text-gray-900">{stats.total_conversations}</p>
                </div>
              </div>
            </div>
            
            <div className="bg-white p-4 rounded-lg shadow border-l-4 border-red-500">
              <div className="flex items-center">
                <FiClock className="h-8 w-8 text-red-500" />
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-500">Non lues</p>
                  <p className="text-2xl font-bold text-gray-900">{stats.conversations_with_unread}</p>
                </div>
              </div>
            </div>
            
            <div className="bg-white p-4 rounded-lg shadow border-l-4 border-green-500">
              <div className="flex items-center">
                <FiCheckCircle className="h-8 w-8 text-green-500" />
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-500">Récentes (24h)</p>
                  <p className="text-2xl font-bold text-gray-900">{stats.recent_conversations}</p>
                </div>
              </div>
            </div>
            
            <div className="bg-white p-4 rounded-lg shadow border-l-4 border-purple-500">
              <div className="flex items-center">
                <FiUsers className="h-8 w-8 text-purple-500" />
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-500">Messages totaux</p>
                  <p className="text-2xl font-bold text-gray-900">{stats.total_messages}</p>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Filtres et recherche */}
      <div className="bg-white p-4 rounded-lg shadow mb-6">
        <div className="flex flex-col md:flex-row gap-4">
          {/* Recherche */}
          <div className="flex-1">
            <div className="relative">
              <FiSearch className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="Rechercher par nom d'utilisateur ou email..."
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>
          
          {/* Filtres */}
          <div className="flex gap-2">
            <select
              className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              value={filters.has_unread}
              onChange={(e) => handleFilterChange('has_unread', e.target.value)}
            >
              <option value="">Tous les statuts</option>
              <option value="true">Avec non lus</option>
              <option value="false">Tout lu</option>
            </select>
            
            <select
              className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              value={filters.period}
              onChange={(e) => handleFilterChange('period', e.target.value)}
            >
              <option value="">Toutes les périodes</option>
              <option value="today">Aujourd'hui</option>
              <option value="week">Cette semaine</option>
              <option value="month">Ce mois</option>
            </select>
          </div>
        </div>
      </div>

      {/* Actions en lot */}
      {selectedConversations.length > 0 && (
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium text-blue-800">
              {selectedConversations.length} conversation{selectedConversations.length > 1 ? 's' : ''} sélectionnée{selectedConversations.length > 1 ? 's' : ''}
            </span>
            <div className="flex gap-2">
              <button
                onClick={handleBulkMarkRead}
                className="px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700 transition-colors"
              >
                Marquer comme lu
              </button>
              <button
                onClick={() => setSelectedConversations([])}
                className="px-4 py-2 bg-gray-300 text-gray-700 text-sm font-medium rounded-lg hover:bg-gray-400 transition-colors"
              >
                Annuler
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Liste des conversations */}
      <div className="bg-white shadow rounded-lg overflow-hidden">
        <div className="px-4 py-3 border-b border-gray-200 bg-gray-50">
          <div className="flex items-center">
            <input
              type="checkbox"
              checked={selectedConversations.length === conversations.length && conversations.length > 0}
              onChange={handleSelectAll}
              className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
            />
            <span className="ml-3 text-sm font-medium text-gray-700">
              Sélectionner tout
            </span>
          </div>
        </div>

        <div className="divide-y divide-gray-200">
          {conversations.map((conversation) => (
            <div
              key={conversation.id}
              className={`p-4 hover:bg-gray-50 transition-colors ${
                conversation.unread_messages > 0 ? 'bg-blue-50' : ''
              }`}
            >
              <div className="flex items-center">
                <input
                  type="checkbox"
                  checked={selectedConversations.includes(conversation.id)}
                  onChange={() => handleSelectConversation(conversation.id)}
                  className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                
                <div className="ml-4 flex-1">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-4">
                      <div>
                        <h3 className="text-sm font-medium text-gray-900">
                          {conversation.client.full_name} ↔ {conversation.provider.full_name}
                        </h3>
                        <p className="text-sm text-gray-500">
                          Client: {conversation.client.email} | Provider: {conversation.provider.email}
                        </p>
                      </div>
                    </div>
                    
                    <div className="flex items-center space-x-2">
                      {getStatusBadge(conversation.status, conversation.unread_messages)}
                      <span className="text-xs text-gray-500">{conversation.duration}</span>
                    </div>
                  </div>
                  
                  {conversation.last_message && (
                    <div className="mt-2 flex items-center text-sm text-gray-600">
                      {getSenderTypeIcon(conversation.last_message.sender_type)}
                      <span className="ml-2 font-medium">
                        {conversation.last_message.sender_name}:
                      </span>
                      <span className="ml-1 truncate">
                        {conversation.last_message.content}
                      </span>
                      <span className="ml-2 text-xs text-gray-400">
                        {new Date(conversation.last_message.created_at).toLocaleDateString('fr-FR', {
                          day: '2-digit',
                          month: '2-digit',
                          hour: '2-digit',
                          minute: '2-digit'
                        })}
                      </span>
                    </div>
                  )}
                  
                  <div className="mt-2 flex items-center justify-between">
                    <div className="flex items-center text-xs text-gray-500">
                      <span>{conversation.total_messages} message{conversation.total_messages > 1 ? 's' : ''}</span>
                      <span className="mx-2">•</span>
                      <span>Créée le {new Date(conversation.created_at).toLocaleDateString('fr-FR')}</span>
                    </div>
                    
                    <Link
                      to={`/conversations/${conversation.id}`}
                      className="inline-flex items-center px-3 py-1 border border-transparent text-sm font-medium rounded-md text-blue-600 hover:text-blue-500"
                    >
                      <FiEye className="w-4 h-4 mr-1" />
                      Voir détails
                    </Link>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {conversations.length === 0 && (
          <div className="text-center py-12">
            <FiMessageSquare className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-2 text-sm font-medium text-gray-900">Aucune conversation</h3>
            <p className="mt-1 text-sm text-gray-500">
              Aucune conversation ne correspond à vos critères de recherche.
            </p>
          </div>
        )}
      </div>
    </div>
  );
};

export default ConversationsList;