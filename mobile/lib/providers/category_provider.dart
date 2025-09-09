// lib/providers/category_provider.dart
import 'package:flutter/material.dart';
import '../core/models/category.dart';
import '../core/services/api_service.dart';

class CategoryProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Category> _categories = [];
  List<Category> _sortedCategories = []; // ← NOUVELLE LISTE TRIÉE
  bool _isLoading = false;
  Map<int, int> _serviceCounts = {};
  bool _isSortedByCount = false; // ← NOUVEAU FLAG

  CategoryProvider(this._apiService);

  // ← MODIFIER LE GETTER POUR RETOURNER LA LISTE TRIÉE
  List<Category> get categories => _isSortedByCount ? _sortedCategories : _categories;
  bool get isLoading => _isLoading;
  bool get isSortedByCount => _isSortedByCount; // ← NOUVEAU GETTER
  
  // Retourne le nombre de services pour une catégorie donnée
  int getServiceCount(int categoryId) {
    return _serviceCounts[categoryId] ?? 0;
  }

  Future<void> fetchCategories({bool sortByServiceCount = true}) async { // ← NOUVEAU PARAMÈTRE
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
      await _fetchServiceCounts(sortByServiceCount); // ← PASSER LE PARAMÈTRE
    } catch (error) {
      print('Error fetching categories: $error');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // ← MODIFIER LA MÉTHODE POUR INCLURE LE TRI
  Future<void> _fetchServiceCounts([bool sortAfterFetch = true]) async {
    try {
      Map<int, int> tempServiceCounts = {};
      
      for (var category in _categories) {
        try {
          // Délai court pour éviter de surcharger l'API
          await Future.delayed(const Duration(milliseconds: 200));
          
          // Récupérer le nombre de services
          final count = await _apiService.getServiceCountByCategory(category.id);
          tempServiceCounts[category.id] = count;
          
          print('✅ Catégorie ${category.name}: $count services');
          
        } catch (e) {
          print('❌ Erreur récupération compteur catégorie ${category.id}: $e');
          tempServiceCounts[category.id] = 0;
        }
      }
      
      // Mettre à jour tous les compteurs d'un coup
      _serviceCounts = tempServiceCounts;
      
      // ← NOUVEAU : TRIER LES CATÉGORIES PAR NOMBRE DE SERVICES
      if (sortAfterFetch) {
        _sortCategoriesByServiceCount();
      }
      
      // Notifier une fois à la fin
      notifyListeners();
      
    } catch (error) {
      print('❌ Erreur lors de la récupération des compteurs: $error');
    }
  }
  
  // ← NOUVELLE MÉTHODE POUR TRIER
  void _sortCategoriesByServiceCount() {
    _sortedCategories = List.from(_categories);
    
    _sortedCategories.sort((a, b) {
      int countA = _serviceCounts[a.id] ?? 0;
      int countB = _serviceCounts[b.id] ?? 0;
      
      // Tri décroissant (plus d'annonces en premier)
      return countB.compareTo(countA);
    });
    
    _isSortedByCount = true;
    
    print('📊 Catégories triées par nombre de services:');
    for (var category in _sortedCategories.take(5)) {
      print('   ${category.name}: ${_serviceCounts[category.id]} services');
    }
  }
  
  // ← NOUVELLE MÉTHODE PUBLIQUE POUR CHANGER LE TRI
  void toggleSortByServiceCount() {
    if (_isSortedByCount) {
      // Revenir à l'ordre original
      _isSortedByCount = false;
    } else {
      // Trier par nombre de services
      _sortCategoriesByServiceCount();
    }
    notifyListeners();
  }
  
  // ← NOUVELLE MÉTHODE POUR FORCER LE TRI
  void sortByServiceCount() {
    _sortCategoriesByServiceCount();
    notifyListeners();
  }
  
  // ← NOUVELLE MÉTHODE POUR L'ORDRE ORIGINAL
  void sortByOriginalOrder() {
    _isSortedByCount = false;
    notifyListeners();
  }
  
  // Recherche de catégories par nom (mise à jour pour prendre en compte le tri)
  List<Category> searchCategories(String query) {
    if (query.isEmpty) {
      return categories; // Utilise le getter qui retourne la bonne liste
    }
    
    final searchLower = query.toLowerCase();
    final categoriesToSearch = _isSortedByCount ? _sortedCategories : _categories;
    
    return categoriesToSearch.where((category) => 
      category.name.toLowerCase().contains(searchLower) ||
      category.description.toLowerCase().contains(searchLower)
    ).toList();
  }
  
  // ← NOUVELLE MÉTHODE POUR OBTENIR LES STATS
  Map<String, dynamic> getCategoriesStats() {
    int totalServices = _serviceCounts.values.fold(0, (sum, count) => sum + count);
    
    return {
      'totalCategories': _categories.length,
      'totalServices': totalServices,
      'averageServicesPerCategory': _categories.isNotEmpty 
          ? (totalServices / _categories.length).toStringAsFixed(1) 
          : '0',
      'topCategory': _sortedCategories.isNotEmpty 
          ? {
              'name': _sortedCategories.first.name,
              'serviceCount': _serviceCounts[_sortedCategories.first.id]
            }
          : null,
    };
  }
}