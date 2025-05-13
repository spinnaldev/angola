import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import DashboardLayout from '../layouts/DashboardLayout';
import { disputeService } from '../services/api';
import { withAuth } from '../context/AuthContext';

// Icônes
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import PersonIcon from '@mui/icons-material/Person';
import HandymanIcon from '@mui/icons-material/Handyman';
import AttachFileIcon from '@mui/icons-material/AttachFile';
import EventIcon from '@mui/icons-material/Event';
import SearchIcon from '@mui/icons-material/Search';
import ChevronLeftIcon from '@mui/icons-material/ChevronLeft';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';

const DisputeStatusBadge = ({ status }) => {
  switch (status) {
    case 'open':
      return (
        <span className="badge badge-warning">
          En attente
        </span>
      );
    case 'under_review':
      return (
        <span className="badge badge-info">
          En cours d'examen
        </span>
      );
    case 'resolved':
      return (
        <span className="badge badge-success">
          Résolu
        </span>
      );
    case 'closed':
      return (
        <span className="badge badge-secondary">
          Fermé
        </span>
      );
    default:
      return (
        <span className="badge badge-secondary">
          {status}
        </span>
      );
  }
};

const DisputeDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [dispute, setDispute] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [resolution, setResolution] = useState('');
  const [newStatus, setNewStatus] = useState('');

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
      const response = await disputeService.updateStatus(id, newStatus, resolution);
      setDispute({ ...dispute, status: newStatus, resolution_note: resolution });
      alert('Statut du litige mis à jour avec succès');
    } catch (err) {
      console.error('Erreur lors de la mise à jour du statut', err);
      setError('Impossible de mettre à jour le statut du litige.');
    }
  };

  if (loading) {
    return (
      <DashboardLayout>
        <div className="flex h-96 items-center justify-center">
          <div className="text-center">
            <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-primary"></div>
            <p className="mt-2 text-text-secondary">Chargement du litige...</p>
          </div>
        </div>
      </DashboardLayout>
    );
  }

  if (error) {
    return (
      <DashboardLayout>
        <div className="rounded-md bg-error/10 p-4">
          <div className="flex">
            <div className="ml-3">
              <h3 className="text-sm font-medium text-error">Erreur</h3>
              <div className="mt-2 text-sm text-error">{error}</div>
              <div className="mt-4">
                <button
                  type="button"
                  className="btn btn-outline"
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
        <div className="text-center">
          <p className="text-text-secondary">Litige non trouvé</p>
          <button
            type="button"
            className="btn btn-outline mt-4"
            onClick={() => navigate('/disputes')}
          >
            Retour aux litiges
          </button>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <button
            type="button"
            className="flex items-center text-text-secondary hover:text-primary"
            onClick={() => navigate('/disputes')}
          >
            <ArrowBackIcon className="mr-1" />
            Retour à la liste
          </button>
          <DisputeStatusBadge status={dispute.status} />
        </div>

        <div className="card">
          <h1 className="mb-4 text-2xl font-bold text-text-primary">
            {dispute.title}
          </h1>
          <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
            <div className="lg:col-span-2">
              <div className="mb-6 rounded-lg border p-4">
                <h2 className="mb-2 text-lg font-semibold text-text-primary">
                  Description du litige
                </h2>
                <p className="text-text-secondary">{dispute.description}</p>
              </div>

              {dispute.evidence && dispute.evidence.length > 0 && (
                <div className="mb-6 rounded-lg border p-4">
                  <h2 className="mb-2 text-lg font-semibold text-text-primary">
                    Preuves soumises
                  </h2>
                  <div className="space-y-4">
                    {dispute.evidence.map((item) => (
                      <div
                        key={item.id}
                        className="flex items-start rounded-lg border p-3"
                      >
                        <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-gray-100">
                          <AttachFileIcon className="text-text-secondary" />
                        </div>
                        <div className="ml-3">
                          <div className="text-sm font-medium text-text-primary">
                            {item.user_name}
                          </div>
                          <div className="text-text-secondary">{item.description}</div>
                          <div className="mt-1">
                            <a
                              href={item.file}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="text-sm text-primary hover:text-primary-dark"
                            >
                              Voir le fichier
                            </a>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              <div className="rounded-lg border p-4">
                <h2 className="mb-2 text-lg font-semibold text-text-primary">
                  Résolution du litige
                </h2>

                <div className="mb-4">
                  <label htmlFor="status" className="label">
                    Statut
                  </label>
                  <select
                    id="status"
                    className="input w-full"
                    value={newStatus}
                    onChange={(e) => setNewStatus(e.target.value)}
                  >
                    <option value="open">En attente</option>
                    <option value="under_review">En cours d'examen</option>
                    <option value="resolved">Résolu</option>
                    <option value="closed">Fermé</option>
                  </select>
                </div>

                <div className="mb-4">
                  <label htmlFor="resolution" className="label">
                    Note de résolution
                  </label>
                  <textarea
                    id="resolution"
                    className="input w-full"
                    rows="5"
                    value={resolution}
                    onChange={(e) => setResolution(e.target.value)}
                    placeholder="Ajoutez ici les détails de la résolution..."
                  ></textarea>
                </div>

                <button
                  type="button"
                  className="btn btn-primary"
                  onClick={handleUpdateStatus}
                >
                  Mettre à jour le statut
                </button>
              </div>
            </div>

            <div className="space-y-6">
              <div className="rounded-lg border p-4">
                <h2 className="mb-4 text-lg font-semibold text-text-primary">
                  Informations du litige
                </h2>
                <div className="space-y-4">
                  <div className="flex items-start">
                    <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
                      <PersonIcon className="text-primary" />
                    </div>
                    <div className="ml-3">
                      <div className="text-sm text-text-secondary">Client</div>
                      <div className="font-medium text-text-primary">
                        {dispute.client_name}
                      </div>
                    </div>
                  </div>

                  <div className="flex items-start">
                    <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-secondary/10">
                      <HandymanIcon className="text-secondary" />
                    </div>
                    <div className="ml-3">
                      <div className="text-sm text-text-secondary">Prestataire</div>
                      <div className="font-medium text-text-primary">
                        {dispute.provider_name}
                      </div>
                    </div>
                  </div>

                  {dispute.service_title && (
                    <div className="flex items-start">
                      <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-accent/10">
                        <CheckCircleIcon className="text-accent" />
                      </div>
                      <div className="ml-3">
                        <div className="text-sm text-text-secondary">Service concerné</div>
                        <div className="font-medium text-text-primary">
                          {dispute.service_title}
                        </div>
                      </div>
                    </div>
                  )}

                  <div className="flex items-start">
                    <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-gray-100">
                      <EventIcon className="text-text-secondary" />
                    </div>
                    <div className="ml-3">
                      <div className="text-sm text-text-secondary">Date de création</div>
                      <div className="font-medium text-text-primary">
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

  const filteredDisputes = disputes.filter((dispute) => {
    const searchTerm = search.toLowerCase();
    const matchesSearch =
      dispute.title.toLowerCase().includes(searchTerm) ||
      dispute.description.toLowerCase().includes(searchTerm) ||
      dispute.client_name.toLowerCase().includes(searchTerm) ||
      dispute.provider_name.toLowerCase().includes(searchTerm);

    const matchesStatus = statusFilter ? dispute.status === statusFilter : true;

    return matchesSearch && matchesStatus;
  });

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {error && (
          <div className="rounded-md bg-error/10 p-4">
            <div className="flex">
              <div className="ml-3">
                <h3 className="text-sm font-medium text-error">Erreur</h3>
                <div className="mt-2 text-sm text-error">{error}</div>
              </div>
            </div>
          </div>
        )}

        <div className="flex flex-col md:flex-row md:items-center md:justify-between">
          <h1 className="text-2xl font-bold text-text-primary">
            Gestion des litiges
          </h1>
          <div className="mt-4 flex items-center space-x-4 md:mt-0">
            <div className="relative">
              <SearchIcon className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-text-disabled" />
              <input
                type="text"
                placeholder="Rechercher..."
                className="input w-full pl-10 md:w-64"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
            <select
              className="input w-full md:w-auto"
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

        <div className="card overflow-hidden p-0">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th
                    scope="col"
                    className="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-text-secondary sm:pl-6"
                  >
                    Titre
                  </th>
                  <th
                    scope="col"
                    className="px-3 py-3.5 text-left text-sm font-semibold text-text-secondary"
                  >
                    Client
                  </th>
                  <th
                    scope="col"
                    className="px-3 py-3.5 text-left text-sm font-semibold text-text-secondary"
                  >
                    Prestataire
                  </th>
                  <th
                    scope="col"
                    className="px-3 py-3.5 text-left text-sm font-semibold text-text-secondary"
                  >
                    Date
                  </th>
                  <th
                    scope="col"
                    className="px-3 py-3.5 text-left text-sm font-semibold text-text-secondary"
                  >
                    Statut
                  </th>
                  <th
                    scope="col"
                    className="relative py-3.5 pl-3 pr-4 sm:pr-6"
                  >
                    <span className="sr-only">Actions</span>
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 bg-white">
                {loading ? (
                  <tr>
                    <td colSpan="6" className="py-10 text-center text-text-secondary">
                      <div className="flex items-center justify-center">
                        <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-primary"></div>
                        <span className="ml-2">Chargement...</span>
                      </div>
                    </td>
                  </tr>
                ) : filteredDisputes.length === 0 ? (
                  <tr>
                    <td colSpan="6" className="py-10 text-center text-text-secondary">
                      Aucun litige trouvé
                    </td>
                  </tr>
                ) : (
                  filteredDisputes.map((dispute) => (
                    <tr key={dispute.id} className="hover:bg-gray-50">
                      <td className="whitespace-nowrap py-4 pl-4 pr-3 text-sm sm:pl-6">
                        <div className="font-medium text-text-primary">
                          {dispute.title}
                        </div>
                        <div className="mt-1 text-xs text-text-secondary line-clamp-1">
                          {dispute.description}
                        </div>
                      </td>
                      <td className="whitespace-nowrap px-3 py-4 text-sm text-text-secondary">
                        {dispute.client_name}
                      </td>
                      <td className="whitespace-nowrap px-3 py-4 text-sm text-text-secondary">
                        {dispute.provider_name}
                      </td>
                      <td className="whitespace-nowrap px-3 py-4 text-sm text-text-secondary">
                        {new Date(dispute.created_at).toLocaleDateString('fr-FR')}
                      </td>
                      <td className="whitespace-nowrap px-3 py-4 text-sm">
                        <DisputeStatusBadge status={dispute.status} />
                      </td>
                      <td className="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6">
                        <button
                          onClick={() => handleViewDispute(dispute.id)}
                          className="text-primary hover:text-primary-dark"
                        >
                          Voir détails
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {!loading && totalPages > 1 && (
            <div className="flex items-center justify-between border-t bg-white px-4 py-3 sm:px-6">
              <div className="hidden sm:flex sm:flex-1 sm:items-center sm:justify-between">
                <div>
                  <p className="text-sm text-text-secondary">
                    Page <span className="font-medium">{currentPage}</span> sur{' '}
                    <span className="font-medium">{totalPages}</span>
                  </p>
                </div>
                <div>
                  <nav
                    className="isolate inline-flex -space-x-px rounded-md shadow-sm"
                    aria-label="Pagination"
                  >
                    <button
                      disabled={currentPage === 1}
                      onClick={() => setCurrentPage((old) => Math.max(old - 1, 1))}
                      className={`relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-400 ${
                        currentPage === 1
                          ? 'cursor-not-allowed'
                          : 'hover:bg-primary/10'
                      }`}
                    >
                      <span className="sr-only">Previous</span>
                      <ChevronLeftIcon className="h-5 w-5" aria-hidden="true" />
                    </button>
                    {/* Current page */}
                    <span
                      aria-current="page"
                      className="relative z-10 inline-flex items-center bg-primary px-4 py-2 text-sm font-semibold text-white focus:z-20 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                    >
                      {currentPage}
                    </span>
                    <button
                      disabled={currentPage === totalPages}
                      onClick={() =>
                        setCurrentPage((old) => Math.min(old + 1, totalPages))
                      }
                      className={`relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-400 ${
                        currentPage === totalPages
                          ? 'cursor-not-allowed'
                          : 'hover:bg-primary/10'
                      }`}
                    >
                      <span className="sr-only">Next</span>
                      <ChevronRightIcon className="h-5 w-5" aria-hidden="true" />
                    </button>
                  </nav>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </DashboardLayout>
  );
};

export { DisputeDetail, Disputes };
export default withAuth(Disputes);