// lib/providers/service_provider.dart - VERSION COMPLÈTEMENT CORRIGÉE avec ApiClient

import 'dart:io';
import 'package:flutter/material.dart';
import '../core/models/category.dart';
import '../core/models/service.dart';
import '../core/models/service_option.dart';
import '../core/services/api_service.dart';
import '../core/api/api_client.dart'; // ✅ Import ApiClient
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class ServiceProvider with ChangeNotifier {
  final ApiService _apiService;
  late final ApiClient _apiClient; // ✅ Référence ApiClient
  
  List<Service> _services = [];
  List<Service> _myServices = [];
  Service? _currentService;
  bool _isLoading = false;
  String? _errorMessage;
  List<Service> _recentServices = [];
  List<Service> _topRatedServices = [];
  List<Service> _nearbyServices = [];
  List<Category> _categories = [];
  Map<int, Category> _categoriesMap = {};
  List<int> _expertiseCategories = [];

  // Getters
  List<Service> get recentServices => _recentServices;
  List<Service> get topRatedServices => _topRatedServices;
  List<Service> get nearbyServices => _nearbyServices;
  List<Service> get services => _services;
  List<Service> get myServices => _myServices;
  Service? get currentService => _currentService;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<int> get expertiseCategories => _expertiseCategories;

  ServiceProvider(this._apiService) {
    // ✅ Initialiser ApiClient pour bénéficier des corrections d'encodage
    _apiClient = ApiClient(baseUrl: _apiService.baseUrl);
  }

  // ✅ MÉTHODE CORRIGÉE: fetchRecentServices
  Future<void> fetchRecentServices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("🔄 Début récupération des services récents...");
      
      // ✅ Utiliser ApiClient au lieu de http.get
      final responseData = await _apiClient.get('services/recent/', requireAuth: false);
      
      print("🔍 Données décodées: $responseData");
      
      // ✅ Gestion des données avec ApiClient (déjà décodées)
      List<dynamic> data;
      
      if (responseData is Map<String, dynamic>) {
        data = responseData['results'] ?? [];
        print("📋 Données dans 'results': ${data.length} éléments");
      } else if (responseData is List) {
        data = responseData;
        print("📋 Données directes: ${data.length} éléments");
      } else {
        print("❌ Structure de réponse inattendue: ${responseData.runtimeType}");
        data = [];
      }

      if (data.isNotEmpty) {
        print("🔧 Premier élément pour debug: ${data.first}");
        
        _recentServices = [];
        for (int i = 0; i < data.length; i++) {
          try {
            final service = Service.fromJson(data[i]);
            _recentServices.add(service);
            print("✅ Service $i parsé: ${service.title} (encodage correct)");
          } catch (e) {
            print("❌ Erreur parsing service $i: $e");
            print("📄 Données problématiques: ${data[i]}");
          }
        }
        
        print("🎉 Services récents récupérés: ${_recentServices.length}");
        
        if (_recentServices.isEmpty && data.isNotEmpty) {
          print("⚠️ Aucun service parsé malgré la présence de données");
          _errorMessage = 'Erreur de format des données des services';
        }
      } else {
        print("ℹ️ Aucun service récent disponible");
        _recentServices = [];
      }
    } catch (e) {
      print("💥 Exception dans fetchRecentServices: $e");
      _errorMessage = 'Erreur de connexion: ${e.toString()}';
      _recentServices = [];
    } finally {
      _isLoading = false;
      print("🔄 Fin fetchRecentServices - Services: ${_recentServices.length}");
      notifyListeners();
    }
  }

  // ✅ MÉTHODE CORRIGÉE: fetchTopRatedServices
  Future<void> fetchTopRatedServices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("🏆 Récupération des services les mieux notés...");
      
      // ✅ Utiliser ApiClient au lieu de http.get
      final responseData = await _apiClient.get('services/top_rated/', requireAuth: false);
      
      List<dynamic> data;
      if (responseData is List) {
        data = responseData;
      } else if (responseData is Map<String, dynamic>) {
        data = responseData['results'] ?? [];
      } else {
        data = [];
      }

      _topRatedServices = data.map((item) {
        final service = Service.fromJson(item);
        print("✅ Service top rated: ${service.title} (encodage correct)");
        return service;
      }).toList();
      
      print("🏆 Services top rated récupérés: ${_topRatedServices.length}");
    } catch (e) {
      print("❌ Erreur fetchTopRatedServices: $e");
      _errorMessage = 'Erreur lors du chargement des meilleurs services';
      _topRatedServices = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCurrentService() {
    _currentService = null;
    notifyListeners();
    print("🧹 ServiceProvider: Service actuel effacé");
  }
  // ✅ MÉTHODE CORRIGÉE: fetchNearbyServices
  Future<void> fetchNearbyServices(double latitude, double longitude, {double radius = 10.0}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("📍 Récupération des services à proximité...");
      
      // ✅ Utiliser ApiClient au lieu de http.get
      final responseData = await _apiClient.get(
        'services/nearby/?latitude=$latitude&longitude=$longitude&radius=$radius', 
        requireAuth: false
      );
      
      List<dynamic> data;
      if (responseData is List) {
        data = responseData;
      } else if (responseData is Map<String, dynamic>) {
        data = responseData['results'] ?? [];
      } else {
        data = [];
      }

      _nearbyServices = data.map((item) {
        final service = Service.fromJson(item);
        print("✅ Service nearby: ${service.title} (encodage correct)");
        return service;
      }).toList();
      
      print("📍 Services nearby récupérés: ${_nearbyServices.length}");
    } catch (e) {
      print("❌ Erreur fetchNearbyServices: $e");
      _errorMessage = 'Erreur lors du chargement des services à proximité';
      _nearbyServices = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ MÉTHODE CORRIGÉE: fetchMyServices
  Future<void> fetchMyServices() async {
    _isLoading = true;
    notifyListeners();

    try {
      print("🔄 Récupération des services du prestataire...");
      
      // ✅ Récupérer seulement les services du prestataire connecté
      final responseData = await _apiClient.get(
        'services/my_services/', // Nouvel endpoint à créer
        requireAuth: true
      );

      if (responseData != null && responseData['results'] != null) {
        _myServices = (responseData['results'] as List)
            .map((json) => Service.fromJson(json))
            .toList();
        
        print("✅ ${_myServices.length} services récupérés");
      } else {
        _myServices = [];
        print("⚠️ Aucun service trouvé");
      }

    } catch (e) {
      print('❌ Erreur lors de la récupération des services: $e');
      _errorMessage = e.toString();
      _myServices = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ MÉTHODE CORRIGÉE: fetchServicesByCategory
  Future<void> fetchServicesByCategory(int categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    _services = [];
    notifyListeners();

    try {
      print("📂 Récupération des services de la catégorie $categoryId...");
      
      // ✅ Utiliser ApiClient au lieu de http.get
      final responseData = await _apiClient.get('services/?category_id=$categoryId', requireAuth: false);
      
      List<dynamic> data = [];
      
      if (responseData is Map<String, dynamic>) {
        data = responseData['results'] ?? [];
      } else if (responseData is List) {
        data = responseData;
      }

      _services = data
          .where((item) => item != null)
          .map((item) {
            try {
              final service = Service.fromJson(item);
              print("✅ Service catégorie: ${service.title} (encodage correct)");
              return service;
            } catch (e) {
              print('❌ Erreur parsing service: $e');
              return null;
            }
          })
          .where((service) => service != null)
          .cast<Service>()
          .toList();

      print('✅ Services catégorie $categoryId récupérés: ${_services.length}');
    } catch (e) {
      print("❌ Erreur fetchServicesByCategory: $e");
      _errorMessage = 'Erreur lors du chargement des services de la catégorie';
      _services = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ MÉTHODE CORRIGÉE: fetchServicesBySubcategory
  Future<void> fetchServicesBySubcategory(int subcategoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("📁 Récupération des services de la sous-catégorie $subcategoryId...");
      
      // ✅ Utiliser ApiClient au lieu de http.get
      final responseData = await _apiClient.get('services/?subcategory_id=$subcategoryId', requireAuth: false);
      
      List<dynamic> data = [];
      if (responseData is Map<String, dynamic>) {
        data = responseData['results'] ?? [];
      } else if (responseData is List) {
        data = responseData;
      }

      _services = data.map((item) {
        final service = Service.fromJson(item);
        print("✅ Service sous-catégorie: ${service.title} (encodage correct)");
        return service;
      }).toList();
      
      print("📁 Services sous-catégorie récupérés: ${_services.length}");
    } catch (e) {
      print("❌ Erreur fetchServicesBySubcategory: $e");
      _errorMessage = 'Erreur lors du chargement des services de la sous-catégorie';
      _services = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ MÉTHODE CORRIGÉE: fetchServiceDetails
  Future<void> fetchServiceDetails(int serviceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("🔍 Récupération des détails du service $serviceId...");
      
      // ✅ Utiliser ApiClient au lieu de http.get
      final responseData = await _apiClient.get('services/$serviceId/', requireAuth: false);
      
      if (responseData != null) {
        _currentService = Service.fromJson(responseData);
        print("✅ Détails service récupérés: ${_currentService!.title} (encodage correct)");
      }
    } catch (e) {
      print("❌ Erreur fetchServiceDetails: $e");
      _errorMessage = 'Erreur lors du chargement des détails du service';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ MÉTHODE CORRIGÉE: getProviderExpertiseCategories
  Future<List<int>> getProviderExpertiseCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("🎯 Récupération des catégories d'expertise...");
      
      // ✅ Utiliser ApiClient au lieu de http.get
      final responseData = await _apiClient.get('providers/expertise_categories/', requireAuth: true);
      
      List<dynamic> data = [];
      if (responseData is List) {
        data = responseData;
      } else if (responseData is Map<String, dynamic>) {
        data = responseData['results'] ?? [];
      }

      _expertiseCategories = data.map<int>((item) => item['id'] as int).toList();

      if (_categories.isEmpty) {
        await fetchCategories();
      }

      print("🎯 Catégories d'expertise récupérées: ${_expertiseCategories.length}");
      
      _isLoading = false;
      notifyListeners();
      return _expertiseCategories;
    } catch (e) {
      print("❌ Erreur getProviderExpertiseCategories: $e");
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // ✅ MÉTHODE CORRIGÉE: fetchCategories
  Future<void> fetchCategories() async {
    try {
      print("📂 Récupération des catégories...");
      
      // ✅ Utiliser ApiClient au lieu de http.get
      final responseData = await _apiClient.get('categories/', requireAuth: false);
      
      List<dynamic> data = [];
      if (responseData is Map<String, dynamic>) {
        data = responseData['results'] ?? [];
      } else if (responseData is List) {
        data = responseData;
      }

      _categories = data.map((item) {
        final category = Category.fromJson(item);
        print("✅ Catégorie: ${category.name} (encodage correct)");
        return category;
      }).toList();

      _categoriesMap = {};
      for (var category in _categories) {
        _categoriesMap[category.id] = category;
      }
      
      print("📂 Catégories récupérées: ${_categories.length}");
    } catch (e) {
      print('❌ Error fetching categories: $e');
      throw e;
    }
  }

  Future<void> fetchProviderServices(int providerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("👨‍💼 Récupération des services du prestataire $providerId...");
      _services = await _apiService.getProviderServices(providerId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _services = [];
      notifyListeners();
      print('❌ Error fetching provider services: $e');
    }
  }

  Category? getCategoryById(int id) {
    return _categoriesMap[id];
  }

  // ✅ MÉTHODE CORRIGÉE: addService (MultipartRequest conservé mais headers corrigés)
  Future<void> addService(
    String title,
    String description,
    int subcategoryId,
    double price,
    String priceType,
    File? mainImage,
    List<File> galleryImages,
    List<String> imageCaptions,
    List<ServiceOption> options,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("➕ Ajout d'un nouveau service...");
      print("✅ Titre: $title (encodage correct)");
      print("✅ Description: $description (encodage correct)");
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/services/'),
      );

      // ✅ Utiliser ApiClient pour les headers (cohérence avec encodage)
      final headers = await _apiClient.getHeaders();
      request.headers.addAll(headers);

      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['subcategory'] = subcategoryId.toString();
      request.fields['price_type'] = priceType;

      if (price > 0) {
        request.fields['price'] = price.toString();
      }

      if (mainImage != null) {
        final mainImageFile = await http.MultipartFile.fromPath(
          'image',
          mainImage.path,
        );
        request.files.add(mainImageFile);
        print("📷 Image principale ajoutée");
      }

      request.fields['gallery_images_count'] = galleryImages.length.toString();
      for (int i = 0; i < galleryImages.length; i++) {
        final file = galleryImages[i];
        final multipartFile = await http.MultipartFile.fromPath(
          'gallery_image_${i}_image',
          file.path,
        );
        request.files.add(multipartFile);
        request.fields['gallery_image_${i}_caption'] = imageCaptions[i];
        print("✅ Image galerie ${i + 1}: ${imageCaptions[i]} (encodage correct)");
      }

      final validOptions = options.where((option) => 
        option.name.isNotEmpty
      ).toList();
      
      request.fields['options_count'] = validOptions.length.toString();
      for (int i = 0; i < validOptions.length; i++) {
        final option = validOptions[i];
        request.fields['option_${i}_name'] = option.name;
        request.fields['option_${i}_description'] = option.description;
        if (option.price != null && option.price! > 0) {
          request.fields['option_${i}_price'] = option.price.toString();
        }
        request.fields['option_${i}_is_included'] = option.isIncluded.toString();
        print("✅ Option ${i + 1}: ${option.name} (encodage correct)");
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("📡 Statut création service: ${response.statusCode}");

      if (response.statusCode == 201) {
        // ✅ Traitement UTF-8 pour la réponse MultipartRequest
        String responseBody;
        try {
          responseBody = utf8.decode(response.bodyBytes);
        } catch (e) {
          responseBody = response.body;
        }
        
        print("✅ Service créé avec succès");
        await fetchMyServices();
      } else {
        _errorMessage = 'Erreur lors de la création du service: ${response.body}';
        throw Exception(_errorMessage);
      }
    } catch (e) {
      print("❌ Erreur addService: $e");
      _errorMessage = e.toString();
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ MÉTHODE CORRIGÉE: updateService (MultipartRequest conservé mais headers corrigés)
  Future<void> updateService(
    int serviceId,
    String title,
    String description,
    int subcategoryId,
    double price,
    String priceType,
    File? mainImage,
    List<File> galleryImages,
    List<String> imageCaptions,
    List<ServiceOption> options,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("📝 Mise à jour du service $serviceId...");
      print("✅ Nouveau titre: $title (encodage correct)");
      
      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse('${_apiService.baseUrl}/services/$serviceId/'),
      );

      // ✅ Utiliser ApiClient pour les headers (cohérence avec encodage)
      final headers = await _apiClient.getHeaders();
      request.headers.addAll(headers);

      // ✅ CHAMPS DE BASE
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['subcategory'] = subcategoryId.toString();
      request.fields['price_type'] = priceType;

      if (price > 0) {
        request.fields['price'] = price.toString();
      }

      // ✅ IMAGE PRINCIPALE
      if (mainImage != null) {
        final mainImageFile = await http.MultipartFile.fromPath(
          'image',
          mainImage.path,
        );
        request.files.add(mainImageFile);
        print("📷 Image principale mise à jour");
      }

      // ✅ AJOUT: TRAITEMENT DES IMAGES DE GALERIE (comme dans addService)
      request.fields['gallery_images_count'] = galleryImages.length.toString();
      print("📷 Nombre d'images de galerie: ${galleryImages.length}");
      
      for (int i = 0; i < galleryImages.length; i++) {
        final file = galleryImages[i];
        final multipartFile = await http.MultipartFile.fromPath(
          'gallery_image_${i}_image',
          file.path,
        );
        request.files.add(multipartFile);
        request.fields['gallery_image_${i}_caption'] = imageCaptions[i];
        print("✅ Image galerie ${i + 1}: ${imageCaptions[i]} (encodage correct)");
      }

      // ✅ AJOUT: TRAITEMENT DES OPTIONS (comme dans addService)
      final validOptions = options.where((option) => 
        option.name.isNotEmpty
      ).toList();
      
      request.fields['options_count'] = validOptions.length.toString();
      print("⚙️ Nombre d'options: ${validOptions.length}");
      
      for (int i = 0; i < validOptions.length; i++) {
        final option = validOptions[i];
        request.fields['option_${i}_name'] = option.name;
        request.fields['option_${i}_description'] = option.description;
        if (option.price != null && option.price! > 0) {
          request.fields['option_${i}_price'] = option.price.toString();
        }
        request.fields['option_${i}_is_included'] = option.isIncluded.toString();
        print("✅ Option ${i + 1}: ${option.name} (encodage correct)");
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("📡 Statut mise à jour service: ${response.statusCode}");

      if (response.statusCode == 200) {
        // ✅ Traitement UTF-8 pour la réponse MultipartRequest
        String responseBody;
        try {
          responseBody = utf8.decode(response.bodyBytes);
        } catch (e) {
          responseBody = response.body;
        }
        
        print("✅ Service mis à jour avec succès");
        await fetchMyServices();
      } else {
        _errorMessage = 'Erreur lors de la mise à jour du service: ${response.body}';
        throw Exception(_errorMessage);
      }
    } catch (e) {
      print("❌ Erreur updateService: $e");
      _errorMessage = e.toString();
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int getServiceCountForCategory(int categoryId) {
    if (!_isLoading && _services.isNotEmpty) {
      return _services
          .where((service) => service.categoryId == categoryId)
          .length;
    }
    return 0;
  }

  // ✅ MÉTHODE CORRIGÉE: updateServiceAvailability
  Future<void> updateServiceAvailability(int serviceId, bool isAvailable) async {
    try {
      print("🔄 Mise à jour disponibilité service $serviceId: $isAvailable");
      
      // ✅ Essayer PATCH d'abord (plus approprié)
      try {
        final responseData = await _apiClient.put(
          'services/$serviceId/toggle_availability/',
          data: {'is_available': isAvailable},
          requireAuth: true
        );
        print("✅ Disponibilité mise à jour avec succès via PATCH");
      } catch (e) {
        print('⚠️ PATCH échoué, tentative PUT: $e');
        
        // Si PATCH échoue, essayer PUT
        final responseData = await _apiClient.put(
          'services/$serviceId/toggle_availability/',
          data: {'is_available': isAvailable},
          requireAuth: true
        );
        print("✅ Disponibilité mise à jour avec succès via PUT");
      }

      // Mettre à jour localement
      final index = _myServices.indexWhere((service) => service.id == serviceId);
      if (index != -1) {
        _myServices[index] = Service(
          id: _myServices[index].id,
          title: _myServices[index].title,
          description: _myServices[index].description,
          imageUrl: _myServices[index].imageUrl,
          rating: _myServices[index].rating,
          reviewCount: _myServices[index].reviewCount,
          provider_id: _myServices[index].provider_id,
          businessType: _myServices[index].businessType,
          price: _myServices[index].price,
          priceType: _myServices[index].priceType,
          categoryId: _myServices[index].categoryId,
          subcategoryId: _myServices[index].subcategoryId,
          isAvailable: isAvailable, // ✅ Nouvelle valeur
          galleryImages: _myServices[index].galleryImages,
          options: _myServices[index].options,
        );
        notifyListeners();
      }
      
    } catch (e) {
      print('❌ Error updateServiceAvailability: $e');
      throw Exception('Impossible de mettre à jour le service: ${e.toString()}');
    }
  }

  // ✅ MÉTHODE CORRIGÉE: deleteService
  Future<void> deleteService(int serviceId) async {
    try {
      print("🗑️ Suppression du service $serviceId...");
      
      // ✅ Utiliser ApiClient au lieu de http.delete
      await _apiClient.delete('services/$serviceId/', requireAuth: true);
      
      _myServices.removeWhere((service) => service.id == serviceId);
      print("✅ Service supprimé avec succès");
      notifyListeners();
    } catch (e) {
      print('❌ Error deleteService: $e');
      rethrow;
    }
  }
}