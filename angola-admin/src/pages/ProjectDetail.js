// admin/src/pages/ProjectDetail.js
import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import DashboardLayout from '../layouts/DashboardLayout';
import { projectService } from '../services/api';

const ProjectDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [project, setProject] = useState(null);
  const [offers, setOffers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [newStatus, setNewStatus] = useState('');
  const [adminNotes, setAdminNotes] = useState('');
  const [activeTab, setActiveTab] = useState('details');
  const [updating, setUpdating] = useState(false);

  useEffect(() => {
    const fetchProjectData = async () => {
      try {
        setLoading(true);
        
        // Récupérer les détails du projet
        const projectResponse = await projectService.getById(id);
        setProject(projectResponse.data);
        setNewStatus(projectResponse.data.status);
        setAdminNotes(projectResponse.data.admin_notes || '');
        
        // Récupérer les offres du projet
        const offersResponse = await projectService.getOffers(id);
        setOffers(offersResponse.data || []);
        
      } catch (err) {
        console.error('Erreur lors du chargement du projet', err);
        setError('Impossible de charger les détails du projet.');
      } finally {
        setLoading(false);
      }
    };

    if (id) {
      fetchProjectData();
    }
  }, [id]);

  const handleUpdateStatus = async () => {
    try {
      setUpdating(true);
      await projectService.updateStatus(id, newStatus, adminNotes);
      setProject({ ...project, status: newStatus, admin_notes: adminNotes });
      
      // Notification de succès
      const notification = document.createElement('div');
      notification.className = 'alert alert-success fixed top-4 right-4 w-auto z-50';
      notification.innerHTML = '<span>Statut du projet mis à jour avec succès</span>';
      document.body.appendChild(notification);
      setTimeout(() => document.body.removeChild(notification), 3000);
      
    } catch (err) {
      console.error('Erreur lors de la mise à jour du statut', err);
      // Notification d'erreur
      const notification = document.createElement('div');
      notification.className = 'alert alert-error fixed top-4 right-4 w-auto z-50';
      notification.innerHTML = '<span>Impossible de mettre à jour le statut du projet</span>';
      document.body.appendChild(notification);
      setTimeout(() => document.body.removeChild(notification), 3000);
    } finally {
      setUpdating(false);
    }
  };

  const getStatusBadge = (status) => {
    const statusConfig = {
      open: { color: 'text-yellow-600 bg-yellow-100', text: '⏳ Ouvert' },
      in_progress: { color: 'text-blue-600 bg-blue-100', text: '🔄 En cours' },
      completed: { color: 'text-green-600 bg-green-100', text: '✅ Terminé' },
      cancelled: { color: 'text-red-600 bg-red-100', text: '❌ Annulé' },
      closed: { color: 'text-red-600 bg-red-100', text: '🔒 Fermé' },
      paused: { color: 'text-gray-600 bg-gray-100', text: '⏸️ En pause' },
    };
    const config = statusConfig[status] || { color: 'text-gray-600 bg-gray-100', text: status };
    return (
      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${config.color}`}>
        {config.text}
      </span>
    );
  };

  const getOfferStatusBadge = (status) => {
    const statusConfig = {
      pending: { color: 'text-yellow-600 bg-yellow-100', text: '⏳ En attente' },
      accepted: { color: 'text-green-600 bg-green-100', text: '✅ Acceptée' },
      rejected: { color: 'text-red-600 bg-red-100', text: '❌ Rejetée' },
      withdrawn: { color: 'text-gray-600 bg-gray-100', text: '↩️ Retirée' },
    };
    const config = statusConfig[status] || { color: 'text-gray-600 bg-gray-100', text: status };
    return (
      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${config.color}`}>
        {config.text}
      </span>
    );
  };

  const getBudgetDisplay = (project) => {
    // Utiliser budget_display si disponible
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
    return name ? name.charAt(0).toUpperCase() : 'P';
  };

  if (loading) {
    return (
      <DashboardLayout>
        <div className="p-6">
          <div className="flex h-96 items-center justify-center">
            <div className="text-center">
              <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-current border-r-transparent motion-reduce:animate-[spin_1.5s_linear_infinite]"></div>
              <p className="mt-4 text-sm text-gray-500">Chargement du projet...</p>
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
                  onClick={() => navigate('/projects')}
                >
                  Retour aux projets
                </button>
              </div>
            </div>
          </div>
        </div>
      </DashboardLayout>
    );
  }

  if (!project) {
    return (
      <DashboardLayout>
        <div className="p-6">
          <div className="text-center py-12">
            <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.172 16.172a4 4 0 015.656 0M9 12h6m-6-4h6m2 5.291A7.962 7.962 0 0112 15c-2.034 0-3.9-.62-5.291-1.709M6.41 15.291A7.962 7.962 0 016 12a8 8 0 018-8 8 8 0 018 8c0 1.285-.3 2.49-.819 3.567L18 21l-6-3-6 3 2.819-5.433z" />
            </svg>
            <h3 className="mt-4 text-sm font-medium text-gray-900">Projet non trouvé</h3>
            <button
              className="mt-4 bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium"
              onClick={() => navigate('/projects')}
            >
              Retour aux projets
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
              onClick={() => navigate('/projects')}
            >
              ← Retour aux projets
            </button>
            <div className="h-6 border-l border-gray-300"></div>
            <h1 className="text-2xl font-semibold text-gray-900">
              {project.title}
            </h1>
          </div>
          <div className="flex items-center space-x-3">
            {getStatusBadge(project.status)}
            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
              ID: {project.id}
            </span>
          </div>
        </div>

        {/* Informations principales */}
        <div className="mb-8 bg-white shadow-sm rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <div className="grid grid-cols-1 gap-y-6 sm:grid-cols-2 lg:grid-cols-3 sm:gap-x-6">
              <div>
                <dt className="text-sm font-medium text-gray-500">Client</dt>
                <dd className="mt-1 text-sm text-gray-900 flex items-center">
                  <div className="h-8 w-8 rounded-full bg-indigo-100 flex items-center justify-center mr-3">
                    <span className="text-sm font-medium text-indigo-600">
                      {getInitials(project.client_name)}
                    </span>
                  </div>
                  {project.client_name || 'Utilisateur'}
                </dd>
              </div>

              <div>
                <dt className="text-sm font-medium text-gray-500">Catégorie</dt>
                <dd className="mt-1">
                  <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                    {project.category_name || 'N/A'}
                  </span>
                </dd>
              </div>

              <div>
                <dt className="text-sm font-medium text-gray-500">Budget</dt>
                <dd className="mt-1 text-sm text-gray-900">
                  💰 {getBudgetDisplay(project)}
                </dd>
              </div>

              <div>
                <dt className="text-sm font-medium text-gray-500">Localisation</dt>
                <dd className="mt-1 text-sm text-gray-900">
                  📍 {project.location || 'Non spécifié'}
                </dd>
              </div>

              <div>
                <dt className="text-sm font-medium text-gray-500">Date limite</dt>
                <dd className="mt-1 text-sm text-gray-900">
                  📅 {project.deadline 
                    ? new Date(project.deadline).toLocaleDateString('fr-FR')
                    : 'Non spécifié'
                  }
                </dd>
              </div>

              <div>
                <dt className="text-sm font-medium text-gray-500">Date de création</dt>
                <dd className="mt-1 text-sm text-gray-900">
                  📅 {new Date(project.created_at).toLocaleDateString('fr-FR')}
                </dd>
              </div>
            </div>

            <div className="mt-6">
              <dt className="text-sm font-medium text-gray-500">Description</dt>
              <dd className="mt-2 text-sm text-gray-900 whitespace-pre-wrap">
                {project.description}
              </dd>
            </div>

            {project.required_skills && project.required_skills.length > 0 && (
              <div className="mt-6">
                <dt className="text-sm font-medium text-gray-500 mb-2">Compétences requises</dt>
                <dd className="flex flex-wrap gap-2">
                  {project.required_skills.map((skill, index) => (
                    <span key={index} className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                      {skill}
                    </span>
                  ))}
                </dd>
              </div>
            )}
          </div>
        </div>

        {/* Navigation par onglets */}
        <div className="mb-8">
          <div className="border-b border-gray-200">
            <nav className="-mb-px flex space-x-8">
              <button
                onClick={() => setActiveTab('details')}
                className={`py-2 px-1 border-b-2 font-medium text-sm ${
                  activeTab === 'details'
                    ? 'border-indigo-500 text-indigo-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                📋 Détails
              </button>
              <button
                onClick={() => setActiveTab('offers')}
                className={`py-2 px-1 border-b-2 font-medium text-sm ${
                  activeTab === 'offers'
                    ? 'border-indigo-500 text-indigo-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                💼 Offres ({offers.length})
              </button>
              <button
                onClick={() => setActiveTab('admin')}
                className={`py-2 px-1 border-b-2 font-medium text-sm ${
                  activeTab === 'admin'
                    ? 'border-indigo-500 text-indigo-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                ⚙️ Administration
              </button>
            </nav>
          </div>
        </div>

        {/* Statistiques rapides */}
        {activeTab === 'details' && (
          <div className="grid grid-cols-1 gap-5 sm:grid-cols-3 mb-8">
            <div className="bg-white overflow-hidden shadow-sm rounded-lg">
              <div className="px-4 py-5 sm:p-6">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <div className="flex h-8 w-8 items-center justify-center rounded-md bg-blue-500 text-white">
                      👀
                    </div>
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">Vues</dt>
                      <dd className="text-lg font-semibold text-gray-900">{project.views_count || 0}</dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>

            <div className="bg-white overflow-hidden shadow-sm rounded-lg">
              <div className="px-4 py-5 sm:p-6">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <div className="flex h-8 w-8 items-center justify-center rounded-md bg-red-500 text-white">
                      ❤️
                    </div>
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">Favoris</dt>
                      <dd className="text-lg font-semibold text-gray-900">{project.favorites_count || 0}</dd>
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
                      💼
                    </div>
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">Offres</dt>
                      <dd className="text-lg font-semibold text-gray-900">{offers.length}</dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Contenu des onglets */}
        {activeTab === 'offers' && (
          <div className="bg-white shadow-sm rounded-lg">
            <div className="px-4 py-5 sm:p-6">
              <h3 className="text-lg font-medium text-gray-900 mb-4">Offres reçues</h3>
              
              {offers.length === 0 ? (
                <div className="text-center py-12">
                  <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
                  </svg>
                  <h3 className="mt-4 text-sm font-medium text-gray-900">Aucune offre</h3>
                  <p className="mt-2 text-sm text-gray-500">
                    Ce projet n'a pas encore reçu d'offres de prestataires.
                  </p>
                </div>
              ) : (
                <div className="space-y-4">
                  {offers.map((offer) => (
                    <div key={offer.id} className="border border-gray-200 rounded-lg p-4 hover:bg-gray-50">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center space-x-4">
                          <div className="flex-shrink-0">
                            <div className="h-10 w-10 rounded-full bg-indigo-100 flex items-center justify-center">
                              <span className="text-sm font-medium text-indigo-600">
                                {getInitials(offer.provider_name)}
                              </span>
                            </div>
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center space-x-3">
                              <p className="text-sm font-medium text-gray-900">
                                {offer.provider_name || 'Prestataire'}
                              </p>
                              {getOfferStatusBadge(offer.status)}
                            </div>
                            <div className="flex items-center space-x-4 mt-1">
                              <p className="text-sm text-gray-500">
                                💰 {offer.proposed_price} AOA
                              </p>
                              <p className="text-sm text-gray-500">
                                ⏱️ {offer.delivery_time || offer.estimated_duration || 'Non spécifié'} jours
                              </p>
                              <p className="text-sm text-gray-500">
                                ⭐ {offer.provider_rating ? parseFloat(offer.provider_rating).toFixed(1) : 'N/A'}
                              </p>
                              <p className="text-sm text-gray-500">
                                📅 {new Date(offer.created_at).toLocaleDateString('fr-FR')}
                              </p>
                            </div>
                          </div>
                        </div>
                        <div className="flex items-center space-x-2">
                          <button className="text-indigo-600 hover:text-indigo-900 text-sm font-medium">
                            👁️ Voir détails
                          </button>
                        </div>
                      </div>
                      {offer.message && (
                        <div className="mt-3 pl-14">
                          <p className="text-sm text-gray-600 italic">
                            "{offer.message}"
                          </p>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}

        {activeTab === 'admin' && (
          <div className="bg-white shadow-sm rounded-lg">
            <div className="px-4 py-5 sm:p-6">
              <h3 className="text-lg font-medium text-gray-900 mb-6">Administration du projet</h3>
              
              <div className="space-y-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Statut du projet
                  </label>
                  <select
                    className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                    value={newStatus}
                    onChange={(e) => setNewStatus(e.target.value)}
                  >
                    <option value="open">Ouvert</option>
                    <option value="in_progress">En cours</option>
                    <option value="completed">Terminé</option>
                    <option value="cancelled">Annulé</option>
                    <option value="closed">Fermé</option>
                    <option value="paused">En pause</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Notes administratives
                  </label>
                  <textarea
                    className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    rows="4"
                    placeholder="Ajoutez des notes administratives sur ce projet..."
                    value={adminNotes}
                    onChange={(e) => setAdminNotes(e.target.value)}
                  />
                </div>

                <div>
                  <button
                    className={`bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium ${
                      updating ? 'opacity-50 cursor-not-allowed' : ''
                    }`}
                    onClick={handleUpdateStatus}
                    disabled={updating}
                  >
                    {updating ? 'Mise à jour...' : 'Mettre à jour'}
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
};

export default ProjectDetail;