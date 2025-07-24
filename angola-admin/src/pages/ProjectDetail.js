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
      await projectService.updateStatus(id, newStatus, adminNotes);
      setProject({ ...project, status: newStatus, admin_notes: adminNotes });
      alert('Statut du projet mis à jour avec succès');
    } catch (err) {
      console.error('Erreur lors de la mise à jour du statut', err);
      alert('Impossible de mettre à jour le statut du projet.');
    }
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

  const getOfferStatusBadge = (status) => {
    const statusConfig = {
      pending: { class: 'badge-warning', text: 'En attente' },
      accepted: { class: 'badge-success', text: 'Acceptée' },
      rejected: { class: 'badge-error', text: 'Rejetée' },
      withdrawn: { class: 'badge-secondary', text: 'Retirée' },
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

  if (loading) {
    return (
      <DashboardLayout>
        <div className="flex h-96 items-center justify-center">
          <div className="text-center">
            <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-primary"></div>
            <p className="mt-2 text-text-secondary">Chargement du projet...</p>
          </div>
        </div>
      </DashboardLayout>
    );
  }

  if (error) {
    return (
      <DashboardLayout>
        <div className="alert alert-error">
          <span>{error}</span>
          <button
            className="btn btn-sm btn-outline"
            onClick={() => navigate('/projects')}
          >
            Retour aux projets
          </button>
        </div>
      </DashboardLayout>
    );
  }

  if (!project) {
    return (
      <DashboardLayout>
        <div className="text-center">
          <p className="text-text-secondary">Projet non trouvé</p>
          <button
            className="btn btn-outline mt-4"
            onClick={() => navigate('/projects')}
          >
            Retour aux projets
          </button>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* En-tête */}
        <div className="flex items-center justify-between">
          <button
            className="btn btn-ghost"
            onClick={() => navigate('/projects')}
          >
            ← Retour aux projets
          </button>
          <div className="flex gap-2">
            {getStatusBadge(project.status)}
            <span className="badge badge-outline">ID: {project.id}</span>
          </div>
        </div>

        {/* Titre et informations principales */}
        <div className="card">
          <div className="card-body">
            <h1 className="text-2xl font-bold text-text-primary mb-4">
              {project.title}
            </h1>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
              <div>
                <h3 className="font-semibold text-text-secondary">Client</h3>
                <p>{project.client_name || 'Utilisateur'}</p>
              </div>
              <div>
                <h3 className="font-semibold text-text-secondary">Catégorie</h3>
                <p>{project.category_name || 'N/A'}</p>
              </div>
              <div>
                <h3 className="font-semibold text-text-secondary">Budget</h3>
                <p>{getBudgetDisplay(project.budget_type, project.max_budget)}</p>
              </div>
              <div>
                <h3 className="font-semibold text-text-secondary">Localisation</h3>
                <p>{project.location || 'Non spécifié'}</p>
              </div>
              <div>
                <h3 className="font-semibold text-text-secondary">Date limite</h3>
                <p>
                  {project.deadline 
                    ? new Date(project.deadline).toLocaleDateString('fr-FR')
                    : 'Non spécifié'
                  }
                </p>
              </div>
              <div>
                <h3 className="font-semibold text-text-secondary">Date de création</h3>
                <p>{new Date(project.created_at).toLocaleDateString('fr-FR')}</p>
              </div>
            </div>
            
            <div>
              <h3 className="font-semibold text-text-secondary mb-2">Description</h3>
              <p className="text-text-primary whitespace-pre-wrap">
                {project.description}
              </p>
            </div>

            {project.required_skills && project.required_skills.length > 0 && (
              <div className="mt-4">
                <h3 className="font-semibold text-text-secondary mb-2">Compétences requises</h3>
                <div className="flex flex-wrap gap-2">
                  {project.required_skills.map((skill, index) => (
                    <span key={index} className="badge badge-outline">
                      {skill}
                    </span>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Onglets */}
        <div className="tabs tabs-bordered">
          <button
            className={`tab ${activeTab === 'details' ? 'tab-active' : ''}`}
            onClick={() => setActiveTab('details')}
          >
            Détails
          </button>
          <button
            className={`tab ${activeTab === 'offers' ? 'tab-active' : ''}`}
            onClick={() => setActiveTab('offers')}
          >
            Offres ({offers.length})
          </button>
          <button
            className={`tab ${activeTab === 'admin' ? 'tab-active' : ''}`}
            onClick={() => setActiveTab('admin')}
          >
            Administration
          </button>
        </div>

        {/* Contenu des onglets */}
        {activeTab === 'offers' && (
          <div className="card">
            <div className="card-body">
              <h3 className="text-lg font-semibold mb-4">Offres reçues</h3>
              
              {offers.length === 0 ? (
                <p className="text-text-secondary">Aucune offre reçue pour ce projet</p>
              ) : (
                <div className="overflow-x-auto">
                  <table className="table table-zebra w-full">
                    <thead>
                      <tr>
                        <th>Prestataire</th>
                        <th>Prix proposé</th>
                        <th>Délai</th>
                        <th>Statut</th>
                        <th>Date</th>
                        <th>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {offers.map((offer) => (
                        <tr key={offer.id}>
                          <td>
                            <div className="flex items-center space-x-2">
                              <div className="avatar placeholder">
                                <div className="bg-neutral-focus text-neutral-content rounded-full w-8">
                                  <span className="text-xs">
                                    {offer.provider_name?.charAt(0) || 'P'}
                                  </span>
                                </div>
                              </div>
                              <div>
                                <div className="font-semibold">{offer.provider_name}</div>
                                <div className="text-sm text-text-secondary">
                                  ⭐ {offer.provider_rating || 'N/A'}
                                </div>
                              </div>
                            </div>
                          </td>
                          <td className="font-semibold">
                            {offer.proposed_price} AOA
                          </td>
                          <td>{offer.estimated_duration || 'Non spécifié'}</td>
                          <td>{getOfferStatusBadge(offer.status)}</td>
                          <td className="text-sm">
                            {new Date(offer.created_at).toLocaleDateString('fr-FR')}
                          </td>
                          <td>
                            <button className="btn btn-sm btn-ghost">
                              Voir détails
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        )}

        {activeTab === 'admin' && (
          <div className="card">
            <div className="card-body">
              <h3 className="text-lg font-semibold mb-4">Administration du projet</h3>
              
              <div className="space-y-4">
                <div>
                  <label className="label">
                    <span className="label-text font-semibold">Statut du projet</span>
                  </label>
                  <select
                    className="select select-bordered w-full max-w-xs"
                    value={newStatus}
                    onChange={(e) => setNewStatus(e.target.value)}
                  >
                    <option value="open">Ouvert</option>
                    <option value="in_progress">En cours</option>
                    <option value="completed">Terminé</option>
                    <option value="cancelled">Annulé</option>
                  </select>
                </div>

                <div>
                  <label className="label">
                    <span className="label-text font-semibold">Notes administratives</span>
                  </label>
                  <textarea
                    className="textarea textarea-bordered w-full"
                    rows="4"
                    placeholder="Ajoutez des notes administratives..."
                    value={adminNotes}
                    onChange={(e) => setAdminNotes(e.target.value)}
                  />
                </div>

                <button
                  className="btn btn-primary"
                  onClick={handleUpdateStatus}
                >
                  Mettre à jour
                </button>
              </div>

              {/* Statistiques du projet */}
              <div className="divider"></div>
              
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="stat">
                  <div className="stat-title">Vues du projet</div>
                  <div className="stat-value text-primary">{project.views_count || 0}</div>
                </div>
                <div className="stat">
                  <div className="stat-title">Favoris</div>
                  <div className="stat-value text-secondary">{project.favorites_count || 0}</div>
                </div>
                <div className="stat">
                  <div className="stat-title">Offres reçues</div>
                  <div className="stat-value text-accent">{offers.length}</div>
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