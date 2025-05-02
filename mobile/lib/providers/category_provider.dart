// lib/providers/category_provider.dart
import 'package:flutter/material.dart';
import '../core/models/category.dart';
import '../core/services/api_service.dart';

class CategoryWithCount {
  final Category category;
  final int serviceCount;

  CategoryWithCount({
    required this.category,
    required this.serviceCount,
  });
}

class CategoryProvider with ChangeNotifier {
  final ApiService _apiService;
  List<CategoryWithCount> _categoriesWithCount = [];
  bool _isLoading = false;
  bool _useLocalData = true; // Flag pour utiliser les données locales

  CategoryProvider(this._apiService);

  List<CategoryWithCount> get categoriesWithCount => _categoriesWithCount;
  List<Category> get categories => _categoriesWithCount.map((cwc) => cwc.category).toList();
  bool get isLoading => _isLoading;

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      List<Category> fetchedCategories = [];
      
      if (_useLocalData) {
        // Utiliser les catégories locales définies dans le modèle
        fetchedCategories = Category.getDefaultCategories();
      } else {
        // Sinon, récupérer les catégories depuis l'API
        fetchedCategories = await _apiService.getCategories();
      }
      
      // Liste temporaire pour stocker les catégories avec leur nombre de services
      List<CategoryWithCount> tempList = [];
      
      // Pour chaque catégorie, récupérer le nombre de services
      for (var category in fetchedCategories) {
        int count = 0;
        try {
          if (!_useLocalData) {
            // Si on utilise l'API, récupérer le nombre de services réel
            count = await _apiService.getServiceCountByCategory(category.id);
          } else {
            // Sinon, utiliser des valeurs locales pour les tests
            count = _getMockServiceCount(category.id);
          }
        } catch (e) {
          print('Erreur lors de la récupération du nombre de services pour la catégorie ${category.id}: $e');
          // En cas d'erreur, on continue avec count = 0
        }
        
        // Ajouter à la liste temporaire
        tempList.add(CategoryWithCount(
          category: category,
          serviceCount: count,
        ));
      }
      
      // Mettre à jour la liste
      _categoriesWithCount = tempList;
    } catch (error) {
      print('Error fetching categories: $error');
      
      // En cas d'erreur globale, utiliser des données de test
      _categoriesWithCount = _getMockCategoriesWithCount();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Méthode mock pour fournir un nombre de services pour chaque catégorie
  int _getMockServiceCount(int categoryId) {
    final Map<int, int> mockCounts = {
      1: 11, // Maison & Construction
      2: 5,  // Bien-être & Beauté
      3: 6,  // Événements & Artistiques
      4: 4,  // Transport & Logistique
      5: 3,  // Santé & Bien-être
      6: 5,  // Services Professionnels & Formation
      7: 4,  // Services Numériques & Technologiques
      8: 3,  // Services pour Animaux
      9: 3,  // Services Divers
    };
    
    return mockCounts[categoryId] ?? 0;
  }
  
  // Données de test en cas d'erreur
  List<CategoryWithCount> _getMockCategoriesWithCount() {
    final categories = Category.getDefaultCategories();
    return categories.map((category) => 
      CategoryWithCount(
        category: category, 
        serviceCount: _getMockServiceCount(category.id)
      )
    ).toList();
  }
  
  void toggleDataSource(bool useLocal) {
    if (_useLocalData != useLocal) {
      _useLocalData = useLocal;
      fetchCategories(); // Recharger les données avec la nouvelle source
    }
  }
}