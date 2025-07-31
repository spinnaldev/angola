// src/pages/Users.js - Version mise à jour avec intégration de la vérification
import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import DashboardLayout from '../layouts/DashboardLayout';
import { userService } from '../services/api';
import { withAuth } from '../context/AuthContext';
import VerificationDetailModal from '../components/VerificationDetailModal';

// Icônes
const SearchIcon = () => <span>🔍</span>;
const EditIcon = () => <span>✏️</span>;
const DeleteIcon = () => <span>🗑️</span>;
const CheckCircleIcon = ({ className }) => <span className={className}>✅</span>;
const CancelIcon = ({ className }) => <span className={className}>❌</span>;
const ChevronLeftIcon = () => <span>⬅️</span>;
const ChevronRightIcon = () => <span>➡️</span>;
const EyeIcon = () => <span>👁️</span>;

const UserRow = ({ user, onEdit, onDelete, onToggleStatus, onToggleVerification, onViewVerification }) => {
  const getVerificationStatus = () => {
    if (user.role === 'provider') {
      // Pour les prestataires, on regarde le statut de vérification des documents
      if (user.provider_verification?.status === 'verified') {
        return { status: 'verified', label: '✅ Vérifié', color: 'bg-green-100 text-green-800' };
      } else if (user.provider_verification?.status === 'rejected') {
        return { status: 'rejected', label: '❌ Rejeté', color: 'bg-red-100 text-red-800' };
      } else if (user.provider_verification?.status === 'pending') {
        return { status: 'pending', label: '⏳ En attente', color: 'bg-yellow-100 text-yellow-800' };
      } else {
        return { status: 'not_started', label: '📋 Non démarré', color: 'bg-gray-100 text-gray-800' };
      }
    } else if (user.role === 'client') {
      // Pour les clients, on regarde la vérification téléphone
      if (user.is_phone_verified) {
        return { status: 'verified', label: '📱 Téléphone vérifié', color: 'bg-green-100 text-green-800' };
      } else {
        return { status: 'not_verified', label: '📱 Non vérifié', color: 'bg-gray-100 text-gray-800' };
      }
    } else {
      // Pour les admins ou autres rôles
      return { status: 'admin', label: '👑 Admin', color: 'bg-purple-100 text-purple-800' };
    }
  };

  const verificationStatus = getVerificationStatus();

  return (
    <tr className="hover:bg-gray-50 border-b">
      <td className="whitespace-nowrap py-3 pl-4 pr-3 text-sm">
        <div className="flex items-center">
          <div className="h-10 w-10 flex-shrink-0">
            {user.profile_picture ? (
              <img
                className="h-10 w-10 rounded-full object-cover"
                src={user.profile_picture}
                alt={user.username}
              />
            ) : (
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-gray-200 text-gray-500">
                {user.first_name?.charAt(0) || user.username?.charAt(0) || 'U'}
              </div>
            )}
          </div>
          <div className="ml-4">
            <div className="font-medium text-gray-900">
              {user.first_name
                ? `${user.first_name} ${user.last_name}`
                : user.username}
            </div>
            <div className="text-gray-500">{user.username}</div>
          </div>
        </div>
      </td>
      <td className="whitespace-nowrap px-3 py-3 text-sm text-gray-500">
        {user.email}
      </td>
      <td className="whitespace-nowrap px-3 py-3 text-sm text-gray-500">
        {user.phone_number || '-'}
      </td>
      <td className="whitespace-nowrap px-3 py-3 text-sm">
        <span
          className={`inline-flex rounded-full px-2 text-xs font-semibold leading-5 ${
            user.role === 'admin'
              ? 'bg-purple-100 text-purple-800'
              : user.role === 'provider'
              ? 'bg-green-100 text-green-800'
              : 'bg-blue-100 text-blue-800'
          }`}
        >
          {user.role === 'admin'
            ? 'Admin'
            : user.role === 'provider'
            ? 'Prestataire'
            : 'Client'}
        </span>
      </td>
      <td className="whitespace-nowrap px-3 py-3 text-sm">
        <span className={`inline-flex rounded-full px-2 text-xs font-semibold leading-5 ${verificationStatus.color}`}>
          {verificationStatus.label}
        </span>
      </td>
      <td className="whitespace-nowrap px-3 py-3 text-sm text-gray-500">
        {new Date(user.date_joined).toLocaleDateString('fr-FR')}
      </td>
      <td className="whitespace-nowrap px-3 py-3 text-sm text-center">
        <button onClick={() => onToggleVerification(user)}>
          {user.is_verified ? (
            <CheckCircleIcon className="text-green-500" />
          ) : (
            <CancelIcon className="text-red-500" />
          )}
        </button>
      </td>
      <td className="whitespace-nowrap px-3 py-3 text-sm text-center">
        <span
          className={`inline-flex rounded-full px-2 text-xs font-semibold leading-5 ${
            user.is_active ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
          }`}
        >
          {user.is_active ? 'Actif' : 'Inactif'}
        </span>
      </td>
      <td className="whitespace-nowrap px-3 py-3 text-sm text-gray-500">
        <div className="flex space-x-2">
          {/* Bouton pour voir les détails de vérification (seulement pour les prestataires) */}
          {user.role === 'provider' && user.provider_verification?.exists && (
            <button
              onClick={() => onViewVerification(user)}
              className="text-indigo-600 hover:text-indigo-900 p-1 rounded-md hover:bg-indigo-50"
              title="Voir les détails de vérification"
            >
              <EyeIcon />
            </button>
          )}
          
          <button
            onClick={() => onEdit(user)}
            className="text-indigo-600 hover:text-indigo-900 p-1 rounded-md hover:bg-indigo-50"
            title="Modifier"
          >
            <EditIcon />
          </button>
          
          <button
            onClick={() => onDelete(user)}
            className="text-red-600 hover:text-red-900 p-1 rounded-md hover:bg-red-50"
            title="Supprimer"
          >
            <DeleteIcon />
          </button>
        </div>
      </td>
    </tr>
  );
};

