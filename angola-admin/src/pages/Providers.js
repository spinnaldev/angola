// admin/src/pages/Providers.js
import React, { useState, useEffect } from 'react';
import DashboardLayout from '../layouts/DashboardLayout';
import { providerService } from '../services/api';
import { withAuth } from '../context/AuthContext';

// Composant Carte de Prestataire
const ProviderCard = ({ provider, onView }) => {
  return (
    <div className="bg-white rounded-lg shadow-sm hover:shadow-md transition-all duration-200 border border-gray-200 overflow-hidden">
      <div className="p-5">
        {/* En-tête avec photo et statut */}
        <div className="flex items-start justify-between mb-4">
          <div className="flex items-center">
            {/* Photo de profil */}
            <div className="h-12 w-12 flex-shrink-0">
              {provider.profile_picture ? (
                <img
                  className="h-12 w-12 rounded-full object-cover ring-2 ring-gray-100"
                  src={provider.profile_picture}
                  alt={provider.full_name || provider.company_name}
                />
              ) : (
                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-indigo-100 text-indigo-600 font-semibold text-lg ring-2 ring-indigo-200">
                  {(provider.full_name || provider.company_name || 'P').charAt(0).toUpperCase()}
                </div>
              )}
            </div>
            
            {/* Nom et entreprise */}
            <div className="ml-3">
              <div className="font-semibold text-gray-900">
                {provider.full_name || provider.username || 'Sans nom'}
              </div>
              {provider.company_name && (
                <div className="text-sm text-gray-600">
                  {provider.company_name}
                </div>
              )}
            </div>
          </div>
          
          {/* Badge de vérification */}
          <div>
            {provider.is_verified ? (
              <span className="inline-flex items-center gap-1 rounded-full bg-green-100 px-2.5 py-1 text-xs font-semibold text-green-700">
                <span>✅</span> Vérifié
              </span>
            ) : (
              <span className="inline-flex items-center gap-1 rounded-full bg-yellow-100 px-2.5 py-1 text-xs font-semibold text-yellow-700">
                <span>⏳</span> En attente
              </span>
            )}
          </div>
        </div>

        {/* Informations détaillées */}
        <div className="space-y-2 mb-4">
          {/* Note moyenne */}
          <div className="flex items-center text-sm">
            <span className="text-yellow-500 mr-1">⭐</span>
            <span className="font-medium text-gray-900">
              {provider.avg_rating ? Number(provider.avg_rating).toFixed(1) : '0.0'}
            </span>
            <span className="text-gray-500 ml-1">
              ({provider.reviews_count || 0} avis)
            </span>
          </div>

          {/* Services et localisation */}
          <div className="flex items-center text-sm text-gray-600">
            <span className="mr-1">📦</span>
            <span>{provider.services_count || 0} service{provider.services_count > 1 ? 's' : ''}</span>
          </div>
          
          {provider.city && (
            <div className="flex items-center text-sm text-gray-600">
              <span className="mr-1">📍</span>
              <span>{provider.city}</span>
            </div>
          )}
          
          {provider.trust_score > 0 && (
            <div className="flex items-center text-sm text-gray-600">
              <span className="mr-1">🛡️</span>
              <span>Score de confiance: {Number(provider.trust_score).toFixed(1)}</span>
            </div>
          )}
        </div>

        {/* Actions - Un seul bouton */}
        <div className="pt-4 border-t border-gray-100">
          <button
            onClick={() => onView(provider)}
            className="w-full inline-flex items-center justify-center px-4 py-2 border border-indigo-300 shadow-sm text-sm font-medium rounded-md text-indigo-700 bg-white hover:bg-indigo-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-colors"
          >
            <span className="mr-1">👁️</span>
            Voir détails
          </button>
        </div>
      </div>
    </div>
  );
};

