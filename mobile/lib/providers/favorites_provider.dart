// mobile/lib/providers/favorites_provider.dart - ÉTENDU AVEC SERVICES
import 'package:flutter/material.dart';
import '../core/models/client_project.dart';
import '../core/models/provider_model.dart';
import '../core/models/service.dart'; // ✅ AJOUT
import '../core/services/api_service.dart';
import '../core/api/api_client.dart';

class FavoritesProvider with ChangeNotifier {
  final ApiService _apiService;
  late final ApiClient _apiClient;

  List<ClientProject> _favoriteProjects = [];
  List<ProviderModel> _favoriteProviders = [];
  List<Service> _favoriteServices = []; // ✅ NOUVEAU
  bool _isLoading = false;
  String _error = '';

  FavoritesProvider(this._apiService) {
    // Initialiser ApiClient comme dans vos autres providers
    _apiClient = ApiClient(baseUrl: _apiService.baseUrl);
  }

  // Getters
  List<ClientProject> get favoriteProjects => _favoriteProjects;
  List<ProviderModel> get favoriteProviders => _favoriteProviders;
  List<Service> get favoriteServices => _favoriteServices; // ✅ NOUVEAU
  bool get isLoading => _isLoading;
  String get error => _error;
  int get totalFavorites => _favoriteProjects.length + _favoriteProviders.length + _favoriteServices.length; // ✅ MODIFIÉ

