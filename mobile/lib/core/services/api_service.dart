import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/subcategory.dart';
import '../models/service.dart';
import '../models/provider_model.dart';
import '../models/review.dart';
import '../models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/project.dart';
import '../models/client_project.dart';
import '../models/project.dart';
import '../models/project_offer.dart';
import '../models/project_skill.dart';
import '../models/project_stats.dart';

class ApiService {
  final String baseUrl;
  final String apiKey;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ApiService({
    required this.baseUrl,
    required this.apiKey,
  });
  // Méthode pour récupérer les tokens
  Future<String?> _getToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  // Créer les en-têtes avec authentification si nécessaire
  Future<Map<String, String>> getHeaders({bool requireAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final token = await _secureStorage.read(key: 'access_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Obtenir le profil utilisateur courant
  Future<User> getCurrentUser() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/me/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        // En cas d'erreur, retourner des données de test
        return _getMockUser();
      }
    } catch (e) {
      print('Error in getCurrentUser: $e');
      // En cas d'exception, retourner des données de test
      return _getMockUser();
    }
  }

  // Récupérer les services récents
  // Future<List<Service>> getRecentServices() async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse('$baseUrl/services/recent/'),
  //       headers: await getHeaders(requireAuth: false),
  //     );

  //     if (response.statusCode == 200) {
  //       final List<dynamic> data = json.decode(response.body)['results'] ?? [];
  //       return data.map((item) => Service.fromJson(item)).toList();
  //     } else {
  //       throw Exception('Failed to load recent services');
  //     }
  //   } catch (e) {
  //     print('Error in getRecentServices: $e');
  //     // Retourner des données de test en cas d'erreur
  //     return _getMockServices();
  //   }
  // }

  // Récupérer les services à proximité
  Future<List<Service>> getNearbyServices() async {
    try {
      // Si l'utilisateur a fourni sa localisation, on l'utilise pour obtenir les services à proximité
      final position = await _getCurrentPosition();

      String url = '$baseUrl/services/nearby/';
      if (position != null) {
        url += '?latitude=${position.latitude}&longitude=${position.longitude}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await getHeaders(requireAuth: false),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['results'] ?? [];
        return data.map((item) => Service.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load nearby services');
      }
    } catch (e) {
      print('Error in getNearbyServices: $e');
      // Retourner des données de test en cas d'erreur
      return _getMockServices();
    }
  }

  // Méthode pour obtenir la position actuelle de l'utilisateur (à implémenter avec un package de géolocalisation)
  Future<Position?> _getCurrentPosition() async {
    try {
      // Implémenter avec package geolocator
      return null;
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  // Méthodes pour les prestataires
  Future<List<ProviderModel>> getProviders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/providers/'),
        headers: await getHeaders(requireAuth: false),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['results'] ?? [];
        return data.map((item) => ProviderModel.fromJson(item)).toList();
      } else {
        // En cas d'erreur, retourner des données de test
        return _getMockProviders();
      }
    } catch (e) {
      print('Erreur getProviders: $e');
      // En cas d'erreur, retourner des données de test
      return _getMockProviders();
    }
  }

