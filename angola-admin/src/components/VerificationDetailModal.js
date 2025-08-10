// src/components/VerificationDetailModal.js
import React, { useState, useEffect } from 'react';

const VerificationDetailModal = ({ isOpen, onClose, verificationId }) => {
  const [verification, setVerification] = useState(null);
  const [loading, setLoading] = useState(true);
  const [imageModalOpen, setImageModalOpen] = useState(false);
  const [selectedImage, setSelectedImage] = useState('');

  useEffect(() => {
    if (isOpen && verificationId) {
      fetchVerificationDetail();
    }
  }, [isOpen, verificationId]);

  const fetchVerificationDetail = async () => {
    setLoading(true);
    try {
      const response = await fetch(`/api/admin/provider-verification/${verificationId}/`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
        },
      });
      const data = await response.json();
      setVerification(data);
    } catch (error) {
      console.error('Erreur lors du chargement du détail:', error);
    } finally {
      setLoading(false);
    }
  };

  const openImageModal = (imageUrl) => {
    setSelectedImage(imageUrl);
    setImageModalOpen(true);
  };

  const formatDate = (dateString) => {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleDateString('fr-FR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const getStatusBadge = (status) => {
    const badges = {
      pending: { bg: 'bg-yellow-100', text: 'text-yellow-800', label: '⏳ En attente' },
      verified: { bg: 'bg-green-100', text: 'text-green-800', label: '✅ Vérifié' },
      rejected: { bg: 'bg-red-100', text: 'text-red-800', label: '❌ Rejeté' }
    };
    
    const badge = badges[status] || badges.pending;
    return (
      <span className={`inline-flex rounded-full px-3 py-1 text-sm font-semibold ${badge.bg} ${badge.text}`}>
        {badge.label}
      </span>
    );
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div className="fixed inset-0 transition-opacity" aria-hidden="true">
          <div className="absolute inset-0 bg-gray-500 opacity-75" onClick={onClose}></div>
        </div>

        <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-4xl sm:w-full">
          {/* En-tête */}
          <div className="bg-white px-6 py-4 border-b border-gray-200">
            <div className="flex items-center justify-between">
              <h3 className="text-xl leading-6 font-medium text-gray-900">
                Détail de la vérification
              </h3>
              <button
                onClick={onClose}
                className="text-gray-400 hover:text-gray-600 transition-colors"
              >
                <span className="sr-only">Fermer</span>
                <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          </div>

          {/* Contenu */}
          <div className="bg-white px-6 py-4 max-h-96 overflow-y-auto">
            {loading ? (
              <div className="flex justify-center py-8">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
              </div>
            ) : verification ? (
              <div className="space-y-6">
                {/* Informations générales */}
                <div className="bg-gray-50 rounded-lg p-4">
                  <h4 className="text-lg font-medium text-gray-900 mb-4">Informations générales</h4>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-500">Utilisateur</label>
                      <p className="mt-1 text-sm text-gray-900">{verification.provider_info?.username}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-500">Email</label>
                      <p className="mt-1 text-sm text-gray-900">{verification.provider_info?.email}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-500">Téléphone</label>
                      <p className="mt-1 text-sm text-gray-900">{verification.provider_info?.phone_number || '-'}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-500">Type</label>
                      <p className="mt-1">
                        <span className={`inline-flex rounded-full px-2 text-xs font-semibold leading-5 ${
                          verification.is_business 
                            ? 'bg-purple-100 text-purple-800' 
                            : 'bg-blue-100 text-blue-800'
                        }`}>
                          {verification.is_business ? '🏢 Entreprise' : '👤 Particulier'}
                        </span>
                      </p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-500">Statut</label>
                      <p className="mt-1">{getStatusBadge(verification.verification_status)}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-500">Date de soumission</label>
                      <p className="mt-1 text-sm text-gray-900">{formatDate(verification.submitted_at)}</p>
                    </div>
                  </div>
                </div>

                {/* Informations d'entreprise */}
                {verification.is_business && (
                  <div className="bg-purple-50 rounded-lg p-4">
                    <h4 className="text-lg font-medium text-gray-900 mb-4">Informations d'entreprise</h4>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-500">Nom de l'entreprise</label>
                        <p className="mt-1 text-sm text-gray-900">{verification.business_name || '-'}</p>
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-500">NIF</label>
                        <p className="mt-1 text-sm text-gray-900">{verification.business_nif || '-'}</p>
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-500">Numéro d'enregistrement</label>
                        <p className="mt-1 text-sm text-gray-900">{verification.business_registration_number || '-'}</p>
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-500">Description</label>
                        <p className="mt-1 text-sm text-gray-900">{verification.business_description || '-'}</p>
                      </div>
                    </div>
                  </div>
                )}

                {/* Documents d'identité */}
                <div className="bg-blue-50 rounded-lg p-4">
                  <h4 className="text-lg font-medium text-gray-900 mb-4">Documents d'identité</h4>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-500">Type de document</label>
                      <p className="mt-1 text-sm text-gray-900">
                        {verification.document_type === 'id_card' ? '🆔 Carte d\'identité' : '📖 Passeport'}
                      </p>
                    </div>
                  </div>
                  
                  <div className="mt-4 grid grid-cols-1 md:grid-cols-2 gap-4">
                    {/* Document recto */}
                    {verification.id_card_front && (
                      <div>
                        <label className="block text-sm font-medium text-gray-500 mb-2">
                          Carte d'identité (Recto)
                        </label>
                        <div 
                          className="relative cursor-pointer group"
                          onClick={() => openImageModal(verification.id_card_front)}
                        >
                          <img
                            src={verification.id_card_front}
                            alt="Carte d'identité recto"
                            className="w-full h-32 object-cover rounded-lg border-2 border-gray-200 group-hover:border-indigo-500 transition-colors"
                          />
                          <div className="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-10 transition-all rounded-lg flex items-center justify-center">
                            <span className="text-white text-sm opacity-0 group-hover:opacity-100 transition-opacity">
                              👁️ Voir en grand
                            </span>
                          </div>
                        </div>
                      </div>
                    )}

                    {/* Document verso */}
                    {verification.id_card_back && (
                      <div>
                        <label className="block text-sm font-medium text-gray-500 mb-2">
                          Carte d'identité (Verso)
                        </label>
                        <div 
                          className="relative cursor-pointer group"
                          onClick={() => openImageModal(verification.id_card_back)}
                        >
                          <img
                            src={verification.id_card_back}
                            alt="Carte d'identité verso"
                            className="w-full h-32 object-cover rounded-lg border-2 border-gray-200 group-hover:border-indigo-500 transition-colors"
                          />
                          <div className="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-10 transition-all rounded-lg flex items-center justify-center">
                            <span className="text-white text-sm opacity-0 group-hover:opacity-100 transition-opacity">
                              👁️ Voir en grand
                            </span>
                          </div>
                        </div>
                      </div>
                    )}

                    {/* Passeport */}
                    {verification.passport_image && (
                      <div>
                        <label className="block text-sm font-medium text-gray-500 mb-2">
                          Passeport
                        </label>
                        <div 
                          className="relative cursor-pointer group"
                          onClick={() => openImageModal(verification.passport_image)}
                        >
                          <img
                            src={verification.passport_image}
                            alt="Passeport"
                            className="w-full h-32 object-cover rounded-lg border-2 border-gray-200 group-hover:border-indigo-500 transition-colors"
                          />
                          <div className="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-10 transition-all rounded-lg flex items-center justify-center">
                            <span className="text-white text-sm opacity-0 group-hover:opacity-100 transition-opacity">
                              👁️ Voir en grand
                            </span>
                          </div>
                        </div>
                      </div>
                    )}

                    {/* Selfie */}
                    {verification.selfie_image && (
                      <div>
                        <label className="block text-sm font-medium text-gray-500 mb-2">
                          Selfie de vérification
                        </label>
                        <div 
                          className="relative cursor-pointer group"
                          onClick={() => openImageModal(verification.selfie_image)}
                        >
                          <img
                            src={verification.selfie_image}
                            alt="Selfie de vérification"
                            className="w-full h-32 object-cover rounded-lg border-2 border-gray-200 group-hover:border-indigo-500 transition-colors"
                          />
                          <div className="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-10 transition-all rounded-lg flex items-center justify-center">
                            <span className="text-white text-sm opacity-0 group-hover:opacity-100 transition-opacity">
                              👁️ Voir en grand
                            </span>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>
                </div>

                {/* Historique des actions */}
                <div className="bg-gray-50 rounded-lg p-4">
                  <h4 className="text-lg font-medium text-gray-900 mb-4">Historique</h4>
                  <div className="space-y-3">
                    <div className="flex items-center text-sm">
                      <span className="text-gray-500">Soumis le:</span>
                      <span className="ml-2 text-gray-900">{formatDate(verification.submitted_at)}</span>
                    </div>
                    
                    {verification.verified_at && (
                      <div className="flex items-center text-sm">
                        <span className="text-gray-500">
                          {verification.verification_status === 'verified' ? 'Approuvé le:' : 'Traité le:'}
                        </span>
                        <span className="ml-2 text-gray-900">{formatDate(verification.verified_at)}</span>
                        {verification.verified_by && (
                          <span className="ml-2 text-gray-500">par {verification.verified_by}</span>
                        )}
                      </div>
                    )}

                    {verification.rejection_reason && (
                      <div className="bg-red-50 border border-red-200 rounded p-3">
                        <h5 className="text-sm font-medium text-red-900">Raison du rejet:</h5>
                        <p className="mt-1 text-sm text-red-700">{verification.rejection_reason}</p>
                      </div>
                    )}

                    {verification.admin_notes && (
                      <div className="bg-yellow-50 border border-yellow-200 rounded p-3">
                        <h5 className="text-sm font-medium text-yellow-900">Notes administratives:</h5>
                        <p className="mt-1 text-sm text-yellow-700 whitespace-pre-wrap">{verification.admin_notes}</p>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            ) : (
              <div className="text-center py-8">
                <p className="text-gray-500">Impossible de charger les détails de la vérification</p>
              </div>
            )}
          </div>

          {/* Pied de page */}
          <div className="bg-gray-50 px-6 py-3 sm:flex sm:flex-row-reverse">
            <button
              type="button"
              onClick={onClose}
              className="w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:w-auto sm:text-sm"
            >
              Fermer
            </button>
          </div>
        </div>
      </div>

      {/* Modal pour afficher les images en grand */}
      {imageModalOpen && (
        <div className="fixed inset-0 z-60 overflow-y-auto">
          <div className="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
            <div className="fixed inset-0 transition-opacity" aria-hidden="true">
              <div className="absolute inset-0 bg-black opacity-75" onClick={() => setImageModalOpen(false)}></div>
            </div>

            <div className="inline-block align-middle bg-white rounded-lg overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-3xl sm:w-full">
              <div className="bg-white p-4">
                <div className="flex justify-between items-center mb-4">
                  <h4 className="text-lg font-medium text-gray-900">Document</h4>
                  <button
                    onClick={() => setImageModalOpen(false)}
                    className="text-gray-400 hover:text-gray-600"
                  >
                    <span className="sr-only">Fermer</span>
                    <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>
                <img
                  src={selectedImage}
                  alt="Document en grand"
                  className="w-full max-h-96 object-contain rounded-lg"
                />
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default VerificationDetailModal;