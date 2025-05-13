import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import DashboardLayout from '../layouts/DashboardLayout';
import { userService } from '../services/api';
import { withAuth } from '../context/AuthContext';

// Icônes
import SearchIcon from '@mui/icons-material/Search';
import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/Delete';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import CancelIcon from '@mui/icons-material/Cancel';
import ChevronLeftIcon from '@mui/icons-material/ChevronLeft';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';

const UserRow = ({ user, onEdit, onDelete, onToggleStatus }) => {
  return (
    <tr className="hover:bg-gray-50">
      <td className="whitespace-nowrap py-3 pl-4 pr-3 text-sm sm:pl-6">
        <div className="flex items-center">
          <div className="h-10 w-10 flex-shrink-0">
            {user.profile_picture ? (
              <img
                className="h-10 w-10 rounded-full"
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
            <div className="font-medium text-text-primary">
              {user.first_name
                ? `${user.first_name} ${user.last_name}`
                : user.username}
            </div>
            <div className="text-text-secondary">{user.username}</div>
          </div>
        </div>
      </td>
      <td className="whitespace-nowrap px-3 py-3 text-sm text-text-secondary">
        {user.email}
      </td>
      <td className="whitespace-nowrap px-3 py-3 text-sm text-text-secondary">
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
      <td className="whitespace-nowrap px-3 py-3 text-sm text-text-secondary">
        {new Date(user.date_joined).toLocaleDateString('fr-FR')}
      </td>
      <td className="whitespace-nowrap px-3 py-3 text-sm text-center">
        {user.is_verified ? (
          <CheckCircleIcon className="text-success" />
        ) : (
          <CancelIcon className="text-error" />
        )}
      </td>
      <td className="relative whitespace-nowrap py-3 pl-3 pr-4 text-right text-sm font-medium sm:pr-6">
        <button
          onClick={() => onEdit(user)}
          className="text-primary hover:text-primary-dark mr-2"
        >
          <EditIcon fontSize="small" />
        </button>
        <button
          onClick={() => onToggleStatus(user)}
          className="text-secondary hover:text-secondary-dark mr-2"
        >
          {user.is_active ? (
            <CancelIcon fontSize="small" />
          ) : (
            <CheckCircleIcon fontSize="small" />
          )}
        </button>
        <button
          onClick={() => onDelete(user)}
          className="text-error hover:text-red-700"
        >
          <DeleteIcon fontSize="small" />
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

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value,
    }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    onSave(formData);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center overflow-y-auto overflow-x-hidden bg-black bg-opacity-50">
      <div className="relative mx-auto my-6 w-full max-w-md p-4">
        <div className="relative rounded-lg bg-white shadow-lg">
          <div className="border-b px-6 py-4">
            <h3 className="text-lg font-semibold text-text-primary">
              {user ? 'Modifier l\'utilisateur' : 'Ajouter un utilisateur'}
            </h3>
            <button
              className="absolute top-4 right-4 text-text-disabled hover:text-text-secondary"
              onClick={onCancel}
            >
              &times;
            </button>
          </div>
          <form onSubmit={handleSubmit}>
            <div className="p-6">
              <div className="mb-4 grid grid-cols-2 gap-4">
                <div>
                  <label className="label" htmlFor="first_name">
                    Prénom
                  </label>
                  <input
                    type="text"
                    id="first_name"
                    name="first_name"
                    className="input w-full"
                    value={formData.first_name}
                    onChange={handleChange}
                  />
                </div>
                <div>
                  <label className="label" htmlFor="last_name">
                    Nom
                  </label>
                  <input
                    type="text"
                    id="last_name"
                    name="last_name"
                    className="input w-full"
                    value={formData.last_name}
                    onChange={handleChange}
                  />
                </div>
              </div>

              <div className="mb-4">
                <label className="label" htmlFor="email">
                  Email
                </label>
                <input
                  type="email"
                  id="email"
                  name="email"
                  className="input w-full"
                  value={formData.email}
                  onChange={handleChange}
                  required
                />
              </div>

              <div className="mb-4">
                <label className="label" htmlFor="phone_number">
                  Téléphone
                </label>
                <input
                  type="text"
                  id="phone_number"
                  name="phone_number"
                  className="input w-full"
                  value={formData.phone_number}
                  onChange={handleChange}
                />
              </div>

              <div className="mb-4">
                <label className="label" htmlFor="role">
                  Rôle
                </label>
                <select
                  id="role"
                  name="role"
                  className="input w-full"
                  value={formData.role}
                  onChange={handleChange}
                >
                  <option value="client">Client</option>
                  <option value="provider">Prestataire</option>
                  <option value="admin">Administrateur</option>
                </select>
              </div>

              <div className="mb-4 flex items-center space-x-4">
                <div className="flex items-center">
                  <input
                    type="checkbox"
                    id="is_verified"
                    name="is_verified"
                    className="h-4 w-4 rounded border-gray-300 text-primary focus:ring-primary"
                    checked={formData.is_verified}
                    onChange={handleChange}
                  />
                  <label
                    htmlFor="is_verified"
                    className="ml-2 text-sm text-text-secondary"
                  >
                    Vérifié
                  </label>
                </div>

                <div className="flex items-center">
                  <input
                    type="checkbox"
                    id="is_active"
                    name="is_active"
                    className="h-4 w-4 rounded border-gray-300 text-primary focus:ring-primary"
                    checked={formData.is_active}
                    onChange={handleChange}
                  />
                  <label
                    htmlFor="is_active"
                    className="ml-2 text-sm text-text-secondary"
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
                  className="btn bg-gray-200 text-text-secondary hover:bg-gray-300"
                  onClick={onCancel}
                >
                  Annuler
                </button>
                <button type="submit" className="btn btn-primary">
                  Enregistrer
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
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center overflow-y-auto overflow-x-hidden bg-black bg-opacity-50">
      <div className="relative mx-auto my-6 w-full max-w-md p-4">
        <div className="relative rounded-lg bg-white shadow-lg">
          <div className="border-b px-6 py-4">
            <h3 className="text-lg font-semibold text-text-primary">
              Confirmer la suppression
            </h3>
          </div>
          <div className="p-6">
            <p className="text-text-secondary">
              Êtes-vous sûr de vouloir supprimer l'utilisateur{' '}
              <span className="font-medium text-text-primary">
                {user.first_name
                  ? `${user.first_name} ${user.last_name}`
                  : user.username}
              </span>
              ? Cette action est irréversible.
            </p>
          </div>
          <div className="border-t bg-gray-50 px-6 py-4">
            <div className="flex justify-end space-x-3">
              <button
                type="button"
                className="btn bg-gray-200 text-text-secondary hover:bg-gray-300"
                onClick={onCancel}
              >
                Annuler
              </button>
              <button
                type="button"
                className="btn bg-error text-white hover:bg-red-700"
                onClick={() => onConfirm(user)}
              >
                Supprimer
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
  const [search, setSearch] = useState('');
  const [editModalOpen, setEditModalOpen] = useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [currentUser, setCurrentUser] = useState(null);
  const [error, setError] = useState('');

  const fetchUsers = async () => {
    setLoading(true);
    setError('');
    try {
      const response = await userService.getAll(currentPage);
      setUsers(response.data.results || []);
      setTotalPages(Math.ceil(response.data.count / 10));
    } catch (err) {
      console.error('Erreur lors du chargement des utilisateurs', err);
      setError('Impossible de charger les utilisateurs. Veuillez réessayer.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, [currentPage]);

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
      await userService.update(user.id, { is_active: !user.is_active });
      setUsers((prevUsers) =>
        prevUsers.map((u) =>
          u.id === user.id ? { ...u, is_active: !u.is_active } : u
        )
      );
    } catch (err) {
      console.error('Erreur lors de la mise à jour du statut', err);
      setError('Impossible de modifier le statut. Veuillez réessayer.');
    }
  };

  const handleSaveUser = async (formData) => {
    try {
      if (currentUser) {
        await userService.update(currentUser.id, formData);
        setUsers((prevUsers) =>
          prevUsers.map((u) =>
            u.id === currentUser.id ? { ...u, ...formData } : u
          )
        );
      } else {
        // Pour la création d'un nouvel utilisateur (non implémenté ici)
      }
      setEditModalOpen(false);
    } catch (err) {
      console.error('Erreur lors de la sauvegarde', err);
      setError('Impossible de sauvegarder les modifications. Veuillez réessayer.');
    }
  };

  const handleConfirmDelete = async (user) => {
    try {
      await userService.delete(user.id);
      setUsers((prevUsers) => prevUsers.filter((u) => u.id !== user.id));
      setDeleteModalOpen(false);
    } catch (err) {
      console.error('Erreur lors de la suppression', err);
      setError('Impossible de supprimer l\'utilisateur. Veuillez réessayer.');
    }
  };

  const filteredUsers = users.filter((user) => {
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
      <div className="space-y-6">
        {error && (
          <div className="rounded-md bg-error/10 p-4">
            <div className="flex">
              <div className="ml-3">
                <h3 className="text-sm font-medium text-error">Erreur</h3>
                <div className="mt-2 text-sm text-error">{error}</div>
              </div>
            </div>
          </div>
        )}

        <div className="flex flex-col md:flex-row md:items-center md:justify-between">
          <h1 className="text-2xl font-bold text-text-primary">
            Gestion des utilisateurs
          </h1>
          <div className="mt-4 flex items-center md:mt-0">
            <div className="relative mr-4">
              <SearchIcon className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-text-disabled" />
              <input
                type="text"
                placeholder="Rechercher..."
                className="input w-full pl-10 md:w-64"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
            <button
              className="btn btn-primary"
              onClick={() => {
                setCurrentUser(null);
                setEditModalOpen(true);
              }}
            >
              Ajouter
            </button>
          </div>
        </div>

        <div className="card overflow-hidden p-0">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th
                    scope="col"
                    className="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-text-secondary sm:pl-6"
                  >
                    Utilisateur
                  </th>
                  <th
                    scope="col"
                    className="px-3 py-3.5 text-left text-sm font-semibold text-text-secondary"
                  >
                    Email
                  </th>
                  <th
                    scope="col"
                    className="px-3 py-3.5 text-left text-sm font-semibold text-text-secondary"
                  >
                    Téléphone
                  </th>
                  <th
                    scope="col"
                    className="px-3 py-3.5 text-left text-sm font-semibold text-text-secondary"
                  >
                    Rôle
                  </th>
                  <th
                    scope="col"
                    className="px-3 py-3.5 text-left text-sm font-semibold text-text-secondary"
                  >
                    Date d'inscription
                  </th>
                  <th
                    scope="col"
                    className="px-3 py-3.5 text-center text-sm font-semibold text-text-secondary"
                  >
                    Vérifié
                  </th>
                  <th
                    scope="col"
                    className="relative py-3.5 pl-3 pr-4 sm:pr-6"
                  >
                    <span className="sr-only">Actions</span>
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 bg-white">
                {loading ? (
                  <tr>
                    <td colSpan="7" className="py-10 text-center text-text-secondary">
                      <div className="flex items-center justify-center">
                        <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-primary"></div>
                        <span className="ml-2">Chargement...</span>
                      </div>
                    </td>
                  </tr>
                ) : filteredUsers.length === 0 ? (
                  <tr>
                    <td colSpan="7" className="py-10 text-center text-text-secondary">
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
                  <p className="text-sm text-text-secondary">
                    Page <span className="font-medium">{currentPage}</span> sur{' '}
                    <span className="font-medium">{totalPages}</span>
                  </p>
                </div>
                <div>
                  <nav
                    className="isolate inline-flex -space-x-px rounded-md shadow-sm"
                    aria-label="Pagination"
                  >
                    <button
                      disabled={currentPage === 1}
                      onClick={() => setCurrentPage((old) => Math.max(old - 1, 1))}
                      className={`relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-400 ${
                        currentPage === 1
                          ? 'cursor-not-allowed'
                          : 'hover:bg-primary/10'
                      }`}
                    >
                      <span className="sr-only">Previous</span>
                      <ChevronLeftIcon className="h-5 w-5" aria-hidden="true" />
                    </button>
                    {/* Current page */}
                    <span
                      aria-current="page"
                      className="relative z-10 inline-flex items-center bg-primary px-4 py-2 text-sm font-semibold text-white focus:z-20 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                    >
                      {currentPage}
                    </span>
                    <button
                      disabled={currentPage === totalPages}
                      onClick={() =>
                        setCurrentPage((old) => Math.min(old + 1, totalPages))
                      }
                      className={`relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-400 ${
                        currentPage === totalPages
                          ? 'cursor-not-allowed'
                          : 'hover:bg-primary/10'
                      }`}
                    >
                      <span className="sr-only">Next</span>
                      <ChevronRightIcon className="h-5 w-5" aria-hidden="true" />
                    </button>
                  </nav>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Edit Modal */}
      {editModalOpen && (
        <EditUserModal
          user={currentUser}
          onSave={handleSaveUser}
          onCancel={() => setEditModalOpen(false)}
        />
      )}

      {/* Delete Confirmation Modal */}
      {deleteModalOpen && currentUser && (
        <DeleteConfirmationModal
          user={currentUser}
          onConfirm={handleConfirmDelete}
          onCancel={() => setDeleteModalOpen(false)}
        />
      )}
    </DashboardLayout>
  );
};

export default withAuth(Users);