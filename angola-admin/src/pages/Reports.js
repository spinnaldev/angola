import React, { useState, useEffect } from 'react';
import DashboardLayout from '../layouts/DashboardLayout';
import { reportService } from '../services/api';
import { withAuth } from '../context/AuthContext';

// Icônes
import SearchIcon from '@mui/icons-material/Search';
import FlagIcon from '@mui/icons-material/Flag';
import PersonIcon from '@mui/icons-material/Person';
import HandymanIcon from '@mui/icons-material/Handyman';
import StarIcon from '@mui/icons-material/Star';
import ChevronLeftIcon from '@mui/icons-material/ChevronLeft';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import MoreVertIcon from '@mui/icons-material/MoreVert';

const ReportStatusBadge = ({ status }) => {
  switch (status) {
    case 'pending':
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
    case 'dismissed':
      return (
        <span className="badge badge-secondary">
          Rejeté
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

const ReportTypeIcon = ({ type }) => {
  switch (type) {
    case 'provider':
      return <HandymanIcon className="text-secondary" />;
    case 'user':
      return <PersonIcon className="text-primary" />;
    case 'review':
      return <StarIcon className="text-warning" />;
    default:
      return <FlagIcon className="text-error" />;
  }
};

const ReportDetailModal = ({ report, onClose, onUpdateStatus }) => {
  const [status, setStatus] = useState(report.status);
  const [adminNotes, setAdminNotes] = useState(report.admin_notes || '');
  const [saving, setSaving] = useState(false);

  const handleStatusUpdate = async () => {
    setSaving(true);
    try {
      await onUpdateStatus(report.id, status, adminNotes);
      onClose();
    } catch (error) {
      console.error('Erreur lors de la mise à jour du statut', error);
      alert('Une erreur est survenue lors de la mise à jour du statut.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center overflow-y-auto overflow-x-hidden bg-black bg-opacity-50">
      <div className="relative mx-auto my-6 w-full max-w-3xl p-4">
        <div className="relative rounded-lg bg-white shadow-lg">
          <div className="flex items-center justify-between border-b px-6 py-4">
            <h3 className="text-xl font-semibold text-text-primary">
              Détails du signalement
            </h3>
            <button
              onClick={onClose}
              className="text-text-disabled hover:text-text-secondary"
            >
              &times;
            </button>
          </div>

          <div className="p-6">
            <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
              <div className="md:col-span-2">
                <div className="rounded-lg border p-4">
                  <h4 className="mb-2 text-lg font-medium text-text-primary">
                    Motif du signalement
                  </h4>
                  <p className="text-text-secondary">{report.reason}</p>
                </div>

                <div className="mt-4 rounded-lg border p-4">
                  <h4 className="mb-2 text-lg font-medium text-text-primary">
                    Traitement du signalement
                  </h4>
                  <div>
                    <label htmlFor="status" className="label">
                      Statut
                    </label>
                    <select
                      id="status"
                      className="input w-full"
                      value={status}
                      onChange={(e) => setStatus(e.target.value)}
                    >
                      <option value="pending">En attente</option>
                      <option value="under_review">En cours d'examen</option>
                      <option value="resolved">Résolu</option>
                      <option value="dismissed">Rejeté</option>
                    </select>
                  </div>

                  <div className="mt-4">
                    <label htmlFor="adminNotes" className="label">
                      Notes administratives
                    </label>
                    <textarea
                      id="adminNotes"
                      className="input w-full"
                      rows="5"
                      value={adminNotes}
                      onChange={(e) => setAdminNotes(e.target.value)}
                      placeholder="Ajoutez vos notes concernant ce signalement..."
                    ></textarea>
                  </div>
                </div>
              </div>

              <div className="space-y-4">
                <div className="rounded-lg border p-4">
                  <h4 className="mb-4 text-lg font-medium text-text-primary">
                    Informations
                  </h4>
                  <div className="space-y-3">
                    <div>
                      <span className="text-sm text-text-secondary">Type:</span>
                      <div className="mt-1 flex items-center">
                        <ReportTypeIcon type={report.type} />
                        <span className="ml-2 font-medium text-text-primary">
                          {report.type === 'provider'
                            ? 'Prestataire'
                            : report.type === 'user'
                            ? 'Utilisateur'
                            : report.type === 'review'
                            ? 'Avis'
                            : report.type}
                        </span>
                      </div>
                    </div>
                    <div>
                      <span className="text-sm text-text-secondary">Statut:</span>
                      <div className="mt-1">
                        <ReportStatusBadge status={report.status} />
                      </div>
                    </div>
                    <div>
                      <span className="text-sm text-text-secondary">Date:</span>
                      <div className="mt-1 font-medium text-text-primary">
                        {new Date(report.created_at).toLocaleDateString('fr-FR', {
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

                <div className="rounded-lg border p-4">
                  <h4 className="mb-4 text-lg font-medium text-text-primary">
                    Personnes concernées
                  </h4>
                  <div className="space-y-3">
                    <div>
                      <span className="text-sm text-text-secondary">Signalé par:</span>
                      <div className="mt-1 font-medium text-text-primary">
                        {report.reporter_name}
                      </div>
                    </div>
                    {report.type === 'user' && report.reported_user_name && (
                      <div>
                        <span className="text-sm text-text-secondary">Utilisateur signalé:</span>
                        <div className="mt-1 font-medium text-text-primary">
                          {report.reported_user_name}
                        </div>
                      </div>
                    )}
                    {report.type === 'provider' && report.reported_provider_name && (
                      <div>
                        <span className="text-sm text-text-secondary">Prestataire signalé:</span>
                        <div className="mt-1 font-medium text-text-primary">
                          {report.reported_provider_name}
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div className="border-t bg-gray-50 px-6 py-4">
            <div className="flex justify-end space-x-4">
              <button
                className="btn bg-gray-200 text-text-secondary hover:bg-gray-300"
                onClick={onClose}
              >
                Annuler
              </button>
              <button
                className="btn btn-primary"
                onClick={handleStatusUpdate}
                disabled={saving}
              >
                {saving ? 'Enregistrement...' : 'Mettre à jour le statut'}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

const Reports = () => {
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [selectedReport, setSelectedReport] = useState(null);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const fetchReports = async () => {
    setLoading(true);
    setError('');
    try {
      const response = await reportService.getAll(currentPage);
      setReports(response.data.results || []);
      setTotalPages(Math.ceil(response.data.count / 10));
    } catch (err) {
      console.error('Erreur lors du chargement des signalements', err);
      setError('Impossible de charger les signalements. Veuillez réessayer.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchReports();
  }, [currentPage]);

  const handleViewReport = (report) => {
    setSelectedReport(report);
  };

  const handleUpdateStatus = async (reportId, status, adminNotes) => {
    try {
      await reportService.updateStatus(reportId, status, adminNotes);
      
      // Mettre à jour l'état local
      setReports(reports.map(r => {
        if (r.id === reportId) {
          return { ...r, status, admin_notes: adminNotes };
        }
        return r;
      }));
      
      setSuccess('Statut du signalement mis à jour avec succès.');
      // Fermer automatiquement la modal
      setSelectedReport(null);
    } catch (err) {
      console.error('Erreur lors de la mise à jour du statut', err);
      setError('Impossible de mettre à jour le statut. Veuillez réessayer.');
      throw err; // Propager l'erreur pour que la modal puisse la gérer
    }
  };

  const filteredReports = reports.filter((report) => {
    const searchTerm = search.toLowerCase();
    const matchesSearch =
      report.reason.toLowerCase().includes(searchTerm) ||
      report.reporter_name.toLowerCase().includes(searchTerm) ||
      (report.reported_user_name && report.reported_user_name.toLowerCase().includes(searchTerm)) ||
      (report.reported_provider_name && report.reported_provider_name.toLowerCase().includes(searchTerm));

    const matchesStatus = statusFilter ? report.status === statusFilter : true;
    const matchesType = typeFilter ? report.type === typeFilter : true;

    return matchesSearch && matchesStatus && matchesType;
  });

  // Effacer les messages après 5 secondes
  useEffect(() => {
    if (success) {
      const timer = setTimeout(() => setSuccess(''), 5000);
      return () => clearTimeout(timer);
    }
  }, [success]);

  useEffect(() => {
    if (error) {
      const timer = setTimeout(() => setError(''), 5000);
      return () => clearTimeout(timer);
    }
  }, [error]);

  const getReportTypeName = (type) => {
    switch (type) {
      case 'provider':
        return 'Prestataire';
      case 'user':
        return 'Utilisateur';
      case 'review':
        return 'Avis';
      default:
        return type;
    }
  };

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between">
          <h1 className="text-2xl font-bold text-text-primary">
            Gestion des signalements
          </h1>
          <div className="mt-4 flex flex-col space-y-2 md:mt-0 md:flex-row md:space-y-0 md:space-x-4">
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
              <option value="pending">En attente</option>
              <option value="under_review">En cours d'examen</option>
              <option value="resolved">Résolu</option>
              <option value="dismissed">Rejeté</option>
            </select>
            <select
              className="input w-full md:w-auto"
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
            >
              <option value="">Tous les types</option>
              <option value="provider">Prestataires</option>
              <option value="user">Utilisateurs</option>
              <option value="review">Avis</option>
            </select>
          </div>
        </div>

        {/* Messages de succès et d'erreur */}
        {success && (
          <div className="rounded-md bg-success/10 p-4">
            <div className="flex">
              <div className="ml-3">
                <p className="text-sm font-medium text-success">{success}</p>
              </div>
            </div>
          </div>
        )}

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

        {loading ? (
          <div className="flex h-64 items-center justify-center">
            <div className="text-center">
              <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-primary"></div>
              <p className="mt-2 text-text-secondary">
                Chargement des signalements...
              </p>
            </div>
          </div>
        ) : (
          <div className="card overflow-hidden p-0">
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th
                      scope="col"
                      className="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-text-secondary sm:pl-6"
                    >
                      Signalement
                    </th>
                    <th
                      scope="col"
                      className="px-3 py-3.5 text-left text-sm font-semibold text-text-secondary"
                    >
                      Signalé par
                    </th>
                    <th
                      scope="col"
                      className="px-3 py-3.5 text-left text-sm font-semibold text-text-secondary"
                    >
                      Type
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
                  {filteredReports.length === 0 ? (
                    <tr>
                      <td colSpan="6" className="py-10 text-center text-text-secondary">
                        Aucun signalement trouvé
                      </td>
                    </tr>
                  ) : (
                    filteredReports.map((report) => (
                      <tr key={report.id} className="hover:bg-gray-50">
                        <td className="whitespace-nowrap py-4 pl-4 pr-3 text-sm sm:pl-6">
                          <div className="font-medium text-text-primary">
                            {report.reason.length > 50
                              ? `${report.reason.substring(0, 50)}...`
                              : report.reason}
                          </div>
                        </td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm text-text-secondary">
                          {report.reporter_name}
                        </td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm">
                          <div className="flex items-center">
                            <div className="mr-2">
                              <ReportTypeIcon type={report.type} />
                            </div>
                            <span>{getReportTypeName(report.type)}</span>
                          </div>
                        </td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm text-text-secondary">
                          {new Date(report.created_at).toLocaleDateString('fr-FR')}
                        </td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm">
                          <ReportStatusBadge status={report.status} />
                        </td>
                        <td className="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6">
                          <button
                            onClick={() => handleViewReport(report)}
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
        )}

        {/* Modale de détail du signalement */}
        {selectedReport && (
          <ReportDetailModal
            report={selectedReport}
            onClose={() => setSelectedReport(null)}
            onUpdateStatus={handleUpdateStatus}
          />
        )}
      </div>
    </DashboardLayout>
  );
};

export default withAuth(Reports);