// CreateNotificationModal.js
import React, { useState, useEffect } from 'react';
import { 
  FiX, 
  FiUser, 
  FiUsers, 
  FiSend,
  FiLoader,
  FiSearch
} from 'react-icons/fi';
import { notificationService } from '../services/notificationService';
import { api } from '../services/api';

const CreateNotificationModal = ({ isOpen, onClose, onSuccess }) => {
  const [formData, setFormData] = useState({
    title: '',
    message: '',
    notification_type: 'system',
    recipient_type: 'specific', // specific, all
    user_id: '',
    user_search: ''
  });
  const [users, setUsers] = useState([]);
  const [searchResults, setSearchResults] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searching, setSearching] = useState(false);
  const [errors, setErrors] = useState({});

  useEffect(() => {
    if (isOpen) {
      fetchUsers();
      resetForm();
    }
  }, [isOpen]);

  const resetForm = () => {
    setFormData({
      title: '',
      message: '',
      notification_type: 'system',
      recipient_type: 'specific',
      user_id: '',
      user_search: ''
    });
    setErrors({});
    setSearchResults([]);
  };

  const fetchUsers = async () => {
    try {
      const response = await api.get('/users/');
      setUsers(response.data.results || response.data);
    } catch (error) {
      console.error('Erreur lors du chargement des utilisateurs:', error);
    }
  };

  const searchUsers = async (query) => {
    if (!query.trim()) {
      setSearchResults([]);
      return;
    }

    try {
      setSearching(true);
      const response = await api.get(`/users/?search=${encodeURIComponent(query)}`);
      setSearchResults(response.data.results || response.data);
    } catch (error) {
      console.error('Erreur lors de la recherche:', error);
      setSearchResults([]);
    } finally {
      setSearching(false);
    }
  };

  const handleInputChange = (field, value) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    
    // Supprimer l'erreur du champ modifié
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: null }));
    }

    // Recherche automatique d'utilisateurs
    if (field === 'user_search') {
      searchUsers(value);
    }
  };

  const selectUser = (user) => {
    setFormData(prev => ({
      ...prev,
      user_id: user.id,
      user_search: `${user.first_name} ${user.last_name} (${user.email})`
    }));
    setSearchResults([]);
  };

  const validateForm = () => {
    const newErrors = {};

    if (!formData.title.trim()) {
      newErrors.title = 'Le titre est requis';
    }

    if (!formData.message.trim()) {
      newErrors.message = 'Le message est requis';
    }

    if (formData.recipient_type === 'specific' && !formData.user_id) {
      newErrors.user_id = 'Veuillez sélectionner un utilisateur';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    try {
      setLoading(true);

      if (formData.recipient_type === 'all') {
        // Diffusion à tous les utilisateurs
        await notificationService.broadcastNotification({
          title: formData.title,
          message: formData.message,
          notification_type: formData.notification_type
        });
      } else {
        // Envoi à un utilisateur spécifique
        await notificationService.sendNotificationToUser(formData.user_id, {
          title: formData.title,
          message: formData.message,
          notification_type: formData.notification_type
        });
      }

      onSuccess();
      onClose();
    } catch (error) {
      console.error('Erreur lors de l\'envoi:', error);
      setErrors({ submit: 'Erreur lors de l\'envoi de la notification' });
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <h2 className="text-xl font-semibold text-gray-900">
            Créer une nouvelle notification
          </h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 p-1 rounded hover:bg-gray-100"
          >
            <FiX className="w-5 h-5" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          {/* Type de destinataire */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Destinataire
            </label>
            <div className="flex space-x-4">
              <label className="flex items-center">
                <input
                  type="radio"
                  name="recipient_type"
                  value="specific"
                  checked={formData.recipient_type === 'specific'}
                  onChange={(e) => handleInputChange('recipient_type', e.target.value)}
                  className="mr-2 text-blue-600 focus:ring-blue-500"
                />
                <FiUser className="w-4 h-4 mr-2 text-gray-500" />
                Utilisateur spécifique
              </label>
              <label className="flex items-center">
                <input
                  type="radio"
                  name="recipient_type"
                  value="all"
                  checked={formData.recipient_type === 'all'}
                  onChange={(e) => handleInputChange('recipient_type', e.target.value)}
                  className="mr-2 text-blue-600 focus:ring-blue-500"
                />
                <FiUsers className="w-4 h-4 mr-2 text-gray-500" />
                Tous les utilisateurs
              </label>
            </div>
          </div>

          {/* Sélection d'utilisateur */}
          {formData.recipient_type === 'specific' && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Rechercher un utilisateur
              </label>
              <div className="relative">
                <div className="relative">
                  <FiSearch className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                  <input
                    type="text"
                    placeholder="Rechercher par nom ou email..."
                    value={formData.user_search}
                    onChange={(e) => handleInputChange('user_search', e.target.value)}
                    className={`w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent ${
                      errors.user_id ? 'border-red-300' : 'border-gray-300'
                    }`}
                  />
                  {searching && (
                    <FiLoader className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4 animate-spin" />
                  )}
                </div>

                {/* Résultats de recherche */}
                {searchResults.length > 0 && (
                  <div className="absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-lg shadow-lg max-h-60 overflow-y-auto">
                    {searchResults.map((user) => (
                      <button
                        key={user.id}
                        type="button"
                        onClick={() => selectUser(user)}
                        className="w-full text-left px-4 py-3 hover:bg-gray-50 flex items-center space-x-3"
                      >
                        <div className="flex-shrink-0 h-8 w-8">
                          <div className="h-8 w-8 rounded-full bg-gray-300 flex items-center justify-center">
                            <FiUser className="w-4 h-4 text-gray-600" />
                          </div>
                        </div>
                        <div>
                          <div className="text-sm font-medium text-gray-900">
                            {user.first_name} {user.last_name}
                          </div>
                          <div className="text-sm text-gray-500">
                            {user.email}
                          </div>
                        </div>
                      </button>
                    ))}
                  </div>
                )}
              </div>
              {errors.user_id && (
                <p className="mt-1 text-sm text-red-600">{errors.user_id}</p>
              )}
            </div>
          )}

          {/* Type de notification */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Type de notification
            </label>
            <select
              value={formData.notification_type}
              onChange={(e) => handleInputChange('notification_type', e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              {notificationService.getNotificationTypes().map(type => (
                <option key={type.value} value={type.value}>
                  {type.label}
                </option>
              ))}
            </select>
          </div>

          {/* Titre */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Titre
            </label>
            <input
              type="text"
              placeholder="Titre de la notification..."
              value={formData.title}
              onChange={(e) => handleInputChange('title', e.target.value)}
              className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent ${
                errors.title ? 'border-red-300' : 'border-gray-300'
              }`}
            />
            {errors.title && (
              <p className="mt-1 text-sm text-red-600">{errors.title}</p>
            )}
          </div>

          {/* Message */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Message
            </label>
            <textarea
              placeholder="Contenu de la notification..."
              value={formData.message}
              onChange={(e) => handleInputChange('message', e.target.value)}
              rows={4}
              className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none ${
                errors.message ? 'border-red-300' : 'border-gray-300'
              }`}
            />
            {errors.message && (
              <p className="mt-1 text-sm text-red-600">{errors.message}</p>
            )}
          </div>

          {/* Erreur générale */}
          {errors.submit && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-3">
              <p className="text-sm text-red-600">{errors.submit}</p>
            </div>
          )}

          {/* Actions */}
          <div className="flex justify-end space-x-3 pt-6 border-t border-gray-200">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-gray-700 bg-gray-200 rounded-lg hover:bg-gray-300"
            >
              Annuler
            </button>
            <button
              type="submit"
              disabled={loading}
              className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
            >
              {loading ? (
                <FiLoader className="w-4 h-4 animate-spin" />
              ) : (
                <FiSend className="w-4 h-4" />
              )}
              <span>{loading ? 'Envoi...' : 'Envoyer'}</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default CreateNotificationModal;