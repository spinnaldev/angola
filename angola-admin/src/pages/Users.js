import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import DashboardLayout from '../layouts/DashboardLayout';
import { userService } from '../services/api';
import { withAuth } from '../context/AuthContext';

// Icônes
const SearchIcon = () => <span>🔍</span>;
const EditIcon = () => <span>✏️</span>;
const DeleteIcon = () => <span>🗑️</span>;
const CheckCircleIcon = ({ className }) => <span className={className}>✅</span>;
const CancelIcon = ({ className }) => <span className={className}>❌</span>;
const ChevronLeftIcon = () => <span>⬅️</span>;
const ChevronRightIcon = () => <span>➡️</span>;

const UserRow = ({ user, onEdit, onDelete, onToggleStatus, onToggleVerification }) => {
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
            user.is_active
              ? 'bg-green-100 text-green-800'
              : 'bg-red-100 text-red-800'
          }`}
        >
          {user.is_active ? 'Actif' : 'Inactif'}
        </span>
      </td>
      <td className="relative whitespace-nowrap py-3 pl-3 pr-4 text-right text-sm font-medium">
        <button
          onClick={() => onEdit(user)}
          className="text-blue-600 hover:text-blue-900 mr-2 p-1"
        >
          <EditIcon />
        </button>
        <button
          onClick={() => onToggleStatus(user)}
          className="text-yellow-600 hover:text-yellow-900 mr-2 p-1"
          title={user.is_active ? 'Désactiver' : 'Activer'}
        >
          {user.is_active ? '🔒' : '🔓'}
        </button>
        <button
          onClick={() => onDelete(user)}
          className="text-red-600 hover:text-red-900 p-1"
        >
          <DeleteIcon />
        </button>
      </td>
    </tr>
  );
};

const EditUserModal = ({ user, onSave, onCancel }) => {
  const [formData, setFormData] = useState({
    first_name: user?.first_name || '',
    last_name: user?.last_name || '',
    email: user?.email || '',
    phone_number: user?.phone_number || '',
    role: user?.role || 'client',
    is_verified: user?.is_verified || false,
    is_active: user?.is_active !== undefined ? user.is_active : true,
  });
  const [profilePicture, setProfilePicture] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value,
    }));
  };

  const handleFileChange = (e) => {
    setProfilePicture(e.target.files[0]);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    
    try {
      const dataToSend = { ...formData };
      if (profilePicture) {
        dataToSend.profile_picture = profilePicture;
      }
      await onSave(dataToSend);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center overflow-y-auto overflow-x-hidden bg-black bg-opacity-50">
      <div className="relative mx-auto my-6 w-full max-w-md p-4">
        <div className="relative rounded-lg bg-white shadow-lg">
          <div className="border-b px-6 py-4">
            <h3 className="text-lg font-semibold text-gray-900">
              {user ? 'Modifier l\'utilisateur' : 'Ajouter un utilisateur'}
            </h3>
            <button
              className="absolute top-4 right-4 text-gray-400 hover:text-gray-600"
              onClick={onCancel}
            >
              ×
            </button>
          </div>
          <form onSubmit={handleSubmit}>
            <div className="p-6 space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700" htmlFor="first_name">
                    Prénom
                  </label>
                  <input
                    type="text"
                    id="first_name"
                    name="first_name"
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    value={formData.first_name}
                    onChange={handleChange}
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700" htmlFor="last_name">
                    Nom
                  </label>
                  <input
                    type="text"
                    id="last_name"
                    name="last_name"
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    value={formData.last_name}
                    onChange={handleChange}
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700" htmlFor="email">
                  Email
                </label>
                <input
                  type="email"
                  id="email"
                  name="email"
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  value={formData.email}
                  onChange={handleChange}
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700" htmlFor="phone_number">
                  Téléphone
                </label>
                <input
                  type="text"
                  id="phone_number"
                  name="phone_number"
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  value={formData.phone_number}
                  onChange={handleChange}
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700" htmlFor="role">
                  Rôle
                </label>
                <select
                  id="role"
                  name="role"
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  value={formData.role}
                  onChange={handleChange}
                >
                  <option value="client">Client</option>
                  <option value="provider">Prestataire</option>
                  <option value="admin">Administrateur</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700" htmlFor="profile_picture">
                  Photo de profil
                </label>
                <input
                  type="file"
                  id="profile_picture"
                  name="profile_picture"
                  accept="image/*"
                  className="mt-1 block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
                  onChange={handleFileChange}
                />
              </div>

              <div className="flex items-center space-x-4">
                <div className="flex items-center">
                  <input
                    type="checkbox"
                    id="is_verified"
                    name="is_verified"
                    className="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                    checked={formData.is_verified}
                    onChange={handleChange}
                  />
                  <label
                    htmlFor="is_verified"
                    className="ml-2 text-sm text-gray-700"
                  >
                    Vérifié
                  </label>
                </div>

                <div className="flex items-center">
                  <input
                    type="checkbox"
                    id="is_active"
                    name="is_active"
                    className="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                    checked={formData.is_active}
                    onChange={handleChange}
                  />
                  <label
                    htmlFor="is_active"
                    className="ml-2 text-sm text-gray-700"
                  >
                    Actif
                  </label>
                </div>
              </div>
            </div>

            <div className="border-t bg-gray-50 px-6 py-4">
              <div className="flex justify-end space-x-3">
                <button
                  type="button"
                  className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-200 rounded-md hover:bg-gray-300"
                  onClick={onCancel}
                  disabled={loading}
                >
                  Annuler
                </button>
                <button 
                  type="submit" 
                  className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700 disabled:opacity-50"
                  disabled={loading}
                >
                  {loading ? 'Enregistrement...' : 'Enregistrer'}
                </button>
              </div>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

const DeleteConfirmationModal = ({ user, onConfirm, onCancel }) => {
  const [loading, setLoading] = useState(false);

  const handleConfirm = async () => {
    setLoading(true);
    try {
      await onConfirm(user);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center overflow-y-auto overflow-x-hidden bg-black bg-opacity-50">
      <div className="relative mx-auto my-6 w-full max-w-md p-4">
        <div className="relative rounded-lg bg-white shadow-lg">
          <div className="border-b px-6 py-4">
            <h3 className="text-lg font-semibold text-gray-900">
              Confirmer la suppression
            </h3>
          </div>
          <div className="p-6">
            <p className="text-gray-700">
              Êtes-vous sûr de vouloir supprimer l'utilisateur{' '}
              <span className="font-medium text-gray-900">
                {user.first_name
                  ? `${user.first_name} ${user.last_name}`
                  : user.username}
              </span>
              ? Cette action va désactiver le compte de manière permanente.
            </p>
          </div>
          <div className="border-t bg-gray-50 px-6 py-4">
            <div className="flex justify-end space-x-3">
              <button
                type="button"
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-200 rounded-md hover:bg-gray-300"
                onClick={onCancel}
                disabled={loading}
              >
                Annuler
              </button>
              <button
                type="button"
                className="px-4 py-2 text-sm font-medium text-white bg-red-600 rounded-md hover:bg-red-700 disabled:opacity-50"
                onClick={handleConfirm}
                disabled={loading}
              >
                {loading ? 'Suppression...' : 'Supprimer'}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

const Users = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const [search, setSearch] = useState('');
  const [editModalOpen, setEditModalOpen] = useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [currentUser, setCurrentUser] = useState(null);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const pageSize = 10;

  const fetchUsers = async () => {
    setLoading(true);
    setError('');
    try {
      const response = await userService.getAll(currentPage, pageSize, search);
      setUsers(response.data.results || []);
      setTotalCount(response.data.count || 0);
      setTotalPages(Math.ceil((response.data.count || 0) / pageSize));
    } catch (err) {
      console.error('Erreur lors du chargement des utilisateurs', err);
      setError('Impossible de charger les utilisateurs. Veuillez réessayer.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, [currentPage, search]);

  // Debounce search
  useEffect(() => {
    const timer = setTimeout(() => {
      setCurrentPage(1);
      fetchUsers();
    }, 500);

    return () => clearTimeout(timer);
  }, [search]);

  const showSuccess = (message) => {
    setSuccess(message);
    setTimeout(() => setSuccess(''), 5000);
  };

  const showError = (message) => {
    setError(message);
    setTimeout(() => setError(''), 5000);
  };

  const handleEdit = (user) => {
    setCurrentUser(user);
    setEditModalOpen(true);
  };

  const handleDelete = (user) => {
    setCurrentUser(user);
    setDeleteModalOpen(true);
  };

  const handleToggleStatus = async (user) => {
    try {
      const response = await userService.toggleStatus(user.id);
      setUsers((prevUsers) =>
        prevUsers.map((u) =>
          u.id === user.id ? { ...u, is_active: !u.is_active } : u
        )
      );
      showSuccess(response.data.detail || 'Statut modifié avec succès');
    } catch (err) {
      console.error('Erreur lors de la mise à jour du statut', err);
      showError(err.response?.data?.detail || 'Impossible de modifier le statut. Veuillez réessayer.');
    }
  };

  const handleToggleVerification = async (user) => {
    try {
      const response = await userService.toggleVerification(user.id);
      setUsers((prevUsers) =>
        prevUsers.map((u) =>
          u.id === user.id ? { ...u, is_verified: !u.is_verified } : u
        )
      );
      showSuccess(response.data.detail || 'Vérification modifiée avec succès');
    } catch (err) {
      console.error('Erreur lors de la mise à jour de la vérification', err);
      showError(err.response?.data?.detail || 'Impossible de modifier la vérification. Veuillez réessayer.');
    }
  };

  const handleSaveUser = async (formData) => {
    try {
      let response;
      if (currentUser) {
        response = await userService.update(currentUser.id, formData);
        setUsers((prevUsers) =>
          prevUsers.map((u) =>
            u.id === currentUser.id ? response.data : u
          )
        );
        showSuccess('Utilisateur modifié avec succès');
      } else {
        response = await userService.create(formData);
        await fetchUsers(); // Recharger la liste pour inclure le nouvel utilisateur
        showSuccess('Utilisateur créé avec succès');
      }
      setEditModalOpen(false);
      setCurrentUser(null);
    } catch (err) {
      console.error('Erreur lors de la sauvegarde', err);
      const errorMessage = err.response?.data?.detail || 
                          (err.response?.data && typeof err.response.data === 'object' 
                            ? Object.values(err.response.data).flat().join(', ')
                            : 'Impossible de sauvegarder les modifications. Veuillez réessayer.');
      showError(errorMessage);
    }
  };

  const handleConfirmDelete = async (user) => {
    try {
      await userService.delete(user.id);
      setUsers((prevUsers) => prevUsers.filter((u) => u.id !== user.id));
      setDeleteModalOpen(false);
      setCurrentUser(null);
      showSuccess('Utilisateur supprimé avec succès');
    } catch (err) {
      console.error('Erreur lors de la suppression', err);
      showError(err.response?.data?.detail || 'Impossible de supprimer l\'utilisateur. Veuillez réessayer.');
    }
  };

  const filteredUsers = users.filter((user) => {
    if (!search) return true;
    const searchTerm = search.toLowerCase();
    return (
      user.username.toLowerCase().includes(searchTerm) ||
      user.email.toLowerCase().includes(searchTerm) ||
      (user.first_name && user.first_name.toLowerCase().includes(searchTerm)) ||
      (user.last_name && user.last_name.toLowerCase().includes(searchTerm)) ||
      (user.phone_number && user.phone_number.includes(searchTerm))
    );
  });

  return (
    <DashboardLayout>
      <div className="space-y-6 p-6">
        {/* Messages d'erreur et de succès */}
        {error && (
          <div className="rounded-md bg-red-50 p-4 border border-red-200">
            <div className="flex">
              <div className="ml-3">
                <h3 className="text-sm font-medium text-red-800">Erreur</h3>
                <div className="mt-2 text-sm text-red-700">{error}</div>
              </div>
            </div>
          </div>
        )}

        {success && (
          <div className="rounded-md bg-green-50 p-4 border border-green-200">
            <div className="flex">
              <div className="ml-3">
                <h3 className="text-sm font-medium text-green-800">Succès</h3>
                <div className="mt-2 text-sm text-green-700">{success}</div>
              </div>
            </div>
          </div>
        )}

        <div className="flex flex-col md:flex-row md:items-center md:justify-between">
          <h1 className="text-2xl font-bold text-gray-900">
            Gestion des utilisateurs
          </h1>
          <div className="mt-4 flex items-center md:mt-0">
            <div className="relative mr-4">
              <SearchIcon className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="Rechercher..."
                className="pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500 w-full md:w-64"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
            <button
              className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700"
              onClick={() => {
                setCurrentUser(null);
                setEditModalOpen(true);
              }}
            >
              Ajouter
            </button>
          </div>
        </div>

        <div className="bg-white shadow rounded-lg overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900">
                    Utilisateur
                  </th>
                  <th className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                    Email
                  </th>
                  <th className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                    Téléphone
                  </th>
                  <th className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                    Rôle
                  </th>
                  <th className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                    Date d'inscription
                  </th>
                  <th className="px-3 py-3.5 text-center text-sm font-semibold text-gray-900">
                    Vérifié
                  </th>
                  <th className="px-3 py-3.5 text-center text-sm font-semibold text-gray-900">
                    Statut
                  </th>
                  <th className="relative py-3.5 pl-3 pr-4">
                    <span className="sr-only">Actions</span>
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 bg-white">
                {loading ? (
                  <tr>
                    <td colSpan="8" className="py-10 text-center text-gray-500">
                      <div className="flex items-center justify-center">
                        <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-blue-600"></div>
                        <span className="ml-2">Chargement...</span>
                      </div>
                    </td>
                  </tr>
                ) : filteredUsers.length === 0 ? (
                  <tr>
                    <td colSpan="8" className="py-10 text-center text-gray-500">
                      Aucun utilisateur trouvé
                    </td>
                  </tr>
                ) : (
                  filteredUsers.map((user) => (
                    <UserRow
                      key={user.id}
                      user={user}
                      onEdit={handleEdit}
                      onDelete={handleDelete}
                      onToggleStatus={handleToggleStatus}
                      onToggleVerification={handleToggleVerification}
                    />
                  ))
                )}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {!loading && totalPages > 1 && (
            <div className="flex items-center justify-between border-t bg-white px-4 py-3 sm:px-6">
              <div className="hidden sm:flex sm:flex-1 sm:items-center sm:justify-between">
                <div>
                  <p className="text-sm text-gray-700">
                    Affichage de{' '}
                    <span className="font-medium">
                      {(currentPage - 1) * pageSize + 1}
                    </span>{' '}
                    à{' '}
                    <span className="font-medium">
                      {Math.min(currentPage * pageSize, totalCount)}
                    </span>{' '}
                    sur <span className="font-medium">{totalCount}</span> résultats
                  </p>
                </div>
                <div>
                  <nav className="isolate inline-flex -space-x-px rounded-md shadow-sm">
                    <button
                      disabled={currentPage === 1}
                      onClick={() => setCurrentPage((old) => Math.max(old - 1, 1))}
                      className={`relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 ${
                        currentPage === 1
                          ? 'cursor-not-allowed'
                          : 'hover:bg-gray-50'
                      }`}
                    >
                      <ChevronLeftIcon />
                    </button>
                    
                    {/* Pages */}
                    {Array.from({ length: totalPages }, (_, i) => i + 1)
                      .filter(page => 
                        page === 1 || 
                        page === totalPages || 
                        Math.abs(page - currentPage) <= 2
                      )
                      .map((page, index, arr) => {
                        if (index > 0 && arr[index - 1] !== page - 1) {
                          return (
                            <React.Fragment key={`ellipsis-${page}`}>
                              <span className="relative inline-flex items-center px-4 py-2 text-sm font-semibold text-gray-700 ring-1 ring-inset ring-gray-300">
                                ...
                              </span>
                              <button
                                onClick={() => setCurrentPage(page)}
                                className={`relative inline-flex items-center px-4 py-2 text-sm font-semibold ${
                                  currentPage === page
                                    ? 'z-10 bg-blue-600 text-white focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600'
                                    : 'text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50'
                                }`}
                              >
                                {page}
                              </button>
                            </React.Fragment>
                          );
                        }
                        return (
                          <button
                            key={page}
                            onClick={() => setCurrentPage(page)}
                            className={`relative inline-flex items-center px-4 py-2 text-sm font-semibold ${
                              currentPage === page
                                ? 'z-10 bg-blue-600 text-white focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600'
                                : 'text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50'
                            }`}
                          >
                            {page}
                          </button>
                        );
                      })}

                    <button
                      disabled={currentPage === totalPages}
                      onClick={() =>
                        setCurrentPage((old) => Math.min(old + 1, totalPages))
                      }
                      className={`relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 ${
                        currentPage === totalPages
                          ? 'cursor-not-allowed'
                          : 'hover:bg-gray-50'
                      }`}
                    >
                      <ChevronRightIcon />
                    </button>
                  </nav>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Edit Modal */}
        {editModalOpen && (
          <EditUserModal
            user={currentUser}
            onSave={handleSaveUser}
            onCancel={() => {
              setEditModalOpen(false);
              setCurrentUser(null);
            }}
          />
        )}

        {/* Delete Confirmation Modal */}
        {deleteModalOpen && currentUser && (
          <DeleteConfirmationModal
            user={currentUser}
            onConfirm={handleConfirmDelete}
            onCancel={() => {
              setDeleteModalOpen(false);
              setCurrentUser(null);
            }}
          />
        )}
      </div>
    </DashboardLayout>
    
  );
};

export default Users;