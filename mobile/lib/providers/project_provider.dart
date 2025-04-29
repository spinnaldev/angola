// lib/providers/project_provider.dart
import 'package:flutter/material.dart';
import '../core/models/project.dart';
import '../core/services/api_service.dart';

import 'package:w3_loc/core/models/project.dart' as models;
import 'package:w3_loc/providers/project_provider.dart';

class ProjectProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Project> _userProjects = [];
  bool _isLoading = false;

  ProjectProvider(this._apiService);

  List<Project> get userProjects => _userProjects;
  bool get isLoading => _isLoading;

  Future<void> fetchUserProjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedProjects = await _apiService.getUserProjects();
      _userProjects = fetchedProjects;
    } catch (error) {
      print('Error fetching user projects: $error');
      // En cas d'erreur, on utilise des données de test
      _userProjects = _getMockProjects();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Project> _getMockProjects() {
    return [
      Project(
        id: 1,
        title: 'Rénovation maison',
        description: 'Je recherche une entreprise capable de gérer l\'ensemble de la construction, y compris la conception, le choix des matériaux, la main-d\'œuvre et le respect des délais.',
        status: 'En cours',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        providers: [
          ProviderInProject(
            id: 1,
            name: 'Tanya',
            specialty: 'Entreprises de charpente et couverture',
            imageUrl: 'https://randomuser.me/api/portraits/women/23.jpg',
          ),
        ],
      ),
    ];
  }
}

// Ajout dans le ApiService pour récupérer les projets utilisateur
// Dans lib/core/services/api_service.dart, ajoutez:

/*
  Future<List<Project>> getUserProjects() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/projects/user/'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['results'] ?? [];
        return data.map((item) => Project.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load user projects');
      }
    } catch (e) {
      print('Error in getUserProjects: $e');
      throw e;
    }
  }
*/