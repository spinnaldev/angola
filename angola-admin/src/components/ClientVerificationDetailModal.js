// angola-admin/src/components/ClientVerificationDetailModal.js
// ⚠️ CRÉER CE NOUVEAU FICHIER

import React, { useState, useEffect } from 'react';
import clientVerificationService from '../services/clientVerificationService';

const ClientVerificationDetailModal = ({ verificationId, onClose }) => {
  const [verification, setVerification] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (verificationId) {
      fetchVerificationDetails();
    }
  }, [verificationId]);

  const fetchVerificationDetails = async () => {
    setLoading(true);
    try {
      const data = await clientVerificationService.getVerification(verificationId);
      setVerification(data);
    } catch (error) {
      console.error('Erreur lors du chargement des détails:', error);
    } finally {
      setLoading(false);
    }
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
      <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${config.color}`}>
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

  if (!verificationId) return null;

  if (loading) {
    return (
      <div className="fixed z-50 inset-0 overflow-y-auto">
        <div className="flex items-center justify-center min-h-screen">
          <div className="fixed inset-0 bg-gray-500 bg-opacity-75" onClick={onClose}></div>
          <div className="relative bg-white rounded-lg p-8">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
            <p className="mt-4 text-gray-600">Chargement...</p>
          </div>
        </div>
      </div>
    );
  }

  if (!verification) {
    return null;
  }

  return (
    <div className="fixed z-50 inset-0 overflow-y-auto">
      <div className="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" onClick={onClose}></div>
        
        <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-4xl sm:w-full">
          {/* En-tête */}
          <div className="bg-gray-50 px-6 py-4 border-b border-gray-200">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-4">
                <span className="text-3xl">👤</span>
                <div>
                  <h3 className="text-lg font-medium text-gray-900">
                    Vérification de {verification.client_name || verification.full_name || 'N/A'}
                  </h3>
                  <p className="text-sm text-gray-500">{verification.client_email || 'N/A'}</p>
                </div>
              </div>
              <button onClick={onClose} className="text-gray-400 hover:text-gray-600">
                <span className="text-2xl">×</span>
              </button>
            </div>
          </div>

          {/* Contenu */}
          <div className="px-6 py-4 max-h-[60vh] overflow-y-auto">
            <div className="space-y-6">
              {/* Informations générales */}
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-medium text-blue-900">
                    Type de document : {verification.document_type === 'id_card' ? '🪪 Carte d\'identité' : '📘 Passeport'}
                  </span>
                  {getStatusBadge(verification.verification_status)}
                </div>
                <div className="text-sm text-blue-800">
                  Soumis le : {formatDate(verification.submitted_at)}
                </div>
              </div>

              {/* Documents */}
              {verification.document_type === 'id_card' && (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {verification.id_card_front && (
                    <div>
                      <h4 className="text-sm font-medium text-gray-700 mb-2">Recto de la carte</h4>
                      <div className="border rounded-lg overflow-hidden">
                        <img
                          src={verification.id_card_front}
                          alt="Recto carte d'identité"
                          className="w-full h-auto cursor-pointer hover:opacity-90"
                          onClick={() => window.open(verification.id_card_front, '_blank')}
                        />
                      </div>
                      <a
                        href={verification.id_card_front}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="mt-2 text-sm text-blue-600 hover:text-blue-800 inline-flex items-center"
                      >
                        🔍 Voir en plein écran
                      </a>
                    </div>
                  )}

                  {verification.id_card_back && (
                    <div>
                      <h4 className="text-sm font-medium text-gray-700 mb-2">Verso de la carte</h4>
                      <div className="border rounded-lg overflow-hidden">
                        <img
                          src={verification.id_card_back}
                          alt="Verso carte d'identité"
                          className="w-full h-auto cursor-pointer hover:opacity-90"
                          onClick={() => window.open(verification.id_card_back, '_blank')}
                        />
                      </div>
                      <a
                        href={verification.id_card_back}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="mt-2 text-sm text-blue-600 hover:text-blue-800 inline-flex items-center"
                      >
                        🔍 Voir en plein écran
                      </a>
                    </div>
                  )}
                </div>
              )}

              {verification.document_type === 'passport' && verification.passport_image && (
                <div>
                  <h4 className="text-sm font-medium text-gray-700 mb-2">Page du passeport</h4>
                  <div className="border rounded-lg overflow-hidden max-w-md mx-auto">
                    <img
                      src={verification.passport_image}
                      alt="Passeport"
                      className="w-full h-auto cursor-pointer hover:opacity-90"
                      onClick={() => window.open(verification.passport_image, '_blank')}
                    />
                  </div>
                  <a
                    href={verification.passport_image}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="mt-2 text-sm text-blue-600 hover:text-blue-800 inline-flex items-center justify-center w-full"
                  >
                    🔍 Voir en plein écran
                  </a>
                </div>
              )}

              {/* Raison du rejet */}
              {verification.verification_status === 'rejected' && verification.rejection_reason && (
                <div className="bg-red-50 border border-red-200 rounded-lg p-4">
                  <h4 className="text-sm font-medium text-red-900 mb-2">Raison du rejet</h4>
                  <p className="text-sm text-red-800">{verification.rejection_reason}</p>
                </div>
              )}

              {/* Notes admin */}
              {verification.admin_notes && (
                <div className="bg-gray-50 rounded-lg p-4">
                  <h4 className="text-sm font-medium text-gray-900 mb-2">Notes administratives</h4>
                  <p className="text-sm text-gray-700 whitespace-pre-wrap">{verification.admin_notes}</p>
                </div>
              )}
            </div>
          </div>

          {/* Footer */}
          <div className="bg-gray-50 px-6 py-4 border-t border-gray-200 flex justify-end">
            <button
              onClick={onClose}
              className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
            >
              Fermer
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ClientVerificationDetailModal;