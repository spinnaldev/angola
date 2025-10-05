// angola-admin/src/pages/ClientVerification.js
import React, { useState, useEffect } from 'react';
import DashboardLayout from '../layouts/DashboardLayout';
import { withAuth } from '../context/AuthContext';
import ClientVerificationDetailModal from '../components/ClientVerificationDetailModal';
import clientVerificationService from '../services/clientVerificationService';

const ClientVerification = () => {
  const [verifications, setVerifications] = useState([]);
  const [loading, setLoading] = useState(true);
  const [statistics, setStatistics] = useState({});
  const [filters, setFilters] = useState({
    status: '',
    search: '',
    document_type: ''
  });
  const [showModal, setShowModal] = useState(false);
  const [modalType, setModalType] = useState('');
  const [currentVerification, setCurrentVerification] = useState(null);
  const [modalData, setModalData] = useState({
    rejectionReason: '',
    adminNotes: ''
  });
  const [detailModalOpen, setDetailModalOpen] = useState(false);
  const [selectedVerificationId, setSelectedVerificationId] = useState(null);

  useEffect(() => {
    fetchVerifications();
    fetchStatistics();
  }, [filters]);

  const fetchVerifications = async () => {
    setLoading(true);
    try {
      const data = await clientVerificationService.getVerifications(filters);
      setVerifications(data.results || data);
    } catch (error) {
      console.error('Erreur lors du chargement des vérifications:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchStatistics = async () => {
    try {
      const stats = await clientVerificationService.getStatistics();
      setStatistics(stats);
    } catch (error) {
      console.error('Erreur lors du chargement des statistiques:', error);
    }
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
          await clientVerificationService.approve(currentVerification.id, adminNotes);
          break;
        case 'reject':
          if (!rejectionReason.trim()) {
            alert('La raison du rejet est obligatoire');
            return;
          }
          await clientVerificationService.reject(currentVerification.id, rejectionReason, adminNotes);
          break;
        case 'reset':
          await clientVerificationService.reset(currentVerification.id);
          break;
      }
      
      closeModal();
      fetchVerifications();
      fetchStatistics();
    } catch (error) {
      console.error('Erreur lors de l\'action:', error);
      alert('Erreur: ' + error.message);
    }
  };

  const openDetailModal = (verificationId) => {
    setSelectedVerificationId(verificationId);
    setDetailModalOpen(true);
  };

  const getStatusBadge = (status) => {
    const statusConfig = {
      'pending': { color: 'bg-yellow-100 text-yellow-800', text: 'En attente', icon: '⏳' },
      'verified': { color: 'bg-green-100 text-green-800', text: 'Vérifié', icon: '✅' },
      'rejected': { color: 'bg-red-100 text-red-800', text: 'Rejeté', icon: '❌' },
      'not_started': { color: 'bg-gray-100 text-gray-800', text: 'Non démarré', icon: '📋' }
    };

    const config = statusConfig[status] || statusConfig['not_started'];
    return (
      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${config.color}`}>
        <span className="mr-1">{config.icon}</span>
        {config.text}
      </span>
    );
  };

  const getDocumentTypeBadge = (docType) => {
    const types = {
      'id_card': { text: 'Carte d\'identité', icon: '🪪' },
      'passport': { text: 'Passeport', icon: '📘' }
    };
    const config = types[docType] || { text: docType, icon: '📄' };
    return (
      <span className="text-sm text-gray-600">
        <span className="mr-1">{config.icon}</span>
        {config.text}
      </span>
    );
  };

  const formatDate = (dateString) => {
    if (!dateString) return 'N/A';
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
      <div className="px-4 sm:px-6 lg:px-8 py-8">
        {/* En-tête */}
        <div className="sm:flex sm:items-center sm:justify-between mb-6">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">
              Vérifications Clients
            </h1>
            <p className="mt-2 text-sm text-gray-700">
              Gérer les vérifications d'identité des clients
            </p>
          </div>
        </div>

        {/* Statistiques */}
        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-5 mb-8">
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

          <div className="bg-yellow-50 overflow-hidden shadow rounded-lg border border-yellow-200">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <span className="text-2xl">⏳</span>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-yellow-700 truncate">En attente</dt>
                    <dd className="text-lg font-medium text-yellow-900">{statistics.pending || 0}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-green-50 overflow-hidden shadow rounded-lg border border-green-200">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <span className="text-2xl">✅</span>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-green-700 truncate">Vérifiés</dt>
                    <dd className="text-lg font-medium text-green-900">{statistics.verified || 0}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-red-50 overflow-hidden shadow rounded-lg border border-red-200">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <span className="text-2xl">❌</span>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-red-700 truncate">Rejetés</dt>
                    <dd className="text-lg font-medium text-red-900">{statistics.rejected || 0}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-orange-50 overflow-hidden shadow rounded-lg border border-orange-200">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <span className="text-2xl">🚨</span>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-orange-700 truncate">Urgents</dt>
                    <dd className="text-lg font-medium text-orange-900">{statistics.urgent || 0}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Filtres */}
        <div className="bg-white shadow rounded-lg mb-6 p-4">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Statut
              </label>
              <select
                value={filters.status}
                onChange={(e) => setFilters({...filters, status: e.target.value})}
                className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
              >
                <option value="">Tous les statuts</option>
                <option value="pending">En attente</option>
                <option value="verified">Vérifiés</option>
                <option value="rejected">Rejetés</option>
                <option value="not_started">Non démarrés</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Type de document
              </label>
              <select
                value={filters.document_type}
                onChange={(e) => setFilters({...filters, document_type: e.target.value})}
                className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
              >
                <option value="">Tous les types</option>
                <option value="id_card">Carte d'identité</option>
                <option value="passport">Passeport</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Rechercher
              </label>
              <input
                type="text"
                placeholder="Nom, email..."
                value={filters.search}
                onChange={(e) => setFilters({...filters, search: e.target.value})}
                className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
              />
            </div>
          </div>
        </div>

        {/* Tableau */}
        <div className="bg-white shadow rounded-lg overflow-hidden">
          {loading ? (
            <div className="text-center py-12">
              <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
              <p className="mt-2 text-sm text-gray-500">Chargement...</p>
            </div>
          ) : (
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Client
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Document
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
                {verifications.map((verification) => (
                  <tr key={verification.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <div className="flex-shrink-0 h-10 w-10">
                          <div className="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center">
                            <span className="text-xl">👤</span>
                          </div>
                        </div>
                        <div className="ml-4">
                          <div className="text-sm font-medium text-gray-900">
                            {verification.user_info?.username || 'N/A'}
                          </div>
                          <div className="text-sm text-gray-500">
                            {verification.user_info?.email || 'N/A'}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {getDocumentTypeBadge(verification.document_type)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {getStatusBadge(verification.verification_status)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {formatDate(verification.submitted_at)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium space-x-2">
                      <button
                        onClick={() => openDetailModal(verification.id)}
                        className="text-blue-600 hover:text-blue-900"
                      >
                        👁️ Voir
                      </button>
                      
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

                      {verification.verification_status === 'rejected' && (
                        <button
                          onClick={() => openModal('reset', verification)}
                          className="text-orange-600 hover:text-orange-900"
                        >
                          🔄 Réinitialiser
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}

          {!loading && verifications.length === 0 && (
            <div className="text-center py-12">
              <span className="text-4xl">📭</span>
              <p className="mt-2 text-sm text-gray-500">Aucune vérification trouvée</p>
            </div>
          )}
        </div>
      </div>

      {/* Modal d'action */}
      {showModal && (
        <div className="fixed z-10 inset-0 overflow-y-auto">
          <div className="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
            <div className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"></div>
            
            <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
              <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                <div className="sm:flex sm:items-start">
                  <div className="mt-3 text-center sm:mt-0 sm:text-left w-full">
                    <h3 className="text-lg leading-6 font-medium text-gray-900 mb-4">
                      {modalType === 'approve' && '✅ Approuver la vérification'}
                      {modalType === 'reject' && '❌ Rejeter la vérification'}
                      {modalType === 'reset' && '🔄 Réinitialiser la vérification'}
                    </h3>
                    
                    <div className="mt-2 space-y-4">
                      {modalType === 'reject' && (
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-1">
                            Raison du rejet *
                          </label>
                          <textarea
                            value={modalData.rejectionReason}
                            onChange={(e) => setModalData({...modalData, rejectionReason: e.target.value})}
                            className="w-full rounded-md border-gray-300 shadow-sm focus:border-red-500 focus:ring-red-500 sm:text-sm"
                            rows="3"
                            placeholder="Expliquez pourquoi la vérification est rejetée..."
                          />
                        </div>
                      )}

                      {modalType !== 'reset' && (
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-1">
                            Notes administratives (optionnel)
                          </label>
                          <textarea
                            value={modalData.adminNotes}
                            onChange={(e) => setModalData({...modalData, adminNotes: e.target.value})}
                            className="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
                            rows="2"
                            placeholder="Ajoutez des notes internes..."
                          />
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              </div>
              <div className="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                <button
                  type="button"
                  onClick={handleAction}
                  className={`w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 text-base font-medium text-white focus:outline-none focus:ring-2 focus:ring-offset-2 sm:ml-3 sm:w-auto sm:text-sm ${
                    modalType === 'approve' ? 'bg-green-600 hover:bg-green-700 focus:ring-green-500' :
                    modalType === 'reject' ? 'bg-red-600 hover:bg-red-700 focus:ring-red-500' :
                    'bg-orange-600 hover:bg-orange-700 focus:ring-orange-500'
                  }`}
                >
                  Confirmer
                </button>
                <button
                  type="button"
                  onClick={closeModal}
                  className="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
                >
                  Annuler
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Modal de détail */}
      {detailModalOpen && (
        <ClientVerificationDetailModal
          verificationId={selectedVerificationId}
          onClose={() => {
            setDetailModalOpen(false);
            setSelectedVerificationId(null);
            fetchVerifications();
            fetchStatistics();
          }}
        />
      )}
    </DashboardLayout>
  );
};

export default withAuth(ClientVerification);