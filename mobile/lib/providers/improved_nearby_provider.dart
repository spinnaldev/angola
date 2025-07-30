// lib/providers/improved_nearby_provider.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/models/provider_model.dart';
import '../core/services/improved_location_service.dart';
import '../core/services/api_service.dart';
import 'dart:async';

enum NearbySearchStatus {
  initial,
  loading,
  success,
  error,
  noResults,
  locationError
}

class ImprovedNearbyProvider with ChangeNotifier {
  final ImprovedLocationService _locationService;
  final ApiService _apiService;

  // État de la recherche
  List<ProviderModel> _nearbyProviders = [];
  List<ProviderModel> _allProviders = [];
  NearbySearchStatus _status = NearbySearchStatus.initial;
  String _errorMessage = '';

  // Paramètres de recherche
  double _searchRadius = 10.0; // km
  String _selectedCategory = '';
  int? _selectedCategoryId;
  double _minRating = 0.0;
  String _businessType = '';
  
  // Cache et optimisation
  DateTime? _lastSearchTime;
  Position? _lastSearchPosition;
  static const Duration _cacheValidityDuration = Duration(minutes: 3);
  static const double _minimumMovementThreshold = 500; // mètres

  ImprovedNearbyProvider(this._locationService, this._apiService);

  // Getters
  List<ProviderModel> get nearbyProviders => _nearbyProviders;
  List<ProviderModel> get allProviders => _allProviders;
  NearbySearchStatus get status => _status;
  String get errorMessage => _errorMessage;
  double get searchRadius => _searchRadius;
  String get selectedCategory => _selectedCategory;
  double get minRating => _minRating;
  String get businessType => _businessType;
  bool get isLoading => _status == NearbySearchStatus.loading;
  bool get hasResults => _nearbyProviders.isNotEmpty;
  int get resultsCount => _nearbyProviders.length;

  // Méthode principale pour rechercher les prestataires à proximité
  Future<void> searchNearbyProviders({
    double? radius,
    int? categoryId,
    double? minRating,
    String? businessType,
    bool forceRefresh = false,
  }) async {
    print('🔍 Recherche de prestataires à proximité...');
    
    // Mettre à jour les paramètres de recherche
    _updateSearchParameters(radius, categoryId, minRating, businessType);

    // Vérifier si on peut utiliser le cache
    if (!forceRefresh && _canUseCachedResults()) {
      print('📦 Utilisation des résultats en cache');
      return;
    }

    _updateStatus(NearbySearchStatus.loading);

    try {
      // 1. S'assurer d'avoir une position valide
      bool hasLocation = await _ensureLocationAvailable();
      if (!hasLocation) {
        _setError('Impossible de récupérer votre position', NearbySearchStatus.locationError);
        return;
      }

      Position currentPosition = _locationService.currentPosition!;
      
      // 2. Rechercher les prestataires via l'API
      List<ProviderModel> providers = await _fetchProvidersFromAPI(currentPosition);
      
      // 3. Filtrer et trier les résultats
      List<ProviderModel> filteredProviders = _filterAndSortProviders(providers, currentPosition);
      
      // 4. Mettre à jour les résultats
      _updateResults(filteredProviders, providers, currentPosition);
      
      print('✅ Recherche terminée: ${filteredProviders.length} prestataires trouvés');

    } catch (e) {
      _setError('Erreur lors de la recherche: $e', NearbySearchStatus.error);
    }
  }

  // S'assurer qu'on a une position disponible
  Future<bool> _ensureLocationAvailable() async {
    if (_locationService.hasValidPosition && _locationService.isPositionCacheValid) {
      return true;
    }

    bool locationSuccess = await _locationService.getCurrentLocation();
    if (!locationSuccess) {
      // Essayer avec la dernière position connue
      Position? lastKnown = _locationService.getLastKnownPosition();
      if (lastKnown != null) {
        print('⚠️ Utilisation de la dernière position connue');
        return true;
      }
      return false;
    }
    
    return true;
  }

