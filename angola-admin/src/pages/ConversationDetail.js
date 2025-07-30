// angola-admin/src/pages/ConversationDetail.js

import React, { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { api } from '../services/api';
import { 
  FiArrowLeft, 
  FiSend, 
  FiTrash2, 
  FiCheckCircle, 
  FiUser,
  FiUsers,
  FiAlertTriangle
} from 'react-icons/fi';

const ConversationDetail = () => {
  const { conversationId } = useParams();
  const navigate = useNavigate();
  const messagesEndRef = useRef(null);
  
  const [conversation, setConversation] = useState(null);
  const [messages, setMessages] = useState([]);
  const [loading, setLoading] = useState(true);
  const [newMessage, setNewMessage] = useState('');
  const [sending, setSending] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(null);

  useEffect(() => {
    const loadData = async () => {
      try {
        const [conversationResponse, messagesResponse] = await Promise.all([
          api.get(`/admin/conversations/${conversationId}/`),
          api.get(`/admin/conversations/${conversationId}/messages/`)
        ]);
        
        setConversation(conversationResponse.data);
        setMessages(messagesResponse.data.results || messagesResponse.data);
      } catch (error) {
        console.error('Erreur lors du chargement:', error);
      } finally {
        setLoading(false);
      }
    };

    loadData();
  }, [conversationId]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const fetchConversationDetail = async () => {
    try {
      const response = await api.get(`/admin/conversations/${conversationId}/`);
      setConversation(response.data);
    } catch (error) {
      console.error('Erreur lors du chargement de la conversation:', error);
    }
  };

  const fetchMessages = async () => {
    try {
      const response = await api.get(`/admin/conversations/${conversationId}/messages/`);
      setMessages(response.data.results || response.data);
    } catch (error) {
      console.error('Erreur lors du chargement des messages:', error);
    }
  };

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const handleSendMessage = async (e) => {
    e.preventDefault();
    if (!newMessage.trim() || sending) return;

    try {
      setSending(true);
      const response = await api.post(`/admin/conversations/${conversationId}/add_admin_message/`, {
        content: newMessage.trim()
      });
      
      setMessages(prev => [...prev, response.data]);
      setNewMessage('');
      scrollToBottom();
    } catch (error) {
      console.error('Erreur lors de l\'envoi du message:', error);
    } finally {
      setSending(false);
    }
  };

  const handleMarkAllRead = async () => {
    try {
      await api.post(`/admin/conversations/${conversationId}/mark_all_read/`);
      fetchMessages();
      fetchConversationDetail();
    } catch (error) {
      console.error('Erreur lors du marquage comme lu:', error);
    }
  };

  const handleDeleteMessage = async (messageId) => {
    try {
      await api.delete(`/admin/messages/${messageId}/delete/`);
      setMessages(prev => prev.filter(msg => msg.id !== messageId));
      setShowDeleteModal(null);
    } catch (error) {
      console.error('Erreur lors de la suppression du message:', error);
    }
  };

  const handleCloseConversation = async () => {
    try {
      await api.post(`/admin/conversations/${conversationId}/close_conversation/`);
      fetchMessages();
    } catch (error) {
      console.error('Erreur lors de la fermeture de la conversation:', error);
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

  const getSenderTypeColor = (senderType) => {
    switch (senderType) {
      case 'admin':
        return 'bg-purple-100 border-purple-200';
      case 'provider':
        return 'bg-blue-100 border-blue-200';
      case 'client':
        return 'bg-green-100 border-green-200';
      default:
        return 'bg-gray-100 border-gray-200';
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!conversation) {
    return (
      <div className="p-6">
        <div className="text-center">
          <h2 className="text-lg font-medium text-gray-900">Conversation non trouvée</h2>
          <button
            onClick={() => navigate('/conversations')}
            className="mt-2 text-blue-600 hover:text-blue-500"
          >
            Retour à la liste
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="h-screen flex flex-col">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-6 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center">
            <button
              onClick={() => navigate('/conversations')}
              className="mr-4 p-2 text-gray-400 hover:text-gray-600 transition-colors"
            >
              <FiArrowLeft className="w-5 h-5" />
            </button>
            
            <div>
              <h1 className="text-lg font-semibold text-gray-900">
                Conversation #{conversation.id}
              </h1>
              <p className="text-sm text-gray-500">
                {conversation.client.full_name} ↔ {conversation.provider.user.full_name}
              </p>
            </div>
          </div>
          
          <div className="flex items-center space-x-2">
            {conversation.unread_messages > 0 && (
              <button
                onClick={handleMarkAllRead}
                className="inline-flex items-center px-3 py-1 border border-green-300 text-sm font-medium rounded-md text-green-700 bg-green-50 hover:bg-green-100"
              >
                <FiCheckCircle className="w-4 h-4 mr-1" />
                Marquer tout lu ({conversation.unread_messages})
              </button>
            )}
            
            <button
              onClick={handleCloseConversation}
              className="inline-flex items-center px-3 py-1 border border-red-300 text-sm font-medium rounded-md text-red-700 bg-red-50 hover:bg-red-100"
            >
              <FiAlertTriangle className="w-4 h-4 mr-1" />
              Fermer conversation
            </button>
          </div>
        </div>
      </div>

      {/* Info Bar */}
      <div className="bg-gray-50 border-b border-gray-200 px-6 py-3">
        <div className="flex items-center justify-between text-sm text-gray-600">
          <div className="flex items-center space-x-6">
            <div>
              <span className="font-medium">Client:</span> {conversation.client.email}
            </div>
            <div>
              <span className="font-medium">Provider:</span> {conversation.provider.user.email}
            </div>
            <div>
              <span className="font-medium">Messages totaux:</span> {conversation.total_messages}
            </div>
          </div>
          <div>
            <span className="font-medium">Créée le:</span> {' '}
            {new Date(conversation.created_at).toLocaleDateString('fr-FR', {
              day: '2-digit',
              month: '2-digit',
              year: 'numeric',
              hour: '2-digit',
              minute: '2-digit'
            })}
          </div>
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-6 space-y-4">
        {messages.map((message) => (
          <div
            key={message.id}
            className={`p-4 rounded-lg border-2 ${getSenderTypeColor(message.sender_type)} relative group`}
          >
            <div className="flex items-start justify-between">
              <div className="flex items-center space-x-2 mb-2">
                {getSenderTypeIcon(message.sender_type)}
                <span className="font-medium text-gray-900">
                  {message.sender.full_name}
                </span>
                <span className="text-xs text-gray-500 uppercase font-medium">
                  {message.sender_type}
                </span>
                {!message.is_read && (
                  <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                    Non lu
                  </span>
                )}
              </div>
              
              <div className="flex items-center space-x-2">
                <span className="text-xs text-gray-500">
                  {message.time_ago}
                </span>
                {!message.is_admin_message && (
                  <button
                    onClick={() => setShowDeleteModal(message.id)}
                    className="opacity-0 group-hover:opacity-100 p-1 text-red-500 hover:text-red-700 transition-all"
                  >
                    <FiTrash2 className="w-4 h-4" />
                  </button>
                )}
              </div>
            </div>
            
            <div className="text-gray-800 whitespace-pre-wrap">
              {message.content}
            </div>
            
            <div className="mt-2 text-xs text-gray-500">
              {new Date(message.created_at).toLocaleString('fr-FR')}
            </div>
          </div>
        ))}
        
        <div ref={messagesEndRef} />
      </div>

      {/* Message Form */}
      <div className="bg-white border-t border-gray-200 p-6">
        <form onSubmit={handleSendMessage} className="flex space-x-4">
          <div className="flex-1">
            <textarea
              value={newMessage}
              onChange={(e) => setNewMessage(e.target.value)}
              placeholder="Écrire un message en tant qu'administrateur..."
              rows={3}
              className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
              disabled={sending}
            />
          </div>
          <button
            type="submit"
            disabled={!newMessage.trim() || sending}
            className="px-6 py-3 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center"
          >
            {sending ? (
              <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
            ) : (
              <FiSend className="w-4 h-4" />
            )}
            <span className="ml-2">Envoyer</span>
          </button>
        </form>
      </div>

      {/* Modal de confirmation de suppression */}
      {showDeleteModal && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
          <div className="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
            <div className="mt-3 text-center">
              <FiTrash2 className="w-16 h-16 text-red-400 mx-auto" />
              <h3 className="text-lg font-medium text-gray-900 mt-2">
                Supprimer le message
              </h3>
              <p className="text-sm text-gray-500 mt-2">
                Êtes-vous sûr de vouloir supprimer ce message ? Cette action est irréversible.
              </p>
              <div className="flex justify-center space-x-3 mt-4">
                <button
                  onClick={() => setShowDeleteModal(null)}
                  className="px-4 py-2 bg-gray-300 text-gray-700 text-sm font-medium rounded-lg hover:bg-gray-400 transition-colors"
                >
                  Annuler
                </button>
                <button
                  onClick={() => handleDeleteMessage(showDeleteModal)}
                  className="px-4 py-2 bg-red-600 text-white text-sm font-medium rounded-lg hover:bg-red-700 transition-colors"
                >
                  Supprimer
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ConversationDetail;