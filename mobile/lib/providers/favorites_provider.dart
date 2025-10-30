// mobile/lib/providers/favorites_provider.dart
// VERSION MODIFIÉE - Gère les PRESTATAIRES favoris pour les clients

import 'package:flutter/material.dart';
import '../core/models/client_project.dart';
import '../core/models/service.dart';
import '../core/models/provider_model.dart'; // ✅ AJOUTÉ
import '../core/services/api_service.dart';
import '../core/api/api_client.dart';
import 'auth_provider.dart'; // ✅ AJOUTÉ pour vérifier le rôle

class FavoritesProvider with ChangeNotifier {
  final ApiService _apiService;
  late final ApiClient _apiClient;
  AuthProvider? _authProvider; // ✅ AJOUTÉ

  List<ClientProject> _favoriteProjects = [];
  List<Service> _favoriteServices = []; // ✅ CONSERVÉ pour rétrocompatibilité si besoin
  List<ProviderModel> _favoriteProviders = []; // ✅ AJOUTÉ
  bool _isLoading = false;
  String _error = '';

  FavoritesProvider(this._apiService) {
    _apiClient = ApiClient(baseUrl: _apiService.baseUrl);
  }

  // ✅ AJOUTÉ : Setter pour AuthProvider
  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  // Getters
  List<ClientProject> get favoriteProjects => _favoriteProjects;
  List<Service> get favoriteServices => _favoriteServices;
  List<ProviderModel> get favoriteProviders => _favoriteProviders; // ✅ AJOUTÉ
  bool get isLoading => _isLoading;
  String get error => _error;
  int get totalFavorites => _favoriteProjects.length + _favoriteProviders.length; // ✅ MODIFIÉ

  /// ✅ MODIFIÉ : Charger tous les favoris selon le rôle de l'utilisateur
  Future<void> loadAllFavorites() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final user = _authProvider?.currentUser;
      
