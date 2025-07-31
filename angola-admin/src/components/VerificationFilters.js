// src/components/VerificationFilters.js
import React from 'react';

const VerificationFilters = ({ 
  filters, 
  onFiltersChange, 
  selectedCount = 0, 
  onBulkApprove, 
  onBulkReject,
  showBulkActions = true,
  showAdvancedFilters = true 
}) => {
  
  const handleFilterChange = (key, value) => {
    onFiltersChange({
      ...filters,
      [key]: value
    });
  };

  const resetFilters = () => {
    onFiltersChange({
      status: '',
      search: '',
      is_business: undefined,
      days: ''
    });
  };

  const hasActiveFilters = () => {
    return filters.status || filters.search || filters.is_business !== undefined || filters.days;
  };

  return (
    <div className="bg-white shadow rounded-lg mb-6">
      <div className="px-4 py-3 border-b border-gray-200">
        <div className="flex flex-col space-y-4 lg:space-y-0 lg:flex-row lg:items-center lg:justify-between">
          
          {/* Filtres principaux */}
          <div className="flex flex-col space-y-3 lg:space-y-0 lg:flex-row lg:space-x-3">
            
            {/* Recherche */}
            <div className="relative min-w-0 flex-1 lg:max-w-xs">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <svg className="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
              </div>
              <input
                type="text"
                placeholder="Rechercher un utilisateur..."
                value={filters.search || ''}
                onChange={(e) => handleFilterChange('search', e.target.value)}
                className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md leading-5 bg-white placeholder-gray-500 focus:outline-none focus:placeholder-gray-400 focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 text-sm"
              />
            </div>

            {/* Filtre par statut */}
            <select
              value={filters.status || ''}
              onChange={(e) => handleFilterChange('status', e.target.value)}
              className="block w-full lg:w-auto pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 text-sm rounded-md"
            >
              <option value="">Tous les statuts</option>
              <option value="pending">⏳ En attente</option>
              <option value="verified">✅ Vérifiés</option>
              <option value="rejected">❌ Rejetés</option>
            </select>

            {showAdvancedFilters && (
              <>
                {/* Filtre par type */}
                <select
                  value={filters.is_business === undefined ? '' : filters.is_business.toString()}
                  onChange={(e) => handleFilterChange('is_business', 
                    e.target.value === '' ? undefined : e.target.value === 'true'
                  )}
                  className="block w-full lg:w-auto pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 text-sm rounded-md"
                >
                  <option value="">Tous les types</option>
                  <option value="false">👤 Particulier</option>
                  <option value="true">🏢 Entreprise</option>
                </select>

                {/* Filtre par période */}
                <select
                  value={filters.days || ''}
                  onChange={(e) => handleFilterChange('days', e.target.value)}
                  className="block w-full lg:w-auto pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 text-sm rounded-md"
                >
                  <option value="">Toute période</option>
                  <option value="1">Aujourd'hui</option>
                  <option value="7">7 derniers jours</option>
                  <option value="30">30 derniers jours</option>
                  <option value="90">90 derniers jours</option>
                </select>
              </>
            )}

            {/* Bouton de réinitialisation */}
            {hasActiveFilters() && (
              <button
                onClick={resetFilters}
                className="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-colors"
              >
                <svg className="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
                Réinitialiser
              </button>
            )}
          </div>

          {/* Actions en lot */}
          {showBulkActions && selectedCount > 0 && (
            <div className="flex space-x-2">
              <button
                onClick={onBulkApprove}
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 transition-colors"
              >
                <svg className="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
                Approuver ({selectedCount})
              </button>
              
              <button
                onClick={onBulkReject}
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 transition-colors"
              >
                <svg className="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
                Rejeter ({selectedCount})
              </button>
            </div>
          )}
        </div>

        {/* Indicateur de filtres actifs */}
        {hasActiveFilters() && (
          <div className="mt-3 flex flex-wrap gap-2">
            {filters.status && (
              <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                Statut: {filters.status === 'pending' ? 'En attente' : 
                         filters.status === 'verified' ? 'Vérifiés' : 'Rejetés'}
                <button
                  onClick={() => handleFilterChange('status', '')}
                  className="ml-1 h-4 w-4 text-blue-400 hover:text-blue-600"
                >
                  <svg fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
                  </svg>
                </button>
              </span>
            )}
            
            {filters.search && (
              <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                Recherche: "{filters.search}"
                <button
                  onClick={() => handleFilterChange('search', '')}
                  className="ml-1 h-4 w-4 text-green-400 hover:text-green-600"
                >
                  <svg fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
                  </svg>
                </button>
              </span>
            )}
            
            {filters.is_business !== undefined && (
              <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800">
                Type: {filters.is_business ? 'Entreprise' : 'Particulier'}
                <button
                  onClick={() => handleFilterChange('is_business', undefined)}
                  className="ml-1 h-4 w-4 text-purple-400 hover:text-purple-600"
                >
                  <svg fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
                  </svg>
                </button>
              </span>
            )}
            
            {filters.days && (
              <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                Période: {filters.days === '1' ? 'Aujourd\'hui' : 
                          filters.days === '7' ? '7 jours' : 
                          filters.days === '30' ? '30 jours' : '90 jours'}
                <button
                  onClick={() => handleFilterChange('days', '')}
                  className="ml-1 h-4 w-4 text-yellow-400 hover:text-yellow-600"
                >
                  <svg fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
                  </svg>
                </button>
              </span>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default VerificationFilters;