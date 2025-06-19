// lib/providers/project_provider.dart - Version améliorée
import 'dart:io';
import 'package:flutter/material.dart';
import '../core/models/client_project.dart';
import '../core/services/api_service.dart';

class ProjectProvider with ChangeNotifier {
  final ApiService _apiService;
  
  List<ClientProject> _userProjects = [];
  List<ClientProject> _allProjects = [];
  bool _isLoading = false;
  bool _isLoadingUserProjects = false;
  String? _errorMessage;

  ProjectProvider(this._apiService);

  // Getters
  List<ClientProject> get userProjects => _userProjects;
  List<ClientProject> get allProjects => _allProjects;
  bool get isLoading => _isLoading;
  bool get isLoadingUserProjects => _isLoadingUserProjects;
  String? get errorMessage => _errorMessage;

  // Méthode pour récupérer tous les projets (pour les prestataires)
  Future<void> fetchAllProjects({Map<String, dynamic>? filters}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.getProjects(filters ?? {});
      _allProjects = result['projects'] ?? [];
    } catch (error) {
      print('Error fetching all projects: $error');
      _errorMessage = error.toString();
      // En cas d'erreur, utiliser des données mock
      _allProjects = _getMockAllProjects();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Méthode pour récupérer les projets de l'utilisateur connecté (pour les clients)
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
      // En cas d'erreur, utiliser des données mock
      _userProjects = _getMockUserProjects();
    } finally {
      _isLoadingUserProjects = false;
      notifyListeners();
    }
  }

  // Méthode pour créer un nouveau projet
  Future<bool> createProject(Map<String, dynamic> projectData, List<File?> attachments) async {
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
      print('Error creating project: $error');
      _errorMessage = error.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Méthode pour mettre à jour le statut d'un projet
  Future<bool> updateProjectStatus(int projectId, String newStatus) async {
    try {
      // Appel API pour mettre à jour le statut
      // await _apiService.updateProjectStatus(projectId, newStatus);
      
      // Mettre à jour localement
      final projectIndex = _userProjects.indexWhere((p) => p.id == projectId);
      if (projectIndex != -1) {
        final updatedProject = _userProjects[projectIndex].copyWith(status: newStatus);
        _userProjects[projectIndex] = updatedProject;
        notifyListeners();
      }
      
      return true;
    } catch (error) {
      print('Error updating project status: $error');
      _errorMessage = error.toString();
      return false;
    }
  }

  // Méthode pour supprimer un projet
  Future<bool> deleteProject(int projectId) async {
    try {
      // Appel API pour supprimer le projet
      // await _apiService.deleteProject(projectId);
      
      // Supprimer localement
      _userProjects.removeWhere((p) => p.id == projectId);
      notifyListeners();
      
      return true;
    } catch (error) {
      print('Error deleting project: $error');
      _errorMessage = error.toString();
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
        final updatedProject = project.copyWith(
          isFavorited: !(project.isFavorited ?? false)
        );
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
    final inProgressProjects = _userProjects.where((p) => p.status == 'in_progress').length;
    final completedProjects = _userProjects.where((p) => p.status == 'completed').length;
    final totalOffers = _userProjects.fold<int>(0, (sum, project) => sum + project.offersCount);

    return {
      'total_projects': _userProjects.length,
      'open_projects': openProjects,
      'in_progress_projects': inProgressProjects,
      'completed_projects': completedProjects,
      'total_offers': totalOffers,
    };
  }

  // Méthode pour filtrer les projets
  List<ClientProject> getFilteredProjects({
    String? category,
    String? location,
    String? urgency,
    String? budgetRange,
    bool? remotePossible,
  }) {
    var filtered = List<ClientProject>.from(_allProjects);

    if (category != null && category.isNotEmpty) {
      filtered = filtered.where((p) => p.categoryName.toLowerCase().contains(category.toLowerCase())).toList();
    }

    if (location != null && location.isNotEmpty) {
      filtered = filtered.where((p) => p.location.toLowerCase().contains(location.toLowerCase())).toList();
    }

    if (urgency != null && urgency.isNotEmpty) {
      filtered = filtered.where((p) => p.urgency == urgency).toList();
    }

    if (budgetRange != null && budgetRange.isNotEmpty) {
      filtered = filtered.where((p) => p.budgetRange == budgetRange).toList();
    }

    if (remotePossible == true) {
      filtered = filtered.where((p) => p.remotePossible == true).toList();
    }

    return filtered;
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
        description: 'Je souhaite rénover entièrement ma maison de 120m². Cela inclut la peinture, la plomberie, l\'électricité et la pose de nouveaux sols. Le projet doit être terminé dans les 3 mois.',
        clientName: 'Vous',
        categoryName: 'Rénovation',
        budgetRange: '10000_30000',
        budgetDisplay: '15000€ - 25000€',
        location: 'Cotonou, Littoral',
        remotePossible: false,
        urgency: 'medium',
        status: 'open',
        contactViaPlatform: true,
        showEmail: false,
        showPhone: true,
        requiredSkills: ['Plomberie', 'Électricité', 'Peinture', 'Carrelage'],
        offersCount: 8,
        viewsCount: 45,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        timeSincePosted: 'Il y a 3 jours',
        isFavorited: false,
        hasUserOffered: false,
        attachments: [
          {'name': 'Plan_maison.pdf', 'url': 'https://example.com/plan.pdf'},
          {'name': 'Photos_actuelles.zip', 'url': 'https://example.com/photos.zip'},
        ],
      ),
      ClientProject(
        id: 2,
        title: 'Création d\'un site web e-commerce',
        description: 'Besoin d\'un développeur pour créer un site e-commerce moderne avec paiement en ligne, gestion des stocks et interface d\'administration.',
        clientName: 'Vous',
        categoryName: 'Développement web',
        budgetRange: '5000_15000',
        budgetDisplay: '8000€ - 12000€',
        location: 'Remote',
        remotePossible: true,
        urgency: 'high',
        status: 'in_progress',
        contactViaPlatform: true,
        showEmail: true,
        showPhone: false,
        requiredSkills: ['React', 'Node.js', 'MongoDB', 'Stripe'],
        offersCount: 15,
        viewsCount: 89,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        timeSincePosted: 'Il y a 10 jours',
        isFavorited: false,
        hasUserOffered: false,
        attachments: [
          {'name': 'Cahier_des_charges.pdf', 'url': 'https://example.com/cdc.pdf'},
          {'name': 'Maquettes.figma', 'url': 'https://example.com/maquettes.figma'},
        ],
      ),
      ClientProject(
        id: 3,
        title: 'Cours de guitare à domicile',
        description: 'Recherche un professeur de guitare expérimenté pour donner des cours à domicile à mon fils de 12 ans. 1h par semaine pendant 6 mois.',
        clientName: 'Vous',
        categoryName: 'Éducation & Formation',
        budgetRange: '500_1000',
        budgetDisplay: '30€/cours (24 cours)',
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
      ClientProject(
        id: 4,
        title: 'Réparation climatisation bureau',
        description: 'Notre climatiseur de bureau ne fonctionne plus correctement. Besoin d\'un technicien pour diagnostic et réparation urgente.',
        clientName: 'Vous',
        categoryName: 'Climatisation',
        budgetRange: '100_500',
        budgetDisplay: '150€ - 300€',
        location: 'Cotonou Centre',
        remotePossible: false,
        urgency: 'high',
        status: 'open',
        contactViaPlatform: true,
        showEmail: true,
        showPhone: true,
        requiredSkills: ['Climatisation', 'Frigoriste', 'Dépannage'],
        offersCount: 4,
        viewsCount: 22,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        timeSincePosted: 'Il y a 8 heures',
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
        description: 'Développement d\'une application mobile cross-platform pour service de livraison de repas avec géolocalisation en temps réel.',
        clientName: 'TechStart SARL',
        categoryName: 'Développement mobile',
        budgetRange: '10000_30000',
        budgetDisplay: '15000€ - 25000€',
        location: 'Remote',
        remotePossible: true,
        urgency: 'medium',
        status: 'open',
        contactViaPlatform: true,
        showEmail: false,
        showPhone: false,
        requiredSkills: ['React Native', 'Node.js', 'MongoDB', 'GPS'],
        offersCount: 12,
        viewsCount: 78,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        timeSincePosted: 'Il y a 4 heures',
        isFavorited: false,
        hasUserOffered: false,
      ),
      ClientProject(
        id: 11,
        title: 'Plomberie urgente - Fuite d\'eau',
        description: 'Fuite d\'eau importante dans la cuisine. Intervention d\'urgence requise pour éviter les dégâts. Disponible aujourd\'hui.',
        clientName: 'Marie K.',
        categoryName: 'Plomberie',
        budgetRange: '100_500',
        budgetDisplay: '150€ - 400€',
        location: 'Akpakpa, Littoral',
        remotePossible: false,
        urgency: 'high',
        status: 'open',
        contactViaPlatform: true,
        showEmail: false,
        showPhone: true,
        requiredSkills: ['Plomberie', 'Dépannage urgent'],
        offersCount: 3,
        viewsCount: 15,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        timeSincePosted: 'Il y a 2 heures',
        isFavorited: false,
        hasUserOffered: false,
      ),
      ClientProject(
        id: 12,
        title: 'Design logo et identité visuelle',
        description: 'Création complète de l\'identité visuelle pour une nouvelle entreprise : logo, carte de visite, papier en-tête, charte graphique.',
        clientName: 'Innovation Corp',
        categoryName: 'Design graphique',
        budgetRange: '1000_5000',
        budgetDisplay: '2000€ - 4000€',
        location: 'Remote',
        remotePossible: true,
        urgency: 'medium',
        status: 'open',
        contactViaPlatform: true,
        showEmail: true,
        showPhone: false,
        requiredSkills: ['Illustrator', 'Photoshop', 'InDesign', 'Branding'],
        offersCount: 18,
        viewsCount: 94,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        timeSincePosted: 'Il y a 1 jour',
        isFavorited: false,
        hasUserOffered: false,
      ),
      ClientProject(
        id: 13,
        title: 'Cours de français pour adultes',
        description: 'Recherche professeur de français qualifié pour cours particuliers niveau débutant. 2h par semaine pendant 3 mois.',
        clientName: 'James M.',
        categoryName: 'Éducation & Formation',
        budgetRange: '500_1000',
        budgetDisplay: '25€/heure',
        location: 'Cotonou, Littoral',
        remotePossible: true,
        urgency: 'low',
        status: 'open',
        contactViaPlatform: true,
        showEmail: false,
        showPhone: false,
        requiredSkills: ['Français langue étrangère', 'Pédagogie adultes'],
        offersCount: 7,
        viewsCount: 34,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        timeSincePosted: 'Il y a 2 jours',
        isFavorited: false,
        hasUserOffered: false,
      ),
      ClientProject(
        id: 14,
        title: 'Installation système de sécurité',
        description: 'Installation complète d\'un système de vidéosurveillance avec 8 caméras IP, enregistreur et accès mobile.',
        clientName: 'Sécuri-Pro',
        categoryName: 'Sécurité & Surveillance',
        budgetRange: '2000_5000',
        budgetDisplay: '3000€ - 4500€',
        location: 'Calavi, Littoral',
        remotePossible: false,
        urgency: 'medium',
        status: 'open',
        contactViaPlatform: true,
        showEmail: true,
        showPhone: true,
        requiredSkills: ['Vidéosurveillance', 'Réseau IP', 'Électricité'],
        offersCount: 5,
        viewsCount: 29,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        timeSincePosted: 'Il y a 12 heures',
        isFavorited: false,
        hasUserOffered: false,
      ),
      ClientProject(
        id: 15,
        title: 'Rédaction contenu site web',
        description: 'Rédaction de contenu SEO pour site web d\'avocat : 20 pages + blog articles. Expertise juridique appréciée.',
        clientName: 'Cabinet Juridique Plus',
        categoryName: 'Rédaction & Traduction',
        budgetRange: '1000_3000',
        budgetDisplay: '1500€ - 2500€',
        location: 'Remote',
        remotePossible: true,
        urgency: 'low',
        status: 'open',
        contactViaPlatform: true,
        showEmail: true,
        showPhone: false,
        requiredSkills: ['Rédaction SEO', 'Juridique', 'WordPress'],
        offersCount: 11,
        viewsCount: 56,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        timeSincePosted: 'Il y a 3 jours',
        isFavorited: false,
        hasUserOffered: false,
      ),
    ];
  }
}