      if (user == null) {
        print('⚠️ Utilisateur non connecté');
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (user.role == 'provider') {
        // Les prestataires voient les PROJETS favoris
        print('👷 Chargement des projets favoris (prestataire)');
        await loadFavoriteProjects();
      } else {
        // ✅ CHANGÉ : Les clients voient les PRESTATAIRES favoris
        print('👤 Chargement des prestataires favoris (client)');
        await loadFavoriteProviders();
      }
    } catch (e) {
      _error = 'Erreur lors du chargement des favoris: $e';
      print('❌ Erreur loadAllFavorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger les projets favoris (pour les prestataires)
  Future<void> loadFavoriteProjects() async {
    try {
      print('📋 Chargement des projets favoris...');
      _favoriteProjects = await _apiService.getFavoriteProjects();
      print('✅ ${_favoriteProjects.length} projets favoris chargés');
    } catch (e) {
      print('❌ Erreur loadFavoriteProjects: $e');
      _favoriteProjects = [];
    }
    notifyListeners();
  }

  /// Charger les services favoris (pour les clients) - CONSERVÉ pour rétrocompatibilité
  Future<void> loadFavoriteServices() async {
    try {
      print('🛍️ Chargement des services favoris...');
      
      final responseData = await _apiClient.get('favorites/', requireAuth: true);
      
      if (responseData != null) {
        List<dynamic> data = [];
        
        if (responseData is Map<String, dynamic>) {
          data = responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        }
        
        _favoriteServices = [];
        
        for (var item in data) {
          if (item is Map<String, dynamic> && item['service_details'] != null) {
            try {
              final service = Service.fromJson(item['service_details']);
              _favoriteServices.add(service);
            } catch (e) {
              print('⚠️ Erreur parsing service favori: $e');
            }
          }
        }
        
        print('✅ ${_favoriteServices.length} services favoris chargés');
      } else {
        _favoriteServices = [];
      }
    } catch (e) {
      print('❌ Erreur loadFavoriteServices: $e');
      _favoriteServices = [];
    }
    notifyListeners();
  }

  /// ✅ AJOUTÉ : Charger les prestataires favoris (pour les clients)
  Future<void> loadFavoriteProviders() async {
    try {
      print('👥 Chargement des prestataires favoris...');
      
      final responseData = await _apiClient.get('favorits/providers/', requireAuth: true);
      
      if (responseData != null) {
        List<dynamic> data = [];
        
        // Gérer différents formats de réponse
        if (responseData is Map<String, dynamic>) {
          data = responseData['data'] ?? responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        }
        
        _favoriteProviders = [];
        
        for (var item in data) {
          try {
            // Si l'item contient directement les données du prestataire
            if (item is Map<String, dynamic>) {
              // Vérifier si c'est un objet avec provider_details ou directement le provider
              final providerData = item['provider_details'] ?? item['provider'] ?? item;
              
              final provider = ProviderModel.fromJson(providerData);
              _favoriteProviders.add(provider);
            }
          } catch (e) {
            print('⚠️ Erreur parsing prestataire favori: $e');
            print('   Item: $item');
          }
        }
        
        print('✅ ${_favoriteProviders.length} prestataires favoris chargés');
      } else {
        print('⚠️ Aucune donnée reçue pour les prestataires favoris');
        _favoriteProviders = [];
      }
    } catch (e) {
      print('❌ Erreur loadFavoriteProviders: $e');
      _favoriteProviders = [];
    }
    notifyListeners();
  }

  /// Basculer favori projet (pour les prestataires)
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

  /// Basculer favori SERVICE (pour les clients) - CONSERVÉ pour rétrocompatibilité
  Future<bool> toggleServiceFavorite(int serviceId) async {
    try {
      print('🔄 Toggle favori service $serviceId...');
      
      final response = await _apiClient.post(
        'favorites/toggle/',
        data: {'service_id': serviceId},
        requireAuth: true,
      );
      
      print('✅ Réponse toggle: $response');
      
      await loadFavoriteServices();
      
      final isNowFavorite = isServiceFavorite(serviceId);
      print('🔍 Service $serviceId est maintenant favori: $isNowFavorite');
      
      return isNowFavorite;
    } catch (e) {
      _error = 'Erreur lors de la modification du favori: $e';
      notifyListeners();
      print('❌ Erreur toggleServiceFavorite: $e');
      return false;
    }
  }

  /// ✅ AJOUTÉ : Basculer favori PRESTATAIRE (pour les clients)
  Future<bool> toggleProviderFavorite(int providerId) async {
    try {
      print('🔄 Toggle favori prestataire $providerId...');
      
      final isCurrentlyFavorite = isProviderFavorite(providerId);
      
      dynamic response;
      if (isCurrentlyFavorite) {
        // Retirer des favoris
        print('🗑️ Retrait du prestataire $providerId des favoris...');
        response = await _apiClient.delete(
          'favorits/providers/$providerId/',
          requireAuth: true,
        );
      } else {
        // Ajouter aux favoris
        print('➕ Ajout du prestataire $providerId aux favoris...');
        response = await _apiClient.post(
          'favorits/providers/',
          data: {'provider_id': providerId},
          requireAuth: true,
        );
      }
      
      print('✅ Réponse toggle prestataire: $response');
      
      // Recharger les favoris
      await loadFavoriteProviders();
      
      // Retourner le nouvel état
      final isNowFavorite = isProviderFavorite(providerId);
      print('🔍 Prestataire $providerId est maintenant favori: $isNowFavorite');
      
      return isNowFavorite;
    } catch (e) {
      _error = 'Erreur lors de la modification du favori: $e';
      notifyListeners();
      print('❌ Erreur toggleProviderFavorite: $e');
      rethrow; // ✅ Rethrow pour que le UI puisse gérer l'erreur
    }
  }

  /// Vérifier si un projet est en favori
  bool isProjectFavorite(int projectId) {
    return _favoriteProjects.any((project) => project.id == projectId);
  }

  /// Vérifier si un SERVICE est en favori - CONSERVÉ pour rétrocompatibilité
  bool isServiceFavorite(int serviceId) {
    final isFavorite = _favoriteServices.any((service) => service.id == serviceId);
    print('🔍 Vérification favori service $serviceId: $isFavorite');
    return isFavorite;
  }

  /// ✅ AJOUTÉ : Vérifier si un PRESTATAIRE est en favori
  bool isProviderFavorite(int providerId) {
    final isFavorite = _favoriteProviders.any((provider) => provider.id == providerId);
    print('🔍 Vérification favori prestataire $providerId: $isFavorite');
    return isFavorite;
  }

  /// Effacer les erreurs
  void clearError() {
    _error = '';
    notifyListeners();
  }

  /// ✅ AJOUTÉ : Méthode utilitaire pour déboguer
  void debugPrintFavorites() {
    print('═══════════════════════════════════════');
    print('📊 État des favoris:');
    print('   Projets favoris: ${_favoriteProjects.length}');
    print('   Services favoris: ${_favoriteServices.length}');
    print('   Prestataires favoris: ${_favoriteProviders.length}');
    print('   Chargement en cours: $_isLoading');
    print('   Erreur: $_error');
    print('═══════════════════════════════════════');
  }
}