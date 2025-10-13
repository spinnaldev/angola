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
  const [totalCount, setTotalCount] = useState(0);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const [error, setError] = useState('');
  const [stats, setStats] = useState({
    total: 0,
    open: 0,
    in_progress: 0,
    completed: 0,
  });

  // Récupérer les statistiques globales (une seule fois au montage ou après recherche)
  const fetchStats = async () => {
    try {
      const response = await projectService.getStats();
      const apiData = response.data;
      
      // ✅ Transformer les données de l'API pour correspondre à la structure attendue
      // L'API renvoie: { total_projects, by_status: { completed, closed, open, in_progress } }
      // On veut: { total, open, in_progress, completed }
      setStats({
        total: apiData.total_projects || 0,
        open: apiData.by_status?.open || 0,
        in_progress: apiData.by_status?.in_progress || 0,
        // ✅ IMPORTANT: Les projets terminés = completed + closed
        completed: (apiData.by_status?.completed || 0) + (apiData.by_status?.closed || 0),
      });
    } catch (err) {
      console.error('Erreur lors du chargement des statistiques', err);
      // Fallback : calculer à partir d'une requête large
      try {
        const response = await projectService.getAll(1, 1, { search }); // Juste pour le count
        const totalCount = response.data.count || 0;
        
        // Faire des requêtes pour chaque statut
        const [openRes, inProgressRes, completedRes, closedRes] = await Promise.all([
          projectService.getAll(1, 1, { status: 'open', search }),
          projectService.getAll(1, 1, { status: 'in_progress', search }),
          projectService.getAll(1, 1, { status: 'completed', search }),
          projectService.getAll(1, 1, { status: 'closed', search }),
        ]);
        
        setStats({
          total: totalCount,
          open: openRes.data.count || 0,
          in_progress: inProgressRes.data.count || 0,
          completed: (completedRes.data.count || 0) + (closedRes.data.count || 0),
        });
      } catch (fallbackErr) {
        console.error('Erreur lors du chargement des statistiques', fallbackErr);
      }
    }
  };

  const fetchProjects = async () => {
    setLoading(true);
    setError('');
    try {
      // Préparer les paramètres
      const params = {
        search,
        category: categoryFilter,
      };

      // Si le filtre est "completed", on doit gérer différemment
      // car on veut inclure à la fois "completed" et "closed"
      if (statusFilter && statusFilter !== 'completed') {
        params.status = statusFilter;
      }

      const response = await projectService.getAll(currentPage, 10, params);
      
      let projectsList = response.data.results || [];
      let count = response.data.count || 0;
      
      // Si le filtre est "completed", filtrer manuellement pour inclure "closed"
      if (statusFilter === 'completed') {
        // Solution 1: Filtrer côté client (pas idéal si beaucoup de données)
        projectsList = projectsList.filter(p => 
          p.status === 'completed' || p.status === 'closed'
        );
        
        // Pour le count, on doit faire une requête séparée ou accepter que ce soit approximatif
        // Mieux : modifier le backend pour accepter status=completed,closed
      }
      
      setProjects(projectsList);
      setTotalPages(Math.ceil(count / 10));
      setTotalCount(count);
    } catch (err) {
      console.error('Erreur lors du chargement des projets', err);
      setError('Impossible de charger les projets. Veuillez réessayer.');
    } finally {
      setLoading(false);
    }
  };

  // Charger les statistiques au montage et après recherche
  useEffect(() => {
    fetchStats();
  }, [search]);

  // Charger les projets quand les filtres changent
  useEffect(() => {
    fetchProjects();
  }, [currentPage, statusFilter, categoryFilter]);

  const handleSearch = (e) => {
    e.preventDefault();
    setCurrentPage(1);
    fetchProjects();
    fetchStats(); // Recharger les stats aussi
  };

  const handleViewProject = (id) => {
    navigate(`/projects/${id}`);
  };

  const getStatusBadge = (status) => {
    const statusConfig = {
      open: { color: 'text-yellow-600 bg-yellow-100', text: '⏳ Ouvert' },
      in_progress: { color: 'text-blue-600 bg-blue-100', text: '🔄 En cours' },
      completed: { color: 'text-green-600 bg-green-100', text: '✅ Terminé' },
      cancelled: { color: 'text-red-600 bg-red-100', text: '❌ Annulé' },
      closed: { color: 'text-green-600 bg-green-100', text: '🔒 Fermé' },
      paused: { color: 'text-gray-600 bg-gray-100', text: '⏸️ En pause' },
    };
    const config = statusConfig[status] || { color: 'text-gray-600 bg-gray-100', text: status };
    return (
      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${config.color}`}>
        {config.text}
      </span>
    );
  };

  const getBudgetDisplay = (project) => {
    if (project.budget_display) {
      return project.budget_display;
    }

    const budgetMap = {
      'moins_500': 'Moins de 500 AOA',
      '500_1000': '500 à 1 000 AOA',
      '1000_10000': '1 000 à 10 000 AOA',
      '10000_plus': '10 000 AOA et plus',
      'sur_devis': 'Sur devis',
    };
    
    if (project.budget_range && budgetMap[project.budget_range]) {
      return budgetMap[project.budget_range];
    }
    
    if (project.min_budget && project.max_budget) {
      if (project.min_budget === project.max_budget) {
        return `${project.min_budget} AOA`;
      }
      return `${project.min_budget} - ${project.max_budget} AOA`;
    }
    
    if (project.min_budget) {
      return `À partir de ${project.min_budget} AOA`;
    }
    
    if (project.max_budget) {
      return `Jusqu'à ${project.max_budget} AOA`;
    }
    
    return 'Budget à discuter';
  };

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
              <p className="mt-4 text-sm text-gray-500">Chargement des projets...</p>
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
            <h1 className="text-2xl font-semibold text-gray-900">Gestion des Projets</h1>
            <p className="mt-2 text-sm text-gray-700">
              Un total de {stats.total} projets au total
            </p>
          </div>
        </div>

        {/* Statistiques - Affiche les stats globales */}
        <div className="mb-8 grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
          <div className="bg-white overflow-hidden shadow-sm rounded-lg">
            <div className="px-4 py-5 sm:p-6">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <div className="flex h-8 w-8 items-center justify-center rounded-md bg-indigo-500 text-white">
                    📋
                  </div>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">Total</dt>
                    <dd className="text-lg font-semibold text-gray-900">{stats.total}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white overflow-hidden shadow-sm rounded-lg">
            <div className="px-4 py-5 sm:p-6">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <div className="flex h-8 w-8 items-center justify-center rounded-md bg-yellow-500 text-white">
                    ⏳
                  </div>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">Ouverts</dt>
                    <dd className="text-lg font-semibold text-gray-900">{stats.open}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white overflow-hidden shadow-sm rounded-lg">
            <div className="px-4 py-5 sm:p-6">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <div className="flex h-8 w-8 items-center justify-center rounded-md bg-blue-500 text-white">
                    🔄
                  </div>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">En cours</dt>
                    <dd className="text-lg font-semibold text-gray-900">{stats.in_progress}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white overflow-hidden shadow-sm rounded-lg">
            <div className="px-4 py-5 sm:p-6">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <div className="flex h-8 w-8 items-center justify-center rounded-md bg-green-500 text-white">
                    ✅
                  </div>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">Terminés</dt>
                    <dd className="text-lg font-semibold text-gray-900">{stats.completed}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Filtres */}
        <div className="mb-6 bg-white shadow-sm rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <form onSubmit={handleSearch}>
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-4">
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
                      placeholder="Rechercher des projets"
                      value={search}
                      onChange={(e) => setSearch(e.target.value)}
                    />
                  </div>
                </div>
                <div>
                  <select
                    className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                    value={statusFilter}
                    onChange={(e) => {
                      setStatusFilter(e.target.value);
                      setCurrentPage(1);
                    }}
                  >
                    <option value="">Tous les statuts</option>
                    <option value="open">Ouvert</option>
                    <option value="in_progress">En cours</option>
                    <option value="completed">Terminé</option>
                    <option value="cancelled">Annulé</option>
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
                {(search || statusFilter || categoryFilter) && (
                  <button
                    type="button"
                    className="ml-3 text-indigo-600 hover:text-indigo-800 text-sm font-medium"
                    onClick={() => {
                      setSearch('');
                      setStatusFilter('');
                      setCategoryFilter('');
                      setCurrentPage(1);
                      fetchProjects();
                      fetchStats();
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

        {/* Liste des projets */}
        <div className="bg-white shadow-sm rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <div className="space-y-4">
              {projects.map((project, index) => (
                <div key={project.id} className="border border-gray-200 rounded-lg p-4 hover:bg-gray-50">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-4">
                      <div className="flex-shrink-0">
                        <div className="h-10 w-10 rounded-full bg-indigo-100 flex items-center justify-center">
                          <span className="text-sm font-medium text-indigo-600">
                            {getInitials(project.client_name)}
                          </span>
                        </div>
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center space-x-3">
                          <p className="text-sm font-medium text-gray-900 truncate">
                            {project.title}
                          </p>
                          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                            {project.category_name || 'N/A'}
                          </span>
                          {getStatusBadge(project.status)}
                        </div>
                        <div className="flex items-center space-x-4 mt-1">
                          <p className="text-sm text-gray-500">
                            👤 {project.client_name || 'Utilisateur'}
                          </p>
                          <p className="text-sm text-gray-500">
                            💰 {getBudgetDisplay(project)}
                          </p>
                          <p className="text-sm text-gray-500">
                            📝 {project.offers_count || 0} offres
                          </p>
                          <p className="text-sm text-gray-500">
                            👀 {project.views_count || 0} vues
                          </p>
                          <p className="text-sm text-gray-500">
                            📅 {new Date(project.created_at).toLocaleDateString('fr-FR')}
                          </p>
                        </div>
                        <p className="text-sm text-gray-600 mt-1 truncate">
                          {project.description}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center space-x-2">
                      <button
                        onClick={() => handleViewProject(project.id)}
                        className="text-indigo-600 hover:text-indigo-900 text-sm font-medium"
                      >
                        ✏️
                      </button>
                      <button className="text-red-600 hover:text-red-900 text-sm font-medium">
                        🗑️
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {projects.length === 0 && !loading && (
              <div className="text-center py-12">
                <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                </svg>
                <h3 className="mt-4 text-sm font-medium text-gray-900">Aucun projet trouvé</h3>
                <p className="mt-2 text-sm text-gray-500">
                  {search || statusFilter || categoryFilter
                    ? 'Essayez de modifier vos critères de recherche'
                    : 'Aucun projet n\'a encore été créé'}
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

export default Projects;