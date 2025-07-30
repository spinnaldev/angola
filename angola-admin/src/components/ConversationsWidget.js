// angola-admin/src/components/ConversationsWidget.js

import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { conversationService } from '../services/conversationService';
import { 
  FiMessageCircle, 
  FiClock, 
  FiUsers, 
  FiArrowRight,
  FiEye 
} from 'react-icons/fi';

const ConversationsWidget = () => {
  const [overview, setOverview] = useState(null);
  const [recentConversations, setRecentConversations] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchOverview();
    fetchRecentConversations();
  }, []);

  const fetchOverview = async () => {
    try {
      const data = await conversationService.getOverview();
      setOverview(data);
    } catch (error) {
      console.error('Erreur lors du chargement de l\'aperçu:', error);
    }
  };

  const fetchRecentConversations = async () => {
    try {
      const data = await conversationService.getConversations({
        ordering: '-updated_at',
        limit: 5
      });
      setRecentConversations(data.results || data.slice(0, 5));
    } catch (error) {
      console.error('Erreur lors du chargement des conversations récentes:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="bg-white p-6 rounded-lg shadow">
        <div className="animate-pulse">
          <div className="h-4 bg-gray-200 rounded w-1/3 mb-4"></div>
          <div className="space-y-3">
            <div className="h-4 bg-gray-200 rounded"></div>
            <div className="h-4 bg-gray-200 rounded w-5/6"></div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow overflow-hidden">
      {/* Header */}
      <div className="px-6 py-4 border-b border-gray-200">
        <div className="flex items-center justify-between">
          <div className="flex items-center">
            <FiMessageCircle className="h-5 w-5 text-blue-500 mr-2" />
            <h3 className="text-lg font-medium text-gray-900">Conversations</h3>
          </div>
          <Link
            to="/conversations"
            className="text-sm text-blue-600 hover:text-blue-500 flex items-center"
          >
            Voir tout
            <FiArrowRight className="ml-1 h-4 w-4" />
          </Link>
        </div>
      </div>

      {/* Stats */}
      {overview && (
        <div className="px-6 py-4 bg-gray-50 border-b border-gray-200">
          <div className="grid grid-cols-3 gap-4">
            <div className="text-center">
              <div className="text-2xl font-bold text-gray-900">
                {overview.conversations.total}
              </div>
              <div className="text-xs text-gray-500">Total</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-red-600">
                {overview.conversations.with_unread}
              </div>
              <div className="text-xs text-gray-500">Non lues</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-green-600">
                {overview.conversations.recent_24h}
              </div>
              <div className="text-xs text-gray-500">Récentes</div>
            </div>
          </div>
        </div>
      )}

      {/* Recent Conversations */}
      <div className="divide-y divide-gray-200">
        {recentConversations.length > 0 ? (
          recentConversations.map((conversation) => (
            <div key={conversation.id} className="px-6 py-4 hover:bg-gray-50">
              <div className="flex items-center justify-between">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center">
                    <div className="flex-shrink-0">
                      <FiUsers className="h-4 w-4 text-gray-400" />
                    </div>
                    <div className="ml-3 flex-1 min-w-0">
                      <p className="text-sm font-medium text-gray-900 truncate">
                        {conversation.client.full_name} ↔ {conversation.provider.user.full_name}
                      </p>
                      {conversation.last_message && (
                        <p className="text-xs text-gray-500 truncate">
                          {conversation.last_message.content}
                        </p>
                      )}
                    </div>
                  </div>
                </div>
                
                <div className="flex items-center space-x-2">
                  {conversation.unread_messages > 0 && (
                    <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                      {conversation.unread_messages}
                    </span>
                  )}
                  
                  <div className="flex items-center text-xs text-gray-500">
                    <FiClock className="h-3 w-3 mr-1" />
                    {conversation.duration}
                  </div>
                  
                  <Link
                    to={`/conversations/${conversation.id}`}
                    className="text-blue-600 hover:text-blue-500"
                  >
                    <FiEye className="h-4 w-4" />
                  </Link>
                </div>
              </div>
            </div>
          ))
        ) : (
          <div className="px-6 py-8 text-center">
            <FiMessageCircle className="mx-auto h-8 w-8 text-gray-400" />
            <p className="mt-2 text-sm text-gray-500">Aucune conversation récente</p>
          </div>
        )}
      </div>

      {/* Chart des messages (optionnel) */}
      {overview && overview.messages_by_day && (
        <div className="px-6 py-4 border-t border-gray-200">
          <h4 className="text-sm font-medium text-gray-700 mb-3">
            Messages par jour (7 derniers jours)
          </h4>
          <div className="flex items-end justify-between h-16">
            {overview.messages_by_day.map((day, index) => (
              <div key={index} className="flex flex-col items-center flex-1">
                <div 
                  className="w-2 bg-blue-500 rounded-t"
                  style={{ 
                    height: `${Math.max((day.count / Math.max(...overview.messages_by_day.map(d => d.count))) * 100, 5)}%` 
                  }}
                ></div>
                <span className="text-xs text-gray-500 mt-1">
                  {new Date(day.date).getDate()}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default ConversationsWidget;