// mobile/lib/providers/favorites_provider.dart
import 'package:flutter/material.dart';
import '../core/models/client_project.dart';
import '../core/models/provider_model.dart';
import '../core/services/api_service.dart';
import '../core/api/api_client.dart';

class FavoritesProvider with ChangeNotifier {
  final ApiService _apiService;
  late final ApiClient _apiClient;

  List<ClientProject> _favoriteProjects = [];
  List<ProviderModel> _favoriteProviders = [];
  bool _isLoading = false;
  String _error = '';

  FavoritesProvider(this._apiService) {
    // ✅ Initialiser ApiClient comme dans vos autres providers
    _apiClient = ApiClient(baseUrl: _apiService.baseUrl);
  }

  // Getters
  List<ClientProject> get favoriteProjects => _favoriteProjects;
  List<ProviderModel> get favoriteProviders => _favoriteProviders;
  bool get isLoading => _isLoading;
  String get error => _error;
  int get totalFavorites => _favoriteProjects.length + _favoriteProviders.length;

  /// Charger tous les favoris
  Future<void> loadAllFavorites() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await Future.wait([
        loadFavoriteProjects(),
        loadFavoriteProviders(),
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
      // ✅ Utiliser la méthode existante de votre ApiService
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
      
      // ✅ Utiliser ApiClient comme dans vos autres services
      final responseData = await _apiClient.get('favorites/', requireAuth: true);
      
      if (responseData != null) {
        List<dynamic> data = [];
        
        if (responseData is Map<String, dynamic>) {
          data = responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        }
        
        _favoriteProviders = data
            .map((item) => ProviderModel.fromJson(item['provider']))
            .toList();
        
        print('✅ ${_favoriteProviders.length} prestataires favoris chargés');
      } else {
        _favoriteProviders = [];
      }
    } catch (e) {
      print('❌ Erreur loadFavoriteProviders: $e');
      _favoriteProviders = [];
    }
  }

  /// Basculer favori projet
  Future<bool> toggleProjectFavorite(int projectId) async {
    try {
      // ✅ Utiliser la méthode existante de votre ApiService
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
        // ✅ Retirer des favoris - trouver l'ID du favori
        final favoriteProvider = _favoriteProviders
            .firstWhere((provider) => provider.id == providerId);
        
        // On a besoin de l'ID du favori (pas du provider)
        // Chercher dans la liste complète pour avoir l'ID du favori
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
            (item) => item['provider']['id'] == providerId,
            orElse: () => null,
          );
          
          if (favoriteItem != null) {
            final favoriteId = favoriteItem['id'];
            await _apiClient.delete('favorites/$favoriteId/', requireAuth: true);
            print('✅ Prestataire retiré des favoris');
          }
        }
      } else {
        // ✅ Ajouter aux favoris
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

  /// Vérifier si un projet est en favori
  bool isProjectFavorite(int projectId) {
    return _favoriteProjects.any((project) => project.id == projectId);
  }

  /// Vérifier si un prestataire est en favori
  bool isProviderFavorite(int providerId) {
    return _favoriteProviders.any((provider) => provider.id == providerId);
  }

  /// Effacer les erreurs
  void clearError() {
    _error = '';
    notifyListeners();
  }
}
