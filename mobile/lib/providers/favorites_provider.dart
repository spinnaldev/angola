// mobile/lib/providers/favorites_provider.dart
// REMPLACER COMPLÈTEMENT le fichier par cette version :

import 'package:flutter/material.dart';
import '../core/models/client_project.dart';
import '../core/models/service.dart';
import '../core/services/api_service.dart';
import '../core/api/api_client.dart';

class FavoritesProvider with ChangeNotifier {
  final ApiService _apiService;
  late final ApiClient _apiClient;

  List<ClientProject> _favoriteProjects = [];
  List<Service> _favoriteServices = [];
  bool _isLoading = false;
  String _error = '';

  FavoritesProvider(this._apiService) {
    _apiClient = ApiClient(baseUrl: _apiService.baseUrl);
  }

  // Getters
  List<ClientProject> get favoriteProjects => _favoriteProjects;
  List<Service> get favoriteServices => _favoriteServices;
  bool get isLoading => _isLoading;
  String get error => _error;
  int get totalFavorites => _favoriteProjects.length + _favoriteServices.length;

  /// Charger tous les favoris
  Future<void> loadAllFavorites() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await Future.wait([
        loadFavoriteProjects(),
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
  }

  /// Charger les services favoris (pour les clients)
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

  /// ✅ Basculer favori SERVICE (pour les clients)
  Future<bool> toggleServiceFavorite(int serviceId) async {
    try {
      print('🔄 Toggle favori service $serviceId...');
      
      // Utiliser l'endpoint toggle qui attend service_id
      final response = await _apiClient.post(
        'favorites/toggle/',
        data: {'service_id': serviceId},
        requireAuth: true,
      );
      
      print('✅ Réponse toggle: $response');
      
      // Recharger les favoris
      await loadFavoriteServices();
      
      // Retourner le nouvel état
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

  /// Vérifier si un projet est en favori
  bool isProjectFavorite(int projectId) {
    return _favoriteProjects.any((project) => project.id == projectId);
  }

  /// ✅ Vérifier si un SERVICE est en favori
  bool isServiceFavorite(int serviceId) {
    final isFavorite = _favoriteServices.any((service) => service.id == serviceId);
    print('🔍 Vérification favori service $serviceId: $isFavorite');
    return isFavorite;
  }

  /// Effacer les erreurs
  void clearError() {
    _error = '';
    notifyListeners();
  }
}