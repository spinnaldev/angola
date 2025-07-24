// admin/src/pages/Projects.js
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import DashboardLayout from '../layouts/DashboardLayout';
import { projectService } from '../services/api';

const Projects = () => {
  const navigate = useNavigate();
  const [projects, setProjects] = useState([]);
  const [loading, setLoading] = useState(true);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const [error, setError] = useState('');
  const [stats, setStats] = useState({
    total: 0,
    open: 0,
    in_progress: 0,
    completed: 0,
    cancelled: 0,
  });

  const fetchProjects = async () => {
    setLoading(true);
    setError('');
    try {
      const response = await projectService.getAll(currentPage, 20, {
        search,
        status: statusFilter,
        category: categoryFilter,
      });
      setProjects(response.data.results || []);
      setTotalPages(Math.ceil(response.data.count / 20));
      
      // Calculer les stats
      const results = response.data.results || [];
      setStats({
        total: response.data.count,
        open: results.filter(p => p.status === 'open').length,
        in_progress: results.filter(p => p.status === 'in_progress').length,
        completed: results.filter(p => p.status === 'completed').length,
        cancelled: results.filter(p => p.status === 'cancelled').length,
      });
    } catch (err) {
      console.error('Erreur lors du chargement des projets', err);
      setError('Impossible de charger les projets. Veuillez réessayer.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProjects();
  }, [currentPage, statusFilter, categoryFilter]);

  const handleSearch = (e) => {
    e.preventDefault();
    setCurrentPage(1);
    fetchProjects();
  };

  const handleViewProject = (id) => {
    navigate(`/projects/${id}`);
  };

  const getStatusBadge = (status) => {
    const statusConfig = {
      open: { class: 'badge-warning', text: 'Ouvert' },
      in_progress: { class: 'badge-info', text: 'En cours' },
      completed: { class: 'badge-success', text: 'Terminé' },
      cancelled: { class: 'badge-error', text: 'Annulé' },
    };
    const config = statusConfig[status] || { class: 'badge-secondary', text: status };
    return <span className={`badge ${config.class}`}>{config.text}</span>;
  };

  const getBudgetDisplay = (budgetType, maxBudget) => {
    const budgetMap = {
      'moins_500': 'Moins de 500 AOA',
      '500_1000': '500 à 1000 AOA',
      '1000_10000': '1000 à 10 000 AOA',
      '10000_plus': '10 000 AOA et plus',
      'sur_devis': 'Sur devis',
    };
    
    if (budgetType === 'sur_devis' && maxBudget) {
      return `Max: ${maxBudget} AOA`;
    }
    
    return budgetMap[budgetType] || budgetType;
  };

  if (loading && currentPage === 1) {
    return (
      <DashboardLayout>
        <div className="flex h-96 items-center justify-center">
          <div className="text-center">
            <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-primary"></div>
            <p className="mt-2 text-text-secondary">Chargement des projets...</p>
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
            <h1 className="text-2xl font-bold text-text-primary">Gestion des Projets</h1>
            <p className="text-text-secondary">
              Gérez et suivez tous les projets de la plateforme
            </p>
          </div>
        </div>

        {/* Statistiques rapides */}
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
          <div className="card bg-gradient-to-r from-blue-500 to-blue-600 text-white">
            <div className="card-body">
              <div className="text-2xl font-bold">{stats.total}</div>
              <div className="text-blue-100">Total projets</div>
            </div>
          </div>
          <div className="card bg-gradient-to-r from-yellow-500 to-yellow-600 text-white">
            <div className="card-body">
              <div className="text-2xl font-bold">{stats.open}</div>
              <div className="text-yellow-100">Ouverts</div>
            </div>
          </div>
          <div className="card bg-gradient-to-r from-blue-500 to-blue-600 text-white">
            <div className="card-body">
              <div className="text-2xl font-bold">{stats.in_progress}</div>
              <div className="text-blue-100">En cours</div>
            </div>
          </div>
          <div className="card bg-gradient-to-r from-green-500 to-green-600 text-white">
            <div className="card-body">
              <div className="text-2xl font-bold">{stats.completed}</div>
              <div className="text-green-100">Terminés</div>
            </div>
          </div>
          <div className="card bg-gradient-to-r from-red-500 to-red-600 text-white">
            <div className="card-body">
              <div className="text-2xl font-bold">{stats.cancelled}</div>
              <div className="text-red-100">Annulés</div>
            </div>
          </div>
        </div>

        {/* Filtres et recherche */}
        <div className="card">
          <div className="card-body">
            <form onSubmit={handleSearch} className="flex flex-wrap gap-4">
              <div className="flex-1 min-w-64">
                <input
                  type="text"
                  placeholder="Rechercher par titre, description, client..."
                  className="input input-bordered w-full"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                />
              </div>
              <select
                className="select select-bordered"
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
              >
                <option value="">Tous les statuts</option>
                <option value="open">Ouvert</option>
                <option value="in_progress">En cours</option>
                <option value="completed">Terminé</option>
                <option value="cancelled">Annulé</option>
              </select>
              <select
                className="select select-bordered"
                value={categoryFilter}
                onChange={(e) => setCategoryFilter(e.target.value)}
              >
                <option value="">Toutes les catégories</option>
                <option value="1">Développement Web</option>
                <option value="2">Design</option>
                <option value="3">Marketing</option>
                <option value="4">Écriture</option>
                <option value="5">Autre</option>
              </select>
              <button type="submit" className="btn btn-primary">
                Rechercher
              </button>
            </form>
          </div>
        </div>

        {/* Tableau des projets */}
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
                    <th>Projet</th>
                    <th>Client</th>
                    <th>Catégorie</th>
                    <th>Budget</th>
                    <th>Statut</th>
                    <th>Offres</th>
                    <th>Date création</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {projects.map((project) => (
                    <tr key={project.id} className="hover">
                      <td>
                        <div>
                          <div className="font-semibold text-text-primary">
                            {project.title}
                          </div>
                          <div className="text-sm text-text-secondary truncate max-w-xs">
                            {project.description}
                          </div>
                        </div>
                      </td>
                      <td>
                        <div className="flex items-center space-x-2">
                          <div className="avatar placeholder">
                            <div className="bg-neutral-focus text-neutral-content rounded-full w-8">
                              <span className="text-xs">
                                {project.client_name?.charAt(0) || 'U'}
                              </span>
                            </div>
                          </div>
                          <div className="text-sm">{project.client_name || 'Utilisateur'}</div>
                        </div>
                      </td>
                      <td>
                        <span className="badge badge-outline">
                          {project.category_name || 'N/A'}
                        </span>
                      </td>
                      <td className="text-sm">
                        {getBudgetDisplay(project.budget_type, project.max_budget)}
                      </td>
                      <td>{getStatusBadge(project.status)}</td>
                      <td>
                        <div className="text-center">
                          <span className="badge badge-info">
                            {project.offers_count || 0}
                          </span>
                        </div>
                      </td>
                      <td className="text-sm text-text-secondary">
                        {new Date(project.created_at).toLocaleDateString('fr-FR')}
                      </td>
                      <td>
                        <button
                          className="btn btn-sm btn-ghost"
                          onClick={() => handleViewProject(project.id)}
                        >
                          Voir détails
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {projects.length === 0 && !loading && (
              <div className="text-center py-8">
                <p className="text-text-secondary">Aucun projet trouvé</p>
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

export default Projects;