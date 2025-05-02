// lib/providers/subcategory_provider.dart
import 'package:flutter/material.dart';
import '../core/models/subcategory.dart';
import '../core/services/api_service.dart';

class SubcategoryWithCount {
  final Subcategory subcategory;
  final int serviceCount;

  SubcategoryWithCount({
    required this.subcategory,
    required this.serviceCount,
  });
}

class SubcategoryProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Subcategory> _subcategories = [];
  List<SubcategoryWithCount> _subcategoriesWithCount = [];
  bool _isLoading = false;
  int? _selectedCategoryId;

  SubcategoryProvider(this._apiService);

  List<Subcategory> get subcategories => _subcategories;
  List<SubcategoryWithCount> get subcategoriesWithCount => _subcategoriesWithCount;
  bool get isLoading => _isLoading;
  int? get selectedCategoryId => _selectedCategoryId;

  Future<void> fetchSubcategories(int categoryId) async {
    _isLoading = true;
    _selectedCategoryId = categoryId;
    notifyListeners();

    try {
      final fetchedSubcategories = await _apiService.getSubcategories(categoryId);
      _subcategories = fetchedSubcategories;
      
      // Récupérer le nombre de services pour chaque sous-catégorie
      List<SubcategoryWithCount> tempList = [];
      for (var subcategory in fetchedSubcategories) {
        int count = 0;
        try {
          // Essayer de récupérer le nombre de services par sous-catégorie
          count = await _apiService.getServiceCountBySubcategory(subcategory.id);
        } catch (e) {
          print('Erreur lors de la récupération du nombre de services pour la sous-catégorie ${subcategory.id}: $e');
          // En cas d'erreur, nous continuons avec count = 0
        }
        
        // Ajouter à la liste temporaire
        tempList.add(SubcategoryWithCount(
          subcategory: subcategory,
          serviceCount: count,
        ));
      }
      
      _subcategoriesWithCount = tempList;
      
    } catch (error) {
      print('Error fetching subcategories: $error');
      
      // En cas d'erreur, utiliser des données de test
      _subcategories = _getMockSubcategories(categoryId);
      _subcategoriesWithCount = _subcategories.map((subcategory) => 
        SubcategoryWithCount(
          subcategory: subcategory, 
          serviceCount: 0
        )
      ).toList();
      
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Méthode mock pour fournir des sous-catégories de test
  List<Subcategory> _getMockSubcategories(int categoryId) {
    if (categoryId == 1) { // Maison & Construction
      return [
        Subcategory(
          id: 1,
          name: 'Construction & rénovation',
          categoryId: 1,
          description: 'Services de construction et rénovation',
        ),
        Subcategory(
          id: 2,
          name: 'Plomberie',
          categoryId: 1,
          description: 'Services de plomberie',
        ),
        Subcategory(
          id: 3,
          name: 'Électricité',
          categoryId: 1,
          description: 'Services d\'électricité',
        ),
        Subcategory(
          id: 4,
          name: 'Menuiserie & Ébénisterie',
          categoryId: 1,
          description: 'Fabrication et réparation de meubles',
        ),
        Subcategory(
          id: 5,
          name: 'Peinture & Décoration',
          categoryId: 1,
          description: 'Peintres en bâtiment, décorateurs d\'intérieur',
        ),
      ];
    } else if (categoryId == 2) { // Bien-être & Beauté
      return [
        Subcategory(
          id: 12,
          name: 'Coiffure & Barbier',
          categoryId: 2,
          description: 'Coiffeurs à domicile, salons de beauté',
        ),
        Subcategory(
          id: 13,
          name: 'Esthétique & Maquillage',
          categoryId: 2,
          description: 'Manucure, soins du visage, maquilleurs professionnels',
        ),
        Subcategory(
          id: 14,
          name: 'Massages & Thérapies',
          categoryId: 2,
          description: 'Massothérapeutes, spa, réflexologie',
        ),
      ];
    }
    // Ajouter d'autres catégories au besoin
    
    return [
      Subcategory(
        id: 999,
        name: 'Sous-catégorie générée',
        categoryId: categoryId,
        description: 'Description générée pour la catégorie $categoryId',
      ),
    ];
  }
}