// src/pages/UserVerification.js
import React, { useState, useEffect } from 'react';
import DashboardLayout from '../layouts/DashboardLayout';
import { withAuth } from '../context/AuthContext';
import VerificationDetailModal from '../components/VerificationDetailModal';
import verificationService from '../services/verificationService';

const UserVerification = () => {
  const [verifications, setVerifications] = useState([]);
  const [loading, setLoading] = useState(true);
  const [statistics, setStatistics] = useState({});
  const [selectedItems, setSelectedItems] = useState(new Set());
  const [filters, setFilters] = useState({
    status: '',
    search: '',
    is_business: undefined
  });
  const [showModal, setShowModal] = useState(false);
  const [modalType, setModalType] = useState(''); // 'approve', 'reject', 'bulk_approve', 'bulk_reject'
  const [currentVerification, setCurrentVerification] = useState(null);
  const [modalData, setModalData] = useState({
    rejectionReason: '',
    adminNotes: ''
  });
  
  // 🆕 États pour le modal de détail
  const [detailModalOpen, setDetailModalOpen] = useState(false);
  const [selectedVerificationId, setSelectedVerificationId] = useState(null);

  useEffect(() => {
    fetchVerifications();
    fetchStatistics();
  }, [filters]);

  const fetchVerifications = async () => {
    setLoading(true);
    try {
      const data = await verificationService.getVerifications(filters);
      setVerifications(data.results || data);
    } catch (error) {
      console.error('Erreur lors du chargement des vérifications:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchStatistics = async () => {
    try {
      const stats = await verificationService.getStatistics();
      setStatistics(stats);
    } catch (error) {
      console.error('Erreur lors du chargement des statistiques:', error);
    }
  };

  const handleSelectAll = () => {
    if (selectedItems.size === verifications.length) {
      setSelectedItems(new Set());
    } else {
      setSelectedItems(new Set(verifications.map(v => v.id)));
    }
  };

  const handleSelectItem = (id) => {
    const newSelected = new Set(selectedItems);
    if (newSelected.has(id)) {
      newSelected.delete(id);
    } else {
      newSelected.add(id);
    }
    setSelectedItems(newSelected);
  };

  const openModal = (type, verification = null) => {
    setModalType(type);
    setCurrentVerification(verification);
    setModalData({ rejectionReason: '', adminNotes: '' });
    setShowModal(true);
  };

  const closeModal = () => {
    setShowModal(false);
    setCurrentVerification(null);
    setModalData({ rejectionReason: '', adminNotes: '' });
  };

  const handleAction = async () => {
    try {
      const { rejectionReason, adminNotes } = modalData;
      
      switch (modalType) {
        case 'approve':
          await verificationService.approve(currentVerification.id, adminNotes);
          break;
        case 'reject':
          if (!rejectionReason.trim()) {
            alert('La raison du rejet est obligatoire');
            return;
          }
          await verificationService.reject(currentVerification.id, rejectionReason, adminNotes);
          break;
        case 'bulk_approve':
          await verificationService.bulkApprove(Array.from(selectedItems), adminNotes);
          setSelectedItems(new Set());
          break;
        case 'bulk_reject':
          if (!rejectionReason.trim()) {
            alert('La raison du rejet est obligatoire');
            return;
          }
          await verificationService.bulkReject(Array.from(selectedItems), rejectionReason, adminNotes);
          setSelectedItems(new Set());
          break;
      }
      
      closeModal();
      await fetchVerifications();
      await fetchStatistics();
    } catch (error) {
      console.error('Erreur lors de l\'action:', error);
      alert('Erreur lors de l\'opération');
    }
  };

  // 🆕 Fonction pour ouvrir le modal de détail
  const openDetailModal = (verificationId) => {
    setSelectedVerificationId(verificationId);
    setDetailModalOpen(true);
  };

  const closeDetailModal = () => {
    setDetailModalOpen(false);
    setSelectedVerificationId(null);
  };

  const getStatusBadge = (status) => {
    const badges = {
      pending: { bg: 'bg-yellow-100', text: 'text-yellow-800', label: '⏳ En attente' },
      verified: { bg: 'bg-green-100', text: 'text-green-800', label: '✅ Vérifié' },
      rejected: { bg: 'bg-red-100', text: 'text-red-800', label: '❌ Rejeté' }
    };
    
    const badge = badges[status] || badges.pending;
    return (
      <span className={`inline-flex rounded-full px-2 text-xs font-semibold leading-5 ${badge.bg} ${badge.text}`}>
        {badge.label}
      </span>
    );
  };

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('fr-FR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  return (
    <DashboardLayout>
      <div className="px-4 sm:px-6 lg:px-8">
        {/* En-tête avec statistiques */}
        <div className="sm:flex sm:items-center sm:justify-between mb-8">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Vérification des Utilisateurs</h1>
            <p className="mt-1 text-sm text-gray-500">
              Gérez les demandes de vérification des prestataires
            </p>
          </div>
        </div>

        {/* Statistiques */}
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-4 mb-6">
          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <span className="text-2xl">📊</span>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">Total</dt>
                    <dd className="text-lg font-medium text-gray-900">{statistics.total || 0}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <span className="text-2xl">⏳</span>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">En attente</dt>
                    <dd className="text-lg font-medium text-yellow-600">{statistics.pending || 0}</dd>
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
                    <dd className="text-lg font-medium text-green-600">{statistics.verified || 0}</dd>
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
                    <dd className="text-lg font-medium text-red-600">{statistics.rejected || 0}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Filtres et actions */}
        <div className="bg-white shadow rounded-lg mb-6">
          <div className="px-4 py-3 border-b border-gray-200">
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-3 sm:space-y-0">
              <div className="flex flex-col sm:flex-row space-y-2 sm:space-y-0 sm:space-x-3">
                {/* Filtre par statut */}
                <select
                  value={filters.status}
                  onChange={(e) => setFilters({...filters, status: e.target.value})}
                  className="rounded-md border-gray-300 py-2 pl-3 pr-10 text-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
                >
                  <option value="">Tous les statuts</option>
                  <option value="pending">En attente</option>
                  <option value="verified">Vérifiés</option>
                  <option value="rejected">Rejetés</option>
                </select>

                {/* Filtre par type */}
                <select
                  value={filters.is_business === undefined ? '' : filters.is_business.toString()}
                  onChange={(e) => setFilters({
                    ...filters, 
                    is_business: e.target.value === '' ? undefined : e.target.value === 'true'
                  })}
                  className="rounded-md border-gray-300 py-2 pl-3 pr-10 text-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
                >
                  <option value="">Tous les types</option>
                  <option value="false">Particulier</option>
                  <option value="true">Entreprise</option>
                </select>

                {/* Recherche */}
                <input
                  type="text"
                  placeholder="Rechercher un utilisateur..."
                  value={filters.search}
                  onChange={(e) => setFilters({...filters, search: e.target.value})}
                  className="rounded-md border-gray-300 py-2 pl-3 pr-3 text-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
                />
              </div>

              {/* Actions en lot */}
              {selectedItems.size > 0 && (
                <div className="flex space-x-2">
                  <button
                    onClick={() => openModal('bulk_approve')}
                    className="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
                  >
                    ✅ Approuver ({selectedItems.size})
                  </button>
                  <button
                    onClick={() => openModal('bulk_reject')}
                    className="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
                  >
                    ❌ Rejeter ({selectedItems.size})
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Tableau des vérifications */}
        <div className="bg-white shadow overflow-hidden sm:rounded-md">
          <div className="min-w-full divide-y divide-gray-200">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    <input
                      type="checkbox"
                      checked={selectedItems.size === verifications.length && verifications.length > 0}
                      onChange={handleSelectAll}
                      className="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                    />
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Utilisateur
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Type
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Statut
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Date de soumission
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {loading ? (
                  <tr>
                    <td colSpan="6" className="px-6 py-4 text-center">
                      <div className="flex justify-center">
                        <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-indigo-600"></div>
                      </div>
                    </td>
                  </tr>
                ) : verifications.length === 0 ? (
                  <tr>
                    <td colSpan="6" className="px-6 py-4 text-center text-gray-500">
                      Aucune vérification trouvée
                    </td>
                  </tr>
                ) : (
                  verifications.map((verification) => (
                    <tr key={verification.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <input
                          type="checkbox"
                          checked={selectedItems.has(verification.id)}
                          onChange={() => handleSelectItem(verification.id)}
                          className="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                        />
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center">
                          <div className="flex-shrink-0 h-10 w-10">
                            <div className="h-10 w-10 rounded-full bg-gray-200 flex items-center justify-center">
                              <span className="text-sm font-medium text-gray-700">
                                {verification.provider_info?.username?.charAt(0)?.toUpperCase() || 'U'}
                              </span>
                            </div>
                          </div>
                          <div className="ml-4">
                            <div className="text-sm font-medium text-gray-900">
                              {verification.provider_name}
                            </div>
                            <div className="text-sm text-gray-500">
                              {verification.provider_email}
                            </div>
                           
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`inline-flex rounded-full px-2 text-xs font-semibold leading-5 ${
                          verification.is_business 
                            ? 'bg-purple-100 text-purple-800' 
                            : 'bg-blue-100 text-blue-800'
                        }`}>
                          {verification.is_business ? '🏢 Entreprise' : '👤 Particulier'}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        {getStatusBadge(verification.verification_status)}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {formatDate(verification.submitted_at)}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                        <div className="flex space-x-2">
                          {verification.verification_status === 'pending' && (
                            <>
                              <button
                                onClick={() => openModal('approve', verification)}
                                className="text-green-600 hover:text-green-900"
                              >
                                ✅ Approuver
                              </button>
                              <button
                                onClick={() => openModal('reject', verification)}
                                className="text-red-600 hover:text-red-900"
                              >
                                ❌ Rejeter
                              </button>
                            </>
                          )}
                          <button
                            onClick={() => openDetailModal(verification.id)}
                            className="text-indigo-600 hover:text-indigo-900"
                          >
                            👁️ Voir détails
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Modal pour les actions */}
        {showModal && (
          <div className="fixed inset-0 z-50 overflow-y-auto">
            <div className="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
              <div className="fixed inset-0 transition-opacity" aria-hidden="true">
                <div className="absolute inset-0 bg-gray-500 opacity-75"></div>
              </div>

              <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
                <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                  <div className="sm:flex sm:items-start">
                    <div className="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left w-full">
                      <h3 className="text-lg leading-6 font-medium text-gray-900">
                        {modalType === 'approve' && 'Approuver la vérification'}
                        {modalType === 'reject' && 'Rejeter la vérification'}
                        {modalType === 'bulk_approve' && `Approuver ${selectedItems.size} vérifications`}
                        {modalType === 'bulk_reject' && `Rejeter ${selectedItems.size} vérifications`}
                      </h3>
                      <div className="mt-4 space-y-4">
                        {(modalType === 'reject' || modalType === 'bulk_reject') && (
                          <div>
                            <label className="block text-sm font-medium text-gray-700">
                              Raison du rejet *
                            </label>
                            <textarea
                              value={modalData.rejectionReason}
                              onChange={(e) => setModalData({...modalData, rejectionReason: e.target.value})}
                              rows={3}
                              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                              placeholder="Expliquez pourquoi vous rejetez cette vérification..."
                            />
                          </div>
                        )}
                        <div>
                          <label className="block text-sm font-medium text-gray-700">
                            Notes administratives (optionnel)
                          </label>
                          <textarea
                            value={modalData.adminNotes}
                            onChange={(e) => setModalData({...modalData, adminNotes: e.target.value})}
                            rows={2}
                            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            placeholder="Notes internes pour le suivi..."
                          />
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                <div className="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                  <button
                    type="button"
                    onClick={handleAction}
                    className={`w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 text-base font-medium text-white focus:outline-none focus:ring-2 focus:ring-offset-2 sm:ml-3 sm:w-auto sm:text-sm ${
                      (modalType === 'approve' || modalType === 'bulk_approve')
                        ? 'bg-green-600 hover:bg-green-700 focus:ring-green-500'
                        : 'bg-red-600 hover:bg-red-700 focus:ring-red-500'
                    }`}
                  >
                    {(modalType === 'approve' || modalType === 'bulk_approve') ? '✅ Approuver' : '❌ Rejeter'}
                  </button>
                  <button
                    type="button"
                    onClick={closeModal}
                    className="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
                  >
                    Annuler
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* 🆕 Modal de détail de vérification */}
      <VerificationDetailModal
        isOpen={detailModalOpen}
        onClose={closeDetailModal}
        verificationId={selectedVerificationId}
      />
    </DashboardLayout>
  );
};

export default withAuth(UserVerification);