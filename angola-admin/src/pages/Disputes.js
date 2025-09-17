import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import DashboardLayout from '../layouts/DashboardLayout';
import { disputeService } from '../services/api';
import { withAuth } from '../context/AuthContext';

const DisputeStatusBadge = ({ status }) => {
  const statusConfig = {
    open: { color: 'text-yellow-600 bg-yellow-100', text: '⏳ En attente' },
    under_review: { color: 'text-blue-600 bg-blue-100', text: '🔍 En cours d\'examen' },
    resolved: { color: 'text-green-600 bg-green-100', text: '✅ Résolu' },
    closed: { color: 'text-gray-600 bg-gray-100', text: '🔒 Fermé' },
  };
  const config = statusConfig[status] || { color: 'text-gray-600 bg-gray-100', text: status };
  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${config.color}`}>
      {config.text}
    </span>
  );
};

const DisputeDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [dispute, setDispute] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [resolution, setResolution] = useState('');
  const [newStatus, setNewStatus] = useState('');
  const [updating, setUpdating] = useState(false);

  useEffect(() => {
    const fetchDispute = async () => {
      setLoading(true);
      try {
        const response = await disputeService.getById(id);
        setDispute(response.data);
        setResolution(response.data.resolution_note || '');
        setNewStatus(response.data.status);
      } catch (err) {
        console.error('Erreur lors du chargement du litige', err);
        setError('Impossible de charger les détails du litige.');
      } finally {
        setLoading(false);
      }
    };

    if (id) {
      fetchDispute();
    }
  }, [id]);

  const handleUpdateStatus = async () => {
    try {
      setUpdating(true);
      await disputeService.updateStatus(id, newStatus, resolution);
      setDispute({ ...dispute, status: newStatus, resolution_note: resolution });
      
      // Notification de succès
      const notification = document.createElement('div');
      notification.className = 'alert alert-success fixed top-4 right-4 w-auto z-50';
      notification.innerHTML = '<span>Statut du litige mis à jour avec succès</span>';
      document.body.appendChild(notification);
      setTimeout(() => document.body.removeChild(notification), 3000);
      
    } catch (err) {
      console.error('Erreur lors de la mise à jour du statut', err);
      setError('Impossible de mettre à jour le statut du litige.');
    } finally {
      setUpdating(false);
    }
  };

  const getInitials = (name) => {
    return name ? name.charAt(0).toUpperCase() : 'U';
  };

  if (loading) {
    return (
      <DashboardLayout>
        <div className="p-6">
          <div className="flex h-96 items-center justify-center">
            <div className="text-center">
              <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-current border-r-transparent motion-reduce:animate-[spin_1.5s_linear_infinite]"></div>
              <p className="mt-4 text-sm text-gray-500">Chargement du litige...</p>
            </div>
          </div>
        </div>
      </DashboardLayout>
    );
  }

  if (error) {
    return (
      <DashboardLayout>
        <div className="p-6">
          <div className="bg-red-50 border border-red-200 rounded-md p-4">
            <div className="flex">
              <div className="flex-shrink-0">
                <svg className="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                </svg>
              </div>
              <div className="ml-3">
                <p className="text-sm text-red-700">{error}</p>
                <button
                  className="mt-2 bg-red-100 hover:bg-red-200 text-red-800 px-3 py-1 rounded text-sm"
                  onClick={() => navigate('/disputes')}
                >
                  Retour aux litiges
                </button>
              </div>
            </div>
          </div>
        </div>
      </DashboardLayout>
    );
  }

  if (!dispute) {
    return (
      <DashboardLayout>
        <div className="p-6">
          <div className="text-center py-12">
            <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
            </svg>
            <h3 className="mt-4 text-sm font-medium text-gray-900">Litige non trouvé</h3>
            <button
              className="mt-4 bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium"
              onClick={() => navigate('/disputes')}
            >
              Retour aux litiges
            </button>
          </div>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="p-6">
        {/* En-tête */}
        <div className="mb-8 flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <button
              className="text-indigo-600 hover:text-indigo-800 text-sm font-medium"
              onClick={() => navigate('/disputes')}
            >
              ← Retour à la liste
            </button>
            <div className="h-6 border-l border-gray-300"></div>
            <h1 className="text-2xl font-semibold text-gray-900">
              {dispute.title}
            </h1>
          </div>
          <div className="flex items-center space-x-3">
            <DisputeStatusBadge status={dispute.status} />
            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
              ID: {dispute.id}
            </span>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Colonne principale */}
          <div className="lg:col-span-2 space-y-6">
            {/* Description */}
            <div className="bg-white shadow-sm rounded-lg">
              <div className="px-4 py-5 sm:p-6">
                <h2 className="text-lg font-medium text-gray-900 mb-4">
                  📝 Description du litige
                </h2>
                <p className="text-sm text-gray-600">
                  {dispute.description}
                </p>
              </div>
            </div>

            {/* Preuves soumises */}
            {dispute.evidence && dispute.evidence.length > 0 && (
              <div className="bg-white shadow-sm rounded-lg">
                <div className="px-4 py-5 sm:p-6">
                  <h2 className="text-lg font-medium text-gray-900 mb-4">
                    📎 Preuves soumises
                  </h2>
                  <div className="space-y-4">
                    {dispute.evidence.map((item) => (
                      <div key={item.id} className="border border-gray-200 rounded-lg p-4">
                        <div className="flex items-start space-x-3">
                          <div className="flex-shrink-0">
                            <div className="h-10 w-10 rounded-full bg-gray-100 flex items-center justify-center">
                              <span className="text-sm font-medium text-gray-600">
                                {getInitials(item.user_name)}
                              </span>
                            </div>
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="text-sm font-medium text-gray-900">
                              {item.user_name}
                            </div>
                            <div className="text-sm text-gray-600 mt-1">
                              {item.description}
                            </div>
                            <div className="mt-2">
                              <a
                                href={item.file}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="text-indigo-600 hover:text-indigo-800 text-sm font-medium"
                              >
                                📄 Voir le fichier
                              </a>
                            </div>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* Résolution */}
            <div className="bg-white shadow-sm rounded-lg">
              <div className="px-4 py-5 sm:p-6">
                <h2 className="text-lg font-medium text-gray-900 mb-6">
                  ⚙️ Résolution du litige
                </h2>
                
                <div className="space-y-6">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Statut
                    </label>
                    <select
                      className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                      value={newStatus}
                      onChange={(e) => setNewStatus(e.target.value)}
                    >
                      <option value="open">En attente</option>
                      <option value="under_review">En cours d'examen</option>
                      <option value="resolved">Résolu</option>
                      <option value="closed">Fermé</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Note de résolution
                    </label>
                    <textarea
                      className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                      rows="5"
                      value={resolution}
                      onChange={(e) => setResolution(e.target.value)}
                      placeholder="Ajoutez ici les détails de la résolution..."
                    />
                  </div>

                  <button
                    className={`bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium ${
                      updating ? 'opacity-50 cursor-not-allowed' : ''
                    }`}
                    onClick={handleUpdateStatus}
                    disabled={updating}
                  >
                    {updating ? 'Mise à jour...' : 'Mettre à jour le statut'}
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Colonne latérale - Informations */}
          <div className="space-y-6">
            <div className="bg-white shadow-sm rounded-lg">
              <div className="px-4 py-5 sm:p-6">
                <h2 className="text-lg font-medium text-gray-900 mb-6">
                  ℹ️ Informations du litige
                </h2>
                
                <div className="space-y-6">
                  {/* Client */}
                  <div className="flex items-start space-x-3">
                    <div className="flex-shrink-0">
                      <div className="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center">
                        <span className="text-sm font-medium text-blue-600">
                          👤
                        </span>
                      </div>
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="text-sm text-gray-500">Client</div>
                      <div className="text-sm font-medium text-gray-900">
                        {dispute.client_name}
                      </div>
                    </div>
                  </div>

                  {/* Prestataire */}
                  <div className="flex items-start space-x-3">
                    <div className="flex-shrink-0">
                      <div className="h-10 w-10 rounded-full bg-orange-100 flex items-center justify-center">
                        <span className="text-sm font-medium text-orange-600">
                          🔧
                        </span>
                      </div>
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="text-sm text-gray-500">Prestataire</div>
                      <div className="text-sm font-medium text-gray-900">
                        {dispute.provider_name}
                      </div>
                    </div>
                  </div>

                  {/* Service concerné */}
                  {dispute.service_title && (
                    <div className="flex items-start space-x-3">
                      <div className="flex-shrink-0">
                        <div className="h-10 w-10 rounded-full bg-green-100 flex items-center justify-center">
                          <span className="text-sm font-medium text-green-600">
                            ✅
                          </span>
                        </div>
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="text-sm text-gray-500">Service concerné</div>
                        <div className="text-sm font-medium text-gray-900">
                          {dispute.service_title}
                        </div>
                      </div>
                    </div>
                  )}

                  {/* Date de création */}
                  <div className="flex items-start space-x-3">
                    <div className="flex-shrink-0">
                      <div className="h-10 w-10 rounded-full bg-gray-100 flex items-center justify-center">
                        <span className="text-sm font-medium text-gray-600">
                          📅
                        </span>
                      </div>
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="text-sm text-gray-500">Date de création</div>
                      <div className="text-sm font-medium text-gray-900">
                        {new Date(dispute.created_at).toLocaleDateString('fr-FR', {
                          day: 'numeric',
                          month: 'long',
                          year: 'numeric',
                          hour: '2-digit',
                          minute: '2-digit',
                        })}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
};

const Disputes = () => {
  const navigate = useNavigate();
  const [disputes, setDisputes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [error, setError] = useState('');

  const fetchDisputes = async () => {
    setLoading(true);
    setError('');
    try {
      const response = await disputeService.getAll(currentPage);
      setDisputes(response.data.results || []);
      setTotalPages(Math.ceil(response.data.count / 10));
      setTotalCount(response.data.count);
    } catch (err) {
      console.error('Erreur lors du chargement des litiges', err);
      setError('Impossible de charger les litiges. Veuillez réessayer.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDisputes();
  }, [currentPage]);

  const handleViewDispute = (id) => {
    navigate(`/disputes/${id}`);
  };

  const handleSearch = (e) => {
    e.preventDefault();
    setCurrentPage(1);
    fetchDisputes();
  };

  const filteredDisputes = disputes.filter((dispute) => {
    const searchTerm = search.toLowerCase();
    const matchesSearch =
      dispute.title?.toLowerCase().includes(searchTerm) ||
      dispute.description?.toLowerCase().includes(searchTerm) ||
      dispute.client_name?.toLowerCase().includes(searchTerm) ||
      dispute.provider_name?.toLowerCase().includes(searchTerm);

    const matchesStatus = statusFilter ? dispute.status === statusFilter : true;

    return matchesSearch && matchesStatus;
  });

  const getInitials = (name) => {
    return name ? name.charAt(0).toUpperCase() : 'U';
  };

  if (loading && currentPage === 1) {
    return (
      <DashboardLayout>
        <div className="p-6">
          <div className="flex h-96 items-center justify-center">
            <div className="text-center">
              <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-current border-r-transparent motion-reduce:animate-[spin_1.5s_linear_infinite]"></div>
              <p className="mt-4 text-sm text-gray-500">Chargement des litiges...</p>
            </div>
          </div>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="p-6">
        {/* En-tête */}
        <div className="mb-8 flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-gray-900">Gestion des litiges</h1>
            <p className="mt-2 text-sm text-gray-700">
              Un total de {totalCount} litiges trouvés
            </p>
          </div>
          <button className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium">
            📊 Statistiques détaillées
          </button>
        </div>

        {/* Filtres et recherche */}
        <div className="mb-6 bg-white shadow-sm rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <form onSubmit={handleSearch}>
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
                <div className="sm:col-span-2">
                  <div className="relative rounded-md shadow-sm">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                      <svg className="h-5 w-5 text-gray-400" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M8 4a4 4 0 100 8 4 4 0 000-8zM2 8a6 6 0 1110.89 3.476l4.817 4.817a1 1 0 01-1.414 1.414l-4.816-4.816A6 6 0 012 8z" clipRule="evenodd" />
                      </svg>
                    </div>
                    <input
                      type="text"
                      className="focus:ring-indigo-500 focus:border-indigo-500 block w-full pl-10 sm:text-sm border-gray-300 rounded-md"
                      placeholder="Rechercher des litiges"
                      value={search}
                      onChange={(e) => setSearch(e.target.value)}
                    />
                  </div>
                </div>
                <div>
                  <select
                    className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value)}
                  >
                    <option value="">Tous les statuts</option>
                    <option value="open">En attente</option>
                    <option value="under_review">En cours d'examen</option>
                    <option value="resolved">Résolu</option>
                    <option value="closed">Fermé</option>
                  </select>
                </div>
              </div>
              <div className="mt-4">
                <button
                  type="submit"
                  className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium"
                >
                  Rechercher
                </button>
                {(search || statusFilter) && (
                  <button
                    type="button"
                    className="ml-3 text-indigo-600 hover:text-indigo-800 text-sm font-medium"
                    onClick={() => {
                      setSearch('');
                      setStatusFilter('');
                      setCurrentPage(1);
                      fetchDisputes();
                    }}
                  >
                    Réinitialiser
                  </button>
                )}
              </div>
            </form>
          </div>
        </div>

        {/* Messages d'erreur */}
        {error && (
          <div className="mb-6 bg-red-50 border border-red-200 rounded-md p-4">
            <div className="flex">
              <div className="flex-shrink-0">
                <svg className="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                </svg>
              </div>
              <div className="ml-3">
                <p className="text-sm text-red-700">{error}</p>
              </div>
            </div>
          </div>
        )}

        {/* Liste des litiges */}
        <div className="bg-white shadow-sm rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <div className="space-y-4">
              {filteredDisputes.map((dispute) => (
                <div key={dispute.id} className="border border-gray-200 rounded-lg p-4 hover:bg-gray-50">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-4">
                      <div className="flex-shrink-0">
                        <div className="h-10 w-10 rounded-full bg-red-100 flex items-center justify-center">
                          <span className="text-sm font-medium text-red-600">
                            ⚠️
                          </span>
                        </div>
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center space-x-3">
                          <p className="text-sm font-medium text-gray-900 truncate">
                            {dispute.title}
                          </p>
                          <DisputeStatusBadge status={dispute.status} />
                        </div>
                        <div className="flex items-center space-x-4 mt-1">
                          <p className="text-sm text-gray-500">
                            👤 Client: {dispute.client_name}
                          </p>
                          <p className="text-sm text-gray-500">
                            🔧 Prestataire: {dispute.provider_name}
                          </p>
                          <p className="text-sm text-gray-500">
                            📅 {new Date(dispute.created_at).toLocaleDateString('fr-FR')}
                          </p>
                        </div>
                        <p className="text-sm text-gray-600 mt-1 truncate">
                          {dispute.description}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center space-x-2">
                      <button
                        onClick={() => handleViewDispute(dispute.id)}
                        className="text-indigo-600 hover:text-indigo-900 text-sm font-medium"
                      >
                        👁️ Voir détails
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {filteredDisputes.length === 0 && !loading && (
              <div className="text-center py-12">
                <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
                </svg>
                <h3 className="mt-4 text-sm font-medium text-gray-900">Aucun litige trouvé</h3>
                <p className="mt-2 text-sm text-gray-500">
                  {search || statusFilter
                    ? 'Essayez de modifier vos critères de recherche'
                    : 'Aucun litige n\'a encore été signalé'}
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6 mt-6 rounded-lg shadow-sm">
            <div className="flex-1 flex justify-between items-center">
              <div>
                <p className="text-sm text-gray-700">
                  Affichage de <span className="font-medium">{((currentPage - 1) * 10) + 1}</span> à{' '}
                  <span className="font-medium">{Math.min(currentPage * 10, totalCount)}</span> sur{' '}
                  <span className="font-medium">{totalCount}</span> résultats
                </p>
              </div>
              <div className="flex space-x-1">
                {Array.from({ length: Math.min(4, totalPages) }, (_, i) => {
                  let pageNum;
                  if (totalPages <= 4) {
                    pageNum = i + 1;
                  } else if (currentPage <= 2) {
                    pageNum = i + 1;
                  } else if (currentPage >= totalPages - 1) {
                    pageNum = totalPages - 3 + i;
                  } else {
                    pageNum = currentPage - 1 + i;
                  }
                  
                  return (
                    <button
                      key={pageNum}
                      onClick={() => setCurrentPage(pageNum)}
                      className={`px-3 py-2 text-sm font-medium rounded-md ${
                        currentPage === pageNum
                          ? 'bg-indigo-600 text-white'
                          : 'text-gray-500 hover:text-gray-700 hover:bg-gray-100'
                      }`}
                    >
                      {pageNum}
                    </button>
                  );
                })}
              </div>
            </div>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
};

export { DisputeDetail, Disputes };
export default withAuth(Disputes);