  /// Charger tous les favoris
  Future<void> loadAllFavorites() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await Future.wait([
        loadFavoriteProjects(),
        loadFavoriteProviders(),
        loadFavoriteServices(), // ✅ NOUVEAU
      ]);
    } catch (e) {
      _error = 'Erreur lors du chargement des favoris: $e';
      print('❌ Erreur loadAllFavorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger les projets favoris
  Future<void> loadFavoriteProjects() async {
    try {
      print('📋 Chargement des projets favoris...');
      _favoriteProjects = await _apiService.getFavoriteProjects();
      print('✅ ${_favoriteProjects.length} projets favoris chargés');
    } catch (e) {
      print('❌ Erreur loadFavoriteProjects: $e');
      _favoriteProjects = [];
    }
  }

  /// Charger les prestataires favoris
  Future<void> loadFavoriteProviders() async {
    try {
      print('👥 Chargement des prestataires favoris...');
      
      final responseData = await _apiClient.get('favorites/', requireAuth: true);
      
      if (responseData != null) {
        List<dynamic> data = [];
        
        if (responseData is Map<String, dynamic>) {
          data = responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        }
        
        _favoriteProviders = [];
        Set<int> seenProviderIds = {}; // ✅ NOUVEAU : Éviter les doublons
        
        for (var item in data) {
          if (item is Map<String, dynamic>) {
            ProviderModel? provider;
            int? providerId;
            
            // ✅ CORRIGÉ : Gérer les différentes structures possibles
            if (item['provider_details'] != null) {
              // Structure : {provider: 1, provider_details: {...}}
              try {
                provider = ProviderModel.fromJson(item['provider_details']);
                providerId = provider.id;
              } catch (e) {
                print('❌ Erreur parsing provider_details: $e');
              }
            } else if (item['provider'] is Map<String, dynamic>) {
              // Structure : {provider: {...}}
              try {
                provider = ProviderModel.fromJson(item['provider']);
                providerId = provider.id;
              } catch (e) {
                print('❌ Erreur parsing provider: $e');
              }
            }
            
            // ✅ NOUVEAU : Ajouter seulement si pas de doublon
            if (provider != null && providerId != null && !seenProviderIds.contains(providerId)) {
              _favoriteProviders.add(provider);
              seenProviderIds.add(providerId);
              // print('✅ Prestataire unique ajouté: ${provider.id} - ${provider.firstName} ${provider.lastName}');
            } else if (providerId != null && seenProviderIds.contains(providerId)) {
              print('⚠️ Doublon ignoré pour prestataire ID: $providerId');
            }
          }
        }
        
        print('✅ ${_favoriteProviders.length} prestataires favoris uniques chargés');
        print('🔍 IDs des prestataires favoris: ${_favoriteProviders.map((p) => p.id).toList()}');
      } else {
        _favoriteProviders = [];
      }
    } catch (e) {
      print('❌ Erreur loadFavoriteProviders: $e');
      _favoriteProviders = [];
    }
  }

  /// ✅ NOUVEAU : Charger les services favoris
  Future<void> loadFavoriteServices() async {
    try {
      print('🔧 Chargement des services favoris...');
      
      final responseData = await _apiClient.get('favorites/', requireAuth: true);
      
      if (responseData != null) {
        List<dynamic> data = [];
        
        if (responseData is Map<String, dynamic>) {
          data = responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        }
        
        _favoriteServices = data
            .where((item) => item['service'] != null) // Filtrer les services
            .map((item) => Service.fromJson(item['service']))
            .toList();
        
        print('✅ ${_favoriteServices.length} services favoris chargés');
      } else {
        _favoriteServices = [];
      }
    } catch (e) {
      print('❌ Erreur loadFavoriteServices: $e');
      _favoriteServices = [];
    }
  }

  /// Basculer favori projet
  Future<bool> toggleProjectFavorite(int projectId) async {
    try {
      final result = await _apiService.toggleProjectFavorite(projectId);
      await loadFavoriteProjects(); // Recharger la liste
      return result;
    } catch (e) {
      _error = 'Erreur lors de la modification du favori: $e';
      notifyListeners();
      return false;
    }
  }

  /// Basculer favori prestataire
  Future<bool> toggleProviderFavorite(int providerId) async {
    try {
      // Vérifier si déjà en favori
      final isCurrentlyFavorite = _favoriteProviders
          .any((provider) => provider.id == providerId);

      if (isCurrentlyFavorite) {
        // Retirer des favoris - trouver l'ID du favori
        final responseData = await _apiClient.get('favorites/', requireAuth: true);
        
        if (responseData != null) {
          List<dynamic> data = [];
          if (responseData is Map<String, dynamic>) {
            data = responseData['results'] ?? [];
          } else if (responseData is List) {
            data = responseData;
          }
          
          // Trouver l'ID du favori correspondant
          final favoriteItem = data.firstWhere(
            (item) => item['provider'] != null && item['provider']['id'] == providerId,
            orElse: () => null,
          );
          
          if (favoriteItem != null) {
            final favoriteId = favoriteItem['id'];
            await _apiClient.delete('favorites/$favoriteId/', requireAuth: true);
            print('✅ Prestataire retiré des favoris');
          }
        }
      } else {
        // Ajouter aux favoris
        await _apiClient.post(
          'favorites/', 
          data: {'provider_id': providerId}, 
          requireAuth: true
        );
        print('✅ Prestataire ajouté aux favoris');
      }

      await loadFavoriteProviders(); // Recharger la liste
      return !isCurrentlyFavorite;
    } catch (e) {
      _error = 'Erreur lors de la modification du favori: $e';
      notifyListeners();
      print('❌ Erreur toggleProviderFavorite: $e');
      return false;
    }
  }

  /// ✅ NOUVEAU : Basculer favori service
  Future<bool> toggleServiceFavorite(int serviceId, {int? providerId}) async {
    try {
      // Vérifier si déjà en favori
      final isCurrentlyFavorite = _favoriteServices
          .any((service) => service.id == serviceId);

      if (isCurrentlyFavorite) {
        // Retirer des favoris - trouver l'ID du favori
        final responseData = await _apiClient.get('favorites/', requireAuth: true);
        
        if (responseData != null) {
          List<dynamic> data = [];
          if (responseData is Map<String, dynamic>) {
            data = responseData['results'] ?? [];
          } else if (responseData is List) {
            data = responseData;
          }
          
          // Trouver l'ID du favori correspondant
          final favoriteItem = data.firstWhere(
            (item) => item['service'] != null && item['service']['id'] == serviceId,
            orElse: () => null,
          );
          
          if (favoriteItem != null) {
            final favoriteId = favoriteItem['id'];
            await _apiClient.delete('favorites/$favoriteId/', requireAuth: true);
            print('✅ Service retiré des favoris');
          }
        }
      } else {
        // ✅ CORRIGÉ : Ajouter aux favoris avec provider_id
        Map<String, dynamic> requestData = {};
        
        if (providerId != null) {
          // Si on a le provider_id, l'utiliser
          requestData['provider'] = providerId;
        }
        
        // Ajouter le service_id si nécessaire (selon votre API)
        requestData['service_id'] = serviceId;
        
        print('🔧 Données envoyées pour favori service: $requestData');
        
        await _apiClient.post(
          'favorites/', 
          data: requestData, 
          requireAuth: true
        );
        print('✅ Service ajouté aux favoris');
      }

      await loadFavoriteServices(); // Recharger la liste
      return !isCurrentlyFavorite;
    } catch (e) {
      _error = 'Erreur lors de la modification du favori: $e';
      notifyListeners();
      print('❌ Erreur toggleServiceFavorite: $e');
      return false;
    }
  }

  /// Vérifier si un projet est en favori
  bool isProjectFavorite(int projectId) {
    return _favoriteProjects.any((project) => project.id == projectId);
  }

  /// Vérifier si un prestataire est en favori
  bool isProviderFavorite(int providerId) {
    return _favoriteProviders.any((provider) => provider.id == providerId);
  }

  /// ✅ NOUVEAU : Vérifier si un service est en favori
  bool isServiceFavorite(int serviceId) {
    final isFavorite = _favoriteServices.any((service) => service.id == serviceId);
    print('🔍 DEBUG - isServiceFavorite($serviceId): $isFavorite');
    print('🔍 DEBUG - _favoriteServices.length: ${_favoriteServices.length}');
    print('🔍 DEBUG - IDs dans _favoriteServices: ${_favoriteServices.map((s) => s.id).toList()}');
    return isFavorite;
  }

  /// Effacer les erreurs
  void clearError() {
    _error = '';
    notifyListeners();
  }
}