  Future<List<ProviderModel>> getProvidersByCategory(int categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/providers/by_category/?category_id=$categoryId'),
        headers: await getHeaders(requireAuth: false),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['results'] ?? [];
        return data.map((item) => ProviderModel.fromJson(item)).toList();
      } else {
        // En cas d'erreur, retourner des données de test filtrées
        return _getMockProviders()
            .where((p) => p.id % 5 == categoryId % 5)
            .toList();
      }
    } catch (e) {
      print('Erreur getProvidersByCategory: $e');
      // En cas d'erreur, retourner des données de test filtrées
      return _getMockProviders()
          .where((p) => p.id % 5 == categoryId % 5)
          .toList();
    }
  }

  Future<List<ProviderModel>> getProvidersBySubcategory(
      int subcategoryId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/providers/by_subcategory/?subcategory_id=$subcategoryId'),
        headers: await getHeaders(requireAuth: false),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['results'] ?? [];
        return data.map((item) => ProviderModel.fromJson(item)).toList();
      } else {
        // En cas d'erreur, retourner des données de test filtrées
        return _getMockProviders()
            .where((p) => p.id % 10 == subcategoryId % 10)
            .toList();
      }
    } catch (e) {
      print('Erreur getProvidersBySubcategory: $e');
      // En cas d'erreur, retourner des données de test filtrées
      return _getMockProviders()
          .where((p) => p.id % 10 == subcategoryId % 10)
          .toList();
    }
  }

  Future<List<ProviderModel>> getNearbyProviders(
      double latitude, double longitude,
      {double radius = 10.0}) async {
    try {
      final queryParams = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius.toString(),
      };

      final uri = Uri.parse('$baseUrl/providers/nearby/')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: await getHeaders(requireAuth: false),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['results'] ?? [];
        return data.map((item) => ProviderModel.fromJson(item)).toList();
      } else {
        // En cas d'erreur, retourner des données de test avec coordonnées aléatoires
        return _getMockProvidersWithCoordinates(latitude, longitude);
      }
    } catch (e) {
      print('Erreur getNearbyProviders: $e');
      // En cas d'erreur, retourner des données de test
      return _getMockProvidersWithCoordinates(latitude, longitude);
    }
  }

  // Obtenir les projets de l'utilisateur
  Future<List<Project>> getUserProjects() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/projects/user/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['results'] ?? [];
        return data.map((item) => Project.fromJson(item)).toList();
      } else {
        // En cas d'erreur, retourner des données de test
        return _getMockProjects();
      }
    } catch (e) {
      print('Error in getUserProjects: $e');
      // En cas d'exception, retourner des données de test
      return _getMockProjects();
    }
  }

  // Méthodes pour générer des données de test
  List<ProviderModel> _getMockProviders() {
    return List.generate(10, (index) {
      return ProviderModel(
        id: index + 1,
        name: 'Prestataire ${index + 1}',
        businessType: index % 2 == 0 ? 'Entreprise' : 'Freelance',
        profileImageUrl:
            'https://randomuser.me/api/portraits/${index % 2 == 0 ? 'men' : 'women'}/${index + 1}.jpg',
        rating: 3.0 + (index % 5) * 0.5,
        reviewCount: 5 + index * 3,
        description:
            'Description du prestataire ${index + 1}. Service de qualité proposé par des professionnels expérimentés.',
        services: List.generate(
            3,
            (i) => ServiceItem(
                  id: i + 1,
                  title: 'Service ${i + 1}',
                  priceType: i % 2 == 0 ? 'fixed' : 'quote',
                )),
      );
    });
  }

  List<ProviderModel> _getMockProvidersWithCoordinates(
      double centerLatitude, double centerLongitude) {
    final random = math.Random();

    return List.generate(10, (index) {
      // Générer des coordonnées aléatoires dans un rayon de 5km
      final latOffset = (random.nextDouble() - 0.5) * 0.1; // ~5km
      final lngOffset = (random.nextDouble() - 0.5) * 0.1; // ~5km

      return ProviderModel(
        id: index + 1,
        name: 'Prestataire ${index + 1}',
        businessType: index % 2 == 0 ? 'Entreprise' : 'Freelance',
        profileImageUrl:
            'https://randomuser.me/api/portraits/${index % 2 == 0 ? 'men' : 'women'}/${index + 1}.jpg',
        rating: 3.0 + (index % 5) * 0.5,
        reviewCount: 5 + index * 3,
        description:
            'Description du prestataire ${index + 1}. Service de qualité proposé par des professionnels expérimentés.',
        services: List.generate(
            3,
            (i) => ServiceItem(
                  id: i + 1,
                  title: 'Service ${i + 1}',
                  priceType: i % 2 == 0 ? 'fixed' : 'quote',
                )),
        latitude: centerLatitude + latOffset,
        longitude: centerLongitude + lngOffset,
        address: 'Adresse du prestataire ${index + 1}, Cotonou',
      );
    });
  }

  // Méthodes de mock pour données de test
  User _getMockUser() {
    return User(
      id: 1,
      username: 'bryan_cooper',
      email: 'bryan.cooper@example.com',
      firstName: 'Bryan',
      lastName: 'Cooper',
      phoneNumber: '+2345678901',
      bio: 'Client à la recherche de services de qualité',
      profilePicture: 'https://randomuser.me/api/portraits/men/32.jpg',
      role: 'client',
      isVerified: true,
      location: 'Angola',
      dateJoined: DateTime.parse('2025-03-15T00:00:00Z'),
    );
  }

  List<Project> _getMockProjects() {
    return [
      Project(
        id: 1,
        title: 'Rénovation maison',
        description:
            'Je recherche une entreprise capable de gérer l\'ensemble de la construction, y compris la conception, le choix des matériaux, la main-d\'œuvre et le respect des délais.',
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

  // Obtenir toutes les catégories
  Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/'),
        headers: {
          // 'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['results'] ?? [];
        return data.map((item) => Category.fromJson(item)).toList();
      } else {
        // En cas d'erreur, retourner des données de test
        return _getMockCategories();
      }
    } catch (e) {
      print('Error in getCategories: $e');
      // En cas d'exception, retourner des données de test
      return _getMockCategories();
    }
  }

  // Obtenir les sous-catégories d'une catégorie
  Future<List<Subcategory>> getSubcategories(int categoryId) async {
    try {
      print(categoryId);
      final response = await http.get(
        Uri.parse('$baseUrl/subcategories/?category_id=$categoryId'),
        headers: {
          // 'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data =
            json.decode(utf8.decode(response.bodyBytes))['results'] ?? [];
        print('Les données recuperes sont : $data');
        return data.map((item) => Subcategory.fromJson(item)).toList();
      } else {
        // En cas d'erreur, retourner des données de test
        return _getMockSubcategories(categoryId);
      }
    } catch (e) {
      print('Error in getSubcategories: $e');
      // En cas d'exception, retourner des données de test
      return _getMockSubcategories(categoryId);
    }
  }

  Future<int> getServiceCountByCategory(int categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/services/count/?category_id=$categoryId'),
        headers: {
          // 'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      } else {
        // En cas d'erreur, retourner le résultat d'une méthode mock
        return _getMockServiceCountByCategory(categoryId);
      }
    } catch (e) {
      print('Error in getServiceCountByCategory: $e');
      // En cas d'exception, retourner le résultat d'une méthode mock
      return _getMockServiceCountByCategory(categoryId);
    }
  }

  Future<int> getCurrentUserId() async {
    try {
      // Récupérer l'utilisateur courant depuis le stockage local
      final user = await getCurrentUser();
      if (user != null) {
        return user.id;
      }

      // Si l'utilisateur n'est pas disponible localement
      throw Exception("Utilisateur non connecté");
    } catch (e) {
      print('Error in getCurrentUserId: $e');
      throw e;
    }
  }

  Future<List<Conversation>> getConversations() async {
    try {
      // Récupérer l'ID de l'utilisateur courant
      final userId = await getCurrentUserId();

      final response = await http.get(
        Uri.parse('$baseUrl/conversations/?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['results'] ?? [];
        return data.map((item) => Conversation.fromJson(item, userId)).toList();
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to load conversations: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getConversations: $e');
      return []; // Retourner une liste vide en cas d'erreur
    }
  }

  Future<List<Message>> getMessages(int conversationId) async {
    try {
      // Récupérer l'ID de l'utilisateur courant
      final userId = await getCurrentUserId();

      final response = await http.get(
        Uri.parse(
            '$baseUrl/conversations/$conversationId/messages/?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['results'] ?? [];
        return data.map((item) => Message.fromJson(item, userId)).toList();
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getMessages: $e');
      return []; // Retourner une liste vide en cas d'erreur
    }
  }

  Future<Message> sendMessage(int conversationId, String content) async {
    try {
      // Récupérer l'ID de l'utilisateur courant
      final userId = await getCurrentUserId();

      final response = await http.post(
        Uri.parse('$baseUrl/conversations/$conversationId/send_message/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'content': content,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return Message.fromJson(data, userId);
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in sendMessage: $e');
      throw e;
    }
  }

  Future<Conversation> startConversation(
      int providerId, String? initialMessage) async {
    try {
      // Récupérer l'ID de l'utilisateur courant
      final userId = await getCurrentUserId();

      final Map<String, dynamic> data = {
        'user_id': userId,
        'provider_id': providerId,
      };

      if (initialMessage != null && initialMessage.isNotEmpty) {
        data['message'] = initialMessage;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/conversations/start/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return Conversation.fromJson(responseData, userId);
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to start conversation: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in startConversation: $e');
      throw e;
    }
  }

  Future<Message?> getInitialMessage(int conversationId) async {
    try {
      final messages = await getMessages(conversationId);
      if (messages.isNotEmpty) {
        return messages.first;
      }
      return null;
    } catch (e) {
      print('Error in getInitialMessage: $e');
      return null;
    }
  }

  Future<bool> markMessagesAsRead(int conversationId) async {
    try {
      // Récupérer l'ID de l'utilisateur courant
      final userId = await getCurrentUserId();

      final response = await http.post(
        Uri.parse('$baseUrl/conversations/$conversationId/mark_read/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error in markMessagesAsRead: $e');
      return false;
    }
  }

  Future<int> getUnreadNotificationCount() async {
    try {
      // Récupérer l'ID de l'utilisateur courant
      final userId = await getCurrentUserId();

      final response = await http.get(
        Uri.parse('$baseUrl/notifications/count/?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      } else {
        print('Error response: ${response.body}');
        return 0;
      }
    } catch (e) {
      print('Error in getUnreadNotificationCount: $e');
      return 0; // En cas d'erreur, retourner 0 comme valeur par défaut
    }
  }

  Future<bool> markAllNotificationsAsRead() async {
    try {
      // Récupérer l'ID de l'utilisateur courant
      final userId = await getCurrentUserId();

      final response = await http.post(
        Uri.parse('$baseUrl/notifications/mark_all_read/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error in markAllNotificationsAsRead: $e');
      return false;
    }
  }

// Méthode mock pour fournir des nombres fictifs en cas d'erreur
  int _getMockServiceCountByCategory(int categoryId) {
    // Associer à chaque catégorie un nombre fictif
    final Map<int, int> mockCounts = {
      1: 11, // Maison & Construction
      2: 5, // Bien-être & Beauté
      3: 6, // Événements & Artistiques
      4: 4, // Transport & Logistique
      5: 3, // Santé & Bien-être
      6: 5, // Services Professionnels & Formation
      7: 4, // Services Numériques & Technologiques
      8: 3, // Services pour Animaux
      9: 3, // Services Divers
    };

    return mockCounts[categoryId] ?? 0;
  }

  // Obtenir les services d'une catégorie
  Future<List<Service>> getServicesByCategory(int categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/services/?category_id=$categoryId'),
        headers: {
          // 'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['results'] ?? [];
        return data.map((item) => Service.fromJson(item)).toList();
      } else {
        // En cas d'erreur, retourner des données de test
        return _getMockServices();
      }
    } catch (e) {
      print('Error in getServicesByCategory: $e');
      // En cas d'exception, retourner des données de test
      return _getMockServices();
    }
  }

  // Obtenir les services d'une sous-catégorie
  Future<List<Service>> getServicesBySubcategory(int subcategoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/services/?subcategory_id=$subcategoryId'),
        headers: {
          // 'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['results'] ?? [];
        return data.map((item) => Service.fromJson(item)).toList();
      } else {
        // En cas d'erreur, retourner des données de test
        return _getMockServices();
      }
    } catch (e) {
      print('Error in getServicesBySubcategory: $e');
      // En cas d'exception, retourner des données de test
      return _getMockServices();
    }
  }

  // Obtenir les détails d'un service
  Future<Service> getServiceDetails(int serviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/services/$serviceId/'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return Service.fromJson(data);
      } else {
        // En cas d'erreur, retourner des données de test
        return _getMockServiceDetails(serviceId);
      }
    } catch (e) {
      print('Error in getServiceDetails: $e');
      // En cas d'exception, retourner des données de test
      return _getMockServiceDetails(serviceId);
    }
  }

  // Obtenir les détails d'un prestataire
  Future<ProviderModel> getProviderDetails(int providerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/providers/$providerId/'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return ProviderModel.fromJson(data);
      } else {
        // En cas d'erreur, retourner des données de test
        return _getMockProviderDetails(providerId);
      }
    } catch (e) {
      print('Error in getProviderDetails: $e');
      // En cas d'exception, retourner des données de test
      return _getMockProviderDetails(providerId);
    }
  }

  // Obtenir un prestataire par l'ID d'un service
  Future<ProviderModel> getProviderByServiceId(int serviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/providers/by-service/$serviceId/'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return ProviderModel.fromJson(data);
      } else {
        // En cas d'erreur, retourner des données de test
        return _getMockProviderByService(serviceId);
      }
    } catch (e) {
      print('Error in getProviderByServiceId: $e');
      // En cas d'exception, retourner des données de test
      return _getMockProviderByService(serviceId);
    }
  }

  // Obtenir les avis d'un prestataire
  Future<List<Review>> getProviderReviews(int providerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/?provider_id=$providerId'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['results'] ?? [];
        return data.map((item) => Review.fromJson(item)).toList();
      } else {
        // En cas d'erreur, retourner des données de test
        return [];
      }
    } catch (e) {
      print("non non l'erreur vient d'ici");

      print('Error in getProviderReviews: $e');
      // En cas d'exception, retourner des données de test
      return [];
    }
  }

// Ajouter cette méthode à votre class ApiService dans le fichier api_service.dart

  Future<int> getServiceCountBySubcategory(int subcategoryId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/services/count_by_subcategory/?subcategory_id=$subcategoryId'),
        headers: {
          // 'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      } else {
        // En cas d'erreur, retourner le résultat d'une méthode mock
        return _getMockServiceCountBySubcategory(subcategoryId);
      }
    } catch (e) {
      print('Error in getServiceCountBySubcategory: $e');
      // En cas d'exception, retourner le résultat d'une méthode mock
      return _getMockServiceCountBySubcategory(subcategoryId);
    }
  }

  // Méthode mock pour fournir des nombres fictifs en cas d'erreur
  int _getMockServiceCountBySubcategory(int subcategoryId) {
    // Associer à chaque sous-catégorie un nombre fictif de services
    final Map<int, int> mockCounts = {
      1: 5, // Construction & rénovation
      2: 3, // Plomberie
      3: 4, // Électricité
      4: 2, // Menuiserie & Ébénisterie
      5: 3, // Peinture & Décoration
      6: 2, // Paysagisme & Jardinage
      7: 1, // Serrurerie
      8: 2, // Ménage & Nettoyage
      9: 1, // Pest Control
      10: 1, // Vitrerie & Fenêtres
      11: 2, // Froid & Climatisation
      12: 3, // Coiffure & Barbier
      13: 2, // Esthétique & Maquillage
      14: 2, // Massages & Thérapies
      15: 1, // Fitness & Coaching Sportif
      16: 1, // Nutrition & Diététique
      17: 2, // Photographie & Vidéographie
      18: 3, // Organisation d'événements
      19: 2, // Traiteur & Chef à domicile
      20: 2, // Animation & Spectacle
      21: 1, // Location de matériel
      22: 2, // Fleuristes & Décoration florale
    };

    return mockCounts[subcategoryId] ?? 0;
  }
  // --- Méthodes pour générer des données de test ---

  // --- Méthodes pour générer des données de test ---

  List<Category> _getMockCategories() {
    return [
      Category(
        id: 1,
        name: 'Maison & Construction',
        imageUrl: 'https://picsum.photos/id/1018/300/200',
        description: 'Services de construction et rénovation',
      ),
      Category(
        id: 2,
        name: 'Bien-être & Beauté',
        imageUrl: 'https://picsum.photos/id/64/300/200',
        description: 'Services de beauté et bien-être',
      ),
      Category(
        id: 3,
        name: 'Événements & Artistiques',
        imageUrl: 'https://picsum.photos/id/1058/300/200',
        description: 'Services liés aux événements et à l\'art',
      ),
      Category(
        id: 4,
        name: 'Transports & Logistiques',
        imageUrl: 'https://picsum.photos/id/1072/300/200',
        description: 'Services de transport et logistique',
      ),
      Category(
        id: 5,
        name: 'Services Professionnels',
        imageUrl: 'https://picsum.photos/id/1066/300/200',
        description: 'Services professionnels divers',
      ),
      Category(
        id: 6,
        name: 'Cours & Formation',
        imageUrl: 'https://picsum.photos/id/20/300/200',
        description: 'Services d\'éducation et formation',
      ),
    ];
  }

  List<Subcategory> _getMockSubcategories(int categoryId) {
    if (categoryId == 1) {
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
      ];
    } else {
      return [
        Subcategory(
          id: 4,
          name: 'Sous-catégorie 1',
          categoryId: categoryId,
          description: 'Description sous-catégorie 1',
        ),
        Subcategory(
          id: 5,
          name: 'Sous-catégorie 2',
          categoryId: categoryId,
          description: 'Description sous-catégorie 2',
        ),
      ];
    }
  }

  List<Service> _getMockServices() {
    return [
      Service(
        id: 1,
        title: 'MICC Services',
        description: 'Entreprise de maçonnerie',
        imageUrl: 'https://picsum.photos/id/1029/300/200',
        rating: 4.5,
        reviewCount: 27,
        provider_id: 1,
        categoryId: 1,
        businessType: 'Entreprise',
        price: 80.0,
      ),
      Service(
        id: 2,
        title: 'MICC Services',
        description: 'Entreprise de maçonnerie',
        imageUrl: 'https://picsum.photos/id/1040/300/200',
        rating: 3.8,
        reviewCount: 15,
        provider_id: 2,
        categoryId: 1,
        businessType: 'Entreprise',
        price: 75.0,
      ),
      Service(
        id: 3,
        title: 'MICC Services',
        description: 'Entreprise de maçonnerie',
        imageUrl: 'https://picsum.photos/id/1076/300/200',
        rating: 5.0,
        reviewCount: 21,
        provider_id: 3,
        categoryId: 1,
        businessType: 'Entreprise',
        price: 120.0,
      ),
      Service(
        id: 4,
        title: 'MICC Services',
        description: 'Entreprise de maçonnerie',
        imageUrl: 'https://picsum.photos/id/1079/300/200',
        rating: 4.2,
        reviewCount: 18,
        provider_id: 4,
        categoryId: 1,
        businessType: 'Entreprise',
        price: 90.0,
      ),
      Service(
        id: 5,
        title: 'MICC Services',
        description: 'Entreprise de maçonnerie',
        imageUrl: 'https://picsum.photos/id/1082/300/200',
        rating: 3.5,
        reviewCount: 12,
        provider_id: 5,
        categoryId: 1,
        businessType: 'Freelance',
        price: 65.0,
      ),
    ];
  }

  Service _getMockServiceDetails(int serviceId) {
    return Service(
      id: serviceId,
      title: 'MICC Services',
      description:
          'Entreprise spécialisée dans la maçonnerie et les travaux de rénovation.',
      imageUrl: 'https://picsum.photos/id/1029/600/400',
      rating: 4.5,
      reviewCount: 27,
      provider_id: 1,
      categoryId: 1,
      businessType: 'Entreprise',
      price: 80.0,
    );
  }

  ProviderModel _getMockProviderDetails(int providerId) {
    return ProviderModel(
      id: providerId,
      name: 'Martin Construction',
      businessType: 'Entreprise générale du bâtiment',
      profileImageUrl:
          'https://randomuser.me/api/portraits/men/$providerId.jpg',
      rating: 4.5,
      reviewCount: 127,
      description:
          'Spécialiste dans les travaux de construction, rénovation et aménagement. Notre équipe qualifiée intervient sur tout type de chantier avec un engagement fort autour de la qualité des finitions et le respect des délais.',
      services: [
        ServiceItem(
          id: 1,
          title: 'Construction neuve',
          priceType: 'Sur devis',
        ),
        ServiceItem(
          id: 2,
          title:
              'Construction complète de maisons individuelles et bâtiments professionnels',
          priceType: 'Sur devis',
        ),
        ServiceItem(
          id: 3,
          title: 'Rénovation',
          priceType: 'Sur devis',
        ),
      ],
    );
  }

  ProviderModel _getMockProviderByService(int serviceId) {
    return ProviderModel(
      id: 1,
      name: 'Martin Construction',
      businessType: 'Entreprise générale du bâtiment',
      profileImageUrl: 'https://randomuser.me/api/portraits/men/22.jpg',
      rating: 4.5,
      reviewCount: 127,
      description:
          'Spécialiste dans les travaux de construction, rénovation et aménagement. Notre équipe qualifiée intervient sur tout type de chantier avec un engagement fort autour de la qualité des finitions et le respect des délais.',
      services: [
        ServiceItem(
          id: 1,
          title: 'Construction neuve',
          priceType: 'Sur devis',
        ),
        ServiceItem(
          id: 2,
          title:
              'Construction complète de maisons individuelles et bâtiments professionnels',
          priceType: 'Sur devis',
        ),
        ServiceItem(
          id: 3,
          title: 'Rénovation',
          priceType: 'Sur devis',
        ),
      ],
    );
  }

  Future<List<Service>> getProviderServices(int providerId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('${baseUrl}/services/?provider_id=$providerId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['results'] ?? [];
        return data.map((item) => Service.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load provider services: ${response.body}');
      }
    } catch (e) {
      print('Error in getProviderServices: $e');
      // En cas d'échec, retourner une liste vide ou autre gestion d'erreur
      return [];
    }
  }

  /// Récupérer la liste des projets avec filtres
  // Future<Map<String, dynamic>> getProjects(
  //     [Map<String, dynamic>? filters]) async {
  //   try {
  //     var uri = Uri.parse('$baseUrl/projects/');

  //     if (filters != null && filters.isNotEmpty) {
  //       uri = uri.replace(
  //           queryParameters:
  //               filters.map((key, value) => MapEntry(key, value.toString())));
  //     }

  //     final response = await http.get(
  //       uri,
  //       headers: await getHeaders(requireAuth: false),
  //     );

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       final projects = (data['results'] as List<dynamic>?)
  //               ?.map((item) => ClientProject.fromJson(item))
  //               .toList() ??
  //           [];

  //       return {
  //         'projects': projects,
  //         'hasMore': data['next'] != null,
  //         'total': data['count'] ?? 0,
  //       };
  //     } else {
  //       throw Exception('Failed to load projects: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Error in getProjects: $e');
  //     // Retourner des données de test en cas d'erreur
  //     return {
  //       'projects': _getMockProjects(),
  //       'hasMore': false,
  //       'total': 1,
  //     };
  //   }
  // }

  /// Récupérer les projets par catégorie
  Future<Map<String, dynamic>> getProjectsByCategory(int categoryId,
      [Map<String, dynamic>? filters]) async {
    final allFilters = filters ?? {};
    allFilters['category'] = categoryId;
    return getProjects(allFilters);
  }

  /// Récupérer un projet spécifique
  Future<ClientProject> getProject(int projectId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/projects/$projectId/'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ClientProject.fromJson(data);
      } else {
        throw Exception('Failed to load project: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getProject: $e');
      throw e;
    }
  }

  /// Créer un nouveau projet
  Future<ClientProject> createProject(
      Map<String, dynamic> projectData, List<File?> attachments) async {
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/projects/'));

      // Ajouter les headers d'authentification
      final headers = await getHeaders();
      request.headers.addAll(headers);

      // Ajouter les données du projet
      projectData.forEach((key, value) {
        if (value != null) {
          if (value is List) {
            // Pour les compétences requises
            request.fields[key] = json.encode(value);
          } else {
            request.fields[key] = value.toString();
          }
        }
      });

      // Ajouter les fichiers joints
      for (int i = 0; i < attachments.length; i++) {
        final file = attachments[i];
        if (file != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'attachment${i + 1}',
              file.path,
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ClientProject.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            'Failed to create project: ${errorData['detail'] ?? response.body}');
      }
    } catch (e) {
      print('Error in createProject: $e');
      throw e;
    }
  }

  /// Récupérer les projets de l'utilisateur connecté
  Future<List<ClientProject>> getMyProjects() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/projects/my_projects/'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['results'] as List<dynamic>?)
                ?.map((item) => ClientProject.fromJson(item))
                .toList() ??
            [];
      } else {
        throw Exception('Failed to load my projects: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getMyProjects: $e');
      return [];
    }
  }

  /// Récupérer les statistiques des projets pour le client
  Future<ProjectStats> getProjectStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/projects/stats/'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ProjectStats.fromJson(data);
      } else {
        throw Exception('Failed to load project stats: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getProjectStats: $e');
      // Retourner des stats par défaut
      return ProjectStats(
        totalProjects: 0,
        openProjects: 0,
        completedProjects: 0,
        totalOffers: 0,
        averageOffersPerProject: 0.0,
      );
    }
  }

  /// Basculer un projet en favori (prestataires uniquement)
  Future<bool> toggleProjectFavorite(int projectId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/projects/$projectId/toggle_favorite/'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['favorited'] ?? false;
      } else {
        throw Exception('Failed to toggle favorite: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in toggleProjectFavorite: $e');
      throw e;
    }
  }

