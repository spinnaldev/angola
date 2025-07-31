import React, { useState, useEffect } from 'react';
import DashboardLayout from '../layouts/DashboardLayout';
import { providerService } from '../services/api';
import { withAuth } from '../context/AuthContext';

// Icônes
import SearchIcon from '@mui/icons-material/Search';
import StarIcon from '@mui/icons-material/Star';
import VerifiedIcon from '@mui/icons-material/Verified';
import LocationOnIcon from '@mui/icons-material/LocationOn';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import CancelIcon from '@mui/icons-material/Cancel';
import VisibilityIcon from '@mui/icons-material/Visibility';
import ChevronLeftIcon from '@mui/icons-material/ChevronLeft';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';

const ProviderCard = ({ provider, onVerify, onView }) => {
  return (
    <div className="bg-white rounded-lg shadow-md hover:shadow-lg transition-all duration-200 border border-gray-100 overflow-hidden">
      <div className="p-4">
        <div className="flex items-start justify-between">
          <div className="flex items-center">
            <div className="h-10 w-10 flex-shrink-0">
              {provider.user?.profile_picture ? (
                <img
                  className="h-10 w-10 rounded-full object-cover"
                  src={provider.profile_picture}
                  alt={provider.full_name}
                />
              ) : (
                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-blue-100 text-blue-600 font-medium">
                  {provider.full_name?.charAt(0) || 'P'}
                </div>
              )}
            </div>
            <div className="ml-3">
              <div className="font-medium text-gray-800">
                {provider.full_name}
              </div>
              {provider.company_name && (
                <div className="text-sm text-gray-500">
                  {provider.company_name}
                </div>
              )}
            </div>
          </div>
          <div>
            {provider.is_verified ? (
              <span className="inline-flex items-center rounded-full bg-green-100 px-2.5 py-1 text-xs font-medium text-green-800">
                <VerifiedIcon className="mr-1 h-3 w-3" /> Vérifié
              </span>
            ) : (
              <span className="inline-flex items-center rounded-full bg-amber-100 px-2.5 py-1 text-xs font-medium text-amber-800">
                En attente
              </span>
            )}
          </div>
        </div>

        <div className="mt-3 flex flex-wrap items-center gap-3 text-sm text-gray-500">
          <div className="flex items-center">
            <StarIcon className="h-4 w-4 text-yellow-500" />
            <span className="ml-1">
              {provider.avg_rating ? Number(provider.avg_rating).toFixed(1) : 'N/A'}
            </span>
          </div>
          <div className="flex items-center">
            <span className="font-medium">{provider.services_count || 0}</span>
            <span className="ml-1">services</span>
          </div>
          <div className="flex items-center">
            <span className="font-medium">{provider.reviews_count || 0}</span>
            <span className="ml-1">avis</span>
          </div>
        </div>

        {provider.address && (
          <div className="mt-2 flex items-center text-sm text-gray-500">
            <LocationOnIcon className="mr-1 h-4 w-4" />
            <span className="truncate">{provider.address}</span>
          </div>
        )}
      </div>

      <div className="flex items-center justify-between border-t bg-gray-50 px-4 py-3">
        <button
          onClick={() => onVerify(provider)}
          className={`inline-flex items-center rounded-md px-3 py-1.5 text-sm font-medium ${
            provider.is_verified
              ? 'bg-gray-200 text-gray-700 hover:bg-gray-300'
              : 'bg-emerald-100 text-emerald-700 hover:bg-emerald-200'
          }`}
        >
          {provider.is_verified ? (
            <>
              <CancelIcon className="mr-1.5 h-4 w-4" /> Retirer vérification
            </>
          ) : (
            <>
              <CheckCircleIcon className="mr-1.5 h-4 w-4" /> Vérifier
            </>
          )}
        </button>
        <button
          onClick={() => onView(provider)}
          className="inline-flex items-center rounded-md bg-blue-100 px-3 py-1.5 text-sm font-medium text-blue-700 hover:bg-blue-200"
        >
          <VisibilityIcon className="mr-1.5 h-4 w-4" /> Voir détails
        </button>
      </div>
    </div>
  );
};

