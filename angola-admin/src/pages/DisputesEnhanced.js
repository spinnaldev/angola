// admin/src/pages/DisputesEnhanced.js - Gestion des litiges améliorée
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import DashboardLayout from '../layouts/DashboardLayout';
import { disputeService } from '../services/api';

const DisputesEnhanced = () => {
  const navigate = useNavigate();
  const [disputes, setDisputes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [priorityFilter, setPriorityFilter] = useState('');
  const [error, setError] = useState('');
  const [stats, setStats] = useState({
    total: 0,
    open: 0,
    under_review: 0,
    resolved: 0,
    closed: 0,
    high_priority: 0,
    avg_resolution_time: 0,
  });
  const [bulkAction, setBulkAction] = useState('');
  const [selectedDisputes, setSelectedDisputes] = useState(new Set());

  const fetchDisputes = async () => {
    setLoading(true);
    setError('');
    try {
      const response = await disputeService.getAll(currentPage, 20, {
        search,
        status: statusFilter,
        priority: priorityFilter,
      });
      
      setDisputes(response.data.results || []);
      setTotalPages(Math.ceil(response.data.count / 20));
      
      // Calculer les stats locales
      const results = response.data.results || [];
      setStats({
        total: response.data.count,
        open: results.filter(d => d.status === 'open').length,
        under_review: results.filter(d => d.status === 'under_review').length,
        resolved: results.filter(d => d.status === 'resolved').length,
        closed: results.filter(d => d.status === 'closed').length,
        high_priority: results.filter(d => d.priority === 'high').length,
        avg_resolution_time: 0, // Calculé côté serveur
      });
    } catch (err) {
      console.error('Erreur lors du chargement des litiges', err);
      setError('Impossible de charger les litiges. Veuillez réessayer.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDisputes();
  }, [currentPage, statusFilter, priorityFilter]);

  const handleSearch = (e) => {
    e.preventDefault();
    setCurrentPage(1);
    fetchDisputes();
  };

  const handleViewDispute = (id) => {
    navigate(`/disputes/${id}`);
  };

  const getStatusBadge = (status) => {
    const statusConfig = {
      open: { class: 'badge-error', text: 'Ouvert' },
      under_review: { class: 'badge-warning', text: 'En examen' },
      resolved: { class: 'badge-success', text: 'Résolu' },
      closed: { class: 'badge-secondary', text: 'Fermé' },
    };
    const config = statusConfig[status] || { class: 'badge-secondary', text: status };
    return <span className={`badge ${config.class}`}>{config.text}</span>;
  };

  const getPriorityBadge = (priority) => {
    const priorityConfig = {
      low: { class: 'badge-info', text: 'Faible' },
      medium: { class: 'badge-warning', text: 'Moyenne' },
      high: { class: 'badge-error', text: 'Élevée' },
      urgent: { class: 'badge-error badge-outline', text: 'Urgent' },
    };
    const config = priorityConfig[priority] || { class: 'badge-secondary', text: priority };
    return <span className={`badge ${config.class} badge-sm`}>{config.text}</span>;
  };

  const getUrgencyIcon = (dispute) => {
    const daysSinceCreated = Math.floor(
      (new Date() - new Date(dispute.created_at)) / (1000 * 60 * 60 * 24)
    );
    
    if (dispute.priority === 'urgent' || (dispute.status === 'open' && daysSinceCreated > 7)) {
      return <span className="text-red-500 text-lg">🔥</span>;
    }
    if (dispute.priority === 'high' || (dispute.status === 'open' && daysSinceCreated > 3)) {
      return <span className="text-orange-500 text-lg">⚠️</span>;
    }
    return null;
  };

  const handleSelectDispute = (disputeId, isSelected) => {
    const newSelection = new Set(selectedDisputes);
    if (isSelected) {
      newSelection.add(disputeId);
    } else {
      newSelection.delete(disputeId);
    }
    setSelectedDisputes(newSelection);
  };

  const handleSelectAll = (isSelected) => {
    if (isSelected) {
      setSelectedDisputes(new Set(disputes.map(d => d.id)));
    } else {
      setSelectedDisputes(new Set());
    }
  };

  const handleBulkAction = async () => {
    if (!bulkAction || selectedDisputes.size === 0) return;
    
    try {
      const promises = Array.from(selectedDisputes).map(disputeId => {
        switch (bulkAction) {
          case 'mark_reviewed':
            return disputeService.updateStatus(disputeId, 'under_review', 'Marqué comme en examen par action groupée');
          case 'resolve':
            return disputeService.updateStatus(disputeId, 'resolved', 'Résolu par action groupée');
          case 'close':
            return disputeService.updateStatus(disputeId, 'closed', 'Fermé par action groupée');
          default:
            return Promise.resolve();
        }
      });
      
      await Promise.all(promises);
      alert(`Action appliquée à ${selectedDisputes.size} litige(s)`);
      setSelectedDisputes(new Set());
      setBulkAction('');
      fetchDisputes();
    } catch (error) {
      console.error('Erreur lors de l\'action groupée:', error);
      alert('Erreur lors de l\'action groupée');
    }
  };

  if (loading && currentPage === 1) {
    return (
      <DashboardLayout>
        <div className="flex h-96 items-center justify-center">
          <div className="text-center">
            <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-primary"></div>
            <p className="mt-2 text-text-secondary">Chargement des litiges...</p>
          </div>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* En-tête avec statistiques */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-text-primary">Gestion des Litiges</h1>
            <p className="text-text-secondary">
              Gérez et résolvez les litiges de la plateforme
            </p>
          </div>
        </div>

        {/* Statistiques rapides */}
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-6">
          <div className="card bg-gradient-to-r from-blue-500 to-blue-600 text-white">
            <div className="card-body p-4">
              <div className="text-2xl font-bold">{stats.total}</div>
              <div className="text-blue-100 text-sm">Total litiges</div>
            </div>
          </div>
          <div className="card bg-gradient-to-r from-red-500 to-red-600 text-white">
            <div className="card-body p-4">
              <div className="text-2xl font-bold">{stats.open}</div>
              <div className="text-red-100 text-sm">Ouverts</div>
            </div>
          </div>
          <div className="card bg-gradient-to-r from-yellow-500 to-yellow-600 text-white">
            <div className="card-body p-4">
              <div className="text-2xl font-bold">{stats.under_review}</div>
              <div className="text-yellow-100 text-sm">En examen</div>
            </div>
          </div>
          <div className="card bg-gradient-to-r from-green-500 to-green-600 text-white">
            <div className="card-body p-4">
              <div className="text-2xl font-bold">{stats.resolved}</div>
              <div className="text-green-100 text-sm">Résolus</div>
            </div>
          </div>
          <div className="card bg-gradient-to-r from-gray-500 to-gray-600 text-white">
            <div className="card-body p-4">
              <div className="text-2xl font-bold">{stats.closed}</div>
              <div className="text-gray-100 text-sm">Fermés</div>
            </div>
          </div>
          <div className="card bg-gradient-to-r from-orange-500 to-orange-600 text-white">
            <div className="card-body p-4">
              <div className="text-2xl font-bold">{stats.high_priority}</div>
              <div className="text-orange-100 text-sm">Priorité élevée</div>
            </div>
          </div>
        </div>

        {/* Filtres et recherche */}
        <div className="card">
          <div className="card-body">
            <form onSubmit={handleSearch} className="flex flex-wrap gap-4 items-end">
              <div className="flex-1 min-w-64">
                <label className="label">
                  <span className="label-text">Rechercher</span>
                </label>
                <input
                  type="text"
                  placeholder="Titre, description, client, prestataire..."
                  className="input input-bordered w-full"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                />
              </div>
              <div>
                <label className="label">
                  <span className="label-text">Statut</span>
                </label>
                <select
                  className="select select-bordered"
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value)}
                >
                  <option value="">Tous les statuts</option>
                  <option value="open">Ouvert</option>
                  <option value="under_review">En examen</option>
                  <option value="resolved">Résolu</option>
                  <option value="closed">Fermé</option>
                </select>
              </div>
              <div>
                <label className="label">
                  <span className="label-text">Priorité</span>
                </label>
                <select
                  className="select select-bordered"
                  value={priorityFilter}
                  onChange={(e) => setPriorityFilter(e.target.value)}
                >
                  <option value="">Toutes les priorités</option>
                  <option value="low">Faible</option>
                  <option value="medium">Moyenne</option>
                  <option value="high">Élevée</option>
                  <option value="urgent">Urgent</option>
                </select>
              </div>
              <button type="submit" className="btn btn-primary">
                Rechercher
              </button>
            </form>
          </div>
        </div>

        {/* Actions groupées */}
        {selectedDisputes.size > 0 && (
          <div className="card">
            <div className="card-body">
              <div className="flex items-center gap-4">
                <span className="text-sm font-medium">
                  {selectedDisputes.size} litige(s) sélectionné(s)
                </span>
                <select
                  className="select select-bordered select-sm"
                  value={bulkAction}
                  onChange={(e) => setBulkAction(e.target.value)}
                >
                  <option value="">Actions groupées</option>
                  <option value="mark_reviewed">Marquer comme en examen</option>
                  <option value="resolve">Marquer comme résolu</option>
                  <option value="close">Fermer</option>
                </select>
                <button
                  className="btn btn-sm btn-primary"
                  onClick={handleBulkAction}
                  disabled={!bulkAction}
                >
                  Appliquer
                </button>
                <button
                  className="btn btn-sm btn-ghost"
                  onClick={() => setSelectedDisputes(new Set())}
                >
                  Désélectionner tout
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Tableau des litiges */}
        {error && (
          <div className="alert alert-error">
            <span>{error}</span>
          </div>
        )}

        <div className="card">
          <div className="card-body p-0">
            <div className="overflow-x-auto">
              <table className="table table-zebra w-full">
                <thead>
                  <tr>
                    <th>
                      <input
                        type="checkbox"
                        className="checkbox checkbox-sm"
                        checked={selectedDisputes.size === disputes.length && disputes.length > 0}
                        onChange={(e) => handleSelectAll(e.target.checked)}
                      />
                    </th>
                    <th>Litige</th>
                    <th>Parties</th>
                    <th>Priorité</th>
                    <th>Statut</th>
                    <th>Date création</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {disputes.map((dispute) => (
                    <tr key={dispute.id} className="hover">
                      <td>
                        <input
                          type="checkbox"
                          className="checkbox checkbox-sm"
                          checked={selectedDisputes.has(dispute.id)}
                          onChange={(e) => handleSelectDispute(dispute.id, e.target.checked)}
                        />
                      </td>
                      <td>
                        <div className="flex items-center gap-2">
                          {getUrgencyIcon(dispute)}
                          <div>
                            <div className="font-semibold text-text-primary">
                              {dispute.title}
                            </div>
                            <div className="text-sm text-text-secondary truncate max-w-xs">
                              {dispute.description}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td>
                        <div className="text-sm">
                          <div><strong>Client:</strong> {dispute.client_name || 'N/A'}</div>
                          <div><strong>Prestataire:</strong> {dispute.provider_name || 'N/A'}</div>
                        </div>
                      </td>
                      <td>{getPriorityBadge(dispute.priority)}</td>
                      <td>{getStatusBadge(dispute.status)}</td>
                      <td className="text-sm text-text-secondary">
                        {new Date(dispute.created_at).toLocaleDateString('fr-FR')}
                        <div className="text-xs">
                          {new Date(dispute.created_at).toLocaleTimeString('fr-FR')}
                        </div>
                      </td>
                      <td>
                        <div className="flex gap-2">
                          <button
                            className="btn btn-sm btn-ghost"
                            onClick={() => handleViewDispute(dispute.id)}
                          >
                            Voir détails
                          </button>
                          {dispute.status === 'open' && (
                            <button
                              className="btn btn-sm btn-warning"
                              onClick={async () => {
                                try {
                                  await disputeService.updateStatus(dispute.id, 'under_review', 'Pris en charge');
                                  fetchDisputes();
                                } catch (error) {
                                  alert('Erreur lors de la mise à jour');
                                }
                              }}
                            >
                              Prendre en charge
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {disputes.length === 0 && !loading && (
              <div className="text-center py-8">
                <p className="text-text-secondary">Aucun litige trouvé</p>
              </div>
            )}
          </div>
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex justify-center">
            <div className="join">
              <button
                className="join-item btn"
                disabled={currentPage === 1}
                onClick={() => setCurrentPage(currentPage - 1)}
              >
                Précédent
              </button>
              
              {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
                let pageNum;
                if (totalPages <= 5) {
                  pageNum = i + 1;
                } else if (currentPage <= 3) {
                  pageNum = i + 1;
                } else if (currentPage >= totalPages - 2) {
                  pageNum = totalPages - 4 + i;
                } else {
                  pageNum = currentPage - 2 + i;
                }
                
                return (
                  <button
                    key={pageNum}
                    className={`join-item btn ${currentPage === pageNum ? 'btn-active' : ''}`}
                    onClick={() => setCurrentPage(pageNum)}
                  >
                    {pageNum}
                  </button>
                );
              })}
              
              <button
                className="join-item btn"
                disabled={currentPage === totalPages}
                onClick={() => setCurrentPage(currentPage + 1)}
              >
                Suivant
              </button>
            </div>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
};

export default DisputesEnhanced;