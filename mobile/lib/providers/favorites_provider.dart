// lib/providers/favorites_provider.dart - CORRECTION DE L'ERREUR

import 'package:flutter/material.dart';
import '../core/models/client_project.dart';
import '../core/models/provider_model.dart';
import '../core/models/service.dart';
import '../core/services/api_service.dart';
import '../core/api/api_client.dart';

class FavoritesProvider with ChangeNotifier {
  final ApiService _apiService;
  late final ApiClient _apiClient;

  List<ClientProject> _favoriteProjects = [];
  List<ProviderModel> _favoriteProviders = [];
  List<Service> _favoriteServices = [];
  bool _isLoading = false;
  String _error = '';

  FavoritesProvider(this._apiService) {
    _apiClient = ApiClient(baseUrl: _apiService.baseUrl);
  }

  // Getters
  List<ClientProject> get favoriteProjects => _favoriteProjects;
  List<ProviderModel> get favoriteProviders => _favoriteProviders;
  List<Service> get favoriteServices => _favoriteServices;
  bool get isLoading => _isLoading;
  String get error => _error;
  int get totalFavorites => _favoriteProjects.length + _favoriteProviders.length + _favoriteServices.length;

  /// Charger tous les favoris
  Future<void> loadAllFavorites() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await Future.wait([
        loadFavoriteProjects(),
        loadFavoriteProviders(),
        loadFavoriteServices(),
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

  /// ✅ CORRECTION : Charger les prestataires favoris
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
        Set<int> seenProviderIds = {};
        
        for (var item in data) {
          if (item is Map<String, dynamic>) {
            ProviderModel? provider;
            int? providerId;
            
            // ✅ CORRECTION : Gérer correctement les différentes structures
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
                print('❌ Erreur parsing provider objet: $e');
              }
            } else if (item['provider'] is int) {
              // ✅ NOUVEAU : Structure {provider: 1} (juste l'ID)
              providerId = item['provider'] as int;
              print('⚠️ Provider ID seulement trouvé: $providerId, récupération des détails...');
              
              // Récupérer les détails du prestataire via l'API
              try {
                final providerData = await _apiClient.get('providers/$providerId/', requireAuth: true);
                if (providerData != null) {
                  provider = ProviderModel.fromJson(providerData);
                }
              } catch (e) {
                print('❌ Erreur récupération provider $providerId: $e');
              }
            }
            
            if (provider != null && providerId != null && !seenProviderIds.contains(providerId)) {
              _favoriteProviders.add(provider);
              seenProviderIds.add(providerId);
              // print('✅ Prestataire unique ajouté: ${provider.id} - ${provider.f} ${provider.lastName}');
            } else if (providerId != null && seenProviderIds.contains(providerId)) {
              print('⚠️ Doublon ignoré pour prestataire ID: $providerId');
            }
          }
        }
        
        print('✅ ${_favoriteProviders.length} prestataires favoris uniques chargés');
      } else {
        _favoriteProviders = [];
      }
    } catch (e) {
      print('❌ Erreur loadFavoriteProviders: $e');
      _favoriteProviders = [];
    }
  }

  /// Charger les services favoris
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
            .where((item) => item['service'] != null)
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
      await loadFavoriteProjects();
      return result;
    } catch (e) {
      _error = 'Erreur lors de la modification du favori: $e';
      notifyListeners();
      return false;
    }
  }

  /// ✅ CORRECTION : Basculer favori prestataire
  Future<bool> toggleProviderFavorite(int providerId) async {
    try {
      final isCurrentlyFavorite = _favoriteProviders
          .any((provider) => provider.id == providerId);

      if (isCurrentlyFavorite) {
        // Retirer des favoris
        final responseData = await _apiClient.get('favorites/', requireAuth: true);
        
        if (responseData != null) {
          List<dynamic> data = [];
          if (responseData is Map<String, dynamic>) {
            data = responseData['results'] ?? [];
          } else if (responseData is List) {
            data = responseData;
          }
          
          // ✅ CORRECTION : Gérer différentes structures pour trouver l'ID du favori
          Map<String, dynamic>? favoriteItem;
          
          for (var item in data) {
            if (item is Map<String, dynamic>) {
              // Structure 1: provider_details existe
              if (item['provider_details'] != null && 
                  item['provider_details']['id'] == providerId) {
                favoriteItem = item;
                break;
              }
              // Structure 2: provider est un objet
              else if (item['provider'] is Map<String, dynamic> && 
                       item['provider']['id'] == providerId) {
                favoriteItem = item;
                break;
              }
              // ✅ Structure 3: provider est juste l'ID
              else if (item['provider'] is int && 
                       item['provider'] == providerId) {
                favoriteItem = item;
                break;
              }
            }
          }
          
          if (favoriteItem != null) {
            final favoriteId = favoriteItem['id'];
            await _apiClient.delete('favorites/$favoriteId/', requireAuth: true);
            print('✅ Prestataire retiré des favoris');
          } else {
            print('⚠️ Favori non trouvé pour le prestataire $providerId');
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

      await loadFavoriteProviders();
      return !isCurrentlyFavorite;
    } catch (e) {
      _error = 'Erreur lors de la modification du favori: $e';
      notifyListeners();
      print('❌ Erreur toggleProviderFavorite: $e');
      return false;
    }
  }

  /// Basculer favori service
  Future<bool> toggleServiceFavorite(int serviceId, {int? providerId}) async {
    try {
      final isCurrentlyFavorite = _favoriteServices
          .any((service) => service.id == serviceId);

      if (isCurrentlyFavorite) {
        // Retirer des favoris
        final responseData = await _apiClient.get('favorites/', requireAuth: true);
        
        if (responseData != null) {
          List<dynamic> data = [];
          if (responseData is Map<String, dynamic>) {
            data = responseData['results'] ?? [];
          } else if (responseData is List) {
            data = responseData;
          }
          
          final favoriteItem = data.cast<Map<String, dynamic>>().firstWhere(
            (item) => item['service'] != null && item['service']['id'] == serviceId,
            orElse: () => {},
          );
          
          if (favoriteItem.isNotEmpty) {
            final favoriteId = favoriteItem['id'];
            await _apiClient.delete('favorites/$favoriteId/', requireAuth: true);
            print('✅ Service retiré des favoris');
          }
        }
      } else {
        // Ajouter aux favoris
        Map<String, dynamic> requestData = {'service_id': serviceId};
        
        if (providerId != null) {
          requestData['provider_id'] = providerId;
        }
        
        await _apiClient.post(
          'favorites/', 
          data: requestData, 
          requireAuth: true
        );
        print('✅ Service ajouté aux favoris');
      }

      await loadFavoriteServices();
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

  /// Vérifier si un service est en favori
  bool isServiceFavorite(int serviceId) {
    final isFavorite = _favoriteServices.any((service) => service.id == serviceId);
    return isFavorite;
  }

  /// Effacer les erreurs
  void clearError() {
    _error = '';
    notifyListeners();
  }
}