// Modal détail du prestataire
const ProviderDetail = ({ provider, onClose, onVerify }) => {
  if (!provider) return null;

  const handleVerifyProvider = async (prov) => {
    await onVerify(prov);
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex min-h-screen items-center justify-center p-4">
        {/* Backdrop */}
        <div className="fixed inset-0 bg-black bg-opacity-30" onClick={onClose}></div>

        {/* Modal */}
        <div className="relative bg-white rounded-lg shadow-xl max-w-3xl w-full max-h-[90vh] overflow-y-auto">
          {/* Header */}
          <div className="border-b bg-gray-50 px-6 py-4 flex items-center justify-between">
            <h2 className="text-xl font-semibold text-gray-900">Détails du prestataire</h2>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600 text-2xl font-bold"
            >
              ×
            </button>
          </div>

          {/* Content */}
          <div className="px-6 py-6">
            {/* En-tête avec photo */}
            <div className="flex items-center mb-6">
              <div className="h-20 w-20 flex-shrink-0">
                {provider.profile_picture ? (
                  <img
                    className="h-20 w-20 rounded-full object-cover ring-4 ring-gray-100"
                    src={provider.profile_picture}
                    alt={provider.full_name}
                  />
                ) : (
                  <div className="flex h-20 w-20 items-center justify-center rounded-full bg-indigo-100 text-indigo-600 font-bold text-2xl ring-4 ring-indigo-200">
                    {(provider.full_name || provider.company_name || 'P').charAt(0).toUpperCase()}
                  </div>
                )}
              </div>
              <div className="ml-4">
                <h3 className="text-2xl font-bold text-gray-900">
                  {provider.full_name || provider.username || 'Sans nom'}
                </h3>
                {provider.company_name && (
                  <p className="text-lg text-gray-600">{provider.company_name}</p>
                )}
                {provider.is_verified && (
                  <span className="inline-flex items-center gap-1 mt-2 rounded-full bg-green-100 px-3 py-1 text-sm font-semibold text-green-700">
                    <span>✅</span> Prestataire vérifié
                  </span>
                )}
              </div>
            </div>

            {/* Grille d'informations */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Informations de base */}
              <div className="space-y-4">
                <h4 className="font-semibold text-gray-900 text-lg mb-3">Informations de base</h4>
                
                <div>
                  <label className="text-sm font-medium text-gray-500">Email</label>
                  <p className="text-gray-900">{provider.email || 'Non renseigné'}</p>
                </div>

                <div>
                  <label className="text-sm font-medium text-gray-500">Téléphone</label>
                  <p className="text-gray-900">{provider.phone_number || 'Non renseigné'}</p>
                </div>

                <div>
                  <label className="text-sm font-medium text-gray-500">Localisation</label>
                  <p className="text-gray-900">
                    {provider.city || 'Non renseignée'}
                    {provider.address && ` - ${provider.address}`}
                  </p>
                </div>

                <div>
                  <label className="text-sm font-medium text-gray-500">Membre depuis</label>
                  <p className="text-gray-900">
                    {provider.created_at
                      ? new Date(provider.created_at).toLocaleDateString('fr-FR', {
                          year: 'numeric',
                          month: 'long',
                          day: 'numeric'
                        })
                      : 'Date inconnue'}
                  </p>
                </div>

                {provider.main_category && (
                  <div>
                    <label className="text-sm font-medium text-gray-500">Catégorie principale</label>
                    <p className="text-gray-900">{provider.main_category.category_name}</p>
                  </div>
                )}
              </div>

              {/* Statistiques */}
              <div className="space-y-4">
                <h4 className="font-semibold text-gray-900 text-lg mb-3">Statistiques</h4>
                
                <div className="bg-yellow-50 rounded-lg p-4">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium text-gray-600">Note moyenne</span>
                    <div className="flex items-center">
                      <span className="text-2xl font-bold text-yellow-600">
                        {provider.avg_rating ? Number(provider.avg_rating).toFixed(1) : '0.0'}
                      </span>
                      <span className="text-yellow-500 ml-1">⭐</span>
                    </div>
                  </div>
                </div>

                <div className="bg-blue-50 rounded-lg p-4">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium text-gray-600">Nombre d'avis</span>
                    <span className="text-2xl font-bold text-blue-600">
                      {provider.reviews_count || 0}
                    </span>
                  </div>
                </div>

                <div className="bg-green-50 rounded-lg p-4">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium text-gray-600">Services proposés</span>
                    <span className="text-2xl font-bold text-green-600">
                      {provider.services_count || 0}
                    </span>
                  </div>
                </div>

                {/* <div className="bg-purple-50 rounded-lg p-4">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium text-gray-600">Mis en avant</span>
                    <span className="text-xl font-bold text-purple-600">
                      {provider.is_featured ? '⭐ Oui' : 'Non'}
                    </span>
                  </div>
                </div> */}
              </div>
            </div>

            {/* Bio / Description */}
            {provider.bio && (
              <div className="mt-6">
                <h4 className="font-semibold text-gray-900 text-lg mb-3">À propos</h4>
                <p className="text-gray-700 whitespace-pre-wrap">
                  {provider.bio}
                </p>
              </div>
            )}

            {/* Compétences */}
            {provider.skills && provider.skills.length > 0 && (
              <div className="mt-6">
                <h4 className="font-semibold text-gray-900 text-lg mb-3">Compétences</h4>
                <div className="flex flex-wrap gap-2">
                  {provider.skills.map((skill, index) => (
                    <span
                      key={index}
                      className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-indigo-100 text-indigo-700"
                    >
                      {skill}
                    </span>
                  ))}
                </div>
              </div>
            )}

            {/* Catégories d'expertise */}
            {provider.expertise_categories && provider.expertise_categories.length > 0 && (
              <div className="mt-6">
                <h4 className="font-semibold text-gray-900 text-lg mb-3">Catégories d'expertise</h4>
                <div className="flex flex-wrap gap-2">
                  {provider.expertise_categories.map((category) => (
                    <span
                      key={category.id}
                      className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-700"
                    >
                      {category.name}
                    </span>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Footer */}
          <div className="border-t bg-gray-50 px-6 py-4 flex justify-between gap-3">
            {/* <button
              onClick={() => handleVerifyProvider(provider)}
              className={`px-6 py-2 border shadow-sm text-sm font-medium rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2 transition-colors ${
                provider.is_verified
                  ? 'border-red-300 text-red-700 bg-white hover:bg-red-50 focus:ring-red-500'
                  : 'border-green-300 text-green-700 bg-white hover:bg-green-50 focus:ring-green-500'
              }`}
            >
              {provider.is_verified ? '❌ Retirer la vérification' : '✅ Vérifier le prestataire'}
            </button> */}
            
            <button
              onClick={onClose}
              className="px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Fermer
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

// Composant principal
const Providers = () => {
  const [providers, setProviders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const [search, setSearch] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');
  const [verificationFilter, setVerificationFilter] = useState('');
  const [error, setError] = useState('');
  const [selectedProvider, setSelectedProvider] = useState(null);

  const itemsPerPage = 9; // 3x3 grid

  // Debounce pour la recherche
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedSearch(search);
      setCurrentPage(1);
    }, 500);
    return () => clearTimeout(timer);
  }, [search]);

  // Réinitialiser la page lors du changement de filtre
  useEffect(() => {
    setCurrentPage(1);
  }, [verificationFilter]);

  // Charger les prestataires
  useEffect(() => {
    fetchProviders();
  }, [currentPage, debouncedSearch, verificationFilter]);

  const fetchProviders = async () => {
    setLoading(true);
    setError('');
    try {
      const params = {
        page: currentPage,
        page_size: itemsPerPage,
      };

      if (debouncedSearch) {
        params.search = debouncedSearch;
      }
      if (verificationFilter) {
        params.is_verified = verificationFilter === 'verified';
      }

      const response = await providerService.getAll(params.page, params.page_size);
      
      setProviders(response.data.results || []);
      setTotalCount(response.data.count || 0);
      setTotalPages(Math.ceil((response.data.count || 0) / itemsPerPage));
    } catch (err) {
      console.error('Erreur lors du chargement des prestataires', err);
      setError('Impossible de charger les prestataires. Veuillez réessayer.');
      setProviders([]);
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyProvider = async (provider) => {
    try {
      if (provider.is_verified) {
        await providerService.unverify(provider.id);
      } else {
        await providerService.verify(provider.id);
      }
      
      // Mettre à jour localement
      setProviders(providers.map(p => 
        p.id === provider.id ? { ...p, is_verified: !p.is_verified } : p
      ));
      
      // Mettre à jour le provider sélectionné si c'est le même
      if (selectedProvider && selectedProvider.id === provider.id) {
        setSelectedProvider({ ...selectedProvider, is_verified: !selectedProvider.is_verified });
      }
    } catch (err) {
      console.error('Erreur lors de la vérification', err);
      alert('Une erreur est survenue lors de la mise à jour du statut de vérification.');
    }
  };

  const handleViewProvider = (provider) => {
    setSelectedProvider(provider);
  };

  const resetFilters = () => {
    setSearch('');
    setDebouncedSearch('');
    setVerificationFilter('');
    setCurrentPage(1);
  };

  // Calcul des stats
  const stats = {
    total: totalCount,
    verified: providers.filter(p => p.is_verified).length,
    pending: providers.filter(p => !p.is_verified).length,
  };

  return (
    <DashboardLayout>
      <div className="px-4 sm:px-6 lg:px-8 py-6">
        {/* En-tête */}
        <div className="mb-8">
          <h1 className="text-2xl font-bold text-gray-900">Gestion des prestataires</h1>
          <p className="mt-1 text-sm text-gray-600">
            Un total de {totalCount} prestataire{totalCount > 1 ? 's' : ''} trouvé{totalCount > 1 ? 's' : ''}
          </p>
        </div>

        {/* Statistiques */}
        <div className="grid grid-cols-1 gap-5 sm:grid-cols-3 mb-8">
          <div className="bg-white overflow-hidden shadow-sm rounded-lg border border-gray-200">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <div className="flex h-12 w-12 items-center justify-center rounded-md bg-indigo-100 text-indigo-600 text-2xl">
                    📋
                  </div>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">Total</dt>
                    <dd className="text-2xl font-semibold text-gray-900">{stats.total}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white overflow-hidden shadow-sm rounded-lg border border-gray-200">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <div className="flex h-12 w-12 items-center justify-center rounded-md bg-green-100 text-green-600 text-2xl">
                    ✅
                  </div>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">Vérifiés</dt>
                    <dd className="text-2xl font-semibold text-gray-900">{stats.verified}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white overflow-hidden shadow-sm rounded-lg border border-gray-200">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <div className="flex h-12 w-12 items-center justify-center rounded-md bg-yellow-100 text-yellow-600 text-2xl">
                    ⏳
                  </div>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">En attente</dt>
                    <dd className="text-2xl font-semibold text-gray-900">{stats.pending}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Filtres */}
        <div className="bg-white shadow-sm rounded-lg border border-gray-200 mb-6">
          <div className="px-6 py-4">
            <div className="flex flex-col sm:flex-row gap-4">
              {/* Recherche */}
              <div className="flex-1">
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <span className="text-gray-400">🔍</span>
                  </div>
                  <input
                    type="text"
                    placeholder="Rechercher un prestataire..."
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    className="focus:ring-indigo-500 focus:border-indigo-500 block w-full pl-10 pr-3 py-2 border-gray-300 rounded-md text-sm"
                  />
                </div>
              </div>

              {/* Filtre vérification */}
              <div className="sm:w-48">
                <select
                  value={verificationFilter}
                  onChange={(e) => setVerificationFilter(e.target.value)}
                  className="focus:ring-indigo-500 focus:border-indigo-500 block w-full px-3 py-2 border-gray-300 rounded-md text-sm"
                >
                  <option value="">Tous les statuts</option>
                  <option value="verified">Vérifiés</option>
                  <option value="pending">En attente</option>
                </select>
              </div>

              {/* Bouton réinitialiser */}
              {(search || verificationFilter) && (
                <button
                  onClick={resetFilters}
                  className="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  Réinitialiser
                </button>
              )}
            </div>
          </div>
        </div>

        {/* Message d'erreur */}
        {error && (
          <div className="mb-6 bg-red-50 border border-red-200 rounded-md p-4">
            <p className="text-sm text-red-700">{error}</p>
          </div>
        )}

        {/* Liste des prestataires */}
        {loading ? (
          <div className="flex h-64 items-center justify-center">
            <div className="text-center">
              <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-indigo-600 border-r-transparent"></div>
              <p className="mt-2 text-gray-500">Chargement des prestataires...</p>
            </div>
          </div>
        ) : providers.length === 0 ? (
          <div className="flex h-64 items-center justify-center rounded-lg border-2 border-dashed border-gray-300 bg-gray-50">
            <div className="text-center">
              <span className="text-6xl mb-4 block">🔍</span>
              <p className="text-lg font-medium text-gray-900">Aucun prestataire trouvé</p>
              <p className="text-sm text-gray-500 mt-1">
                {search || verificationFilter
                  ? 'Essayez de modifier vos critères de recherche'
                  : 'Aucun prestataire n\'est encore inscrit'}
              </p>
            </div>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {providers.map((provider) => (
              <ProviderCard
                key={provider.id}
                provider={provider}
                onView={handleViewProvider}
              />
            ))}
          </div>
        )}

        {/* Pagination */}
        {!loading && totalPages > 1 && (
          <div className="flex items-center justify-between border-t border-gray-200 bg-white px-4 py-3 sm:px-6 mt-8 rounded-lg shadow-sm">
            <div className="flex flex-1 justify-between sm:hidden">
              <button
                disabled={currentPage === 1}
                onClick={() => setCurrentPage((old) => Math.max(old - 1, 1))}
                className={`relative inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium ${
                  currentPage === 1
                    ? 'cursor-not-allowed text-gray-400'
                    : 'text-gray-700 hover:bg-gray-50'
                }`}
              >
                Précédent
              </button>
              <button
                disabled={currentPage === totalPages}
                onClick={() => setCurrentPage((old) => Math.min(old + 1, totalPages))}
                className={`relative ml-3 inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium ${
                  currentPage === totalPages
                    ? 'cursor-not-allowed text-gray-400'
                    : 'text-gray-700 hover:bg-gray-50'
                }`}
              >
                Suivant
              </button>
            </div>
            <div className="hidden sm:flex sm:flex-1 sm:items-center sm:justify-between">
              <div>
                <p className="text-sm text-gray-700">
                  Affichage de{' '}
                  <span className="font-medium">{(currentPage - 1) * itemsPerPage + 1}</span> à{' '}
                  <span className="font-medium">
                    {Math.min(currentPage * itemsPerPage, totalCount)}
                  </span>{' '}
                  sur <span className="font-medium">{totalCount}</span> résultats
                </p>
              </div>
              <div>
                <nav className="isolate inline-flex -space-x-px rounded-md shadow-sm">
                  <button
                    disabled={currentPage === 1}
                    onClick={() => setCurrentPage((old) => Math.max(old - 1, 1))}
                    className={`relative inline-flex items-center rounded-l-md px-2 py-2 ${
                      currentPage === 1
                        ? 'cursor-not-allowed bg-gray-100 text-gray-400'
                        : 'text-gray-500 hover:bg-gray-50'
                    } ring-1 ring-inset ring-gray-300 focus:z-20`}
                  >
                    <span>⬅️</span>
                  </button>
                  
                  {Array.from({ length: totalPages }, (_, i) => i + 1)
                    .filter(page => {
                      // Afficher les 5 premières pages, la page actuelle ±2, et les 2 dernières
                      return (
                        page <= 3 ||
                        page >= totalPages - 1 ||
                        Math.abs(page - currentPage) <= 2
                      );
                    })
                    .map((page, index, array) => {
                      // Ajouter "..." si nécessaire
                      const showEllipsis = index > 0 && page - array[index - 1] > 1;
                      
                      return (
                        <React.Fragment key={page}>
                          {showEllipsis && (
                            <span className="relative inline-flex items-center px-4 py-2 text-sm font-semibold text-gray-700 ring-1 ring-inset ring-gray-300">
                              ...
                            </span>
                          )}
                          <button
                            onClick={() => setCurrentPage(page)}
                            className={`relative inline-flex items-center px-4 py-2 text-sm font-semibold ${
                              page === currentPage
                                ? 'z-10 bg-indigo-600 text-white focus:z-20'
                                : 'text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50'
                            }`}
                          >
                            {page}
                          </button>
                        </React.Fragment>
                      );
                    })}
                  
                  <button
                    disabled={currentPage === totalPages}
                    onClick={() => setCurrentPage((old) => Math.min(old + 1, totalPages))}
                    className={`relative inline-flex items-center rounded-r-md px-2 py-2 ${
                      currentPage === totalPages
                        ? 'cursor-not-allowed bg-gray-100 text-gray-400'
                        : 'text-gray-500 hover:bg-gray-50'
                    } ring-1 ring-inset ring-gray-300 focus:z-20`}
                  >
                    <span>➡️</span>
                  </button>
                </nav>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Modal détail prestataire */}
      {selectedProvider && (
        <ProviderDetail
          provider={selectedProvider}
          onClose={() => setSelectedProvider(null)}
          onVerify={handleVerifyProvider}
        />
      )}
    </DashboardLayout>
  );
};

export default withAuth(Providers);