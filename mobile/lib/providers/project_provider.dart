// lib/providers/project_provider.dart - Version corrigée avec gestion d'authentification

import 'dart:io';
import 'package:flutter/material.dart';
import '../core/models/client_project.dart';
import '../core/services/api_service.dart';
import '../providers/auth_provider.dart';

class ProjectProvider with ChangeNotifier {
  final ApiService _apiService;
  final AuthProvider? _authProvider;

  List<ClientProject> _userProjects = [];
  List<ClientProject> _allProjects = [];
  bool _isLoading = false;
  bool _isLoadingUserProjects = false;
  String? _errorMessage;

  ProjectProvider(this._apiService, [this._authProvider]);

  // Getters
  List<ClientProject> get userProjects => _userProjects;
  List<ClientProject> get allProjects => _allProjects;
  bool get isLoading => _isLoading;
  bool get isLoadingUserProjects => _isLoadingUserProjects;
  String? get errorMessage => _errorMessage;

  // Méthode pour récupérer les projets de l'utilisateur connecté avec gestion d'auth
  // Future<void> fetchUserProjects() async {
  //   _isLoadingUserProjects = true;
  //   _errorMessage = null;
  //   notifyListeners();

  //   try {
  //     // Vérifier d'abord si l'utilisateur est connecté
  //     if (_authProvider != null && !_authProvider!.isAuthenticated) {
  //       throw Exception('Utilisateur non connecté');
  //     }

  //     final result = await _apiService.getUserProjects();
  //     _userProjects = result['projects'] ?? [];
  //   } catch (error) {
  //     print('Error fetching user projects: $error');
  //     _errorMessage = error.toString();