// === MÉTHODES POUR LES OFFRES ===

  /// Créer une offre sur un projet
  Future<ProjectOffer> createProjectOffer(
      Map<String, dynamic> offerData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/project-offers/'),
        headers: await getHeaders(),
        body: json.encode(offerData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ProjectOffer.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        String errorMessage = 'Failed to create offer';

        if (errorData['non_field_errors'] != null) {
          errorMessage = errorData['non_field_errors'][0];
        } else if (errorData['detail'] != null) {
          errorMessage = errorData['detail'];
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error in createProjectOffer: $e');
      throw e;
    }
  }

  /// Récupérer les offres pour un projet (client)
  Future<List<ProjectOffer>> getProjectOffers(int projectId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/project-offers/by_project/?project_id=$projectId'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data as List<dynamic>?)
                ?.map((item) => ProjectOffer.fromJson(item))
                .toList() ??
            [];
      } else {
        throw Exception(
            'Failed to load project offers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getProjectOffers: $e');
      return [];
    }
  }

  /// Récupérer les offres du prestataire connecté
  Future<List<ProjectOffer>> getMyOffers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/project-offers/'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['results'] as List<dynamic>?)
                ?.map((item) => ProjectOffer.fromJson(item))
                .toList() ??
            [];
      } else {
        throw Exception('Failed to load my offers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getMyOffers: $e');
      return [];
    }
  }

  /// Mettre à jour le statut d'une offre (accepter/rejeter)
  Future<ProjectOffer> updateOfferStatus(int offerId, String status,
      {String? notes}) async {
    try {
      final data = {
        'status': status,
        if (notes != null) 'notes': notes,
      };

      final response = await http.patch(
        Uri.parse('$baseUrl/project-offers/$offerId/update_status/'),
        headers: await getHeaders(),
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return ProjectOffer.fromJson(responseData);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update offer status');
      }
    } catch (e) {
      print('Error in updateOfferStatus: $e');
      throw e;
    }
  }

  /// Retirer une offre (prestataire uniquement)
  Future<void> withdrawOffer(int offerId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/project-offers/$offerId/withdraw/'),
        headers: await getHeaders(),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to withdraw offer');
      }
    } catch (e) {
      print('Error in withdrawOffer: $e');
      throw e;
    }
  }

  /// Récupérer les projets favoris du prestataire
  Future<List<ClientProject>> getFavoriteProjects() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/project-favorites/'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['results'] as List<dynamic>?)
                ?.map((item) => ClientProject.fromJson(item['project']))
                .toList() ??
            [];
      } else {
        throw Exception(
            'Failed to load favorite projects: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getFavoriteProjects: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getProjects([Map<String, dynamic>? filters]) async {
    try {
      var uri = Uri.parse('$baseUrl/projects/');
      
      if (filters != null && filters.isNotEmpty) {
        uri = uri.replace(queryParameters: 
          filters.map((key, value) => MapEntry(key, value.toString()))
        );
      }
      
      // Appel SANS authentification requise pour permettre l'accès public
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final projects = (data['results'] as List<dynamic>?)
            ?.map((item) => ClientProject.fromJson(item))
            .toList() ?? [];
        
        return {
          'projects': projects,
          'hasMore': data['next'] != null,
          'total': data['count'] ?? 0,
        };
      } else if (response.statusCode == 401) {
        // Si l'endpoint nécessite une authentification, retourner des données publiques limitées
        print('Endpoint nécessite une authentification, utilisation des données mock');
        return {
          'projects': [],
          'hasMore': false,
          'total':0,
        };
      } else {
        throw Exception('Failed to load projects: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getProjects: $e');
      // En cas d'erreur, retourner des données de test
      return {
        'projects': [],
        'hasMore': false,
        'total': [].length,
      };
    }
  }

  /// Récupérer les services récents (accessible sans authentification)
  Future<List<Service>> getRecentServices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/services/recent/'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['results'] ?? [];
        return data.map((item) => Service.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        // Retourner des services publics limités
        return [];
      } else {
        throw Exception('Failed to load recent services: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getRecentServices: $e');
      return [];
    }
  }
