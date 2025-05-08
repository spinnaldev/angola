// lib/providers/service_provider.dart - Ajouter des méthodes pour gérer les services du prestataire

import 'dart:io';
import 'package:flutter/material.dart';
import '../core/models/service.dart';
import '../core/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class ServiceProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Service> _services = [];
  List<Service> _myServices = []; // Services du prestataire connecté
  Service? _currentService;
  bool _isLoading = false;
  String? _errorMessage;

  ServiceProvider(this._apiService);

  List<Service> get services => _services;
  List<Service> get myServices => _myServices;
  Service? get currentService => _currentService;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Méthodes existantes...

  // Récupérer les services du prestataire connecté
  Future<void> fetchMyServices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${_apiService.baseUrl}/services/my_services/'),
        headers: await _apiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['results'] ?? [];
        _myServices = data.map((item) => Service.fromJson(item)).toList();
      } else {
        _errorMessage = 'Erreur lors du chargement des services';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchServicesByCategory(int categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${_apiService.baseUrl}/services/?category_id=$categoryId'),
        headers: await _apiService.getHeaders(requireAuth: false),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['results'] ?? [];
        _services = data.map((item) => Service.fromJson(item)).toList();
      } else {
        _errorMessage =
            'Erreur lors du chargement des services de la catégorie';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Méthodes pour récupérer les services par sous-catégorie
  Future<void> fetchServicesBySubcategory(int subcategoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(
            '${_apiService.baseUrl}/services/?subcategory_id=$subcategoryId'),
        headers: await _apiService.getHeaders(requireAuth: false),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['results'] ?? [];
        _services = data.map((item) => Service.fromJson(item)).toList();
      } else {
        _errorMessage =
            'Erreur lors du chargement des services de la sous-catégorie';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Méthode pour récupérer les détails d'un service
  Future<void> fetchServiceDetails(int serviceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${_apiService.baseUrl}/services/$serviceId/'),
        headers: await _apiService.getHeaders(requireAuth: false),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentService = Service.fromJson(data);
      } else {
        _errorMessage = 'Erreur lors du chargement des détails du service';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Ajouter un nouveau service
  Future<void> addService(
    String title,
    String description,
    int subcategoryId,
    double price,
    String priceType,
    File? imageFile,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Utiliser un MultipartRequest pour envoyer l'image
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/services/'),
      );

      // Ajouter les headers d'authentification
      final headers = await _apiService.getHeaders();
      request.headers.addAll(headers);

      // Ajouter les champs du formulaire
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['subcategory'] = subcategoryId.toString();
      request.fields['price_type'] = priceType;

      if (price > 0) {
        request.fields['price'] = price.toString();
      }

      // Ajouter l'image si elle existe
      if (imageFile != null) {
        print("Ajout de l'image au formulaire: ${imageFile.path}");
        final fileName = imageFile.path.split('/').last;
        final fileExtension = fileName.split('.').last.toLowerCase();
        
        request.files.add(
          http.MultipartFile(
            'image',
            imageFile.readAsBytes().asStream(),
            imageFile.lengthSync(),
            filename: fileName,
            contentType: MediaType('image', fileExtension),
          ),
        );
        print("Image ajoutée à la requête");
      } else {
        print("Aucune image à ajouter");
      }

      // Envoyer la requête
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        // Service créé avec succès, mettre à jour la liste des services
        await fetchMyServices();
      } else {
        _errorMessage =
            'Erreur lors de la création du service: ${response.body}';
        throw Exception(_errorMessage);
      }
    } catch (e) {
      _errorMessage = e.toString();
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mettre à jour un service existant
  Future<void> updateService(
    int serviceId,
    String title,
    String description,
    int subcategoryId,
    double price,
    String priceType,
    File? imageFile,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Utiliser un MultipartRequest pour envoyer l'image
      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse('${_apiService.baseUrl}/services/$serviceId/'),
      );

      // Ajouter les headers d'authentification
      final headers = await _apiService.getHeaders();
      request.headers.addAll(headers);

      // Ajouter les champs du formulaire
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['subcategory'] = subcategoryId.toString();
      request.fields['price_type'] = priceType;

      if (price > 0) {
        request.fields['price'] = price.toString();
      }

      // Ajouter l'image si elle existe
      if (imageFile != null) {
        final fileName = imageFile.path.split('/').last;
        final fileExtension = fileName.split('.').last.toLowerCase();

        request.files.add(
          http.MultipartFile(
            'image',
            imageFile.readAsBytes().asStream(),
            imageFile.lengthSync(),
            filename: fileName,
            contentType: MediaType('image', fileExtension),
          ),
        );
      }

      // Envoyer la requête
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Service mis à jour avec succès, mettre à jour la liste des services
        await fetchMyServices();
      } else {
        _errorMessage =
            'Erreur lors de la mise à jour du service: ${response.body}';
        throw Exception(_errorMessage);
      }
    } catch (e) {
      _errorMessage = e.toString();
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  int getServiceCountForCategory(int categoryId) {
    // Si les services ont déjà été chargés, comptez-les
    if (!_isLoading && _services.isNotEmpty) {
      return _services.where((service) => service.categoryId == categoryId).length;
    }
    
    // Sinon, il faut faire un appel API (implémentation simplifiée)
    // Dans une implémentation réelle, vous feriez probablement un appel API asynchrone
    return 0;  // Par défaut, retourne 0
  }
  // Mettre à jour la disponibilité d'un service
  Future<void> updateServiceAvailability(
      int serviceId, bool isAvailable) async {
    try {
      final response = await http.patch(
        Uri.parse('${_apiService.baseUrl}/services/$serviceId/'),
        headers: await _apiService.getHeaders(),
        body: json.encode({
          'is_available': isAvailable,
        }),
      );

      if (response.statusCode == 200) {
        // Mettre à jour localement
        final index =
            _myServices.indexWhere((service) => service.id == serviceId);
        if (index != -1) {
          _myServices[index] = Service(
            id: _myServices[index].id,
            title: _myServices[index].title,
            description: _myServices[index].description,
            imageUrl: _myServices[index].imageUrl,
            rating: _myServices[index].rating,
            reviewCount: _myServices[index].reviewCount,
            providerId: _myServices[index].providerId,
            businessType: _myServices[index].businessType,
            price: _myServices[index].price,
            priceType: _myServices[index].priceType,
            categoryId: _myServices[index].categoryId,
            subcategoryId: _myServices[index].subcategoryId,
            isAvailable: isAvailable,
          );
          notifyListeners();
        }
      } else {
        throw Exception('Erreur lors de la mise à jour de la disponibilité');
      }
    } catch (e) {
      print('Error updateServiceAvailability: $e');
      rethrow;
    }
  }

  // Supprimer un service
  Future<void> deleteService(int serviceId) async {
    try {
      final response = await http.delete(
        Uri.parse('${_apiService.baseUrl}/services/$serviceId/'),
        headers: await _apiService.getHeaders(),
      );

      if (response.statusCode == 204) {
        // Supprimer localement
        _myServices.removeWhere((service) => service.id == serviceId);
        notifyListeners();
      } else {
        throw Exception('Erreur lors de la suppression du service');
      }
    } catch (e) {
      print('Error deleteService: $e');
      rethrow;
    }
  }
}
