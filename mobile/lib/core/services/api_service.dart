import 'dart:convert';
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
      'Content-Type': 'application/json',
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
        
        final List<dynamic> data = json.decode(response.body)['results'] ?? [];
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
      Uri.parse('$baseUrl/conversations/$conversationId/messages/?user_id=$userId'),
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

Future<Conversation> startConversation(int providerId, String? initialMessage) async {
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
        providerId: 1,
        categoryId:1,
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
        providerId: 2,
        categoryId:1,
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
        providerId: 3,
        categoryId:1,
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
        providerId: 4,
        categoryId:1,
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
        providerId: 5,
        categoryId:1,
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
      providerId: 1,
      categoryId:1,
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