const Users = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [searchTerm, setSearchTerm] = useState('');
  const [roleFilter, setRoleFilter] = useState('');
  const [verificationFilter, setVerificationFilter] = useState('');
  
  // 🆕 États pour le modal de vérification
  const [verificationModalOpen, setVerificationModalOpen] = useState(false);
  const [selectedVerificationId, setSelectedVerificationId] = useState(null);

  const itemsPerPage = 10;

  useEffect(() => {
    fetchUsers();
  }, [currentPage, searchTerm, roleFilter, verificationFilter]);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const data = await userService.getAll({
        page: currentPage,
        search: searchTerm,
        role: roleFilter,
        verification_status: verificationFilter,
        page_size: itemsPerPage,
      });
      
      setUsers(data.results || []);
      setTotalPages(Math.ceil((data.count || 0) / itemsPerPage));
    } catch (error) {
      console.error('Erreur lors du chargement des utilisateurs:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = (user) => {
    console.log('Modifier utilisateur:', user);
    // Logique pour modifier l'utilisateur
  };

  const handleDelete = async (user) => {
    if (window.confirm(`Êtes-vous sûr de vouloir supprimer l'utilisateur ${user.username} ?`)) {
      try {
        await userService.delete(user.id);
        await fetchUsers();
      } catch (error) {
        console.error('Erreur lors de la suppression:', error);
        alert('Erreur lors de la suppression de l\'utilisateur');
      }
    }
  };

  const handleToggleStatus = async (user) => {
    try {
      await userService.toggleStatus(user.id);
      await fetchUsers();
    } catch (error) {
      console.error('Erreur lors du changement de statut:', error);
      alert('Erreur lors du changement de statut');
    }
  };

  const handleToggleVerification = async (user) => {
    try {
      await userService.toggleVerification(user.id);
      await fetchUsers();
    } catch (error) {
      console.error('Erreur lors du changement de vérification:', error);
      alert('Erreur lors du changement de vérification');
    }
  };

  // 🆕 Fonction pour ouvrir le modal de détail de vérification
  const handleViewVerification = (user) => {
    if (user.provider_verification?.id) {
      setSelectedVerificationId(user.provider_verification.id);
      setVerificationModalOpen(true);
    } else {
      alert('Aucune vérification trouvée pour cet utilisateur');
    }
  };

  const handlePageChange = (page) => {
    setCurrentPage(page);
  };

  const resetFilters = () => {
    setSearchTerm('');
    setRoleFilter('');
    setVerificationFilter('');
    setCurrentPage(1);
  };

  const getVerificationStats = () => {
    const stats = users.reduce((acc, user) => {
      if (user.role === 'provider') {
        const status = user.provider_verification?.status || 'not_started';
        acc[status] = (acc[status] || 0) + 1;
      } else if (user.role === 'client') {
        const status = user.is_phone_verified ? 'phone_verified' : 'phone_not_verified';
        acc[status] = (acc[status] || 0) + 1;
      }
      return acc;
    }, {});
    
    return stats;
  };

  const verificationStats = getVerificationStats();

  return (
    <DashboardLayout>
      <div className="px-4 sm:px-6 lg:px-8">
        {/* En-tête avec statistiques */}
        <div className="sm:flex sm:items-center sm:justify-between mb-8">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Gestion des Utilisateurs</h1>
            <p className="mt-1 text-sm text-gray-500">
              Un total de {users.length} utilisateurs trouvés
            </p>
          </div>
          <div className="mt-4 sm:mt-0">
            <Link
              to="/user-verification"
              className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              🔍 Vérifications détaillées
            </Link>
          </div>
        </div>

        {/* Statistiques rapides */}
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-4 mb-6">
          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <span className="text-2xl">⏳</span>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">En attente</dt>
                    <dd className="text-lg font-medium text-yellow-600">{verificationStats.pending || 0}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <span className="text-2xl">✅</span>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">Vérifiés</dt>
                    <dd className="text-lg font-medium text-green-600">{verificationStats.verified || 0}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <span className="text-2xl">❌</span>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">Rejetés</dt>
                    <dd className="text-lg font-medium text-red-600">{verificationStats.rejected || 0}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <span className="text-2xl">📱</span>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">Tél. vérifiés</dt>
                    <dd className="text-lg font-medium text-blue-600">{verificationStats.phone_verified || 0}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Filtres */}
        <div className="bg-white shadow rounded-lg mb-6">
          <div className="px-4 py-3 border-b border-gray-200">
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-3 sm:space-y-0">
              <div className="flex flex-col sm:flex-row space-y-2 sm:space-y-0 sm:space-x-3">
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <SearchIcon />
                  </div>
                  <input
                    type="text"
                    placeholder="Rechercher des utilisateurs..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="focus:ring-indigo-500 focus:border-indigo-500 block w-full pl-10 pr-3 py-2 sm:text-sm border-gray-300 rounded-md"
                  />
                </div>

                <select
                  value={roleFilter}
                  onChange={(e) => setRoleFilter(e.target.value)}
                  className="focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:w-auto px-3 py-2 border-gray-300 rounded-md text-sm"
                >
                  <option value="">Tous les rôles</option>
                  <option value="client">Client</option>
                  <option value="provider">Prestataire</option>
                  <option value="admin">Admin</option>
                </select>

                <select
                  value={verificationFilter}
                  onChange={(e) => setVerificationFilter(e.target.value)}
                  className="focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:w-auto px-3 py-2 border-gray-300 rounded-md text-sm"
                >
                  <option value="">Toutes les vérifications</option>
                  <option value="verified">Vérifiés</option>
                  <option value="pending">En attente</option>
                  <option value="rejected">Rejetés</option>
                  <option value="not_started">Non démarrés</option>
                </select>
              </div>

              <button
                onClick={resetFilters}
                className="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                Réinitialiser
              </button>
            </div>
          </div>
        </div>

        {/* Tableau */}
        <div className="bg-white shadow overflow-hidden sm:rounded-md">
          <div className="min-w-full divide-y divide-gray-200">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Utilisateur
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Email
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Téléphone
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Rôle
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Vérification
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Date d'inscription
                  </th>
                  <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Vérifié
                  </th>
                  <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Statut
                  </th>
                  <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {loading ? (
                  <tr>
                    <td colSpan="9" className="px-6 py-4 text-center">
                      <div className="flex justify-center">
                        <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-indigo-600"></div>
                      </div>
                    </td>
                  </tr>
                ) : users.length === 0 ? (
                  <tr>
                    <td colSpan="9" className="px-6 py-4 text-center text-gray-500">
                      Aucun utilisateur trouvé
                    </td>
                  </tr>
                ) : (
                  users.map((user) => (
                    <UserRow
                      key={user.id}
                      user={user}
                      onEdit={handleEdit}
                      onDelete={handleDelete}
                      onToggleStatus={handleToggleStatus}
                      onToggleVerification={handleToggleVerification}
                      onViewVerification={handleViewVerification}
                    />
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6 mt-6 rounded-lg shadow">
            <div className="flex-1 flex justify-between sm:hidden">
              <button
                onClick={() => handlePageChange(currentPage - 1)}
                disabled={currentPage === 1}
                className="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Précédent
              </button>
              <button
                onClick={() => handlePageChange(currentPage + 1)}
                disabled={currentPage === totalPages}
                className="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Suivant
              </button>
            </div>
            <div className="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
              <div>
                <p className="text-sm text-gray-700">
                  Affichage de{' '}
                  <span className="font-medium">{(currentPage - 1) * itemsPerPage + 1}</span> à{' '}
                  <span className="font-medium">
                    {Math.min(currentPage * itemsPerPage, users.length)}
                  </span>{' '}
                  sur <span className="font-medium">{users.length}</span> résultats
                </p>
              </div>
              <div>
                <nav className="relative z-0 inline-flex rounded-md shadow-sm -space-x-px">
                  {Array.from({ length: totalPages }, (_, i) => i + 1).map((page) => (
                    <button
                      key={page}
                      onClick={() => handlePageChange(page)}
                      className={`relative inline-flex items-center px-4 py-2 border text-sm font-medium ${
                        page === currentPage
                          ? 'z-10 bg-indigo-50 border-indigo-500 text-indigo-600'
                          : 'bg-white border-gray-300 text-gray-500 hover:bg-gray-50'
                      } ${page === 1 ? 'rounded-l-md' : ''} ${
                        page === totalPages ? 'rounded-r-md' : ''
                      }`}
                    >
                      {page}
                    </button>
                  ))}
                </nav>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* 🆕 Modal de détail de vérification */}
      <VerificationDetailModal
        isOpen={verificationModalOpen}
        onClose={() => setVerificationModalOpen(false)}
        verificationId={selectedVerificationId}
      />
    </DashboardLayout>
  );
};

export default withAuth(Users);