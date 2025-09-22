// NotificationsPage.js
import React, { useState, useEffect } from 'react';
import { 
  FiBell, 
  FiEye, 
  FiSearch, 
  FiFilter, 
  FiRefreshCw,
  FiMoreHorizontal,
  FiUser,
  FiClock,
  FiCheck,
  FiTrash2,
  FiPlus,
  FiMessageSquare,
  FiStar,
  FiHeart,
  FiAlertTriangle,
  FiInfo,
  FiFileText,
  FiCheckCircle,
  FiXCircle,
  FiBriefcase
} from 'react-icons/fi';
import { notificationService } from '../services/notificationService';
import CreateNotificationModal from '../components/CreateNotificationModal';

const NotificationsPage = () => {
  const [notifications, setNotifications] = useState([]);
  const [stats, setStats] = useState({
    total: 0,
    unread: 0,
    recent: 0,
    byType: {}
  });
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({
    search: '',
    type: 'all',
    status: 'all', // all, read, unread
    period: 'all' // all, today, week, month
  });
  const [selectedNotifications, setSelectedNotifications] = useState([]);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(null);

  useEffect(() => {
    fetchData();
  }, [filters]);

  const fetchData = async () => {
    try {
      setLoading(true);
      
      // Récupérer les statistiques
      const statsData = await notificationService.getStats();
      setStats(statsData);
      
      // Récupérer les notifications avec filtres
      const params = {};
      if (filters.search) params.search = filters.search;
      if (filters.type !== 'all') params.notification_type = filters.type;
      if (filters.status !== 'all') params.is_read = filters.status === 'read';
      if (filters.period !== 'all') params.period = filters.period;
      
      const notificationsData = await notificationService.getAllNotifications(params);
      setNotifications(notificationsData.results || notificationsData);
      
    } catch (error) {
      console.error('Erreur lors du chargement des données:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSelectNotification = (notificationId) => {
    setSelectedNotifications(prev => {
      const isSelected = prev.includes(notificationId);
      if (isSelected) {
        return prev.filter(id => id !== notificationId);
      } else {
        return [...prev, notificationId];
      }
    });
  };

  const handleSelectAll = () => {
    if (selectedNotifications.length === notifications.length) {
      setSelectedNotifications([]);
    } else {
      setSelectedNotifications(notifications.map(notif => notif.id));
    }
  };

  const handleBulkMarkRead = async () => {
    try {
      // Marquer les notifications sélectionnées comme lues
      await Promise.all(
        selectedNotifications.map(id => notificationService.markAsRead(id))
      );
      setSelectedNotifications([]);
      fetchData();
    } catch (error) {
      console.error('Erreur lors du marquage en lot:', error);
    }
  };

  const handleBulkDelete = async () => {
    try {
      await notificationService.bulkDelete(selectedNotifications);
      setSelectedNotifications([]);
      fetchData();
    } catch (error) {
      console.error('Erreur lors de la suppression en lot:', error);
    }
  };

  const handleDeleteNotification = async (notificationId) => {
    try {
      await notificationService.deleteNotification(notificationId);
      setShowDeleteModal(null);
      fetchData();
    } catch (error) {
      console.error('Erreur lors de la suppression:', error);
    }
  };

  const getNotificationIcon = (type) => {
    const icons = {
      'message': FiMessageSquare,
      'review': FiStar,
      'favorite': FiHeart,
      'dispute': FiAlertTriangle,
      'system': FiInfo,
      'quote_request': FiFileText,
      'quote_accepted': FiCheckCircle,
      'quote_rejected': FiXCircle,
      'quote_completed': FiCheck,
      'new_offer': FiBriefcase,
      'offer_accepted': FiCheckCircle,
      'offer_rejected': FiXCircle,
    };
    return icons[type] || FiBell;
  };

  const getTypeColor = (type) => {
    const colors = {
      'message': 'text-blue-500 bg-blue-100',
      'review': 'text-yellow-500 bg-yellow-100',
      'favorite': 'text-pink-500 bg-pink-100',
      'dispute': 'text-red-500 bg-red-100',
      'system': 'text-gray-500 bg-gray-100',
      'quote_request': 'text-purple-500 bg-purple-100',
      'quote_accepted': 'text-green-500 bg-green-100',
      'quote_rejected': 'text-red-500 bg-red-100',
      'quote_completed': 'text-blue-500 bg-blue-100',
      'new_offer': 'text-indigo-500 bg-indigo-100',
      'offer_accepted': 'text-green-500 bg-green-100',
      'offer_rejected': 'text-red-500 bg-red-100',
    };
    return colors[type] || 'text-gray-500 bg-gray-100';
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffInHours = (now - date) / (1000 * 60 * 60);
    
    if (diffInHours < 1) {
      return 'Il y a quelques minutes';
    } else if (diffInHours < 24) {
      return `Il y a ${Math.floor(diffInHours)} heures`;
    } else {
      return date.toLocaleDateString('fr-FR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric'
      });
    }
  };

  const getTypeName = (type) => {
    const types = notificationService.getNotificationTypes();
    const typeObj = types.find(t => t.value === type);
    return typeObj?.label || type;
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Gestion des Notifications</h1>
          <p className="text-gray-600">Gérez toutes les notifications de votre plateforme</p>
        </div>
        <div className="flex space-x-3">
          <button
            onClick={() => setShowCreateModal(true)}
            className="flex items-center space-x-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
          >
            <FiPlus className="w-4 h-4" />
            <span>Nouvelle notification</span>
          </button>
          <button
            onClick={fetchData}
            disabled={loading}
            className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
          >
            <FiRefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
            <span>Actualiser</span>
          </button>
        </div>
      </div>

      {/* Statistiques */}
      <div className="grid grid-cols-1 md:grid-cols-6 gap-6">
        <div className="bg-white p-6 rounded-lg border border-gray-200">
          <div className="flex items-center">
            <FiBell className="w-8 h-8 text-blue-500" />
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Total</p>
              <p className="text-2xl font-bold text-gray-900">{stats.total_notifications}</p>
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg border border-gray-200">
          <div className="flex items-center">
            <FiBell className="w-8 h-8 text-red-500" />
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Non lues</p>
              <p className="text-2xl font-bold text-gray-900">{stats.unread_notifications}</p>
            </div>
          </div>
        </div>

        {/* <div className="bg-white p-6 rounded-lg border border-gray-200">
          <div className="flex items-center">
            <FiClock className="w-8 h-8 text-green-500" />
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Récentes (24h)</p>
              <p className="text-2xl font-bold text-gray-900">{stats.recent}</p>
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg border border-gray-200">
          <div className="flex items-center">
            <FiUser className="w-8 h-8 text-purple-500" />
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Utilisateurs actifs</p>
              <p className="text-2xl font-bold text-gray-900">{stats.activeUsers || 0}</p>
            </div>
          </div>
        </div> */}
      </div>

      {/* Filtres et recherche */}
      <div className="bg-white p-6 rounded-lg border border-gray-200">
        <div className="flex flex-col lg:flex-row gap-4">
          {/* Recherche */}
          <div className="flex-1">
            <div className="relative">
              <FiSearch className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
              <input
                type="text"
                placeholder="Rechercher par titre, message ou utilisateur..."
                value={filters.search}
                onChange={(e) => setFilters(prev => ({ ...prev, search: e.target.value }))}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
          </div>

          {/* Filtres */}
          <div className="flex gap-4">
            <select
              value={filters.type}
              onChange={(e) => setFilters(prev => ({ ...prev, type: e.target.value }))}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="all">Tous les types</option>
              {notificationService.getNotificationTypes().map(type => (
                <option key={type.value} value={type.value}>{type.label}</option>
              ))}
            </select>

            <select
              value={filters.status}
              onChange={(e) => setFilters(prev => ({ ...prev, status: e.target.value }))}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="all">Tous les statuts</option>
              <option value="unread">Non lues</option>
              <option value="read">Lues</option>
            </select>

            <select
              value={filters.period}
              onChange={(e) => setFilters(prev => ({ ...prev, period: e.target.value }))}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="all">Toutes les périodes</option>
              <option value="today">Aujourd'hui</option>
              <option value="week">Cette semaine</option>
              <option value="month">Ce mois</option>
            </select>
          </div>
        </div>
      </div>

      {/* Actions en lot */}
      {selectedNotifications.length > 0 && (
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <div className="flex items-center justify-between">
            <span className="text-blue-700">
              {selectedNotifications.length} notification(s) sélectionnée(s)
            </span>
            <div className="flex gap-2">
              <button
                onClick={handleBulkMarkRead}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center space-x-2"
              >
                <FiCheck className="w-4 h-4" />
                <span>Marquer comme lues</span>
              </button>
              <button
                onClick={handleBulkDelete}
                className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 flex items-center space-x-2"
              >
                <FiTrash2 className="w-4 h-4" />
                <span>Supprimer</span>
              </button>
              <button
                onClick={() => setSelectedNotifications([])}
                className="px-4 py-2 bg-gray-500 text-white rounded-lg hover:bg-gray-600"
              >
                Annuler
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Liste des notifications */}
      <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
        {loading ? (
          <div className="p-8 text-center">
            <FiRefreshCw className="w-8 h-8 animate-spin mx-auto text-gray-400 mb-4" />
            <p className="text-gray-500">Chargement des notifications...</p>
          </div>
        ) : notifications.length === 0 ? (
          <div className="p-8 text-center">
            <FiBell className="w-12 h-12 mx-auto text-gray-400 mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">Aucune notification</h3>
            <p className="text-gray-500">Aucune notification ne correspond à vos critères de recherche.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left">
                    <input
                      type="checkbox"
                      checked={selectedNotifications.length === notifications.length}
                      onChange={handleSelectAll}
                      className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                    />
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Type
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Notification
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Utilisateur
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Statut
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Date
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {notifications.map((notification) => {
                  const IconComponent = getNotificationIcon(notification.notification_type);
                  const typeColor = getTypeColor(notification.notification_type);
                  
                  return (
                    <tr 
                      key={notification.id}
                      className={`hover:bg-gray-50 ${!notification.is_read ? 'bg-blue-50' : ''}`}
                    >
                      <td className="px-6 py-4">
                        <input
                          type="checkbox"
                          checked={selectedNotifications.includes(notification.id)}
                          onChange={() => handleSelectNotification(notification.id)}
                          className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                        />
                      </td>
                      <td className="px-6 py-4">
                        <div className={`inline-flex items-center p-2 rounded-full ${typeColor}`}>
                          <IconComponent className="w-4 h-4" />
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div>
                          <div className="text-sm font-medium text-gray-900">
                            {notification.title}
                          </div>
                          <div className="text-sm text-gray-500 truncate max-w-xs">
                            {notification.message}
                          </div>
                          <div className="text-xs text-gray-400 mt-1">
                            {getTypeName(notification.notification_type)}
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center">
                          <div className="flex-shrink-0 h-8 w-8">
                            <div className="h-8 w-8 rounded-full bg-gray-300 flex items-center justify-center">
                              <FiUser className="w-4 h-4 text-gray-600" />
                            </div>
                          </div>
                          <div className="ml-3">
                            <div className="text-sm font-medium text-gray-900">
                              {notification.user?.first_name} {notification.user?.last_name}
                            </div>
                            <div className="text-sm text-gray-500">
                              {notification.user?.email}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                          notification.is_read
                            ? 'bg-green-100 text-green-800'
                            : 'bg-red-100 text-red-800'
                        }`}>
                          {notification.is_read ? 'Lue' : 'Non lue'}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-500">
                        {formatDate(notification.created_at)}
                      </td>
                      <td className="px-6 py-4 text-right text-sm font-medium">
                        <div className="flex items-center justify-end space-x-2">
                          {!notification.is_read && (
                            <button
                              onClick={() => notificationService.markAsRead(notification.id).then(fetchData)}
                              className="text-blue-600 hover:text-blue-900 p-1 rounded hover:bg-blue-100"
                              title="Marquer comme lue"
                            >
                              <FiCheck className="w-4 h-4" />
                            </button>
                          )}
                          <button
                            onClick={() => setShowDeleteModal(notification.id)}
                            className="text-red-600 hover:text-red-900 p-1 rounded hover:bg-red-100"
                            title="Supprimer"
                          >
                            <FiTrash2 className="w-4 h-4" />
                          </button>
                          <button
                            className="text-gray-600 hover:text-gray-900 p-1 rounded hover:bg-gray-100"
                            title="Plus d'actions"
                          >
                            <FiMoreHorizontal className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Modal de suppression */}
      {showDeleteModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
            <h3 className="text-lg font-medium text-gray-900 mb-4">
              Confirmer la suppression
            </h3>
            <p className="text-gray-500 mb-6">
              Êtes-vous sûr de vouloir supprimer cette notification ? Cette action est irréversible.
            </p>
            <div className="flex justify-end space-x-3">
              <button
                onClick={() => setShowDeleteModal(null)}
                className="px-4 py-2 text-gray-700 bg-gray-200 rounded-lg hover:bg-gray-300"
              >
                Annuler
              </button>
              <button
                onClick={() => handleDeleteNotification(showDeleteModal)}
                className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700"
              >
                Supprimer
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal de création */}
      <CreateNotificationModal
        isOpen={showCreateModal}
        onClose={() => setShowCreateModal(false)}
        onSuccess={fetchData}
      />
    </div>
  );
};

export default NotificationsPage;