const ProviderDetail = ({ provider, onClose }) => {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center overflow-y-auto overflow-x-hidden bg-black bg-opacity-50">
      <div className="relative mx-auto my-6 w-full max-w-4xl p-4">
        <div className="relative rounded-lg bg-white shadow-xl">
          <div className="flex items-center justify-between border-b px-6 py-4">
            <h3 className="text-xl font-semibold text-gray-800">
              Détails du prestataire
            </h3>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600"
            >
              &times;
            </button>
          </div>

          <div className="p-6">
            <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
              <div className="md:col-span-1">
                <div className="flex flex-col items-center rounded-lg border p-4 text-center">
                  <div className="h-24 w-24">
                    {provider.user?.profile_picture ? (
                      <img
                        className="h-24 w-24 rounded-full object-cover"
                        src={provider.profile_picture}
                        alt={provider.full_name}
                      />
                    ) : (
                      <div className="flex h-24 w-24 items-center justify-center rounded-full bg-blue-100 text-gray-600 text-2xl">
                        {provider.full_name?.charAt(0) || 'P'}
                      </div>
                    )}
                  </div>
                  <h3 className="mt-4 text-lg font-semibold text-gray-800">
                    {provider.full_name}
                  </h3>
                  {provider.company_name && (
                    <p className="text-gray-500">{provider.company_name}</p>
                  )}
                  <div className="mt-2 flex items-center">
                    <StarIcon className="h-5 w-5 text-yellow-500" />
                    <span className="ml-1 font-medium">
                      {provider.avg_rating ? Number(provider.avg_rating).toFixed(1) : 'N/A'}
                    </span>
                  </div>
                  <div className="mt-4">
                    {provider.is_verified ? (
                      <span className="inline-flex items-center rounded-full bg-green-100 px-3 py-1 text-sm font-medium text-green-800">
                        <VerifiedIcon className="mr-1 h-4 w-4" /> Vérifié
                      </span>
                    ) : (
                      <span className="inline-flex items-center rounded-full bg-amber-100 px-3 py-1 text-sm font-medium text-amber-800">
                        En attente de vérification
                      </span>
                    )}
                  </div>
                </div>

                <div className="mt-4 rounded-lg border p-4">
                  <h4 className="mb-2 font-medium text-gray-800">
                    Informations de contact
                  </h4>
                  <div className="space-y-2 text-gray-500">
                    <p>
                      <span className="font-medium">Email:</span>{' '}
                      {provider.user?.email || 'Non spécifié'}
                    </p>
                    <p>
                      <span className="font-medium">Téléphone:</span>{' '}
                      {provider.user?.phone_number || 'Non spécifié'}
                    </p>
                    <p>
                      <span className="font-medium">Adresse:</span>{' '}
                      {provider.address || 'Non spécifiée'}
                    </p>
                  </div>
                </div>
              </div>

              <div className="md:col-span-2">
                <div className="rounded-lg border p-4">
                  <h4 className="mb-4 font-medium text-gray-800">Services</h4>
                  {provider.services && provider.services.length > 0 ? (
                    <div className="space-y-4">
                      {provider.services.map((service) => (
                        <div
                          key={service.id}
                          className="rounded-lg border p-3 transition-colors hover:bg-gray-50"
                        >
                          <div className="flex items-start justify-between">
                            <div>
                              <h5 className="font-medium text-gray-800">
                                {service.title}
                              </h5>
                              <p className="mt-1 text-sm text-gray-500">
                                {service.description &&
                                  service.description.substring(0, 100)}
                                {service.description &&
                                  service.description.length > 100 &&
                                  '...'}
                              </p>
                              <div className="mt-2 text-sm">
                                <span className="font-medium">Catégorie:</span>{' '}
                                {service.category_name}
                              </div>
                              <div className="mt-1 text-sm">
                                <span className="font-medium">Sous-catégorie:</span>{' '}
                                {service.subcategory_name}
                              </div>
                            </div>
                            <div className="text-right">
                              <div className="rounded-md bg-blue-50 px-2 py-1 text-sm font-medium text-blue-700">
                                {service.price
                                  ? `${service.price} AOA`
                                  : service.price_type === 'quote'
                                  ? 'Sur devis'
                                  : 'Prix non spécifié'}
                              </div>
                              <div className="mt-2 text-xs text-gray-500">
                                {service.price_type === 'fixed'
                                  ? 'Prix fixe'
                                  : service.price_type === 'hourly'
                                  ? 'Prix horaire'
                                  : service.price_type === 'daily'
                                  ? 'Prix journalier'
                                  : service.price_type === 'negotiable'
                                  ? 'Prix négociable'
                                  : 'Sur devis'}
                              </div>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-gray-500">
                      Ce prestataire n'a pas encore ajouté de services.
                    </p>
                  )}
                </div>

                <div className="mt-4 rounded-lg border p-4">
                  <h4 className="mb-4 font-medium text-gray-800">
                    Certificats et qualifications
                  </h4>
                  {provider.certificates && provider.certificates.length > 0 ? (
                    <div className="space-y-3">
                      {provider.certificates.map((cert) => (
                        <div
                          key={cert.id}
                          className="flex items-center justify-between rounded-lg border p-3"
                        >
                          <div>
                            <div className="font-medium text-gray-800">
                              {cert.title}
                            </div>
                            <div className="text-sm text-gray-500">
                              {cert.issuing_organization}
                            </div>
                            <div className="mt-1 text-xs text-gray-500">
                              Délivré le:{' '}
                              {new Date(cert.issue_date).toLocaleDateString('fr-FR')}
                            </div>
                          </div>
                          <div>
                            {cert.is_verified ? (
                              <span className="rounded-full bg-green-100 px-2 py-1 text-xs font-medium text-green-800">
                                Vérifié
                              </span>
                            ) : (
                              <span className="rounded-full bg-amber-100 px-2 py-1 text-xs font-medium text-amber-800">
                                Non vérifié
                              </span>
                            )}
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-gray-500">
                      Ce prestataire n'a pas encore ajouté de certificats.
                    </p>
                  )}
                </div>
              </div>
            </div>
          </div>

          <div className="border-t bg-gray-50 px-6 py-4">
            <div className="flex justify-end">
              <button
                onClick={onClose}
                className="rounded-md bg-blue-600 px-4 py-2 font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
              >
                Fermer
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

const Providers = () => {
  const [providers, setProviders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const [verificationFilter, setVerificationFilter] = useState('');
  const [error, setError] = useState('');
  const [selectedProvider, setSelectedProvider] = useState(null);

  const fetchProviders = async () => {
    setLoading(true);
    setError('');
    try {
      const response = await providerService.getAll(currentPage);
      setProviders(response.data.results || []);
      setTotalPages(Math.ceil(response.data.count / 10));
    } catch (err) {
      console.error('Erreur lors du chargement des prestataires', err);
      setError('Impossible de charger les prestataires. Veuillez réessayer.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProviders();
  }, [currentPage]);

  const handleVerifyProvider = async (provider) => {
    try {
      if (provider.is_verified) {
        await providerService.unverify(provider.id);
      } else {
        await providerService.verify(provider.id);
      }
      
      // Mettre à jour l'état local
      setProviders(providers.map(p => {
        if (p.id === provider.id) {
          return { ...p, is_verified: !p.is_verified };
        }
        return p;
      }));
    } catch (err) {
      console.error('Erreur lors de la vérification du prestataire', err);
      setError('Une erreur est survenue lors de la mise à jour du statut de vérification.');
    }
  };

  const handleViewProvider = (provider) => {
    setSelectedProvider(provider);
  };

  const filteredProviders = providers.filter((provider) => {
    const searchTerm = search.toLowerCase();
    const matchesSearch =
      (provider.full_name && provider.full_name.toLowerCase().includes(searchTerm)) ||
      (provider.company_name && provider.company_name.toLowerCase().includes(searchTerm)) ||
      (provider.username && provider.username.toLowerCase().includes(searchTerm));

    const matchesVerification =
      verificationFilter === ''
        ? true
        : verificationFilter === 'verified'
        ? provider.is_verified
        : !provider.is_verified;

    const matchesCategory =
      categoryFilter === ''
        ? true
        : provider.main_category && provider.main_category.category_id.toString() === categoryFilter;

    return matchesSearch && matchesVerification && matchesCategory;
  });

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {error && (
          <div className="rounded-md bg-red-50 p-4">
            <div className="flex">
              <div className="ml-3">
                <h3 className="text-sm font-medium text-red-800">Erreur</h3>
                <div className="mt-2 text-sm text-red-700">{error}</div>
              </div>
            </div>
          </div>
        )}

        <div className="flex flex-col md:flex-row md:items-center md:justify-between">
          <h1 className="text-2xl font-bold text-gray-800">
            Gestion des prestataires
          </h1>
          <div className="mt-4 flex flex-col space-y-2 md:mt-0 md:flex-row md:space-y-0 md:space-x-4">
            <div className="relative">
              <SearchIcon className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="Rechercher..."
                className="w-full rounded-md border border-gray-300 pl-10 py-2 pr-3 shadow-sm focus:border-blue-500 focus:ring-1 focus:ring-blue-500 md:w-64"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
            <select
              className="rounded-md border border-gray-300 py-2 pl-3 pr-8 shadow-sm focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
              value={verificationFilter}
              onChange={(e) => setVerificationFilter(e.target.value)}
            >
              <option value="">Tous les statuts</option>
              <option value="verified">Vérifiés</option>
              <option value="unverified">Non vérifiés</option>
            </select>
          </div>
        </div>

        {loading ? (
          <div className="flex h-64 items-center justify-center">
            <div className="text-center">
              <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-blue-600"></div>
              <p className="mt-2 text-gray-500">
                Chargement des prestataires...
              </p>
            </div>
          </div>
        ) : filteredProviders.length === 0 ? (
          <div className="flex h-64 items-center justify-center rounded-lg border border-gray-200 bg-white">
            <p className="text-gray-500">Aucun prestataire trouvé</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {filteredProviders.map((provider) => (
              <ProviderCard
                key={provider.id}
                provider={provider}
                onVerify={handleVerifyProvider}
                onView={handleViewProvider}
              />
            ))}
          </div>
        )}

        {/* Pagination */}
        {!loading && totalPages > 1 && (
          <div className="flex items-center justify-center space-x-2 pt-6">
            <button
              disabled={currentPage === 1}
              onClick={() => setCurrentPage((old) => Math.max(old - 1, 1))}
              className={`flex items-center justify-center rounded-md border px-3 py-2 ${
                currentPage === 1
                  ? 'cursor-not-allowed border-gray-200 bg-gray-100 text-gray-400'
                  : 'border-gray-300 bg-white text-gray-700 hover:bg-gray-50'
              }`}
            >
              <ChevronLeftIcon className="h-5 w-5" />
            </button>
            <span className="text-sm text-gray-700">
              Page {currentPage} sur {totalPages}
            </span>
            <button
              disabled={currentPage === totalPages}
              onClick={() =>
                setCurrentPage((old) => Math.min(old + 1, totalPages))
              }
              className={`flex items-center justify-center rounded-md border px-3 py-2 ${
                currentPage === totalPages
                  ? 'cursor-not-allowed border-gray-200 bg-gray-100 text-gray-400'
                  : 'border-gray-300 bg-white text-gray-700 hover:bg-gray-50'
              }`}
            >
              <ChevronRightIcon className="h-5 w-5" />
            </button>
          </div>
        )}
      </div>

      {/* Provider Detail Modal */}
      {selectedProvider && (
        <ProviderDetail
          provider={selectedProvider}
          onClose={() => setSelectedProvider(null)}
        />
      )}
    </DashboardLayout>
  );
};

export default withAuth(Providers);