// === MÉTHODES MOCK POUR LES TESTS ===

  List<ClientProject> _getMockClientProjects() {
    return [
      ClientProject(
        id: 1,
        title: 'Création d\'un site web e-commerce',
        description:
            'Je recherche un développeur pour créer un site e-commerce complet avec gestion des stocks, paiements sécurisés et interface d\'administration.',
        clientName: 'Marie Dubois',
        categoryName: 'Développement web',
        budgetRange: '1000_10000',
        budgetDisplay: '3000€ - 8000€',
        location: 'Paris',
        remotePossible: true,
        urgency: 'medium',
        status: 'open',
        contactViaPlatform: true,
        showEmail: false,
        showPhone: false,
        requiredSkills: [
          ProjectSkill(id: 1, name: 'PHP', isRequired: true),
          ProjectSkill(id: 2, name: 'JavaScript', isRequired: true),
          ProjectSkill(id: 3, name: 'MySQL', isRequired: true),
          ProjectSkill(id: 4, name: 'E-commerce', isRequired: false),
        ],
        offersCount: 12,
        viewsCount: 45,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        timeSincePosted: 'Il y a 6 heures',
        isFavorited: false,
        hasUserOffered: false,
      ),
      ClientProject(
        id: 2,
        title: 'Design d\'une application mobile',
        description:
            'Recherche un designer UX/UI pour concevoir l\'interface d\'une application mobile de fitness avec suivi d\'activités et coaching personnalisé.',
        clientName: 'Thomas Martin',
        categoryName: 'Design graphique',
        budgetRange: 'sur_devis',
        budgetDisplay: 'Sur devis',
        location: 'Lyon',
        remotePossible: true,
        urgency: 'high',
        status: 'open',
        contactViaPlatform: true,
        showEmail: true,
        showPhone: false,
        requiredSkills: [
          ProjectSkill(id: 5, name: 'UI/UX Design', isRequired: true),
          ProjectSkill(id: 6, name: 'Figma', isRequired: true),
          ProjectSkill(id: 7, name: 'Prototypage', isRequired: false),
        ],
        offersCount: 8,
        viewsCount: 32,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        timeSincePosted: 'Il y a 2 jours',
        isFavorited: true,
        hasUserOffered: false,
      ),
      ClientProject(
        id: 3,
        title: 'Rénovation d\'appartement',
        description:
            'Rénovation complète d\'un appartement de 80m² : peinture, parquet, salle de bain, cuisine. Travaux à prévoir sur 6 semaines.',
        clientName: 'Sophie Laurent',
        categoryName: 'Rénovation',
        budgetRange: '10000_plus',
        budgetDisplay: '15000€ - 25000€',
        location: 'Marseille',
        remotePossible: false,
        urgency: 'low',
        status: 'open',
        contactViaPlatform: true,
        showEmail: false,
        showPhone: true,
        requiredSkills: [
          ProjectSkill(id: 8, name: 'Peinture', isRequired: true),
          ProjectSkill(id: 9, name: 'Carrelage', isRequired: true),
          ProjectSkill(id: 10, name: 'Plomberie', isRequired: false),
        ],
        offersCount: 5,
        viewsCount: 18,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        timeSincePosted: 'Il y a 1 jour',
        isFavorited: false,
        hasUserOffered: true,
      ),
    ];
  }

  // List<Review> _getMockReviews() {
  //   return [
  //     Review(
  //       id: 1,
  //       userName: 'Jean Dupont',
  //       userImageUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
  //       rating: 5.0,
  //       comment:
  //           'Excellent travail, je suis très satisfait du résultat. L\'équipe était professionnelle et ponctuelle.',
  //       date: DateTime.now().subtract(const Duration(days: 2)),
  //     ),
  //     Review(
  //       id: 2,
  //       userName: 'Marie Leclerc',
  //       userImageUrl: 'https://randomuser.me/api/portraits/women/2.jpg',
  //       rating: 4.0,
  //       comment:
  //           'Bon travail dans l\'ensemble, quelques petits détails à améliorer mais je recommande.',
  //       date: DateTime.now().subtract(const Duration(days: 15)),
  //     ),
  //     Review(
  //       id: 3,
  //       userName: 'Pierre Martin',
  //       userImageUrl: 'https://randomuser.me/api/portraits/men/3.jpg',
  //       rating: 5.0,
  //       comment:
  //           'Très professionnel, travail soigné et dans les délais. Je recommande vivement !',
  //       date: DateTime.now().subtract(const Duration(days: 30)),
  //     ),
  //   ];
  // }
}

List<Subcategory> _getMockSubcategories(int categoryId) {
  if (categoryId == 1) {
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
    ];
  } else {
    return [
      Subcategory(
        id: 4,
        name: 'Sous-catégorie 1',
        categoryId: categoryId,
        description: 'Description sous-catégorie 1',
      ),
      Subcategory(
        id: 5,
        name: 'Sous-catégorie 2',
        categoryId: categoryId,
        description: 'Description sous-catégorie 2',
      ),
    ];
  }
}
