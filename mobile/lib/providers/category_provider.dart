// lib/providers/category_provider.dart
import 'package:flutter/material.dart';
import '../core/models/category.dart';
import '../core/services/api_service.dart';

class CategoryProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Category> _categories = [];
  bool _isLoading = false;
  Map<int, int> _serviceCounts = {};

  CategoryProvider(this._apiService);

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  
  // Retourne le nombre de services pour une catégorie donnée
  int getServiceCount(int categoryId) {
    return _serviceCounts[categoryId] ?? 0;
  }

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Récupérer les catégories
      final fetchedCategories = await _apiService.getCategories();
      _categories = fetchedCategories;
      
      // Notification immédiate pour afficher les catégories
      _isLoading = false;
      notifyListeners();
      
      // Ensuite, récupérer les compteurs de services en arrière-plan
      _fetchServiceCounts();
    } catch (error) {
      print('Error fetching categories: $error');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Méthode privée pour récupérer le nombre de services par catégorie
  Future<void> _fetchServiceCounts() async {
    try {
      for (var category in _categories) {
        try {
          // Délai court pour éviter de surcharger l'API
          await Future.delayed(const Duration(milliseconds: 200));
          
          // Récupérer le nombre de services
          final count = await _apiService.getServiceCountByCategory(category.id);
          _serviceCounts[category.id] = count;
          
          // Notifier après chaque mise à jour pour rafraîchir l'UI progressivement
          notifyListeners();
        } catch (e) {
          print('Error fetching service count for category ${category.id}: $e');
          // Ne pas planter si une requête échoue
        }
      }
    } catch (error) {
      print('Error fetching service counts: $error');
    }
  }
  
  // Recherche de catégories par nom
  List<Category> searchCategories(String query) {
    if (query.isEmpty) {
      return _categories;
    }
    
    final searchLower = query.toLowerCase();
    return _categories.where((category) => 
      category.name.toLowerCase().contains(searchLower) ||
      category.description.toLowerCase().contains(searchLower)
    ).toList();
  }
}