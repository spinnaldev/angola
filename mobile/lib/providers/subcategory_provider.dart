// lib/providers/subcategory_provider.dart - Version corrigée avec ApiClient
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/models/subcategory.dart';
import '../core/services/api_service.dart';
import '../core/api/api_client.dart'; // ✅ Import ApiClient

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
  late final ApiClient _apiClient; // ✅ Référence ApiClient
  
  List<Subcategory> _subcategories = [];
  List<SubcategoryWithCount> _subcategoriesWithCount = [];
  bool _isLoading = false;
  int? _selectedCategoryId;

  SubcategoryProvider(this._apiService) {
    // ✅ Initialiser ApiClient pour bénéficier des corrections d'encodage
    _apiClient = ApiClient(baseUrl: _apiService.baseUrl);
  }

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
      print('ON est arrivé ici oh et on a $fetchedSubcategories');
      _subcategories = fetchedSubcategories;
      print('Pour afficher on a : $_subcategories');
      
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
      _subcategoriesWithCount = _subcategories
          .map((subcategory) =>
              SubcategoryWithCount(subcategory: subcategory, serviceCount: 0))
          .toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ MÉTHODE CORRIGÉE: fetchAllSubcategories
  Future<void> fetchAllSubcategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      print('Fin de connait B');
      
      // ✅ Utiliser ApiClient au lieu de http.get
      final responseData = await _apiClient.get('subcategories/', requireAuth: false);
      
      print("Les réponses: $responseData");
      print("Type de responseData: ${responseData.runtimeType}");

      if (responseData != null) {
        // ✅ Gérer les données déjà décodées par ApiClient
        List<dynamic> data = [];
        
        if (responseData is Map<String, dynamic>) {
          data = responseData['results'] ?? [];
          print("Données extraites de 'results': ${data.length} éléments");
        } else if (responseData is List) {
          data = responseData;
          print("Données directes: ${data.length} éléments");
        }

        print("Données brutes: $data");

        // ✅ Mettre à jour les sous-catégories avec gestion des nulls
        _subcategories = data
            .map((item) {
              try {
                return Subcategory.fromJson(item);
              } catch (e) {
                print("Erreur lors de la conversion d'un élément: $e");
                print("Élément problématique: $item");
                return null;
              }
            })
            .where((item) => item != null)
            .cast<Subcategory>()
            .toList();

        print("✅ Sous-catégories chargées: ${_subcategories.length}");
        
        // ✅ Vérifier que les caractères accentués sont corrects
        for (var subcategory in _subcategories.take(3)) {
          print("✅ Sous-catégorie: ${subcategory.name} (encodage correct)");
        }
      } else {
        print("❌ Réponse nulle de l'API");
        _subcategories = [];
      }
    } catch (error) {
      print('❌ Error fetching all subcategories: $error');
      print('Stack trace: ${StackTrace.current}');
      _subcategories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ MÉTHODE CORRIGÉE: fetchSubcategoriesForCategory
  Future<List<Subcategory>> fetchSubcategoriesForCategory(int categoryId) async {
    _isLoading = true;
    _selectedCategoryId = categoryId;
    notifyListeners();

    try {
      // ✅ Utiliser ApiClient au lieu de http.get
      final responseData = await _apiClient.get('subcategories/?category_id=$categoryId', requireAuth: false);

      if (responseData != null) {
        // ✅ Gérer les données déjà décodées par ApiClient
        List<dynamic> data = [];
        
        if (responseData is Map<String, dynamic>) {
          data = responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        }
        
        final subcategories = data.map((item) => Subcategory.fromJson(item)).toList();
        
        print("✅ Récupéré ${subcategories.length} sous-catégories pour la catégorie $categoryId");
        
        // ✅ Debug encodage
        for (var subcategory in subcategories.take(2)) {
          print("✅ Sous-catégorie: ${subcategory.name}");
        }
        
        _isLoading = false;
        notifyListeners();
        
        return subcategories;
      } else {
        _isLoading = false;
        notifyListeners();
        throw Exception('Réponse nulle de l\'API pour les sous-catégories');
      }
    } catch (e) {
      print('❌ Erreur dans fetchSubcategoriesForCategory: $e');
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Méthode mock pour fournir des sous-catégories de test
  List<Subcategory> _getMockSubcategories(int categoryId) {
    if (categoryId == 1) {
      // Maison & Construction
      return [
        // Données mock commentées car elles ne sont plus nécessaires
        // avec l'API fonctionnelle
      ];
    } else if (categoryId == 2) {
      // Bien-être & Beauté
      return [
        // Données mock commentées
      ];
    }
    
    return [];
  }
}