  // Récupérer les prestataires depuis l'API
  Future<List<ProviderModel>> _fetchProvidersFromAPI(Position position) async {
    try {
      // Recherche par proximité si l'API le supporte
      if (_selectedCategoryId != null) {
        List<ProviderModel> categoryProviders = await _apiService.getProvidersByCategory(_selectedCategoryId!);
        return categoryProviders;
      } else {
        // Essayer d'abord la recherche par proximité
        try {
          List<ProviderModel> nearbyProviders = await _apiService.getNearbyProviders(
            position.latitude,
            position.longitude,
            radius: _searchRadius
          );
          
          if (nearbyProviders.isNotEmpty) {
            return nearbyProviders;
          }
        } catch (e) {
          print('⚠️ API de proximité non disponible, fallback vers tous les prestataires');
        }
        
        // Fallback: récupérer tous les prestataires
        return await _apiService.getProviders();
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération des prestataires: $e');
      throw Exception('Impossible de récupérer les prestataires: $e');
    }
  }

  // Filtrer et trier les prestataires
  List<ProviderModel> _filterAndSortProviders(List<ProviderModel> providers, Position userPosition) {
    List<ProviderModel> filtered = providers.where((provider) {
      // Filtrer par coordonnées valides
      if (provider.latitude == null || provider.longitude == null) {
        return false;
      }

      // Calculer la distance
      double distance = _locationService.calculateDistance(
        userPosition.latitude,
        userPosition.longitude,
        provider.latitude!,
        provider.longitude!,
      );

      // Filtrer par rayon
      if (distance > _searchRadius) {
        return false;
      }

      // Filtrer par note minimum
      if (_minRating > 0 && provider.rating < _minRating) {
        return false;
      }

      // Filtrer par type d'entreprise
      if (_businessType.isNotEmpty && provider.businessType != _businessType) {
        return false;
      }

      return true;
    }).toList();

    // Calculer et assigner les distances
    for (var provider in filtered) {
      provider.distance = _locationService.calculateDistance(
        userPosition.latitude,
        userPosition.longitude,
        provider.latitude!,
        provider.longitude!,
      );
    }

    // Trier par distance puis par note
    filtered.sort((a, b) {
      // D'abord par distance
      int distanceComparison = (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity);
      if (distanceComparison != 0) return distanceComparison;
      
      // Puis par note (descendant)
      return b.rating.compareTo(a.rating);
    });

    return filtered;
  }

  // Mettre à jour les paramètres de recherche
  void _updateSearchParameters(double? radius, int? categoryId, double? minRating, String? businessType) {
    if (radius != null) _searchRadius = radius;
    if (categoryId != null) _selectedCategoryId = categoryId;
    if (minRating != null) _minRating = minRating;
    if (businessType != null) _businessType = businessType;
  }

  // Vérifier si on peut utiliser les résultats en cache
  bool _canUseCachedResults() {
    if (_lastSearchTime == null || _lastSearchPosition == null) {
      return false;
    }

    // Vérifier la validité temporelle du cache
    bool cacheStillValid = DateTime.now().difference(_lastSearchTime!) < _cacheValidityDuration;
    if (!cacheStillValid) {
      return false;
    }

    // Vérifier si l'utilisateur a beaucoup bougé
    Position? currentPos = _locationService.currentPosition;
    if (currentPos != null) {
      double movementDistance = Geolocator.distanceBetween(
        _lastSearchPosition!.latitude,
        _lastSearchPosition!.longitude,
        currentPos.latitude,
        currentPos.longitude,
      );

      if (movementDistance > _minimumMovementThreshold) {
        return false;
      }
    }

    return _nearbyProviders.isNotEmpty;
  }

  // Mettre à jour les résultats
  void _updateResults(List<ProviderModel> nearbyProviders, List<ProviderModel> allProviders, Position searchPosition) {
    _nearbyProviders = nearbyProviders;
    _allProviders = allProviders;
    _lastSearchTime = DateTime.now();
    _lastSearchPosition = searchPosition;
    
    if (nearbyProviders.isEmpty) {
      _updateStatus(NearbySearchStatus.noResults);
    } else {
      _updateStatus(NearbySearchStatus.success);
    }
  }

  // Méthodes pour ajuster les filtres
  void updateRadius(double radius) {
    if (_searchRadius != radius) {
      _searchRadius = radius;
      _invalidateCache();
      notifyListeners();
    }
  }

  void updateCategoryFilter(int? categoryId, String categoryName) {
    if (_selectedCategoryId != categoryId) {
      _selectedCategoryId = categoryId;
      _selectedCategory = categoryName;
      _invalidateCache();
      notifyListeners();
    }
  }

  void updateRatingFilter(double minRating) {
    if (_minRating != minRating) {
      _minRating = minRating;
      _invalidateCache();
      notifyListeners();
    }
  }

  void updateBusinessTypeFilter(String businessType) {
    if (_businessType != businessType) {
      _businessType = businessType;
      _invalidateCache();
      notifyListeners();
    }
  }

  // Réinitialiser tous les filtres
  void resetFilters() {
    _searchRadius = 10.0;
    _selectedCategoryId = null;
    _selectedCategory = '';
    _minRating = 0.0;
    _businessType = '';
    _invalidateCache();
    notifyListeners();
  }

  // Invalider le cache
  void _invalidateCache() {
    _lastSearchTime = null;
    _lastSearchPosition = null;
  }

  // Méthodes utilitaires pour l'interface
  List<ProviderModel> getProvidersByDistance() {
    List<ProviderModel> sorted = List.from(_nearbyProviders);
    sorted.sort((a, b) => (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));
    return sorted;
  }

  List<ProviderModel> getProvidersByRating() {
    List<ProviderModel> sorted = List.from(_nearbyProviders);
    sorted.sort((a, b) => b.rating.compareTo(a.rating));
    return sorted;
  }

  ProviderModel? getProviderById(int id) {
    try {
      return _nearbyProviders.firstWhere((provider) => provider.id == id);
    } catch (e) {
      return null;
    }
  }

  // Recherche rapide par mot-clé
  Future<void> quickSearch(String query) async {
    if (query.isEmpty) {
      await searchNearbyProviders();
      return;
    }

    _updateStatus(NearbySearchStatus.loading);

    try {
      // Filtrer les prestataires existants par le mot-clé
      List<ProviderModel> filtered = _allProviders.where((provider) {
        return provider.name.toLowerCase().contains(query.toLowerCase()) ||
               provider.description.toLowerCase().contains(query.toLowerCase()) ||
               provider.businessType.toLowerCase().contains(query.toLowerCase());
      }).toList();

      // Recalculer les distances et trier
      if (_locationService.hasValidPosition) {
        Position pos = _locationService.currentPosition!;
        filtered = _filterAndSortProviders(filtered, pos);
      }

      _nearbyProviders = filtered;
      _updateStatus(filtered.isEmpty ? NearbySearchStatus.noResults : NearbySearchStatus.success);
      
    } catch (e) {
      _setError('Erreur lors de la recherche: $e', NearbySearchStatus.error);
    }
  }

  // Actualiser la recherche
  Future<void> refresh() async {
    await searchNearbyProviders(forceRefresh: true);
  }

  // Gestion du statut
  void _updateStatus(NearbySearchStatus newStatus) {
    _status = newStatus;
    if (newStatus != NearbySearchStatus.error && newStatus != NearbySearchStatus.locationError) {
      _errorMessage = '';
    }
    notifyListeners();
  }

  void _setError(String message, NearbySearchStatus status) {
    _errorMessage = message;
    _status = status;
    print('❌ Erreur NearbyProvider: $message');
    notifyListeners();
  }

  // Réinitialiser les erreurs
  void clearError() {
    _errorMessage = '';
    if (_status == NearbySearchStatus.error || _status == NearbySearchStatus.locationError) {
      _status = NearbySearchStatus.initial;
    }
    notifyListeners();
  }

  // Obtenir des statistiques sur la recherche
  Map<String, dynamic> getSearchStats() {
    return {
      'totalProviders': _allProviders.length,
      'nearbyProviders': _nearbyProviders.length,
      'searchRadius': _searchRadius,
      'averageDistance': _nearbyProviders.isNotEmpty 
          ? _nearbyProviders.map((p) => p.distance ?? 0).reduce((a, b) => a + b) / _nearbyProviders.length
          : 0,
      'averageRating': _nearbyProviders.isNotEmpty
          ? _nearbyProviders.map((p) => p.rating).reduce((a, b) => a + b) / _nearbyProviders.length
          : 0,
      'lastSearchTime': _lastSearchTime,
      'cacheValid': _canUseCachedResults(),
    };
  }
}