  //     // Si l'erreur est liée à l'authentification, essayer de rafraîchir le token
  //     if (error.toString().contains('Unauthorized') ||
  //         error.toString().contains('401')) {
  //       try {
  //         // Tenter de rafraîchir le token
  //         if (_authProvider != null) {
  //           await _authProvider!.refreshToken();
  //           // Réessayer la requête après le rafraîchissement
  //           final result = await _apiService.getUserProjects();
  //           _userProjects = result['projects'] ?? [];
  //           _errorMessage = null; // Effacer l'erreur si la requête réussit
  //         } else {
  //           // Si pas d'auth provider, utiliser des données mock
  //           _userProjects = _getMockUserProjects();
  //           _errorMessage = 'Session expirée. Veuillez vous reconnecter.';
  //         }
  //       } catch (refreshError) {
  //         print('Error refreshing token: $refreshError');
  //         // En cas d'échec du rafraîchissement, déconnecter l'utilisateur
  //         if (_authProvider != null) {
  //           await _authProvider!.logout();
  //         }
  //         _userProjects = [];
  //         _errorMessage = 'Session expirée. Veuillez vous reconnecter.';
  //       }
  //     } else {
  //       // Pour les autres erreurs, utiliser des données mock
  //       _userProjects = _getMockUserProjects();
  //     }
  //   } finally {
  //     _isLoadingUserProjects = false;
  //     notifyListeners();
  //   }
  // }
  Future<bool> closeProject(int projectId) async {
    try {
      final success = await _apiService.closeProject(projectId);

      if (success) {
        // Mettre à jour localement le projet dans la liste
        final projectIndex = _userProjects.indexWhere((p) => p.id == projectId);
        if (projectIndex != -1) {
          final updatedProject =
              _userProjects[projectIndex].copyWith(status: 'closed');
          _userProjects[projectIndex] = updatedProject;
          notifyListeners();
        }
      }

      return success;
    } catch (error) {
      print('Error closing project: $error');
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  /// Mettre à jour le statut d'un projet (version améliorée)
  Future<bool> updateProjectStatus(int projectId, String newStatus) async {
    try {
      final updatedProject =
          await _apiService.updateProjectStatus(projectId, newStatus);

      // Mettre à jour localement
      final projectIndex = _userProjects.indexWhere((p) => p.id == projectId);
      if (projectIndex != -1) {
        _userProjects[projectIndex] = updatedProject;
        notifyListeners();
      }

      return true;
    } catch (error) {
      print('Error updating project status: $error');
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  /// Supprimer un projet (version améliorée)
  Future<bool> deleteProject(int projectId) async {
    try {
      final success = await _apiService.deleteProject(projectId);

      if (success) {
        // Supprimer localement
        _userProjects.removeWhere((p) => p.id == projectId);
        notifyListeners();
      }

      return success;
    } catch (error) {
      print('Error deleting project: $error');
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  /// Incrémenter les vues d'un projet
  Future<void> incrementProjectView(int projectId) async {
    try {
      final updatedProject = await _apiService.incrementProjectView(projectId);

      // Mettre à jour le projet dans la liste des projets (si applicable)
      final projectIndex = _allProjects.indexWhere((p) => p.id == projectId);
      if (projectIndex != -1) {
        _allProjects[projectIndex] = updatedProject;
        notifyListeners();
      }
    } catch (error) {
      print('Error incrementing project view: $error');
      // Ne pas afficher d'erreur à l'utilisateur pour les vues
      // C'est une fonctionnalité en arrière-plan
    }
  }

  /// Obtenir les statistiques d'un projet
  Future<Map<String, dynamic>?> getProjectStatistics(int projectId) async {
    try {
      return await _apiService.getProjectStatistics(projectId);
    } catch (error) {
      print('Error getting project statistics: $error');
      _errorMessage = error.toString();
      notifyListeners();
      return null;
    }
  }

  // Méthode pour récupérer tous les projets (pour les prestataires)
  Future<void> fetchUserProjects() async {
    _isLoadingUserProjects = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.getUserProjects();
      _userProjects = result['projects'] ?? [];
    } catch (error) {
      print('Error fetching user projects: $error');
      _errorMessage = error.toString();

      // NOUVELLE GESTION : Vérifier si c'est une erreur 401
      if (error.toString().contains('Unauthorized') ||
          error.toString().contains('401')) {
        print(
            '🔄 Erreur 401 détectée, tentative de rafraîchissement du token...');

        // Tenter de rafraîchir le token si AuthProvider est disponible
        if (_authProvider != null) {
          try {
            final tokenRefreshed = await _authProvider!.refreshToken();
            if (tokenRefreshed) {
              print('✅ Token rafraîchi, nouvelle tentative...');
              // Réessayer la requête avec le nouveau token
              final result = await _apiService.getUserProjects();
              _userProjects = result['projects'] ?? [];
              _errorMessage = null; // Effacer l'erreur si succès
            } else {
              print('❌ Échec du rafraîchissement du token');
              _userProjects = _getMockUserProjects();
              _errorMessage = 'Session expirée. Veuillez vous reconnecter.';
            }
          } catch (refreshError) {
            print('❌ Erreur lors du rafraîchissement: $refreshError');
            _userProjects = _getMockUserProjects();
            _errorMessage = 'Session expirée. Veuillez vous reconnecter.';
          }
        } else {
          // Si pas d'AuthProvider, utiliser des données mock
          print('⚠️ AuthProvider non disponible, utilisation des données mock');
          _userProjects = _getMockUserProjects();
          _errorMessage =
              'Problème d\'authentification. Données de démonstration affichées.';
        }
      } else {
        // Pour les autres erreurs, utiliser des données mock
        _userProjects = _getMockUserProjects();
      }
    } finally {
      _isLoadingUserProjects = false;
      notifyListeners();
    }
  }

  // Méthode pour créer un nouveau projet
  Future<bool> createProject(
      Map<String, dynamic> projectData, List<File?> attachments) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newProject = await _apiService.createProject(projectData, attachments);
      _userProjects.insert(0, newProject);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      print('❌ Erreur dans createProject: $error');
      
      // Gestion spéciale des erreurs d'authentification
      if (error.toString().contains('Non autorisé') || 
          error.toString().contains('401')) {
        _errorMessage = 'Session expirée. Veuillez vous reconnecter.';
        
        // Optionnel : déconnecter l'utilisateur automatiquement
        if (_authProvider != null) {
          await _authProvider!.logout();
        }
      } else {
        _errorMessage = error.toString();
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Méthode pour marquer un projet comme favori
  Future<void> toggleProjectFavorite(int projectId) async {
    try {
      await _apiService.toggleProjectFavorite(projectId);

      // Mettre à jour localement dans allProjects
      final projectIndex = _allProjects.indexWhere((p) => p.id == projectId);
      if (projectIndex != -1) {
        final project = _allProjects[projectIndex];
        final updatedProject =
            project.copyWith(isFavorited: !(project.isFavorited ?? false));
        _allProjects[projectIndex] = updatedProject;
        notifyListeners();
      }
    } catch (error) {
      print('Error toggling project favorite: $error');
      throw error;
    }
  }

  // Méthode pour obtenir les statistiques des projets utilisateur
  Map<String, int> getUserProjectStats() {
    final openProjects = _userProjects.where((p) => p.status == 'open').length;
    final inProgressProjects =
        _userProjects.where((p) => p.status == 'in_progress').length;
    final completedProjects =
        _userProjects.where((p) => p.status == 'completed').length;
    final totalOffers =
        _userProjects.fold<int>(0, (sum, project) => sum + project.offersCount);

    return {
      'total_projects': _userProjects.length,
      'open_projects': openProjects,
      'in_progress_projects': inProgressProjects,
      'completed_projects': completedProjects,
      'total_offers': totalOffers,
    };
  }

  // Réinitialiser les erreurs
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Données mock pour les projets utilisateur (clients)
  List<ClientProject> _getMockUserProjects() {
    return [
      ClientProject(
        id: 1,
        title: 'Rénovation complète de ma maison',
        description:
            'Je souhaite rénover entièrement ma maison de 120m². Cela inclut la peinture, la plomberie, l\'électricité et la pose de nouveaux sols.',
        clientName: 'Vous',
        categoryName: 'Rénovation & Construction',
        budgetRange: '5000_15000',
        budgetDisplay: '8000AOA - 12000AOA',
        location: 'Cotonou, Littoral',
        remotePossible: false,
        urgency: 'medium',
        status: 'open',
        contactViaPlatform: true,
        showEmail: true,
        showPhone: true,
        requiredSkills: ['Peinture', 'Plomberie', 'Électricité', 'Sols'],
        offersCount: 8,
        viewsCount: 45,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        timeSincePosted: 'Il y a 2 jours',
        isFavorited: false,
        hasUserOffered: false,
      ),
      ClientProject(
        id: 2,
        title: 'Cours particuliers de guitare',
        description:
            'Recherche professeur de guitare pour ma fille de 12 ans. Débutante complète.',
        clientName: 'Vous',
        categoryName: 'Éducation & Formation',
        budgetRange: '500_1000',
        budgetDisplay: '30AOA/cours',
        location: 'Cotonou, Littoral',
        remotePossible: false,
        urgency: 'low',
        status: 'completed',
        contactViaPlatform: true,
        showEmail: false,
        showPhone: true,
        requiredSkills: ['Guitare classique', 'Pédagogie', 'Enfants'],
        offersCount: 6,
        viewsCount: 28,
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        timeSincePosted: 'Il y a 45 jours',
        isFavorited: false,
        hasUserOffered: false,
      ),
    ];
  }

  // Données mock pour tous les projets (prestataires)
  List<ClientProject> _getMockAllProjects() {
    return [
      ClientProject(
        id: 10,
        title: 'Application mobile de livraison',
        description:
            'Développement d\'une application mobile cross-platform pour service de livraison.',
        clientName: 'TechStart SARL',
        categoryName: 'Développement mobile',
        budgetRange: '10000_30000',
        budgetDisplay: '15000AOA - 25000AOA',
        location: 'Remote',
        remotePossible: true,
        urgency: 'medium',
        status: 'open',
        contactViaPlatform: true,
        showEmail: false,
        showPhone: false,
        requiredSkills: ['React Native', 'Node.js', 'MongoDB'],
        offersCount: 12,
        viewsCount: 78,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        timeSincePosted: 'Il y a 4 heures',
        isFavorited: false,
        hasUserOffered: false,
      ),
    ];
  }
}
