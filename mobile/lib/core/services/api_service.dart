// import 'dart:convert';
// import 'dart:io';
// import 'dart:math' as math;
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
// import '../models/category.dart';
// import '../models/conversation.dart';
// import '../models/message.dart';
// import '../models/subcategory.dart';
// import '../models/service.dart';
// import '../models/provider_model.dart';
// import '../models/review.dart';
// import '../models/user.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import '../models/project.dart';
// import '../models/client_project.dart';
// import '../models/project.dart';
// import '../models/project_offer.dart';
// import '../models/project_skill.dart';
// import '../models/project_stats.dart';
// import '../api/api_client.dart';
// class ApiService {
//   final String baseUrl;
//   final String apiKey;
//   final ApiClient _apiClient;
//   final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

//   ApiService({
//     required this.baseUrl,
//     required this.apiKey,
//   })  : _apiClient = ApiClient(baseUrl: baseUrl);
//   // Méthode pour récupérer les tokens
//   Future<String?> _getToken() async {
//     return await _secureStorage.read(key: 'access_token');
//   }

//   // Créer les en-têtes avec authentification si nécessaire
//   Future<Map<String, String>> getHeaders({bool requireAuth = true}) async {
//     Map<String, String> headers = {
//       'Content-Type': 'application/json; charset=utf-8',
//       'Accept': 'application/json; charset=utf-8',
//       'Accept-Charset': 'utf-8',
//       'Accept-Encoding': 'utf-8',
//     };

//     if (requireAuth) {
//       final token = await _secureStorage.read(key: 'access_token');
//       if (token != null) {
//         headers['Authorization'] = 'Bearer $token';
//       }
//     }

//     return headers;
//   }

//   // Obtenir le profil utilisateur courant
//   Future<User> getCurrentUser() async {
//     try {
//       final headers = await getHeaders();
//       final response = await http.get(
//         Uri.parse('$baseUrl/users/me/'),
//         headers: headers,
//       );

//       if (response.statusCode == 200) {
//         final dynamic data = json.decode(response.body);
//         return User.fromJson(data);
//       } else {
//         // En cas d'erreur, retourner des données de test
//         return _getMockUser();
//       }
//     } catch (e) {
//       print('Error in getCurrentUser: $e');
//       // En cas d'exception, retourner des données de test
//       return _getMockUser();
//     }
//   }

//   // Récupérer les services récents
//   // Future<List<Service>> getRecentServices() async {
//   //   try {
//   //     final response = await http.get(
//   //       Uri.parse('$baseUrl/services/recent/'),
//   //       headers: await getHeaders(requireAuth: false),
//   //     );

//   //     if (response.statusCode == 200) {
//   //       final List<dynamic> data = json.decode(response.body)['results'] ?? [];
//   //       return data.map((item) => Service.fromJson(item)).toList();
//   //     } else {
//   //       throw Exception('Failed to load recent services');
//   //     }
//   //   } catch (e) {
//   //     print('Error in getRecentServices: $e');
//   //     // Retourner des données de test en cas d'erreur
//   //     return _getMockServices();
//   //   }
//   // }

//   // ===============================
//   // MÉTHODES POUR LES STATISTIQUES PRESTATAIRE
//   // ===============================

//   Future<Map<String, dynamic>> getProviderStats() async {
//     try {
//       print('📊 Récupération des statistiques prestataire...');

//       final data = await _apiClient.get('users/profile_stats/', requireAuth: true);

//       print('✅ Statistiques récupérées avec succès');
//       return data ?? {};

//     } catch (e) {
//       print('❌ Erreur dans getProviderStats: $e');
//       // Retourner des données mock en cas d'erreur
//       return {
//         'prestations_completed_this_month': 0,
//         'prestations_in_progress': 0,
//         'unread_messages': 0,
//         'total_earnings_this_month': 0,
//         'avg_rating': 0,
//         'total_reviews': 0,
//       };
//     }
//   }

//   // Récupérer les services à proximité
//   Future<List<Service>> getNearbyServices() async {
//     try {
//       // Si l'utilisateur a fourni sa localisation, on l'utilise pour obtenir les services à proximité
//       final position = await _getCurrentPosition();

//       String url = '$baseUrl/services/nearby/';
//       if (position != null) {
//         url += '?latitude=${position.latitude}&longitude=${position.longitude}';
//       }

//       final response = await http.get(
//         Uri.parse(url),
//         headers: await getHeaders(requireAuth: false),
//       );

//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body)['results'] ?? [];
//         return data.map((item) => Service.fromJson(item)).toList();
//       } else {
//         throw Exception('Failed to load nearby services');
//       }
//     } catch (e) {
//       print('Error in getNearbyServices: $e');
//       // Retourner des données de test en cas d'erreur
//       return _getMockServices();
//     }
//   }

//   // Méthode pour obtenir la position actuelle de l'utilisateur (à implémenter avec un package de géolocalisation)
//   Future<Position?> _getCurrentPosition() async {
//     try {
//       // Implémenter avec package geolocator
//       return null;
//     } catch (e) {
//       print('Error getting current position: $e');
//       return null;
//     }
//   }

//   // Méthodes pour les prestataires
//   Future<List<ProviderModel>> getProviders() async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/providers/'),
//         headers: await getHeaders(requireAuth: false),
//       );

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//         final List<dynamic> data = responseData['results'] ?? [];
//         return data.map((item) => ProviderModel.fromJson(item)).toList();
//       } else {
//         // En cas d'erreur, retourner des données de test
//         return _getMockProviders();
//       }
//     } catch (e) {
//       print('Erreur getProviders: $e');
//       // En cas d'erreur, retourner des données de test
//       return _getMockProviders();
//     }
//   }

//   Future<List<ProviderModel>> getProvidersByCategory(int categoryId) async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/providers/by_category/?category_id=$categoryId'),
//         headers: await getHeaders(requireAuth: false),
//       );

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//         final List<dynamic> data = responseData['results'] ?? [];
//         return data.map((item) => ProviderModel.fromJson(item)).toList();
//       } else {
//         // En cas d'erreur, retourner des données de test filtrées
//         return _getMockProviders()
//             .where((p) => p.id % 5 == categoryId % 5)
//             .toList();
//       }
//     } catch (e) {
//       print('Erreur getProvidersByCategory: $e');
//       // En cas d'erreur, retourner des données de test filtrées
//       return _getMockProviders()
//           .where((p) => p.id % 5 == categoryId % 5)
//           .toList();
//     }
//   }

//   Future<List<ProviderModel>> getProvidersBySubcategory(
//       int subcategoryId) async {
//     try {
//       final response = await http.get(
//         Uri.parse(
//             '$baseUrl/providers/by_subcategory/?subcategory_id=$subcategoryId'),
//         headers: await getHeaders(requireAuth: false),
//       );

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//         final List<dynamic> data = responseData['results'] ?? [];
//         return data.map((item) => ProviderModel.fromJson(item)).toList();
//       } else {
//         // En cas d'erreur, retourner des données de test filtrées
//         return _getMockProviders()
//             .where((p) => p.id % 10 == subcategoryId % 10)
//             .toList();
//       }
//     } catch (e) {
//       print('Erreur getProvidersBySubcategory: $e');
//       // En cas d'erreur, retourner des données de test filtrées
//       return _getMockProviders()
//           .where((p) => p.id % 10 == subcategoryId % 10)
//           .toList();
//     }
//   }

//   Future<List<ProviderModel>> getNearbyProviders(
//       double latitude, double longitude,
//       {double radius = 10.0}) async {
//     try {
//       final queryParams = {
//         'latitude': latitude.toString(),
//         'longitude': longitude.toString(),
//         'radius': radius.toString(),
//       };

//       final uri = Uri.parse('$baseUrl/providers/nearby/')
//           .replace(queryParameters: queryParams);

//       final response = await http.get(
//         uri,
//         headers: await getHeaders(requireAuth: false),
//       );

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//         final List<dynamic> data = responseData['results'] ?? [];
//         return data.map((item) => ProviderModel.fromJson(item)).toList();
//       } else {
//         // En cas d'erreur, retourner des données de test avec coordonnées aléatoires
//         return _getMockProvidersWithCoordinates(latitude, longitude);
//       }
//     } catch (e) {
//       print('Erreur getNearbyProviders: $e');
//       // En cas d'erreur, retourner des données de test
//       return _getMockProvidersWithCoordinates(latitude, longitude);
//     }
//   }

//   // ===============================
//   // MÉTHODES POUR LES OFFRES
//   // ===============================

//   // Future<void> submitOffer(int projectId, Map<String, dynamic> offerData) async {
//   //   try {
//   //     final response = await http.post(
//   //       Uri.parse('$baseUrl/projects/$projectId/offers/'),
//   //       headers: await getHeaders(),
//   //       body: json.encode(offerData),
//   //     );

//   //     if (response.statusCode != 201) {
//   //       final errorData = json.decode(response.body);
//   //       throw Exception(errorData['detail'] ?? 'Erreur lors de l\'envoi de l\'offre');
//   //     }
//   //   } catch (e) {
//   //     print('Error in submitOffer: $e');
//   //     throw e;
//   //   }
//   // }

//   // Obtenir les projets de l'utilisateur
//   // Future<List<Project>> getUserProjects() async {
//   //   try {
//   //     final headers = await getHeaders();
//   //     final response = await http.get(
//   //       Uri.parse('$baseUrl/projects/user/'),
//   //       headers: headers,
//   //     );

//   //     if (response.statusCode == 200) {
//   //       final List<dynamic> data = json.decode(response.body)['results'] ?? [];
//   //       return data.map((item) => Project.fromJson(item)).toList();
//   //     } else {
//   //       // En cas d'erreur, retourner des données de test
//   //       return _getMockProjects();
//   //     }
//   //   } catch (e) {
//   //     print('Error in getUserProjects: $e');
//   //     // En cas d'exception, retourner des données de test
//   //     return _getMockProjects();
//   //   }
//   // }
//   Future<Map<String, dynamic>> getUserProjects() async {
//     int retryCount = 0;
//     const maxRetries = 2;

//     while (retryCount < maxRetries) {
//       try {
//         print('=== Tentative ${retryCount + 1} - Récupération des projets utilisateur ===');

//         final headers = await getHeaders();
//         print('Headers préparés: ${headers.containsKey('Authorization') ? 'Token présent' : 'AUCUN TOKEN'}');

//         final response = await http.get(
//           Uri.parse('$baseUrl/projects/my_projects/'),
//           headers: headers,
//         );

//         print('Réponse API getUserProjects: ${response.statusCode}');

//         if (response.statusCode == 200) {
//           final data = json.decode(response.body);
//           final List<dynamic> projectsJson = data['results'] ?? [];

//           final projects = projectsJson.map((item) {
//             return ClientProject.fromJson(item);
//           }).toList();

//           print('✅ Projets récupérés avec succès: ${projects.length} projets');
//           return {
//             'projects': projects,
//             'count': data['count'] ?? 0,
//           };

//         } else if (response.statusCode == 401) {
//           print('❌ Erreur 401 - Token invalide ou expiré');
//           print('Corps de la réponse: ${response.body}');

//           if (retryCount < maxRetries - 1) {
//             print('🔄 Tentative de rafraîchissement du token...');

//             // Tenter de rafraîchir le token
//             final tokenRefreshed = await _attemptTokenRefresh();
//             if (tokenRefreshed) {
//               print('✅ Token rafraîchi, nouvelle tentative...');
//               retryCount++;
//               continue; // Réessayer avec le nouveau token
//             } else {
//               print('❌ Échec du rafraîchissement du token');
//               throw Exception('Unauthorized');
//             }
//           } else {
//             throw Exception('Unauthorized');
//           }

//         } else {
//           print('❌ Erreur HTTP ${response.statusCode}');
//           print('Corps de la réponse: ${response.body}');
//           throw Exception('Failed to load user projects: ${response.statusCode} - ${response.body}');
//         }

//       } catch (e) {
//         print('Erreur lors de la récupération des projets: $e');

//         if (retryCount == maxRetries - 1) {
//           // Dernière tentative échouée
//           rethrow;
//         } else if (e.toString().contains('Unauthorized')) {
//           // Pour les erreurs 401, essayer de rafraîchir le token
//           retryCount++;
//         } else {
//           // Pour les autres erreurs, relancer immédiatement
//           rethrow;
//         }
//       }
//     }

//     throw Exception('Impossible de récupérer les projets après $maxRetries tentatives');
//   }

//   // AJOUTEZ cette nouvelle méthode à votre ApiService :
//   Future<bool> _attemptTokenRefresh() async {
//     try {
//       final refreshToken = await _secureStorage.read(key: 'refresh_token');
//       if (refreshToken == null) {
//         print('❌ Aucun refresh token disponible');
//         return false;
//       }

//       print('🔄 Rafraîchissement du token...');

//       final response = await http.post(
//         Uri.parse('$baseUrl/auth/token/refresh/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//         body: json.encode({'refresh': refreshToken}),
//       );

//       print('Réponse refresh token: ${response.statusCode}');

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final newAccessToken = data['access'];

//         // Sauvegarder le nouveau token d'accès
//         await _secureStorage.write(key: 'access_token', value: newAccessToken);

//         print('✅ Token rafraîchi et sauvegardé');
//         return true;
//       } else {
//         print('❌ Échec du rafraîchissement: ${response.statusCode} - ${response.body}');

//         // Supprimer les tokens invalides
//         await _secureStorage.delete(key: 'access_token');
//         await _secureStorage.delete(key: 'refresh_token');

//         return false;
//       }
//     } catch (e) {
//       print('❌ Erreur lors du rafraîchissement du token: $e');
//       return false;
//     }
//   }

//   // AJOUTEZ aussi cette méthode de debug (optionnelle) :
//   Future<void> debugTokenState() async {
//     final token = await _secureStorage.read(key: 'access_token');
//     final refreshToken = await _secureStorage.read(key: 'refresh_token');

//     print('=== DEBUG TOKEN STATE ===');
//     print('Access Token: ${token != null ? 'EXISTS (${token.length} chars)' : 'NULL'}');
//     print('Refresh Token: ${refreshToken != null ? 'EXISTS' : 'NULL'}');
//     print('Base URL: $baseUrl');
//     print('========================');
//   }

//   // Méthodes pour générer des données de test
//   List<ProviderModel> _getMockProviders() {
//     return List.generate(10, (index) {
//       return ProviderModel(
//         id: index + 1,
//         name: 'Prestataire ${index + 1}',
//         businessType: index % 2 == 0 ? 'Entreprise' : 'Freelance',
//         profileImageUrl:
//             'https://randomuser.me/api/portraits/${index % 2 == 0 ? 'men' : 'women'}/${index + 1}.jpg',
//         rating: 3.0 + (index % 5) * 0.5,
//         reviewCount: 5 + index * 3,
//         description:
//             'Description du prestataire ${index + 1}. Service de qualité proposé par des professionnels expérimentés.',
//         services: List.generate(
//             3,
//             (i) => ServiceItem(
//                   id: i + 1,
//                   title: 'Service ${i + 1}',
//                   priceType: i % 2 == 0 ? 'fixed' : 'quote',
//                 )),
//       );
//     });
//   }

//   List<ProviderModel> _getMockProvidersWithCoordinates(
//       double centerLatitude, double centerLongitude) {
//     final random = math.Random();

//     return List.generate(10, (index) {
//       // Générer des coordonnées aléatoires dans un rayon de 5km
//       final latOffset = (random.nextDouble() - 0.5) * 0.1; // ~5km
//       final lngOffset = (random.nextDouble() - 0.5) * 0.1; // ~5km

//       return ProviderModel(
//         id: index + 1,
//         name: 'Prestataire ${index + 1}',
//         businessType: index % 2 == 0 ? 'Entreprise' : 'Freelance',
//         profileImageUrl:
//             'https://randomuser.me/api/portraits/${index % 2 == 0 ? 'men' : 'women'}/${index + 1}.jpg',
//         rating: 3.0 + (index % 5) * 0.5,
//         reviewCount: 5 + index * 3,
//         description:
//             'Description du prestataire ${index + 1}. Service de qualité proposé par des professionnels expérimentés.',
//         services: List.generate(
//             3,
//             (i) => ServiceItem(
//                   id: i + 1,
//                   title: 'Service ${i + 1}',
//                   priceType: i % 2 == 0 ? 'fixed' : 'quote',
//                 )),
//         latitude: centerLatitude + latOffset,
//         longitude: centerLongitude + lngOffset,
//         address: 'Adresse du prestataire ${index + 1}, Cotonou',
//       );
//     });
//   }

//   // Méthodes de mock pour données de test
//   User _getMockUser() {
//     return User(
//       id: 1,
//       username: 'bryan_cooper',
//       email: 'bryan.cooper@example.com',
//       firstName: 'Bryan',
//       lastName: 'Cooper',
//       phoneNumber: '+2345678901',
//       bio: 'Client à la recherche de services de qualité',
//       profilePicture: 'https://randomuser.me/api/portraits/men/32.jpg',
//       role: 'client',
//       isVerified: true,
//       location: 'Angola',
//       dateJoined: DateTime.parse('2025-03-15T00:00:00Z'),
//     );
//   }

//   List<Project> _getMockProjects() {
//     return [
//       Project(
//         id: 1,
//         title: 'Rénovation maison',
//         description:
//             'Je recherche une entreprise capable de gérer l\'ensemble de la construction, y compris la conception, le choix des matériaux, la main-d\'œuvre et le respect des délais.',
//         status: 'En cours',
//         createdAt: DateTime.now().subtract(const Duration(days: 30)),
//         providers: [
//           ProviderInProject(
//             id: 1,
//             name: 'Tanya',
//             specialty: 'Entreprises de charpente et couverture',
//             imageUrl: 'https://randomuser.me/api/portraits/women/23.jpg',
//           ),
//         ],
//       ),
//     ];
//   }

//   // Obtenir toutes les catégories
//   Future<List<Category>> getCategories() async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/categories/'),
//         headers: {
//           // 'Authorization': 'Bearer $apiKey',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body)['results'] ?? [];
//         return data.map((item) => Category.fromJson(item)).toList();
//       } else {
//         // En cas d'erreur, retourner des données de test
//         return _getMockCategories();
//       }
//     } catch (e) {
//       print('Error in getCategories: $e');
//       // En cas d'exception, retourner des données de test
//       return _getMockCategories();
//     }
//   }

//   // Obtenir les sous-catégories d'une catégorie
//   Future<List<Subcategory>> getSubcategories(int categoryId) async {
//     try {
//       print(categoryId);
//       final response = await http.get(
//         Uri.parse('$baseUrl/subcategories/?category_id=$categoryId'),
//         headers: {
//           // 'Authorization': 'Bearer $apiKey',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final List<dynamic> data =
//             json.decode(utf8.decode(response.bodyBytes))['results'] ?? [];
//         print('Les données recuperes sont : $data');
//         return data.map((item) => Subcategory.fromJson(item)).toList();
//       } else {
//         // En cas d'erreur, retourner des données de test
//         return _getMockSubcategories(categoryId);
//       }
//     } catch (e) {
//       print('Error in getSubcategories: $e');
//       // En cas d'exception, retourner des données de test
//       return _getMockSubcategories(categoryId);
//     }
//   }

//   Future<int> getServiceCountByCategory(int categoryId) async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/services/count/?category_id=$categoryId'),
//         headers: {
//           // 'Authorization': 'Bearer $apiKey',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return data['count'] ?? 0;
//       } else {
//         // En cas d'erreur, retourner le résultat d'une méthode mock
//         return _getMockServiceCountByCategory(categoryId);
//       }
//     } catch (e) {
//       print('Error in getServiceCountByCategory: $e');
//       // En cas d'exception, retourner le résultat d'une méthode mock
//       return _getMockServiceCountByCategory(categoryId);
//     }
//   }

//   Future<int> getCurrentUserId() async {
//     try {
//       // Récupérer l'utilisateur courant depuis le stockage local
//       final user = await getCurrentUser();
//       if (user != null) {
//         return user.id;
//       }

//       // Si l'utilisateur n'est pas disponible localement
//       throw Exception("Utilisateur non connecté");
//     } catch (e) {
//       print('Error in getCurrentUserId: $e');
//       throw e;
//     }
//   }

//   Future<List<Conversation>> getConversations() async {
//     try {
//       // Récupérer l'ID de l'utilisateur courant
//       final userId = await getCurrentUserId();

//       final response = await http.get(
//         Uri.parse('$baseUrl/conversations/?user_id=$userId'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//         final List<dynamic> data = responseData['results'] ?? [];
//         return data.map((item) => Conversation.fromJson(item, userId)).toList();
//       } else {
//         print('Error response: ${response.body}');
//         throw Exception('Failed to load conversations: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in getConversations: $e');
//       return []; // Retourner une liste vide en cas d'erreur
//     }
//   }

//   Future<List<Message>> getMessages(int conversationId) async {
//     try {
//       // Récupérer l'ID de l'utilisateur courant
//       final userId = await getCurrentUserId();

//       final response = await http.get(
//         Uri.parse(
//             '$baseUrl/conversations/$conversationId/messages/?user_id=$userId'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//         final List<dynamic> data = responseData['results'] ?? [];
//         return data.map((item) => Message.fromJson(item, userId)).toList();
//       } else {
//         print('Error response: ${response.body}');
//         throw Exception('Failed to load messages: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in getMessages: $e');
//       return []; // Retourner une liste vide en cas d'erreur
//     }
//   }

//   Future<Message> sendMessage(int conversationId, String content) async {
//     try {
//       // Récupérer l'ID de l'utilisateur courant
//       final userId = await getCurrentUserId();

//       final response = await http.post(
//         Uri.parse('$baseUrl/conversations/$conversationId/send_message/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//         body: json.encode({
//           'user_id': userId,
//           'content': content,
//         }),
//       );

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final data = json.decode(response.body);
//         return Message.fromJson(data, userId);
//       } else {
//         print('Error response: ${response.body}');
//         throw Exception('Failed to send message: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in sendMessage: $e');
//       throw e;
//     }
//   }

//   Future<Conversation> startConversation(
//       int providerId, String? initialMessage) async {
//     try {
//       // Récupérer l'ID de l'utilisateur courant
//       final userId = await getCurrentUserId();

//       final Map<String, dynamic> data = {
//         'user_id': userId,
//         'provider_id': providerId,
//       };

//       if (initialMessage != null && initialMessage.isNotEmpty) {
//         data['message'] = initialMessage;
//       }

//       final response = await http.post(
//         Uri.parse('$baseUrl/conversations/start/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//         body: json.encode(data),
//       );

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final responseData = json.decode(response.body);
//         return Conversation.fromJson(responseData, userId);
//       } else {
//         print('Error response: ${response.body}');
//         throw Exception('Failed to start conversation: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in startConversation: $e');
//       throw e;
//     }
//   }

//   Future<Message?> getInitialMessage(int conversationId) async {
//     try {
//       final messages = await getMessages(conversationId);
//       if (messages.isNotEmpty) {
//         return messages.first;
//       }
//       return null;
//     } catch (e) {
//       print('Error in getInitialMessage: $e');
//       return null;
//     }
//   }

//   Future<bool> markMessagesAsRead(int conversationId) async {
//     try {
//       // Récupérer l'ID de l'utilisateur courant
//       final userId = await getCurrentUserId();

//       final response = await http.post(
//         Uri.parse('$baseUrl/conversations/$conversationId/mark_read/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//         body: json.encode({
//           'user_id': userId,
//         }),
//       );

//       return response.statusCode == 200;
//     } catch (e) {
//       print('Error in markMessagesAsRead: $e');
//       return false;
//     }
//   }

//   Future<int> getUnreadNotificationCount() async {
//     try {
//       // Récupérer l'ID de l'utilisateur courant
//       final userId = await getCurrentUserId();

//       final response = await http.get(
//         Uri.parse('$baseUrl/notifications/count/?user_id=$userId'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return data['count'] ?? 0;
//       } else {
//         print('Error response: ${response.body}');
//         return 0;
//       }
//     } catch (e) {
//       print('Error in getUnreadNotificationCount: $e');
//       return 0; // En cas d'erreur, retourner 0 comme valeur par défaut
//     }
//   }

//   Future<bool> markAllNotificationsAsRead() async {
//     try {
//       // Récupérer l'ID de l'utilisateur courant
//       final userId = await getCurrentUserId();

//       final response = await http.post(
//         Uri.parse('$baseUrl/notifications/mark_all_read/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//         body: json.encode({
//           'user_id': userId,
//         }),
//       );

//       return response.statusCode == 200;
//     } catch (e) {
//       print('Error in markAllNotificationsAsRead: $e');
//       return false;
//     }
//   }

// // Méthode mock pour fournir des nombres fictifs en cas d'erreur
//   int _getMockServiceCountByCategory(int categoryId) {
//     // Associer à chaque catégorie un nombre fictif
//     final Map<int, int> mockCounts = {
//       1: 11, // Maison & Construction
//       2: 5, // Bien-être & Beauté
//       3: 6, // Événements & Artistiques
//       4: 4, // Transport & Logistique
//       5: 3, // Santé & Bien-être
//       6: 5, // Services Professionnels & Formation
//       7: 4, // Services Numériques & Technologiques
//       8: 3, // Services pour Animaux
//       9: 3, // Services Divers
//     };

//     return mockCounts[categoryId] ?? 0;
//   }

//   // Obtenir les services d'une catégorie
//   Future<List<Service>> getServicesByCategory(int categoryId) async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/services/?category_id=$categoryId'),
//         headers: {
//           // 'Authorization': 'Bearer $apiKey',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body)['results'] ?? [];
//         return data.map((item) => Service.fromJson(item)).toList();
//       } else {
//         // En cas d'erreur, retourner des données de test
//         return _getMockServices();
//       }
//     } catch (e) {
//       print('Error in getServicesByCategory: $e');
//       // En cas d'exception, retourner des données de test
//       return _getMockServices();
//     }
//   }

//   // Obtenir les services d'une sous-catégorie
//   Future<List<Service>> getServicesBySubcategory(int subcategoryId) async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/services/?subcategory_id=$subcategoryId'),
//         headers: {
//           // 'Authorization': 'Bearer $apiKey',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body)['results'] ?? [];
//         return data.map((item) => Service.fromJson(item)).toList();
//       } else {
//         // En cas d'erreur, retourner des données de test
//         return _getMockServices();
//       }
//     } catch (e) {
//       print('Error in getServicesBySubcategory: $e');
//       // En cas d'exception, retourner des données de test
//       return _getMockServices();
//     }
//   }

//   // Obtenir les détails d'un service
//   Future<Service> getServiceDetails(int serviceId) async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/services/$serviceId/'),
//         headers: {
//           'Authorization': 'Bearer $apiKey',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final dynamic data = json.decode(response.body);
//         return Service.fromJson(data);
//       } else {
//         // En cas d'erreur, retourner des données de test
//         return _getMockServiceDetails(serviceId);
//       }
//     } catch (e) {
//       print('Error in getServiceDetails: $e');
//       // En cas d'exception, retourner des données de test
//       return _getMockServiceDetails(serviceId);
//     }
//   }

//   // Obtenir les détails d'un prestataire
//   Future<ProviderModel> getProviderDetails(int providerId) async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/providers/$providerId/'),
//         headers: {
//           'Authorization': 'Bearer $apiKey',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final dynamic data = json.decode(response.body);
//         return ProviderModel.fromJson(data);
//       } else {
//         // En cas d'erreur, retourner des données de test
//         return _getMockProviderDetails(providerId);
//       }
//     } catch (e) {
//       print('Error in getProviderDetails: $e');
//       // En cas d'exception, retourner des données de test
//       return _getMockProviderDetails(providerId);
//     }
//   }

//   // Obtenir un prestataire par l'ID d'un service
//   Future<ProviderModel> getProviderByServiceId(int serviceId) async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/providers/by-service/$serviceId/'),
//         headers: {
//           'Authorization': 'Bearer $apiKey',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final dynamic data = json.decode(response.body);
//         return ProviderModel.fromJson(data);
//       } else {
//         // En cas d'erreur, retourner des données de test
//         return _getMockProviderByService(serviceId);
//       }
//     } catch (e) {
//       print('Error in getProviderByServiceId: $e');
//       // En cas d'exception, retourner des données de test
//       return _getMockProviderByService(serviceId);
//     }
//   }

//   // Obtenir les avis d'un prestataire
//   Future<List<Review>> getProviderReviews(int providerId) async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/reviews/?provider_id=$providerId'),
//         headers: {
//           'Authorization': 'Bearer $apiKey',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body)['results'] ?? [];
//         return data.map((item) => Review.fromJson(item)).toList();
//       } else {
//         // En cas d'erreur, retourner des données de test
//         return [];
//       }
//     } catch (e) {
//       print("non non l'erreur vient d'ici");

//       print('Error in getProviderReviews: $e');
//       // En cas d'exception, retourner des données de test
//       return [];
//     }
//   }

// // Ajouter cette méthode à votre class ApiService dans le fichier api_service.dart

//   Future<int> getServiceCountBySubcategory(int subcategoryId) async {
//     try {
//       final response = await http.get(
//         Uri.parse(
//             '$baseUrl/services/count_by_subcategory/?subcategory_id=$subcategoryId'),
//         headers: {
//           // 'Authorization': 'Bearer $apiKey',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return data['count'] ?? 0;
//       } else {
//         // En cas d'erreur, retourner le résultat d'une méthode mock
//         return _getMockServiceCountBySubcategory(subcategoryId);
//       }
//     } catch (e) {
//       print('Error in getServiceCountBySubcategory: $e');
//       // En cas d'exception, retourner le résultat d'une méthode mock
//       return _getMockServiceCountBySubcategory(subcategoryId);
//     }
//   }

//   // Méthode mock pour fournir des nombres fictifs en cas d'erreur
//   int _getMockServiceCountBySubcategory(int subcategoryId) {
//     // Associer à chaque sous-catégorie un nombre fictif de services
//     final Map<int, int> mockCounts = {
//       1: 5, // Construction & rénovation
//       2: 3, // Plomberie
//       3: 4, // Électricité
//       4: 2, // Menuiserie & Ébénisterie
//       5: 3, // Peinture & Décoration
//       6: 2, // Paysagisme & Jardinage
//       7: 1, // Serrurerie
//       8: 2, // Ménage & Nettoyage
//       9: 1, // Pest Control
//       10: 1, // Vitrerie & Fenêtres
//       11: 2, // Froid & Climatisation
//       12: 3, // Coiffure & Barbier
//       13: 2, // Esthétique & Maquillage
//       14: 2, // Massages & Thérapies
//       15: 1, // Fitness & Coaching Sportif
//       16: 1, // Nutrition & Diététique
//       17: 2, // Photographie & Vidéographie
//       18: 3, // Organisation d'événements
//       19: 2, // Traiteur & Chef à domicile
//       20: 2, // Animation & Spectacle
//       21: 1, // Location de matériel
//       22: 2, // Fleuristes & Décoration florale
//     };

//     return mockCounts[subcategoryId] ?? 0;
//   }
//   // --- Méthodes pour générer des données de test ---

//   // --- Méthodes pour générer des données de test ---

//   List<Category> _getMockCategories() {
//     return [
//       Category(
//         id: 1,
//         name: 'Maison & Construction',
//         imageUrl: 'https://picsum.photos/id/1018/300/200',
//         description: 'Services de construction et rénovation',
//       ),
//       Category(
//         id: 2,
//         name: 'Bien-être & Beauté',
//         imageUrl: 'https://picsum.photos/id/64/300/200',
//         description: 'Services de beauté et bien-être',
//       ),
//       Category(
//         id: 3,
//         name: 'Événements & Artistiques',
//         imageUrl: 'https://picsum.photos/id/1058/300/200',
//         description: 'Services liés aux événements et à l\'art',
//       ),
//       Category(
//         id: 4,
//         name: 'Transports & Logistiques',
//         imageUrl: 'https://picsum.photos/id/1072/300/200',
//         description: 'Services de transport et logistique',
//       ),
//       Category(
//         id: 5,
//         name: 'Services Professionnels',
//         imageUrl: 'https://picsum.photos/id/1066/300/200',
//         description: 'Services professionnels divers',
//       ),
//       Category(
//         id: 6,
//         name: 'Cours & Formation',
//         imageUrl: 'https://picsum.photos/id/20/300/200',
//         description: 'Services d\'éducation et formation',
//       ),
//     ];
//   }

//   List<Subcategory> _getMockSubcategories(int categoryId) {
//     if (categoryId == 1) {
//       return [
//         Subcategory(
//           id: 1,
//           name: 'Construction & rénovation',
//           categoryId: 1,
//           description: 'Services de construction et rénovation',
//         ),
//         Subcategory(
//           id: 2,
//           name: 'Plomberie',
//           categoryId: 1,
//           description: 'Services de plomberie',
//         ),
//         Subcategory(
//           id: 3,
//           name: 'Électricité',
//           categoryId: 1,
//           description: 'Services d\'électricité',
//         ),
//       ];
//     } else {
//       return [
//         Subcategory(
//           id: 4,
//           name: 'Sous-catégorie 1',
//           categoryId: categoryId,
//           description: 'Description sous-catégorie 1',
//         ),
//         Subcategory(
//           id: 5,
//           name: 'Sous-catégorie 2',
//           categoryId: categoryId,
//           description: 'Description sous-catégorie 2',
//         ),
//       ];
//     }
//   }

//   List<Service> _getMockServices() {
//     return [
//       Service(
//         id: 1,
//         title: 'MICC Services',
//         description: 'Entreprise de maçonnerie',
//         imageUrl: 'https://picsum.photos/id/1029/300/200',
//         rating: 4.5,
//         reviewCount: 27,
//         provider_id: 1,
//         categoryId: 1,
//         businessType: 'Entreprise',
//         price: 80.0,
//       ),
//       Service(
//         id: 2,
//         title: 'MICC Services',
//         description: 'Entreprise de maçonnerie',
//         imageUrl: 'https://picsum.photos/id/1040/300/200',
//         rating: 3.8,
//         reviewCount: 15,
//         provider_id: 2,
//         categoryId: 1,
//         businessType: 'Entreprise',
//         price: 75.0,
//       ),
//       Service(
//         id: 3,
//         title: 'MICC Services',
//         description: 'Entreprise de maçonnerie',
//         imageUrl: 'https://picsum.photos/id/1076/300/200',
//         rating: 5.0,
//         reviewCount: 21,
//         provider_id: 3,
//         categoryId: 1,
//         businessType: 'Entreprise',
//         price: 120.0,
//       ),
//       Service(
//         id: 4,
//         title: 'MICC Services',
//         description: 'Entreprise de maçonnerie',
//         imageUrl: 'https://picsum.photos/id/1079/300/200',
//         rating: 4.2,
//         reviewCount: 18,
//         provider_id: 4,
//         categoryId: 1,
//         businessType: 'Entreprise',
//         price: 90.0,
//       ),
//       Service(
//         id: 5,
//         title: 'MICC Services',
//         description: 'Entreprise de maçonnerie',
//         imageUrl: 'https://picsum.photos/id/1082/300/200',
//         rating: 3.5,
//         reviewCount: 12,
//         provider_id: 5,
//         categoryId: 1,
//         businessType: 'Freelance',
//         price: 65.0,
//       ),
//     ];
//   }

//   Service _getMockServiceDetails(int serviceId) {
//     return Service(
//       id: serviceId,
//       title: 'MICC Services',
//       description:
//           'Entreprise spécialisée dans la maçonnerie et les travaux de rénovation.',
//       imageUrl: 'https://picsum.photos/id/1029/600/400',
//       rating: 4.5,
//       reviewCount: 27,
//       provider_id: 1,
//       categoryId: 1,
//       businessType: 'Entreprise',
//       price: 80.0,
//     );
//   }

//   ProviderModel _getMockProviderDetails(int providerId) {
//     return ProviderModel(
//       id: providerId,
//       name: 'Martin Construction',
//       businessType: 'Entreprise générale du bâtiment',
//       profileImageUrl:
//           'https://randomuser.me/api/portraits/men/$providerId.jpg',
//       rating: 4.5,
//       reviewCount: 127,
//       description:
//           'Spécialiste dans les travaux de construction, rénovation et aménagement. Notre équipe qualifiée intervient sur tout type de chantier avec un engagement fort autour de la qualité des finitions et le respect des délais.',
//       services: [
//         ServiceItem(
//           id: 1,
//           title: 'Construction neuve',
//           priceType: 'Sur devis',
//         ),
//         ServiceItem(
//           id: 2,
//           title:
//               'Construction complète de maisons individuelles et bâtiments professionnels',
//           priceType: 'Sur devis',
//         ),
//         ServiceItem(
//           id: 3,
//           title: 'Rénovation',
//           priceType: 'Sur devis',
//         ),
//       ],
//     );
//   }

//   ProviderModel _getMockProviderByService(int serviceId) {
//     return ProviderModel(
//       id: 1,
//       name: 'Martin Construction',
//       businessType: 'Entreprise générale du bâtiment',
//       profileImageUrl: 'https://randomuser.me/api/portraits/men/22.jpg',
//       rating: 4.5,
//       reviewCount: 127,
//       description:
//           'Spécialiste dans les travaux de construction, rénovation et aménagement. Notre équipe qualifiée intervient sur tout type de chantier avec un engagement fort autour de la qualité des finitions et le respect des délais.',
//       services: [
//         ServiceItem(
//           id: 1,
//           title: 'Construction neuve',
//           priceType: 'Sur devis',
//         ),
//         ServiceItem(
//           id: 2,
//           title:
//               'Construction complète de maisons individuelles et bâtiments professionnels',
//           priceType: 'Sur devis',
//         ),
//         ServiceItem(
//           id: 3,
//           title: 'Rénovation',
//           priceType: 'Sur devis',
//         ),
//       ],
//     );
//   }

//   Future<List<Service>> getProviderServices(int providerId) async {
//     try {
//       final headers = await getHeaders();
//       final response = await http.get(
//         Uri.parse('${baseUrl}/services/?provider_id=$providerId'),
//         headers: headers,
//       );

//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body)['results'] ?? [];
//         return data.map((item) => Service.fromJson(item)).toList();
//       } else {
//         throw Exception('Failed to load provider services: ${response.body}');
//       }
//     } catch (e) {
//       print('Error in getProviderServices: $e');
//       // En cas d'échec, retourner une liste vide ou autre gestion d'erreur
//       return [];
//     }
//   }

//   /// Récupérer la liste des projets avec filtres
//   // Future<Map<String, dynamic>> getProjects(
//   //     [Map<String, dynamic>? filters]) async {
//   //   try {
//   //     var uri = Uri.parse('$baseUrl/projects/');

//   //     if (filters != null && filters.isNotEmpty) {
//   //       uri = uri.replace(
//   //           queryParameters:
//   //               filters.map((key, value) => MapEntry(key, value.toString())));
//   //     }

//   //     final response = await http.get(
//   //       uri,
//   //       headers: await getHeaders(requireAuth: false),
//   //     );

//   //     if (response.statusCode == 200) {
//   //       final data = json.decode(response.body);
//   //       final projects = (data['results'] as List<dynamic>?)
//   //               ?.map((item) => ClientProject.fromJson(item))
//   //               .toList() ??
//   //           [];

//   //       return {
//   //         'projects': projects,
//   //         'hasMore': data['next'] != null,
//   //         'total': data['count'] ?? 0,
//   //       };
//   //     } else {
//   //       throw Exception('Failed to load projects: ${response.statusCode}');
//   //     }
//   //   } catch (e) {
//   //     print('Error in getProjects: $e');
//   //     // Retourner des données de test en cas d'erreur
//   //     return {
//   //       'projects': _getMockProjects(),
//   //       'hasMore': false,
//   //       'total': 1,
//   //     };
//   //   }
//   // }

//   /// Récupérer les projets par catégorie
//   Future<Map<String, dynamic>> getProjectsByCategory(int categoryId,
//       [Map<String, dynamic>? filters]) async {
//     final allFilters = filters ?? {};
//     allFilters['category'] = categoryId;
//     return getProjects(allFilters);
//   }

//   /// Récupérer un projet spécifique
//   Future<ClientProject> getProject(int projectId) async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/projects/$projectId/'),
//         headers: await getHeaders(),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return ClientProject.fromJson(data);
//       } else {
//         throw Exception('Failed to load project: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in getProject: $e');
//       throw e;
//     }
//   }

//   /// Créer un nouveau projet
//   // Future<ClientProject> createProject(
//   //     Map<String, dynamic> projectData, List<File?> attachments) async {
//   //   try {
//   //     var request =
//   //         http.MultipartRequest('POST', Uri.parse('$baseUrl/projects/'));

//   //     // Ajouter les headers d'authentification
//   //     final headers = await getHeaders();
//   //     request.headers.addAll(headers);

//   //     // Ajouter les données du projet
//   //     projectData.forEach((key, value) {
//   //       if (value != null) {
//   //         if (value is List) {
//   //           // Pour les compétences requises
//   //           request.fields[key] = json.encode(value);
//   //         } else {
//   //           request.fields[key] = value.toString();
//   //         }
//   //       }
//   //     });

//   //     // Ajouter les fichiers joints
//   //     for (int i = 0; i < attachments.length; i++) {
//   //       final file = attachments[i];
//   //       if (file != null) {
//   //         request.files.add(
//   //           await http.MultipartFile.fromPath(
//   //             'attachment${i + 1}',
//   //             file.path,
//   //           ),
//   //         );
//   //       }
//   //     }

//   //     final streamedResponse = await request.send();
//   //     final response = await http.Response.fromStream(streamedResponse);

//   //     if (response.statusCode == 201) {
//   //       final data = json.decode(response.body);
//   //       return ClientProject.fromJson(data);
//   //     } else {
//   //       final errorData = json.decode(response.body);
//   //       throw Exception(
//   //           'Failed to create project: ${errorData['detail'] ?? response.body}');
//   //     }
//   //   } catch (e) {
//   //     print('Error in createProject: $e');
//   //     throw e;
//   //   }
//   // }
//   Future<ClientProject> createProject(
//     Map<String, dynamic> projectData, List<File?> attachments) async {
//     try {
//       var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/projects/'));

//       // Ajouter les headers d'authentification
//       final headers = await getHeaders();
//       request.headers.addAll(headers);

//       // CORRECTION: Traitement manuel des champs pour éviter l'erreur forEach
//       // Ajouter les données du projet une par une
//       for (final entry in projectData.entries) {
//         final key = entry.key;
//         final value = entry.value;

//         if (value != null) {
//           if (value is List) {
//             // Pour les compétences requises - conversion sécurisée
//             try {
//               request.fields[key] = json.encode(value);
//             } catch (e) {
//               print('Error encoding list for key $key: $e');
//               // Fallback : convertir chaque élément en string
//               final stringList = value.map((item) => item.toString()).toList();
//               request.fields[key] = json.encode(stringList);
//             }
//           } else {
//             // Conversion sécurisée en string
//             request.fields[key] = value.toString();
//           }
//         }
//       }

//       // CORRECTION: Traitement sécurisé des fichiers attachments
//       // Utiliser une boucle for classique avec index explicite
//       final validAttachments = <File>[];

//       // Filtrer les attachments non-null d'abord
//       for (int i = 0; i < attachments.length; i++) {
//         final file = attachments[i];
//         if (file != null && file.existsSync()) {
//           validAttachments.add(file);
//         }
//       }

//       // Ajouter les fichiers valides
//       for (int index = 0; index < validAttachments.length && index < 3; index++) {
//         final file = validAttachments[index];
//         try {
//           final multipartFile = await http.MultipartFile.fromPath(
//             'attachment${index + 1}', // attachment1, attachment2, attachment3
//             file.path,
//           );
//           request.files.add(multipartFile);
//           print('Added attachment${index + 1}: ${file.path.split('/').last}');
//         } catch (e) {
//           print('Error adding attachment ${index + 1}: $e');
//           // Continuer avec les autres fichiers même si un fichier échoue
//         }
//       }

//       print('Sending project creation request with ${request.fields.length} fields and ${request.files.length} files');

//       final streamedResponse = await request.send();
//       final response = await http.Response.fromStream(streamedResponse);

//       print('Response status: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       if (response.statusCode == 201) {
//         final data = json.decode(response.body);
//         return ClientProject.fromJson(data);
//       } else {
//         // Gestion d'erreur améliorée
//         String errorMessage = 'Failed to create project';
//         try {
//           final errorData = json.decode(response.body);
//           if (errorData is Map<String, dynamic>) {
//             if (errorData.containsKey('detail')) {
//               errorMessage = errorData['detail'].toString();
//             } else if (errorData.containsKey('message')) {
//               errorMessage = errorData['message'].toString();
//             } else {
//               // Afficher les erreurs de validation spécifiques
//               final errors = <String>[];
//               errorData.forEach((key, value) {
//                 if (value is List) {
//                   errors.add('$key: ${value.join(', ')}');
//                 } else {
//                   errors.add('$key: $value');
//                 }
//               });
//               if (errors.isNotEmpty) {
//                 errorMessage = errors.join('; ');
//               }
//             }
//           }
//         } catch (e) {
//           errorMessage = 'HTTP ${response.statusCode}: ${response.body}';
//         }

//         throw Exception(errorMessage);
//       }
//     } catch (e) {
//       print('Error in createProject: $e');
//       if (e is Exception) {
//         rethrow;
//       } else {
//         throw Exception('Erreur lors de la création du projet: $e');
//       }
//     }
//   }

//   /// Récupérer les projets de l'utilisateur connecté
//   Future<List<ClientProject>> getMyProjects() async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/projects/my_projects/'),
//         headers: await getHeaders(),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return (data['results'] as List<dynamic>?)
//                 ?.map((item) => ClientProject.fromJson(item))
//                 .toList() ??
//             [];
//       } else {
//         throw Exception('Failed to load my projects: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in getMyProjects: $e');
//       return [];
//     }
//   }
//   Future<bool> closeProject(int projectId) async {
//   try {
//     print('🔒 Clôture du projet $projectId...');

//     final response = await http.patch(
//       Uri.parse('$baseUrl/projects/$projectId/close_project/'),
//       headers: await getHeaders(),
//     );

//     print('Réponse clôture projet: ${response.statusCode}');

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       print('✅ Projet clôturé avec succès');
//       print('Notifications envoyées: ${data['notifications_sent']}');
//       return true;
//     } else {
//       final errorData = json.decode(response.body);
//       throw Exception(errorData['error'] ?? 'Erreur lors de la clôture du projet');
//     }
//   } catch (e) {
//     print('❌ Erreur lors de la clôture du projet: $e');
//     throw e;
//   }
// }

// /// Mettre à jour le statut d'un projet
// Future<ClientProject> updateProjectStatus(int projectId, String newStatus) async {
//   try {
//     print('📝 Mise à jour du statut du projet $projectId vers "$newStatus"...');

//     final response = await http.patch(
//       Uri.parse('$baseUrl/projects/$projectId/update_status/'),
//       headers: await getHeaders(),
//       body: json.encode({'status': newStatus}),
//     );

//     print('Réponse mise à jour statut: ${response.statusCode}');

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       print('✅ Statut mis à jour avec succès');
//       return ClientProject.fromJson(data['project']);
//     } else {
//       final errorData = json.decode(response.body);
//       throw Exception(errorData['error'] ?? 'Erreur lors de la mise à jour du statut');
//     }
//   } catch (e) {
//     print('❌ Erreur lors de la mise à jour du statut: $e');
//     throw e;
//   }
// }

// /// Incrémenter le compteur de vues d'un projet
// Future<ClientProject> incrementProjectView(int projectId) async {
//   try {
//     print('👁️ Incrémentation des vues pour le projet $projectId...');

//     final response = await http.post(
//       Uri.parse('$baseUrl/projects/$projectId/increment_view/'),
//       headers: await getHeaders(),
//     );

//     print('Réponse incrémentation vue: ${response.statusCode}');

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       print('✅ Vue comptabilisée');
//       return ClientProject.fromJson(data);
//     } else {
//       final errorData = json.decode(response.body);
//       print('⚠️ Erreur vue: ${errorData['error']}');
//       // Pour les vues, on peut continuer même en cas d'erreur
//       throw Exception(errorData['error'] ?? 'Erreur lors de l\'incrémentation des vues');
//     }
//   } catch (e) {
//     print('❌ Erreur lors de l\'incrémentation des vues: $e');
//     throw e;
//   }
// }

// /// Obtenir les statistiques de vues d'un projet
// Future<Map<String, dynamic>> getProjectStatistics(int projectId) async {
//   try {
//     print('📊 Récupération des statistiques pour le projet $projectId...');

//     final response = await http.get(
//       Uri.parse('$baseUrl/projects/$projectId/view_statistics/'),
//       headers: await getHeaders(),
//     );

//     print('Réponse statistiques: ${response.statusCode}');

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       print('✅ Statistiques récupérées');
//       return data;
//     } else {
//       final errorData = json.decode(response.body);
//       throw Exception(errorData['error'] ?? 'Erreur lors de la récupération des statistiques');
//     }
//   } catch (e) {
//     print('❌ Erreur lors de la récupération des statistiques: $e');
//     throw e;
//   }
// }

// /// Supprimer un projet
// Future<bool> deleteProject(int projectId) async {
//   try {
//     print('🗑️ Suppression du projet $projectId...');

//     final response = await http.delete(
//       Uri.parse('$baseUrl/projects/$projectId/'),
//       headers: await getHeaders(),
//     );

//     print('Réponse suppression: ${response.statusCode}');

//     if (response.statusCode == 204) {
//       print('✅ Projet supprimé avec succès');
//       return true;
//     } else {
//       final errorData = response.body.isNotEmpty
//           ? json.decode(response.body)
//           : {'error': 'Erreur inconnue'};
//       throw Exception(errorData['error'] ?? 'Erreur lors de la suppression du projet');
//     }
//   } catch (e) {
//     print('❌ Erreur lors de la suppression du projet: $e');
//     throw e;
//   }
// }
//   /// Récupérer les statistiques des projets pour le client
//   Future<ProjectStats> getProjectStats() async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/projects/stats/'),
//         headers: await getHeaders(),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return ProjectStats.fromJson(data);
//       } else {
//         throw Exception('Failed to load project stats: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in getProjectStats: $e');
//       // Retourner des stats par défaut
//       return ProjectStats(
//         totalProjects: 0,
//         openProjects: 0,
//         completedProjects: 0,
//         totalOffers: 0,
//         averageOffersPerProject: 0.0,
//       );
//     }
//   }

//   /// Basculer un projet en favori (prestataires uniquement)
//   Future<bool> toggleProjectFavorite(int projectId) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/projects/$projectId/toggle_favorite/'),
//         headers: await getHeaders(),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return data['favorited'] ?? false;
//       } else {
//         throw Exception('Failed to toggle favorite: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in toggleProjectFavorite: $e');
//       throw e;
//     }
//   }

// //  // ===============================
//   // MÉTHODES POUR LES OFFRES
//   // ===============================

//   Future<void> submitOffer(int projectId, Map<String, dynamic> offerData) async {
//     try {
//       print('🚀 Soumission d\'offre pour le projet $projectId');
//       print('📝 Données envoyées: $offerData');

//       // Vérifier et formater les données avant envoi
//       final Map<String, dynamic> formattedData = {
//         'project': projectId, // Assurer que l'ID du projet est inclus
//         'proposed_price': _parseToDouble(offerData['proposed_price'] ?? offerData['price']),
//         'delivery_time': _parseToInt(offerData['delivery_time']),
//         'message': (offerData['message'] ?? '').toString().trim(),
//         'includes_materials': offerData['includes_materials'] ?? false,
//         'warranty_period': _parseToInt(offerData['warranty_period']),
//         'travel_costs_included': offerData['travel_costs_included'] ?? false,
//       };

//       // Supprimer les champs null ou vides
//       formattedData.removeWhere((key, value) =>
//           value == null ||
//           (value is String && value.isEmpty) ||
//           (value is num && value <= 0 && key != 'warranty_period')
//       );

//       print('📦 Données formatées: $formattedData');

//       final response = await http.post(
//         Uri.parse('$baseUrl/projects/$projectId/offers/'),
//         headers: await getHeaders(),
//         body: json.encode(formattedData),
//       );

//       print('📡 Réponse API: ${response.statusCode}');
//       print('📄 Corps de la réponse: ${response.body}');

//       if (response.statusCode == 201) {
//         print('✅ Offre créée avec succès');
//       } else {
//         // Analyser l'erreur pour donner un message plus précis
//         final errorData = json.decode(response.body);
//         String errorMessage = 'Erreur lors de l\'envoi de l\'offre';

//         if (errorData is Map<String, dynamic>) {
//           if (errorData.containsKey('detail')) {
//             errorMessage = errorData['detail'];
//           } else if (errorData.containsKey('non_field_errors')) {
//             errorMessage = (errorData['non_field_errors'] as List).join(', ');
//           } else {
//             // Collecter toutes les erreurs de validation
//             List<String> errors = [];
//             errorData.forEach((key, value) {
//               if (value is List) {
//                 errors.add('$key: ${value.join(', ')}');
//               } else {
//                 errors.add('$key: $value');
//               }
//             });
//             if (errors.isNotEmpty) {
//               errorMessage = errors.join('\n');
//             }
//           }
//         }

//         print('❌ Erreur API: $errorMessage');
//         throw Exception(errorMessage);
//       }
//     } catch (e) {
//       print('💥 Erreur complète: $e');
//       rethrow;
//     }
//   }

//   Future<void> createProjectOffer(Map<String, dynamic> offerData) async {
//     try {
//       // Essayer d'abord l'endpoint /project-offers/
//       var response = await http.post(
//         Uri.parse('$baseUrl/project-offers/'),
//         headers: await getHeaders(),
//         body: json.encode(offerData),
//       );

//       // Si 404, essayer l'endpoint alternatif
//       if (response.statusCode == 404) {
//         final projectId = offerData['project'];
//         response = await http.post(
//           Uri.parse('$baseUrl/projects/$projectId/offers/'),
//           headers: await getHeaders(),
//           body: json.encode(offerData),
//         );
//       }

//       // Si encore 404, essayer l'endpoint offers/ directement
//       if (response.statusCode == 404) {
//         response = await http.post(
//           Uri.parse('$baseUrl/offers/'),
//           headers: await getHeaders(),
//           body: json.encode(offerData),
//         );
//       }

//       if (response.statusCode != 201) {
//         final errorData = json.decode(response.body);
//         throw Exception(errorData['detail'] ?? 'Erreur lors de l\'envoi de l\'offre');
//       }
//     } catch (e) {
//       print('Error in createProjectOffer: $e');
//       throw e;
//     }
//   }

//   Future<List<dynamic>> getProjectOffers(int projectId) async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/projects/$projectId/offers/'),
//         headers: await getHeaders(),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return data['results'] ?? [];
//       } else {
//         throw Exception('Failed to load project offers: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in getProjectOffers: $e');
//       throw e;
//     }
//   }

//   /// Récupérer les offres du prestataire connecté
//   Future<List<ProjectOffer>> getMyOffers() async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/project-offers/'),
//         headers: await getHeaders(),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return (data['results'] as List<dynamic>?)
//                 ?.map((item) => ProjectOffer.fromJson(item))
//                 .toList() ??
//             [];
//       } else {
//         throw Exception('Failed to load my offers: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in getMyOffers: $e');
//       return [];
//     }
//   }

//   /// Mettre à jour le statut d'une offre (accepter/rejeter)
//   Future<ProjectOffer> updateOfferStatus(int offerId, String status,
//       {String? notes}) async {
//     try {
//       final data = {
//         'status': status,
//         if (notes != null) 'notes': notes,
//       };

//       final response = await http.patch(
//         Uri.parse('$baseUrl/project-offers/$offerId/update_status/'),
//         headers: await getHeaders(),
//         body: json.encode(data),
//       );

//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         return ProjectOffer.fromJson(responseData);
//       } else {
//         final errorData = json.decode(response.body);
//         throw Exception(errorData['error'] ?? 'Failed to update offer status');
//       }
//     } catch (e) {
//       print('Error in updateOfferStatus: $e');
//       throw e;
//     }
//   }

//   /// Retirer une offre (prestataire uniquement)
//   Future<void> withdrawOffer(int offerId) async {
//     try {
//       final response = await http.delete(
//         Uri.parse('$baseUrl/project-offers/$offerId/withdraw/'),
//         headers: await getHeaders(),
//       );

//       if (response.statusCode != 200) {
//         final errorData = json.decode(response.body);
//         throw Exception(errorData['error'] ?? 'Failed to withdraw offer');
//       }
//     } catch (e) {
//       print('Error in withdrawOffer: $e');
//       throw e;
//     }
//   }

//   /// Récupérer les projets favoris du prestataire
//   Future<List<ClientProject>> getFavoriteProjects() async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/project-favorites/'),
//         headers: await getHeaders(),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return (data['results'] as List<dynamic>?)
//                 ?.map((item) => ClientProject.fromJson(item['project']))
//                 .toList() ??
//             [];
//       } else {
//         throw Exception(
//             'Failed to load favorite projects: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in getFavoriteProjects: $e');
//       return [];
//     }
//   }

//   // Future<Map<String, dynamic>> getProjects([Map<String, dynamic>? filters]) async {
//   //   try {
//   //     var uri = Uri.parse('$baseUrl/projects/');

//   //     if (filters != null && filters.isNotEmpty) {
//   //       uri = uri.replace(queryParameters:
//   //         filters.map((key, value) => MapEntry(key, value.toString()))
//   //       );
//   //     }

//   //     // Appel SANS authentification requise pour permettre l'accès public
//   //     final response = await http.get(
//   //       uri,
//   //       headers: {
//   //         'Content-Type': 'application/json; charset=utf-8',
//   //         'Accept': 'application/json',
//   //       },
//   //     );

//   //     if (response.statusCode == 200) {
//   //       final data = json.decode(response.body);
//   //       final projects = (data['results'] as List<dynamic>?)
//   //           ?.map((item) => ClientProject.fromJson(item))
//   //           .toList() ?? [];

//   //       return {
//   //         'projects': projects,
//   //         'hasMore': data['next'] != null,
//   //         'total': data['count'] ?? 0,
//   //       };
//   //     } else if (response.statusCode == 401) {
//   //       // Si l'endpoint nécessite une authentification, retourner des données publiques limitées
//   //       print('Endpoint nécessite une authentification, utilisation des données mock');
//   //       return {
//   //         'projects': [],
//   //         'hasMore': false,
//   //         'total':0,
//   //       };
//   //     } else {
//   //       throw Exception('Failed to load projects: ${response.statusCode}');
//   //     }
//   //   } catch (e) {
//   //     print('Error in getProjects: $e');
//   //     // En cas d'erreur, retourner des données de test
//   //     return {
//   //       'projects': [],
//   //       'hasMore': false,
//   //       'total': [].length,
//   //     };
//   //   }
//   // }
//   Future<Map<String, dynamic>> getProjects(Map<String, dynamic> filters) async {
//     try {
//       // Construire les paramètres de requête
//       final queryParams = <String, String>{};

//       filters.forEach((key, value) {
//         if (value != null) {
//           queryParams[key] = value.toString();
//         }
//       });

//       final uri = Uri.parse('$baseUrl/projects/').replace(
//         queryParameters: queryParams.isNotEmpty ? queryParams : null,
//       );

//       final response = await http.get(
//         uri,
//         headers: await getHeaders(requireAuth: false),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final List<dynamic> projectsJson = data['results'] ?? [];

//         final projects = projectsJson.map((item) {
//           return ClientProject.fromJson(item);
//         }).toList();

//         return {
//           'projects': projects,
//           'count': data['count'] ?? 0,
//           'next': data['next'],
//           'previous': data['previous'],
//         };
//       } else {
//         throw Exception('Failed to load projects: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in getProjects: $e');
//       throw e;
//     }
//   }
//   /// Récupérer les services récents (accessible sans authentification)
//   Future<List<Service>> getRecentServices() async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/services/recent/'),
//         headers: {
//           'Content-Type': 'application/json; charset=utf-8',
//           'Accept': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body)['results'] ?? [];
//         return data.map((item) => Service.fromJson(item)).toList();
//       } else if (response.statusCode == 401) {
//         // Retourner des services publics limités
//         return [];
//       } else {
//         throw Exception('Failed to load recent services: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error in getRecentServices: $e');
//       return [];
//     }
//   }

//   // Méthodes utilitaires pour le parsing sécurisé
//   double? _parseToDouble(dynamic value) {
//     if (value == null) return null;
//     if (value is double) return value;
//     if (value is int) return value.toDouble();
//     if (value is String) {
//       return double.tryParse(value);
//     }
//     return null;
//   }
//   int? _parseToInt(dynamic value) {
//   if (value == null) return null;
//   if (value is int) return value;
//   if (value is double) return value.toInt();
//   if (value is String) {
//     return int.tryParse(value);
//   }
//   return null;
// }

// // === MÉTHODES MOCK POUR LES TESTS ===

//   // List<ClientProject> _getMockClientProjects() {
//   //   return [
//   //     ClientProject(
//   //       id: 1,
//   //       title: 'Création d\'un site web e-commerce',
//   //       description:
//   //           'Je recherche un développeur pour créer un site e-commerce complet avec gestion des stocks, paiements sécurisés et interface d\'administration.',
//   //       clientName: 'Marie Dubois',
//   //       categoryName: 'Développement web',
//   //       budgetRange: '1000_10000',
//   //       budgetDisplay: '3000AOA - 8000AOA',
//   //       location: 'Paris',
//   //       remotePossible: true,
//   //       urgency: 'medium',
//   //       status: 'open',
//   //       contactViaPlatform: true,
//   //       showEmail: false,
//   //       showPhone: false,
//   //       requiredSkills: [
//   //         ProjectSkill(id: 1, name: 'PHP', isRequired: true),
//   //         ProjectSkill(id: 2, name: 'JavaScript', isRequired: true),
//   //         ProjectSkill(id: 3, name: 'MySQL', isRequired: true),
//   //         ProjectSkill(id: 4, name: 'E-commerce', isRequired: false),
//   //       ],
//   //       offersCount: 12,
//   //       viewsCount: 45,
//   //       createdAt: DateTime.now().subtract(const Duration(hours: 6)),
//   //       timeSincePosted: 'Il y a 6 heures',
//   //       isFavorited: false,
//   //       hasUserOffered: false,
//   //     ),
//   //     ClientProject(
//   //       id: 2,
//   //       title: 'Design d\'une application mobile',
//   //       description:
//   //           'Recherche un designer UX/UI pour concevoir l\'interface d\'une application mobile de fitness avec suivi d\'activités et coaching personnalisé.',
//   //       clientName: 'Thomas Martin',
//   //       categoryName: 'Design graphique',
//   //       budgetRange: 'sur_devis',
//   //       budgetDisplay: 'Sur devis',
//   //       location: 'Lyon',
//   //       remotePossible: true,
//   //       urgency: 'high',
//   //       status: 'open',
//   //       contactViaPlatform: true,
//   //       showEmail: true,
//   //       showPhone: false,
//   //       requiredSkills: [
//   //         ProjectSkill(id: 5, name: 'UI/UX Design', isRequired: true),
//   //         ProjectSkill(id: 6, name: 'Figma', isRequired: true),
//   //         ProjectSkill(id: 7, name: 'Prototypage', isRequired: false),
//   //       ],
//   //       offersCount: 8,
//   //       viewsCount: 32,
//   //       createdAt: DateTime.now().subtract(const Duration(days: 2)),
//   //       timeSincePosted: 'Il y a 2 jours',
//   //       isFavorited: true,
//   //       hasUserOffered: false,
//   //     ),
//   //     ClientProject(
//   //       id: 3,
//   //       title: 'Rénovation d\'appartement',
//   //       description:
//   //           'Rénovation complète d\'un appartement de 80m² : peinture, parquet, salle de bain, cuisine. Travaux à prévoir sur 6 semaines.',
//   //       clientName: 'Sophie Laurent',
//   //       categoryName: 'Rénovation',
//   //       budgetRange: '10000_plus',
//   //       budgetDisplay: '15000AOA - 25000AOA',
//   //       location: 'Marseille',
//   //       remotePossible: false,
//   //       urgency: 'low',
//   //       status: 'open',
//   //       contactViaPlatform: true,
//   //       showEmail: false,
//   //       showPhone: true,
//   //       requiredSkills: [
//   //         ProjectSkill(id: 8, name: 'Peinture', isRequired: true),
//   //         ProjectSkill(id: 9, name: 'Carrelage', isRequired: true),
//   //         ProjectSkill(id: 10, name: 'Plomberie', isRequired: false),
//   //       ],
//   //       offersCount: 5,
//   //       viewsCount: 18,
//   //       createdAt: DateTime.now().subtract(const Duration(days: 1)),
//   //       timeSincePosted: 'Il y a 1 jour',
//   //       isFavorited: false,
//   //       hasUserOffered: true,
//   //     ),
//   //   ];
//   // }

//   // List<Review> _getMockReviews() {
//   //   return [
//   //     Review(
//   //       id: 1,
//   //       userName: 'Jean Dupont',
//   //       userImageUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
//   //       rating: 5.0,
//   //       comment:
//   //           'Excellent travail, je suis très satisfait du résultat. L\'équipe était professionnelle et ponctuelle.',
//   //       date: DateTime.now().subtract(const Duration(days: 2)),
//   //     ),
//   //     Review(
//   //       id: 2,
//   //       userName: 'Marie Leclerc',
//   //       userImageUrl: 'https://randomuser.me/api/portraits/women/2.jpg',
//   //       rating: 4.0,
//   //       comment:
//   //           'Bon travail dans l\'ensemble, quelques petits détails à améliorer mais je recommande.',
//   //       date: DateTime.now().subtract(const Duration(days: 15)),
//   //     ),
//   //     Review(
//   //       id: 3,
//   //       userName: 'Pierre Martin',
//   //       userImageUrl: 'https://randomuser.me/api/portraits/men/3.jpg',
//   //       rating: 5.0,
//   //       comment:
//   //           'Très professionnel, travail soigné et dans les délais. Je recommande vivement !',
//   //       date: DateTime.now().subtract(const Duration(days: 30)),
//   //     ),
//   //   ];
//   // }
// }

// List<Subcategory> _getMockSubcategories(int categoryId) {
//   if (categoryId == 1) {
//     return [
//       Subcategory(
//         id: 1,
//         name: 'Construction & rénovation',
//         categoryId: 1,
//         description: 'Services de construction et rénovation',
//       ),
//       Subcategory(
//         id: 2,
//         name: 'Plomberie',
//         categoryId: 1,
//         description: 'Services de plomberie',
//       ),
//       Subcategory(
//         id: 3,
//         name: 'Électricité',
//         categoryId: 1,
//         description: 'Services d\'électricité',
//       ),
//     ];
//   } else {
//     return [
//       Subcategory(
//         id: 4,
//         name: 'Sous-catégorie 1',
//         categoryId: categoryId,
//         description: 'Description sous-catégorie 1',
//       ),
//       Subcategory(
//         id: 5,
//         name: 'Sous-catégorie 2',
//         categoryId: categoryId,
//         description: 'Description sous-catégorie 2',
//       ),
//     ];
//   }
// }
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../models/project_offer.dart';
import '../models/project_skill.dart';
import '../models/project_stats.dart';
import '../api/api_client.dart';
import '../models/notification_model.dart';

class ApiService {
  final String baseUrl;
  final String apiKey;
  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ApiService({
    required this.baseUrl,
    required this.apiKey,
  }) : _apiClient = ApiClient(baseUrl: baseUrl);

  // ===============================
  // MÉTHODES POUR LES STATISTIQUES PRESTATAIRE
  // ===============================
  Future<bool> _attemptTokenRefresh() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) {
        print('❌ Aucun refresh token disponible');
        return false;
      }

      print('🔄 Rafraîchissement du token...');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/token/refresh/'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: json.encode({'refresh': refreshToken}),
      );

      print('Réponse refresh token: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final newAccessToken = data['access'];

        // Sauvegarder le nouveau token d'accès
        await _secureStorage.write(key: 'access_token', value: newAccessToken);

        print('✅ Token rafraîchi et sauvegardé');
        return true;
      } else {
        print(
            '❌ Échec du rafraîchissement: ${response.statusCode} - ${response.body}');

        // Supprimer les tokens invalides
        await _secureStorage.delete(key: 'access_token');
        await _secureStorage.delete(key: 'refresh_token');

        return false;
      }
    } catch (e) {
      print('❌ Erreur lors du rafraîchissement du token: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getProviderStatsById(int providerId) async {
    try {
      print('📊 Récupération des statistiques du prestataire $providerId...');
      
      final data = await _apiClient.get('providers-public/$providerId/stats/', requireAuth: false);
      
      print('✅ Statistiques prestataire récupérées');
      return data;
    } catch (e) {
      print('❌ Erreur dans getProviderStatsById: $e');
      // Retourner des données par défaut en cas d'erreur
      return {
        'total_completed_projects': 0,
        'avg_rating': 0.0,
        'total_reviews': 0,
      };
    }
  }


  Future<Map<String, dynamic>> getProviderStats() async {
    try {
      print('📊 Récupération des statistiques prestataire...');

      // Essayer plusieurs endpoints possibles
      Map<String, dynamic>? data;

      try {
        // Essayer l'endpoint principal
        data = await _apiClient.get('providers/stats/', requireAuth: true);
      } catch (e) {
        print(
            '📊 Tous les endpoints ont échoué, utilisation de données simulées');
        throw Exception('Stats endpoints not available');
      }

      print('✅ Statistiques récupérées avec succès');
      return data ?? {};
    } catch (e) {
      print('❌ Erreur dans getProviderStats: $e');

      // Retourner des données simulées réalistes
      return {
        'prestations_completed_this_month': 0,
        'prestations_in_progress': 0,
        'unread_messages': 0,
        'total_earnings_this_month': 00, // En FCFA
        'avg_rating': 0,
        'total_reviews': 0,
      };
    }
  }

  // ===============================
  // MÉTHODES POUR LES UTILISATEURS
  // ===============================
  Future<User> getUserById(int userId) async {
    try {
      print('👤 Récupération utilisateur par ID: $userId...');

      // ✅ UTILISER LE NOUVEAU ENDPOINT AVEC ID
      final data = await _apiClient.get('user/$userId/',
          requireAuth: false); // Pas d'auth requise

      // Vérifier la structure de la réponse
      if (data != null && data['user'] != null) {
        final user = User.fromJson(data['user']);
        print('✅ Utilisateur récupéré par ID: ${user.username}');
        return user;
      } else if (data != null) {
        // Si la réponse est directement l'utilisateur
        final user = User.fromJson(data);
        print('✅ Utilisateur récupéré par ID: ${user.username}');
        return user;
      } else {
        throw Exception('Réponse vide du serveur');
      }
    } catch (e) {
      print('❌ Erreur dans getUserById: $e');
      rethrow;
    }
  }

  // Modifiez getCurrentUser pour utiliser getUserById :
  Future<User> getCurrentUser() async {
    try {
      print('👤 Récupération de l\'utilisateur actuel...');

      // D'abord, essayez de récupérer l'ID utilisateur depuis le cache local
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');

      if (userData != null) {
        try {
          final user = User.fromJsonString(userData);
          print('📱 Utilisation du cache local pour user ID: ${user.id}');

          // Utiliser getUserById avec l'ID du cache
          return await getUserById(user.id);
        } catch (e) {
          print('❌ Erreur cache local: $e');
        }
      }

      // Si pas de cache, essayer avec l'endpoint original
      try {
        final data = await _apiClient.get('current-user/', requireAuth: true);

        if (data != null && data['user'] != null) {
          final user = User.fromJson(data['user']);
          print('✅ Utilisateur récupéré via current-user: ${user.username}');
          return user;
        }
      } catch (e) {
        print('❌ Échec current-user: $e');
      }

      throw Exception('Impossible de récupérer l\'utilisateur actuel');
    } catch (e) {
      print('❌ Erreur dans getCurrentUser: $e');
      rethrow;
    }
  }

  Future<int> getCurrentUserId() async {
    try {
      final user = await getCurrentUser();
      return user.id;
    } catch (e) {
      print('❌ Erreur dans getCurrentUserId: $e');
      throw Exception("Utilisateur non connecté");
    }
  }

  // ===============================
  // MÉTHODES POUR LES CATÉGORIES
  // ===============================

  Future<List<Category>> getCategories() async {
    try {
      print('📂 Récupération des catégories...');

      final data = await _apiClient.get('categories/', requireAuth: false);

      final List<dynamic> categoriesData = data['results'] ?? [];
      final categories =
          categoriesData.map((item) => Category.fromJson(item)).toList();

      print('✅ Catégories récupérées: ${categories.length}');
      return categories;
    } catch (e) {
      print('❌ Erreur dans getCategories: $e');
      return _getMockCategories();
    }
  }

  Future<List<Subcategory>> getSubcategories(int categoryId) async {
    try {
      print(
          '📂 Récupération des sous-catégories pour la catégorie $categoryId...');

      final data = await _apiClient
          .get('subcategories/?category_id=$categoryId', requireAuth: false);

      final List<dynamic> subcategoriesData = data['results'] ?? [];
      final subcategories =
          subcategoriesData.map((item) => Subcategory.fromJson(item)).toList();

      print('✅ Sous-catégories récupérées: ${subcategories.length}');
      return subcategories;
    } catch (e) {
      print('❌ Erreur dans getSubcategories: $e');
      return _getMockSubcategories(categoryId);
    }
  }

  // ===============================
  // MÉTHODES POUR LES SERVICES
  // ===============================

  Future<List<Service>> getRecentServices() async {
    try {
      print('🔧 Récupération des services récents...');

      final data = await _apiClient.get('services/recent/', requireAuth: false);

      final List<dynamic> servicesData = data['results'] ?? [];
      final services =
          servicesData.map((item) => Service.fromJson(item)).toList();

      print('✅ Services récents récupérés: ${services.length}');
      return services;
    } catch (e) {
      print('❌ Erreur dans getRecentServices: $e');
      return [];
    }
  }

  Future<List<Service>> getNearbyServices() async {
    try {
      print('🔧 Récupération des services à proximité...');

      final position = await _getCurrentPosition();

      String endpoint = 'services/nearby/';
      if (position != null) {
        endpoint +=
            '?latitude=${position.latitude}&longitude=${position.longitude}';
      }

      final data = await _apiClient.get(endpoint, requireAuth: false);

      final List<dynamic> servicesData = data['results'] ?? [];
      final services =
          servicesData.map((item) => Service.fromJson(item)).toList();

      print('✅ Services à proximité récupérés: ${services.length}');
      return services;
    } catch (e) {
      print('❌ Erreur dans getNearbyServices: $e');
      return [];
    }
  }

  Future<List<Service>> getServicesByCategory(int categoryId) async {
    try {
      print('🔧 Récupération des services pour la catégorie $categoryId...');

      final data = await _apiClient.get('services/?category_id=$categoryId',
          requireAuth: false);

      final List<dynamic> servicesData = data['results'] ?? [];
      final services =
          servicesData.map((item) => Service.fromJson(item)).toList();

      print('✅ Services par catégorie récupérés: ${services.length}');
      return services;
    } catch (e) {
      print('❌ Erreur dans getServicesByCategory: $e');
      return [];
    }
  }

  Future<List<Service>> getServicesBySubcategory(int subcategoryId) async {
    try {
      print(
          '🔧 Récupération des services pour la sous-catégorie $subcategoryId...');

      final data = await _apiClient
          .get('services/?subcategory_id=$subcategoryId', requireAuth: false);

      final List<dynamic> servicesData = data['results'] ?? [];
      final services =
          servicesData.map((item) => Service.fromJson(item)).toList();

      print('✅ Services par sous-catégorie récupérés: ${services.length}');
      return services;
    } catch (e) {
      print('❌ Erreur dans getServicesBySubcategory: $e');
      return [];
    }
  }

  Future<Service> getServiceDetails(int serviceId) async {
    try {
      print('🔧 Récupération des détails du service $serviceId...');

      final data =
          await _apiClient.get('services/$serviceId/', requireAuth: false);

      final service = Service.fromJson(data);
      print('✅ Détails du service récupérés: ${service.title}');

      return service;
    } catch (e) {
      print('❌ Erreur dans getServiceDetails: $e');
      return _getMockServiceDetails(serviceId);
    }
  }

  Future<int> getServiceCountByCategory(int categoryId) async {
    try {
      print(
          '📊 Récupération du nombre de services pour la catégorie $categoryId...');

      final data = await _apiClient
          .get('services/count/?category_id=$categoryId', requireAuth: false);

      final count = data['count'] ?? 0;
      print('✅ Nombre de services: $count');

      return count;
    } catch (e) {
      print('❌ Erreur dans getServiceCountByCategory: $e');
      return _getMockServiceCountByCategory(categoryId);
    }
  }

  Future<int> getServiceCountBySubcategory(int subcategoryId) async {
    try {
      print(
          '📊 Récupération du nombre de services pour la sous-catégorie $subcategoryId...');

      final data = await _apiClient.get(
          'services/count_by_subcategory/?subcategory_id=$subcategoryId',
          requireAuth: false);

      final count = data['count'] ?? 0;
      print('✅ Nombre de services: $count');

      return count;
    } catch (e) {
      print('❌ Erreur dans getServiceCountBySubcategory: $e');
      return _getMockServiceCountBySubcategory(subcategoryId);
    }
  }

  // ===============================
  // MÉTHODES POUR LES PRESTATAIRES
  // ===============================

  Future<List<ProviderModel>> getProviders() async {
    try {
      print('👥 Récupération des prestataires...');

      final data = await _apiClient.get('providers/', requireAuth: false);
      print('📥 Données brutes reçues: $data'); // Debug

      final List<dynamic> providersData = data['results'] ?? [];
      print(
          '📋 Nombre de prestataires dans les données: ${providersData.length}');

      final List<ProviderModel> providers = [];
      final Set<int> seenIds = <int>{};

      // ✅ Parser chaque provider individuellement avec gestion d'erreurs
      for (int i = 0; i < providersData.length; i++) {
        try {
          final providerJson = providersData[i];
          print(
              '🔍 Parsing provider $i: ${providerJson['id']} - ${providerJson['name']}');

          final provider = ProviderModel.fromJson(providerJson);

          // ✅ Vérifier les doublons
          if (seenIds.contains(provider.id)) {
            print('⚠️ Provider ${provider.id} déjà vu, ignoré');
            continue;
          }

          seenIds.add(provider.id);
          providers.add(provider);
        } catch (e, stackTrace) {
          print('❌ Erreur parsing provider $i: $e');
          print('📋 Données problématiques: ${providersData[i]}');
          print('📍 Stack trace: $stackTrace');
          // Continuer avec les autres providers
        }
      }

      print('✅ Prestataires récupérés avec succès: ${providers.length}');
      return providers;
    } catch (e, stackTrace) {
      print('❌ Erreur dans getProviders: $e');
      print('📍 Stack trace: $stackTrace');
      return _getMockProviders(); // Fallback
    }
  }

  Future<List<ProviderModel>> getProvidersByCategory(int categoryId) async {
    try {
      print(
          '👥 Récupération des prestataires pour la catégorie $categoryId...');

      final data = await _apiClient.get(
          'providers/by_category/?category_id=$categoryId',
          requireAuth: false);

      final List<dynamic> providersData = data['results'] ?? [];
      final providers =
          providersData.map((item) => ProviderModel.fromJson(item)).toList();

      print('✅ Prestataires par catégorie récupérés: ${providers.length}');
      return providers;
    } catch (e) {
      print('❌ Erreur dans getProvidersByCategory: $e');
      return _getMockProviders()
          .where((p) => p.id % 5 == categoryId % 5)
          .toList();
    }
  }

  Future<List<ProviderModel>> getProvidersBySubcategory(
      int subcategoryId) async {
    try {
      print(
          '👥 Récupération des prestataires pour la sous-catégorie $subcategoryId...');

      final data = await _apiClient.get(
          'providers/by_subcategory/?subcategory_id=$subcategoryId',
          requireAuth: false);

      final List<dynamic> providersData = data['results'] ?? [];
      final providers =
          providersData.map((item) => ProviderModel.fromJson(item)).toList();

      print('✅ Prestataires par sous-catégorie récupérés: ${providers.length}');
      return providers;
    } catch (e) {
      print('❌ Erreur dans getProvidersBySubcategory: $e');
      return _getMockProviders()
          .where((p) => p.id % 10 == subcategoryId % 10)
          .toList();
    }
  }

  Future<List<ProviderModel>> getNearbyProviders(
      double latitude, double longitude,
      {double radius = 10.0}) async {
    try {
      print('👥 Récupération des prestataires à proximité...');

      final queryParams = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius.toString(),
      };

      String endpoint = 'providers/nearby/?';
      endpoint +=
          queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

      final data = await _apiClient.get(endpoint, requireAuth: false);

      final List<dynamic> providersData = data['results'] ?? [];
      final providers =
          providersData.map((item) => ProviderModel.fromJson(item)).toList();

      print('✅ Prestataires à proximité récupérés: ${providers.length}');
      return providers;
    } catch (e) {
      print('❌ Erreur dans getNearbyProviders: $e');
      return _getMockProvidersWithCoordinates(latitude, longitude);
    }
  }

  Future<ProviderModel> getProviderDetails(int providerId) async {
    try {
      print('👥 Récupération des détails du prestataire $providerId...');

      final data =
          await _apiClient.get('providers/$providerId/', requireAuth: false);

      final provider = ProviderModel.fromJson(data);
      print('✅ Détails du prestataire récupérés: ${provider.name}');

      return provider;
    } catch (e) {
      print('❌ Erreur dans getProviderDetails: $e');
      return _getMockProviderDetails(providerId);
    }
  }

  Future<Map<String, dynamic>?> getProjectDetails(int projectId) async {
    try {
      print('📋 Récupération des détails du projet $projectId...');

      // Charger les détails complets du projet
      final data =
          await _apiClient.get('projects/$projectId/', requireAuth: true);

      if (data != null) {
        print('✅ Détails du projet récupérés avec succès');
        return data;
      } else {
        print('⚠️ Aucune donnée reçue pour le projet $projectId');
        return null;
      }
    } catch (e) {
      print('❌ Erreur dans getProjectDetails: $e');
      return null;
    }
  }

  Future<ProviderModel> getProviderByServiceId(int serviceId) async {
    try {
      print('👥 Récupération du prestataire pour le service $serviceId...');

      final data = await _apiClient.get('providers/by-service/$serviceId/',
          requireAuth: false);

      final provider = ProviderModel.fromJson(data);
      print('✅ Prestataire récupéré: ${provider.name}');

      return provider;
    } catch (e) {
      print('❌ Erreur dans getProviderByServiceId: $e');
      return _getMockProviderByService(serviceId);
    }
  }

  Future<List<Service>> getProviderServices(int providerId) async {
    try {
      print('🔧 Récupération des services du prestataire $providerId...');

      final data = await _apiClient.get('services/?provider_id=$providerId',
          requireAuth: false);

      final List<dynamic> servicesData = data['results'] ?? [];
      final services =
          servicesData.map((item) => Service.fromJson(item)).toList();

      print('✅ Services du prestataire récupérés: ${services.length}');
      return services;
    } catch (e) {
      print('❌ Erreur dans getProviderServices: $e');
      return [];
    }
  }

  Future<List<Review>> getProviderReviews(int providerId) async {
    try {
      print('⭐ Récupération des avis du prestataire $providerId...');

      final data = await _apiClient.get('reviews/?provider_id=$providerId',
          requireAuth: false);

      final List<dynamic> reviewsData = data['results'] ?? [];
      final reviews = reviewsData.map((item) => Review.fromJson(item)).toList();

      print('✅ Avis récupérés: ${reviews.length}');
      return reviews;
    } catch (e) {
      print('❌ Erreur dans getProviderReviews: $e');
      return [];
    }
  }

  // ===============================
  // MÉTHODES POUR LES PROJETS
  // ===============================

  Future<Map<String, dynamic>> getProjects(Map<String, dynamic> filters) async {
    try {
      print('📋 Récupération des projets avec filtres: $filters');

      String endpoint = 'projects/';
      if (filters.isNotEmpty) {
        final queryParams = filters.entries
            .where((entry) => entry.value != null)
            .map((entry) =>
                '${entry.key}=${Uri.encodeComponent(entry.value.toString())}')
            .join('&');
        endpoint += '?$queryParams';
      }

      final data = await _apiClient.get(endpoint, requireAuth: false);

      final List<dynamic> projectsJson = data['results'] ?? [];
      final projects = projectsJson
          .map((item) {
            try {
              return ClientProject.fromJson(item);
            } catch (e) {
              print('❌ Erreur lors du parsing du projet: $e');
              print('Données du projet problématique: $item');
              // Ignorer ce projet et continuer
              return null;
            }
          })
          .where((project) => project != null)
          .cast<ClientProject>()
          .toList();

      print('✅ Projets récupérés: ${projects.length}');

      return {
        'projects': projects,
        'count': data['count'] ?? 0,
        'next': data['next'],
        'previous': data['previous'],
        'hasMore': data['next'] != null, // Ajouter explicitement hasMore
      };
    } catch (e) {
      print('❌ Erreur dans getProjects: $e');
      // Retourner une structure par défaut en cas d'erreur
      return {
        'projects': <ClientProject>[],
        'count': 0,
        'next': null,
        'previous': null,
        'hasMore': false,
      };
    }
  }

  Future<Map<String, dynamic>> getProjectsByCategory(int categoryId,
      [Map<String, dynamic>? filters]) async {
    final allFilters = filters ?? {};
    allFilters['category'] = categoryId;
    return getProjects(allFilters);
  }

  Future<ClientProject> getProject(int projectId) async {
    try {
      print('📋 Récupération du projet $projectId...');

      final data =
          await _apiClient.get('projects/$projectId/', requireAuth: true);

      final project = ClientProject.fromJson(data);
      print('✅ Projet récupéré: ${project.title}');

      return project;
    } catch (e) {
      print('❌ Erreur dans getProject: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>> getUserProjects() async {
    try {
      print('📋 Récupération des projets utilisateur...');

      final data =
          await _apiClient.get('projects/my_projects/', requireAuth: true);

      final List<dynamic> projectsJson = data['results'] ?? [];
      final projects =
          projectsJson.map((item) => ClientProject.fromJson(item)).toList();

      print('✅ Projets utilisateur récupérés: ${projects.length}');

      return {
        'projects': projects,
        'count': data['count'] ?? 0,
      };
    } catch (e) {
      print('❌ Erreur dans getUserProjects: $e');
      throw e;
    }
  }

  Future<List<ClientProject>> getMyProjects() async {
    try {
      print('📋 Récupération de mes projets...');

      final data =
          await _apiClient.get('projects/my_projects/', requireAuth: true);

      final List<dynamic> projectsJson = data['results'] ?? [];
      final projects =
          projectsJson.map((item) => ClientProject.fromJson(item)).toList();

      print('✅ Mes projets récupérés: ${projects.length}');
      return projects;
    } catch (e) {
      print('❌ Erreur dans getMyProjects: $e');
      return [];
    }
  }

  Future<ProjectStats> getProjectStats() async {
    try {
      print('📊 Récupération des statistiques projets...');

      final data = await _apiClient.get('projects/stats/', requireAuth: true);

      final stats = ProjectStats.fromJson(data);
      print('✅ Statistiques projets récupérées');

      return stats;
    } catch (e) {
      print('❌ Erreur dans getProjectStats: $e');
      return ProjectStats(
        totalProjects: 0,
        openProjects: 0,
        completedProjects: 0,
        totalOffers: 0,
        averageOffersPerProject: 0.0,
      );
    }
  }

  Future<bool> closeProject(int projectId) async {
    try {
      print('Clôture du projet $projectId...');

      // CHANGEMENT: PUT -> PATCH
      final data = await _apiClient.patch('projects/$projectId/close_project/',
          requireAuth: true);

      print('Projet clôturé avec succès');
      print('Notifications envoyées: ${data['notifications_sent']}');

      return true;
    } catch (e) {
      print('Erreur lors de la clôture du projet: $e');
      throw e;
    }
  }

  Future<ClientProject> updateProjectStatus(
    int projectId, String newStatus) async {
    try {
      print('Mise à jour du statut du projet $projectId vers "$newStatus"...');

      // CHANGEMENT: PUT -> PATCH
      final data = await _apiClient.patch('projects/$projectId/update_status/',
          data: {'status': newStatus}, requireAuth: true);

      print('Statut du projet mis à jour avec succès');
      return ClientProject.fromJson(data);
    } catch (e) {
      print('Erreur lors de la mise à jour du statut: $e');
      throw e;
    }
  }

  Future<ClientProject> incrementProjectView(int projectId) async {
    try {
      print('👁️ Incrémentation des vues pour le projet $projectId...');

      final data = await _apiClient.post('projects/$projectId/increment_view/',
          requireAuth: true);

      print('✅ Vue comptabilisée');
      return ClientProject.fromJson(data);
    } catch (e) {
      print('❌ Erreur lors de l\'incrémentation des vues: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>> getProjectStatistics(int projectId) async {
    try {
      print('📊 Récupération des statistiques pour le projet $projectId...');

      final data = await _apiClient.get('projects/$projectId/view_statistics/',
          requireAuth: true);

      print('✅ Statistiques récupérées');
      return data;
    } catch (e) {
      print('❌ Erreur lors de la récupération des statistiques: $e');
      throw e;
    }
  }

  Future<bool> deleteProject(int projectId) async {
    try {
      print('🗑️ Suppression du projet $projectId...');

      await _apiClient.delete('projects/$projectId/', requireAuth: true);

      print('✅ Projet supprimé avec succès');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la suppression du projet: $e');
      throw e;
    }
  }

  // ===============================
  // MÉTHODES POUR LES OFFRES
  // ===============================
  Future<void> createProjectOffer(Map<String, dynamic> offerData) async {
    try {
      print('🚀 Création d\'offre de projet...');
      print('📝 Données: $offerData');

      // Essayer d'abord l'endpoint /project-offers/ avec ApiClient
      try {
        await _apiClient.post('project-offers/',
            data: offerData, requireAuth: true);
        print('✅ Offre créée via /project-offers/');
        return;
      } catch (e) {
        print('⚠️ Échec /project-offers/, tentative endpoint alternatif...');
      }

      // Si 404, essayer l'endpoint alternatif /projects/{id}/offers/
      final projectId = offerData['project'];
      if (projectId != null) {
        try {
          await _apiClient.post('projects/$projectId/offers/',
              data: offerData, requireAuth: true);
          print('✅ Offre créée via /projects/$projectId/offers/');
          return;
        } catch (e) {
          print(
              '⚠️ Échec /projects/$projectId/offers/, tentative endpoint /offers/...');
        }
      }

      // Si encore 404, essayer l'endpoint /offers/ directement
      try {
        await _apiClient.post('offers/', data: offerData, requireAuth: true);
        print('✅ Offre créée via /offers/');
        return;
      } catch (e) {
        print('❌ Échec de tous les endpoints d\'offres');
        throw Exception('Tous les endpoints d\'offres ont échoué: $e');
      }
    } catch (e) {
      print('❌ Erreur dans createProjectOffer: $e');

      // Fournir un message d'erreur plus spécifique
      if (e.toString().contains('404')) {
        throw Exception(
            'Endpoint d\'offres non trouvé. Vérifiez la configuration de l\'API.');
      } else if (e.toString().contains('401')) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      } else if (e.toString().contains('400')) {
        throw Exception(
            'Données d\'offre invalides. Vérifiez les informations saisies.');
      } else {
        throw Exception('Erreur lors de l\'envoi de l\'offre: $e');
      }
    }
  }

  Future<void> submitOffer(
      int projectId, Map<String, dynamic> offerData) async {
    try {
      print('🚀 Soumission d\'offre pour le projet $projectId');

      final Map<String, dynamic> formattedData = {
        'project': projectId,
        'proposed_price':
            _parseToDouble(offerData['proposed_price'] ?? offerData['price']),
        'delivery_time': _parseToInt(offerData['delivery_time']),
        'message': (offerData['message'] ?? '').toString().trim(),
        'includes_materials': offerData['includes_materials'] ?? false,
        'warranty_period': _parseToInt(offerData['warranty_period']),
        'travel_costs_included': offerData['travel_costs_included'] ?? false,
      };

      formattedData.removeWhere((key, value) =>
          value == null ||
          (value is String && value.isEmpty) ||
          (value is num && value <= 0 && key != 'warranty_period'));

      await _apiClient.post('projects/$projectId/offers/',
          data: formattedData, requireAuth: true);

      print('✅ Offre créée avec succès');
    } catch (e) {
      print('❌ Erreur dans submitOffer: $e');
      throw e;
    }
  }

  Future<List<ProjectOffer>> getMyOffers() async {
    try {
      print('📋 Récupération de mes offres...');

      final data = await _apiClient.get('project-offers/', requireAuth: true);

      final List<dynamic> offersData = data['results'] ?? [];
      final offers =
          offersData.map((item) => ProjectOffer.fromJson(item)).toList();

      print('✅ Mes offres récupérées: ${offers.length}');
      return offers;
    } catch (e) {
      print('❌ Erreur dans getMyOffers: $e');
      return [];
    }
  }

  Future<List<dynamic>> getProjectOffers(int projectId) async {
    try {
      print('📋 Récupération des offres pour le projet $projectId...');

      // Utiliser l'endpoint project-offers avec un filtre
      final data = await _apiClient.get('project-offers/?project=$projectId',
          requireAuth: true);

      final List<dynamic> offers = data['results'] ?? [];

      // Enrichir les données d'offres avec l'ID du provider si manquant
      for (var offer in offers) {
        if (offer['provider'] != null) {
          // Si provider est un objet, extraire l'ID
          if (offer['provider'] is Map<String, dynamic>) {
            offer['provider_id'] = offer['provider']['id'];
          } else if (offer['provider'] is int) {
            // Si provider est déjà un ID
            offer['provider_id'] = offer['provider'];
          }
        }
      }

      print('✅ Offres récupérées: ${offers.length}');
      return offers;
    } catch (e) {
      print('❌ Erreur dans getProjectOffers: $e');
      return [];
    }
  }

  Future<ProjectOffer> updateOfferStatus(int offerId, String status,
      {String? notes}) async {
    try {
      print('📝 Mise à jour du statut de l\'offre $offerId...');

      final data =
          await _apiClient.put('project-offers/$offerId/update_status/',
              data: {
                'status': status,
                if (notes != null) 'notes': notes,
              },
              requireAuth: true);

      print('✅ Statut de l\'offre mis à jour');
      return ProjectOffer.fromJson(data);
    } catch (e) {
      print('❌ Erreur dans updateOfferStatus: $e');
      throw e;
    }
  }

  Future<void> withdrawOffer(int offerId) async {
    try {
      print('🗑️ Retrait de l\'offre $offerId...');

      await _apiClient.delete('project-offers/$offerId/withdraw/',
          requireAuth: true);

      print('✅ Offre retirée avec succès');
    } catch (e) {
      print('❌ Erreur dans withdrawOffer: $e');
      throw e;
    }
  }

  // ===============================
  // MÉTHODES POUR LES FAVORIS
  // ===============================

  Future<bool> toggleProjectFavorite(int projectId) async {
    try {
      print('⭐ Basculer favori pour le projet $projectId...');

      final data = await _apiClient.post('projects/$projectId/toggle_favorite/',
          requireAuth: true);

      final favorited = data['favorited'] ?? false;
      print('✅ Favori basculé: $favorited');

      return favorited;
    } catch (e) {
      print('❌ Erreur dans toggleProjectFavorite: $e');
      throw e;
    }
  }

  Future<List<ClientProject>> getFavoriteProjects() async {
    try {
      print('⭐ Récupération des projets favoris...');

      final data =
          await _apiClient.get('project-favorites/', requireAuth: true);

      final List<dynamic> favoritesData = data['results'] ?? [];
      final projects = favoritesData
          .map((item) => ClientProject.fromJson(item['project']))
          .toList();

      print('✅ Projets favoris récupérés: ${projects.length}');
      return projects;
    } catch (e) {
      print('❌ Erreur dans getFavoriteProjects: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getProviderRecentProjects() async {
    try {
      final data =
          await _apiClient.get('providers/recent_projects/', requireAuth: true);
      print("Côté API on a :");
      print(data);
      return data ?? {'results': []};
    } catch (e) {
      print('❌ Erreur dans getProviderRecentProjects: $e');
      return {'results': []};
    }
  }

  Future<Map<String, dynamic>> getProviderQuoteRequests() async {
    try {
      final data = await _apiClient.get('quote-requests/recent_quote_requests/',
          requireAuth: true);
      return data ?? {'results': []};
    } catch (e) {
      print('❌ Erreur dans getProviderQuoteRequests: $e');
      return {'results': []};
    }
  }

  // ===============================
// MÉTHODES DE RECHERCHE
// ===============================

  Future<Map<String, dynamic>> searchServices(String query) async {
    try {
      print('🔍 Recherche de services: $query');

      // ✅ CORRECTION: Utiliser l'endpoint réel du ViewSet avec search
      final data = await _apiClient.get(
          'services/?search=${Uri.encodeComponent(query)}',
          requireAuth: false);

      print(
          '✅ Résultats de recherche services: ${data['results']?.length ?? 0}');
      return data ?? {'results': []};
    } catch (e) {
      print('❌ Erreur dans searchServices: $e');

      // Gérer les erreurs spécifiques
      if (e.toString().contains('404')) {
        print('🔍 Tentative avec endpoint alternatif...');
        try {
          // Fallback: essayer avec l'endpoint sans search
          final fallbackData =
              await _apiClient.get('services/', requireAuth: false);
          final allResults = fallbackData['results'] ?? [];

          // Filtrer côté client
          final filteredResults = allResults.where((service) {
            final title = (service['title'] ?? '').toString().toLowerCase();
            final description =
                (service['description'] ?? '').toString().toLowerCase();
            final searchLower = query.toLowerCase();
            return title.contains(searchLower) ||
                description.contains(searchLower);
          }).toList();

          return {'results': filteredResults};
        } catch (e2) {
          print('❌ Erreur fallback services: $e2');
          return {'results': []};
        }
      }
      return {'results': []};
    }
  }

  Future<Map<String, dynamic>> searchProjects(String query) async {
    try {
      print('🔍 Recherche de projets: $query');

      // ✅ CORRECTION: Utiliser l'endpoint réel du ViewSet avec search
      final data = await _apiClient.get(
          'projects/?search=${Uri.encodeComponent(query)}',
          requireAuth: false); // Lecture publique selon le backend

      print(
          '✅ Résultats de recherche projets: ${data['results']?.length ?? 0}');
      return data ?? {'results': []};
    } catch (e) {
      print('❌ Erreur dans searchProjects: $e');

      // Gérer les erreurs spécifiques
      if (e.toString().contains('404')) {
        print('🔍 Tentative avec endpoint alternatif...');
        try {
          // Fallback: essayer avec l'endpoint sans search
          final fallbackData =
              await _apiClient.get('projects/', requireAuth: false);
          final allResults = fallbackData['results'] ?? [];

          // Filtrer côté client
          final filteredResults = allResults.where((project) {
            final title = (project['title'] ?? '').toString().toLowerCase();
            final description =
                (project['description'] ?? '').toString().toLowerCase();
            final location =
                (project['location'] ?? '').toString().toLowerCase();
            final searchLower = query.toLowerCase();
            return title.contains(searchLower) ||
                description.contains(searchLower) ||
                location.contains(searchLower);
          }).toList();

          return {'results': filteredResults};
        } catch (e2) {
          print('❌ Erreur fallback projets: $e2');
          return {'results': []};
        }
      }
      return {'results': []};
    }
  }

  // ===============================
  // MÉTHODES POUR LES CONVERSATIONS
  // ===============================

  Future<List<Conversation>> getConversations() async {
    try {
      print('💬 Récupération des conversations...');

      final userId = await getCurrentUserId();
      final data = await _apiClient.get('conversations/?user_id=$userId',
          requireAuth: true);

      final List<dynamic> conversationsData = data['results'] ?? [];
      final conversations = conversationsData
          .map((item) => Conversation.fromJson(item, userId))
          .toList();

      print('✅ Conversations récupérées: ${conversations.length}');
      return conversations;
    } catch (e) {
      print('❌ Erreur dans getConversations: $e');
      return [];
    }
  }

  Future<List<Message>> getMessages(int conversationId) async {
    try {
      print(
          '💬 Récupération des messages pour la conversation $conversationId...');

      final userId = await getCurrentUserId();
      print('👤 User ID récupéré: $userId');

      // ✅ SOLUTION 1: Utiliser l'endpoint qui requiert user_id (pour compatibilité)
      final data = await _apiClient.get(
          'conversations/$conversationId/messages/?user_id=$userId',
          requireAuth: true);

      final List<dynamic> messagesData = data['results'] ?? data ?? [];
      final messages =
          messagesData.map((item) => Message.fromJson(item, userId)).toList();

      print('✅ Messages récupérés: ${messages.length}');
      return messages;
    } catch (e) {
      print('❌ Erreur dans getMessages: $e');

      // Si l'erreur contient "user_id est requis", réessayer différemment
      if (e.toString().contains('user_id est requis')) {
        try {
          print('🔄 Réessai avec user_id dans les paramètres...');
          final userId = await getCurrentUserId();

          // Essayer avec user_id dans l'URL
          final data = await _apiClient.get(
              'conversations/$conversationId/messages/?user_id=$userId',
              requireAuth: true);

          final List<dynamic> messagesData = data['results'] ?? data ?? [];
          final messages = messagesData
              .map((item) => Message.fromJson(item, userId))
              .toList();

          return messages;
        } catch (e2) {
          print('❌ Erreur finale getMessages: $e2');
          return [];
        }
      }

      return [];
    }
  }

  Future<Message> sendMessage(int conversationId, String content) async {
    try {
      print('📤 Envoi d\'un message vers conversation $conversationId...');
      print(
          '📝 Contenu: ${content.substring(0, content.length > 50 ? 50 : content.length)}...');

      final userId = await getCurrentUserId();
      print('👤 User ID: $userId');

      Map<String, dynamic> data;

      try {
        // ✅ MÉTHODE 1: Endpoint ViewSet (SANS user_id - utilise l'auth)
        print('🔄 Tentative avec endpoint ViewSet authentifié...');
        data =
            await _apiClient.post('conversations/$conversationId/send_message/',
                data: {
                  'content': content, // ✅ Plus de user_id !
                },
                requireAuth: true);
        print('✅ Message envoyé via ViewSet authentifié');
      } catch (e) {
        print('⚠️ Échec ViewSet, tentative endpoint messages...');

        try {
          // ✅ MÉTHODE 2: Endpoint messages (nouveau)
          data = await _apiClient.post('messages/',
              data: {
                'conversation': conversationId,
                'content': content,
              },
              requireAuth: true);
          print('✅ Message envoyé via endpoint messages');
        } catch (e2) {
          print('⚠️ Échec endpoint messages, tentative avec user_id...');

          // ✅ MÉTHODE 3: Fallback avec user_id (pour compatibilité)
          data = await _apiClient.post(
              'conversations/$conversationId/send_message/',
              data: {
                'user_id': userId, // Fallback au cas où
                'content': content,
              },
              requireAuth: true);
          print('✅ Message envoyé via fallback avec user_id');
        }
      }

      final message = Message.fromJson(data, userId);
      print('✅ Message traité côté Flutter');

      return message;
    } catch (e) {
      print('❌ Erreur dans sendMessage: $e');

      // Gestion spéciale de l'erreur HTML (page 404/500 Django)
      if (e.toString().contains('<!DOCTYPE html>') ||
          e.toString().contains('FormatException')) {
        print('🚨 Erreur: Le serveur a renvoyé du HTML au lieu de JSON');
        print('🔍 Cela indique probablement une erreur 404/500 sur le serveur');
        throw Exception(
            'Erreur serveur: Endpoint non trouvé ou erreur interne');
      }

      // Autres erreurs
      if (e.toString().contains('404')) {
        throw Exception(
            'Endpoint de message non trouvé. Vérifiez la configuration du serveur.');
      } else if (e.toString().contains('403')) {
        throw Exception(
            'Accès refusé. Vous n\'êtes pas autorisé à envoyer ce message.');
      } else if (e.toString().contains('401')) {
        throw Exception('Non authentifié. Veuillez vous reconnecter.');
      } else if (e.toString().contains('400')) {
        throw Exception('Données invalides. Vérifiez le contenu du message.');
      } else {
        throw Exception('Erreur lors de l\'envoi du message: $e');
      }
    }
  }

  Future<Map<String, dynamic>> startConversationWithClient(
      int clientId, String? initialMessage) async {
    try {
      final userId = await getCurrentUserId();
      final Map<String, dynamic> requestData = {
        'user_id': userId,
        'client_id': clientId,
      };

      if (initialMessage != null && initialMessage.isNotEmpty) {
        requestData['message'] = initialMessage;
      }

      final data = await _apiClient.post('conversations/start/',
          data: requestData, requireAuth: true);

      return data;
    } catch (e) {
      rethrow;
    }
  }
  // Future<Conversation> startConversation(
  //     int providerId, String? initialMessage) async {
  //   try {
  //     print('💬 Démarrage d\'une conversation...');

  //     final userId = await getCurrentUserId();
  //     final Map<String, dynamic> requestData = {
  //       'user_id': userId,
  //       'provider_id': providerId,
  //     };

  //     if (initialMessage != null && initialMessage.isNotEmpty) {
  //       requestData['message'] = initialMessage;
  //     }

  //     final data = await _apiClient.post('conversations/start/',
  //         data: requestData, requireAuth: true);

  //     final conversation = Conversation.fromJson(data, userId);
  //     print('✅ Conversation démarrée');

  //     return conversation;
  //   } catch (e) {
  //     print('❌ Erreur dans startConversation: $e');
  //     throw e;
  //   }
  // }

  Future<Message?> getInitialMessage(int conversationId) async {
    try {
      final messages = await getMessages(conversationId);
      if (messages.isNotEmpty) {
        return messages.first;
      }
      return null;
    } catch (e) {
      print('❌ Erreur dans getInitialMessage: $e');
      return null;
    }
  }

  Future<bool> markMessagesAsRead(int conversationId) async {
    try {
      print('✅ Marquage des messages comme lus...');

      final userId = await getCurrentUserId();
      await _apiClient.post('conversations/$conversationId/mark_read/',
          data: {'user_id': userId}, requireAuth: true);

      print('✅ Messages marqués comme lus');
      return true;
    } catch (e) {
      print('❌ Erreur dans markMessagesAsRead: $e');
      return false;
    }
  }

  // ===============================
  // NOTIFICATIONS
  // ===============================

  Future<List<NotificationModel>> getNotifications() async {
    try {
      print('🔔 Récupération des notifications...');

      final userId = await getCurrentUserId();
      final data = await _apiClient.get('notifications/?user_id=$userId',
          requireAuth: true);

      final List<dynamic> results = data['results'] ?? data;
      final notifications =
          results.map((item) => NotificationModel.fromJson(item)).toList();

      print('✅ ${notifications.length} notifications récupérées');
      return notifications;
    } catch (e) {
      print('❌ Erreur récupération notifications: $e');
      rethrow;
    }
  }

  Future<int> getUnreadNotificationCount() async {
    try {
      print('🔔 Récupération du nombre de notifications non lues...');

      final userId = await getCurrentUserId();
      final data = await _apiClient.get('notifications/count/?user_id=$userId',
          requireAuth: true);

      final count = data['count'] ?? 0;
      print('✅ $count notifications non lues');
      return count;
    } catch (e) {
      print('❌ Erreur récupération compteur notifications: $e');
      return 0;
    }
  }

  Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      print('✅ Marquage notification $notificationId comme lue...');

      await _apiClient.post('notifications/$notificationId/mark_read/',
          requireAuth: true);

      print('✅ Notification marquée comme lue');
      return true;
    } catch (e) {
      print('❌ Erreur marquage notification: $e');
      return false;
    }
  }

  Future<bool> markAllNotificationsAsRead() async {
    try {
      print('✅ Marquage de toutes les notifications comme lues...');

      final userId = await getCurrentUserId();
      await _apiClient.post('notifications/mark_all_read/',
          data: {'user_id': userId}, requireAuth: true);

      print('✅ Toutes les notifications marquées comme lues');
      return true;
    } catch (e) {
      print('❌ Erreur marquage toutes notifications: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(int notificationId) async {
    try {
      print('🗑️ Suppression notification $notificationId...');

      await _apiClient.delete('notifications/$notificationId/',
          requireAuth: true);

      print('✅ Notification supprimée');
      return true;
    } catch (e) {
      print('❌ Erreur suppression notification: $e');
      return false;
    }
  }

  // ===============================
  // MÉTHODES POUR CRÉATION DE PROJET (avec fichiers)
  // ===============================

  Future<ClientProject> createProject(
      Map<String, dynamic> projectData, List<File?> attachments) async {
    const int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        print('📤 Tentative ${retryCount + 1} de création de projet...');

        var request =
            http.MultipartRequest('POST', Uri.parse('$baseUrl/projects/'));

        // Ajouter les headers d'authentification
        final headers = await _apiClient.getHeaders();
        request.headers.addAll(headers);

        // Ajouter les données du projet
        for (final entry in projectData.entries) {
          final key = entry.key;
          final value = entry.value;

          if (value != null) {
            if (value is List) {
              try {
                request.fields[key] = json.encode(value);
              } catch (e) {
                print('Error encoding list for key $key: $e');
                final stringList =
                    value.map((item) => item.toString()).toList();
                request.fields[key] = json.encode(stringList);
              }
            } else {
              request.fields[key] = value.toString();
            }
          }
        }

        // Ajouter les fichiers
        for (int i = 0; i < attachments.length; i++) {
          final file = attachments[i];
          if (file != null && await file.exists()) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'attachment_${i + 1}',
                file.path,
              ),
            );
          }
        }

        print('📤 Envoi de la requête de création...');
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        print('📥 Réponse reçue: ${response.statusCode}');

        if (response.statusCode == 201) {
          // Succès - créer et retourner le projet
          final data = json.decode(utf8.decode(response.bodyBytes));
          print('✅ Projet créé avec succès');
          return ClientProject.fromJson(data);
        } else if (response.statusCode == 401) {
          print(
              '❌ Erreur 401 - Token invalide ou expiré (tentative ${retryCount + 1})');
          print('Corps de la réponse: ${response.body}');

          if (retryCount < maxRetries - 1) {
            print('🔄 Tentative de rafraîchissement du token...');

            // Tenter de rafraîchir le token
            final tokenRefreshed = await _attemptTokenRefresh();
            if (tokenRefreshed) {
              print('✅ Token rafraîchi, nouvelle tentative...');
              retryCount++;
              continue; // Réessayer avec le nouveau token
            } else {
              print('❌ Échec du rafraîchissement du token');
              throw Exception('Non autorisé. Veuillez vous reconnecter.');
            }
          } else {
            throw Exception('Non autorisé. Veuillez vous reconnecter.');
          }
        } else {
          print('❌ Erreur HTTP ${response.statusCode}');
          print('Corps de la réponse: ${response.body}');
          throw Exception(
              'Erreur lors de la création du projet: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ Erreur dans createProject: $e');

        if (retryCount == maxRetries - 1) {
          // Dernière tentative échouée
          rethrow;
        } else if (e.toString().contains('Non autorisé') ||
            e.toString().contains('401')) {
          // Pour les erreurs 401, essayer de rafraîchir le token
          retryCount++;
        } else {
          // Pour les autres erreurs, relancer immédiatement
          rethrow;
        }
      }
    }

    throw Exception(
        'Impossible de créer le projet après $maxRetries tentatives');
  }

  // Méthode privée pour créer un projet avec fichiers (utilise http directement)
  Future<ClientProject> _createProjectWithFiles(
      Map<String, dynamic> projectData, List<File?> attachments) async {
    try {
      print('📎 Création de projet avec fichiers...');

      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/projects/'));

      // Récupérer les headers d'authentification via ApiClient
      final headers = await _apiClient.getHeaders(requireAuth: true);
      request.headers.addAll(headers);

      // Ajouter les données du projet
      for (final entry in projectData.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value != null) {
          if (value is List) {
            try {
              request.fields[key] = json.encode(value);
            } catch (e) {
              print('❌ Erreur encodage liste pour $key: $e');
              final stringList = value.map((item) => item.toString()).toList();
              request.fields[key] = json.encode(stringList);
            }
          } else {
            request.fields[key] = value.toString();
          }
        }
      }

      // Ajouter les fichiers valides
      final validAttachments = <File>[];
      for (int i = 0; i < attachments.length; i++) {
        final file = attachments[i];
        if (file != null && file.existsSync()) {
          validAttachments.add(file);
        }
      }

      for (int index = 0;
          index < validAttachments.length && index < 3;
          index++) {
        final file = validAttachments[index];
        try {
          final multipartFile = await http.MultipartFile.fromPath(
            'attachment${index + 1}',
            file.path,
          );
          request.files.add(multipartFile);
          print('📎 Fichier ajouté: ${file.path.split('/').last}');
        } catch (e) {
          print('❌ Erreur ajout fichier ${index + 1}: $e');
        }
      }

      print(
          '📤 Envoi de la requête avec ${request.fields.length} champs et ${request.files.length} fichiers');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 Statut de la réponse: ${response.statusCode}');

      if (response.statusCode == 201) {
        // Utiliser le traitement UTF-8 d'ApiClient pour la réponse
        final responseBody = utf8.decode(response.bodyBytes);
        final data = json.decode(responseBody);
        final project = ClientProject.fromJson(data);

        print('✅ Projet créé avec succès: ${project.title}');
        return project;
      } else {
        String errorMessage = 'Failed to create project';
        try {
          final responseBody = utf8.decode(response.bodyBytes);
          final errorData = json.decode(responseBody);

          if (errorData is Map<String, dynamic>) {
            if (errorData.containsKey('detail')) {
              errorMessage = errorData['detail'].toString();
            } else if (errorData.containsKey('message')) {
              errorMessage = errorData['message'].toString();
            } else {
              final errors = <String>[];
              errorData.forEach((key, value) {
                if (value is List) {
                  errors.add('$key: ${value.join(', ')}');
                } else {
                  errors.add('$key: $value');
                }
              });
              if (errors.isNotEmpty) {
                errorMessage = errors.join('; ');
              }
            }
          }
        } catch (e) {
          errorMessage = 'HTTP ${response.statusCode}: ${response.body}';
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Erreur création projet avec fichiers: $e');
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Erreur lors de la création du projet: $e');
      }
    }
  }

  Future<Map<String, dynamic>> startConversation(
    int? providerId,
    String? initialMessage, {
    int? clientId,
  }) async {
    try {
      print('🚀 Démarrage conversation...');

      final data = <String, dynamic>{};

      // Ajouter les paramètres selon le contexte
      if (providerId != null) {
        data['provider_id'] = providerId;
        print('📞 Contacter prestataire $providerId');
      }

      if (clientId != null) {
        data['client_id'] = clientId;
        print('📞 Contacter client $clientId');
      }

      if (initialMessage?.isNotEmpty == true) {
        data['initial_message'] = initialMessage;
      }

      // Retourner les données JSON brutes
      final response = await _apiClient.post(
          'conversations/start_conversation/',
          data: data,
          requireAuth: true);

      print('✅ Conversation démarrée avec succès');
      return response;
    } catch (e) {
      print('❌ Erreur démarrage conversation: $e');
      throw Exception('Impossible de démarrer la conversation: $e');
    }
  }

  // 🎯 NOUVELLE MÉTHODE pour contacter le propriétaire d'un projet
  Future<Map<String, dynamic>> startConversationFromProject(
    int projectId,
    String? initialMessage,
  ) async {
    try {
      print('🚀 Démarrage conversation depuis projet $projectId...');

      final data = {
        'project_id': projectId,
        if (initialMessage?.isNotEmpty == true)
          'initial_message': initialMessage,
      };

      final response = await _apiClient.post(
          'conversations/start_conversation_from_project/',
          data: data,
          requireAuth: true);

      print('✅ Conversation depuis projet démarrée avec succès');
      return response;
    } catch (e) {
      print('❌ Erreur démarrage conversation depuis projet: $e');
      throw Exception('Impossible de démarrer la conversation: $e');
    }
  }

  /// Supprimer/retirer une offre
  Future<void> deleteOffer(int offerId) async {
    try {
      print('🗑️ Suppression de l\'offre $offerId...');

      // Option 1: Essayer DELETE d'abord
      try {
        await _apiClient.delete('project-offers/$offerId/', requireAuth: true);
        print('✅ Offre supprimée via DELETE');
        return;
      } catch (e) {
        print('⚠️ DELETE échoué, tentative PATCH...');
      }

      // Option 3: Dernière tentative avec PUT (certaines APIs l'utilisent)
      try {
        await _apiClient.put(
          'project-offers/$offerId/',
          data: {'status': 'withdrawn'},
          requireAuth: true,
        );
        print('✅ Offre retirée via PUT');
        return;
      } catch (e) {
        print('❌ Toutes les méthodes ont échoué');
        throw Exception(
            'Impossible de retirer l\'offre. Méthodes HTTP non supportées.');
      }
    } catch (e) {
      print('❌ Erreur dans deleteOffer: $e');
      throw e;
    }
  }

  // ✅ MÉTHODE ALTERNATIVE si updateOfferStatus existe déjà mais ne marche pas bien
  Future<void> withdrawOfferSafely(int offerId) async {
    try {
      print('🔄 Retrait sécurisé de l\'offre $offerId...');

      // Méthode 1: Essayer l'endpoint spécifique de retrait s'il existe
      try {
        await _apiClient.post('project-offers/$offerId/withdraw/',
            requireAuth: true);
        print('✅ Offre retirée via endpoint /withdraw/');
        return;
      } catch (e) {
        print('⚠️ Endpoint /withdraw/ non disponible');
      }

      // Méthode 2: Utiliser PATCH avec status

      // Méthode 3: Utiliser POST sur un endpoint d'action
      try {
        await _apiClient.post(
          'project-offers/$offerId/update-status/',
          data: {'status': 'withdrawn'},
          requireAuth: true,
        );
        print('✅ Offre retirée via POST /update-status/');
        return;
      } catch (e) {
        print('❌ Toutes les méthodes ont échoué');
        throw Exception(
            'Service temporairement indisponible. Réessayez plus tard.');
      }
    } catch (e) {
      print('❌ Erreur dans withdrawOfferSafely: $e');

      // Donner un message d'erreur plus user-friendly
      if (e.toString().contains('405')) {
        throw Exception('Action non autorisée par le serveur');
      } else if (e.toString().contains('401')) {
        throw Exception('Session expirée. Reconnectez-vous');
      } else if (e.toString().contains('404')) {
        throw Exception('Offre non trouvée');
      } else {
        throw Exception('Erreur de connexion. Vérifiez votre réseau');
      }
    }
  }

  /// Récupérer un projet spécifique par son ID
  Future<Map<String, dynamic>?> getProjectById(int projectId) async {
    try {
      print('🔍 Récupération du projet ID: $projectId depuis l\'API...');

      // Option 1: Essayer l'endpoint projects/{id}
      try {
        final data =
            await _apiClient.get('projects/$projectId/', requireAuth: true);
        print(data);
        print('✅ Projet récupéré via /projects/$projectId/');
        return data;
      } catch (e) {
        print(
            '⚠️ Échec /projects/$projectId/, tentative endpoint alternatif...');
      }

      // Option 2: Essayer l'endpoint client-projects/{id}
      try {
        final data = await _apiClient.get('client-projects/$projectId/',
            requireAuth: true);
        print('✅ Projet récupéré via /client-projects/$projectId/');
        return data;
      } catch (e) {
        print('⚠️ Échec /client-projects/$projectId/, tentative recherche...');
      }

      // Option 3: Chercher dans la liste de tous les projets
      try {
        final allProjectsData =
            await _apiClient.get('projects/', requireAuth: true);
        final projects = allProjectsData['results'] as List<dynamic>?;

        if (projects != null) {
          final project = projects.firstWhere(
            (p) => p['id'] == projectId,
            orElse: () => null,
          );

          if (project != null) {
            print('✅ Projet trouvé dans la liste des projets');
            return project as Map<String, dynamic>;
          }
        }
      } catch (e) {
        print('⚠️ Échec recherche dans liste des projets');
      }

      print('❌ Projet $projectId non trouvé dans tous les endpoints');
      return null;
    } catch (e) {
      print('❌ Erreur dans getProjectById: $e');
      throw Exception('Erreur lors de la récupération du projet: $e');
    }
  }

  Future<int> getUnreadMessagesCount() async {
    try {
      print('💬 Récupération du compteur de messages non lus...');
      
      final data = await _apiClient.get('messages/unread_count/', requireAuth: true);
      
      if (data != null) {
        final count = data['count'] as int? ?? 0;
        print('✅ Compteur messages récupéré: $count');
        return count;
      } else {
        print('⚠️ Réponse nulle pour le compteur de messages');
        return 0;
      }
    } catch (e) {
      print('❌ Erreur récupération compteur messages: $e');
      return 0; // Retourner 0 en cas d'erreur pour éviter les crashs
    }
  }


  // ===============================
  // MÉTHODES UTILITAIRES
  // ===============================

  Future<Position?> _getCurrentPosition() async {
    try {
      // Implémenter avec package geolocator si nécessaire
      return null;
    } catch (e) {
      print('❌ Erreur récupération position: $e');
      return null;
    }
  }

  double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  // ===============================
  // MÉTHODES MOCK POUR LES TESTS
  // ===============================

  // User _getMockUser() {
  //   return [];
  // }

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
      final latOffset = (random.nextDouble() - 0.5) * 0.1;
      final lngOffset = (random.nextDouble() - 0.5) * 0.1;

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

  List<Category> _getMockCategories() {
    return [
      // Category(
      //   id: 1,
      //   name: 'Maison & Construction',
      //   imageUrl: 'https://picsum.photos/id/1018/300/200',
      //   description: 'Services de construction et rénovation',
      // ),
      // Category(
      //   id: 2,
      //   name: 'Bien-être & Beauté',
      //   imageUrl: 'https://picsum.photos/id/64/300/200',
      //   description: 'Services de beauté et bien-être',
      // ),
      // Category(
      //   id: 3,
      //   name: 'Événements & Artistiques',
      //   imageUrl: 'https://picsum.photos/id/1058/300/200',
      //   description: 'Services liés aux événements et à l\'art',
      // ),
      // Category(
      //   id: 4,
      //   name: 'Transports & Logistiques',
      //   imageUrl: 'https://picsum.photos/id/1072/300/200',
      //   description: 'Services de transport et logistique',
      // ),
      // Category(
      //   id: 5,
      //   name: 'Services Professionnels',
      //   imageUrl: 'https://picsum.photos/id/1066/300/200',
      //   description: 'Services professionnels divers',
      // ),
      // Category(
      //   id: 6,
      //   name: 'Cours & Formation',
      //   imageUrl: 'https://picsum.photos/id/20/300/200',
      //   description: 'Services d\'éducation et formation',
      // ),
    ];
  }

  List<Subcategory> _getMockSubcategories(int categoryId) {
    if (categoryId == 1) {
      return [
        // Subcategory(
        //   id: 1,
        //   name: 'Construction & rénovation',
        //   categoryId: 1,
        //   description: 'Services de construction et rénovation',
        // ),
        // Subcategory(
        //   id: 2,
        //   name: 'Plomberie',
        //   categoryId: 1,
        //   description: 'Services de plomberie',
        // ),
        // Subcategory(
        //   id: 3,
        //   name: 'Électricité',
        //   categoryId: 1,
        //   description: 'Services d\'électricité',
        // ),
      ];
    } else {
      return [
        // Subcategory(
        //   id: 4,
        //   name: 'Sous-catégorie 1',
        //   categoryId: categoryId,
        //   description: 'Description sous-catégorie 1',
        // ),
        // Subcategory(
        //   id: 5,
        //   name: 'Sous-catégorie 2',
        //   categoryId: categoryId,
        //   description: 'Description sous-catégorie 2',
        // ),
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

  int _getMockServiceCountByCategory(int categoryId) {
    final Map<int, int> mockCounts = {
      1: 11,
      2: 5,
      3: 6,
      4: 4,
      5: 3,
      6: 5,
      7: 4,
      8: 3,
      9: 3,
    };
    return mockCounts[categoryId] ?? 0;
  }

  int _getMockServiceCountBySubcategory(int subcategoryId) {
    final Map<int, int> mockCounts = {
      1: 5,
      2: 3,
      3: 4,
      4: 2,
      5: 3,
      6: 2,
      7: 1,
      8: 2,
      9: 1,
      10: 1,
      11: 2,
      12: 3,
      13: 2,
      14: 2,
      15: 1,
      16: 1,
      17: 2,
      18: 3,
      19: 2,
      20: 2,
      21: 1,
      22: 2,
    };
    return mockCounts[subcategoryId] ?? 0;
  }

  // ===============================
  // MÉTHODES HÉRITÉES POUR COMPATIBILITÉ
  // ===============================

  // Gardez cette méthode pour la compatibilité avec vos providers existants
  @deprecated
  Future<Map<String, String>> getHeaders({bool requireAuth = true}) async {
    return await _apiClient.getHeaders(requireAuth: requireAuth);
  }

  // Méthodes de debug pour les tokens (optionnelles)
  Future<void> debugTokenState() async {
    final token = await _secureStorage.read(key: 'access_token');
    final refreshToken = await _secureStorage.read(key: 'refresh_token');

    print('=== DEBUG TOKEN STATE ===');
    print(
        'Access Token: ${token != null ? 'EXISTS (${token.length} chars)' : 'NULL'}');
    print('Refresh Token: ${refreshToken != null ? 'EXISTS' : 'NULL'}');
    print('Base URL: $baseUrl');
    print('========================');
  }

  /// Enregistrer le token FCM de l'utilisateur
  Future<bool> updateFCMToken(String fcmToken) async {
    try {
      print('📤 Envoi du token FCM au backend...');

      final userId = await getCurrentUserId();
      final data = await _apiClient.post(
        'fcm/register-token/',
        data: {
          'user_id': userId,
          'fcm_token': fcmToken,
          'device_type': Platform.isAndroid ? 'android' : 'ios',
          'app_version': '1.0.0', // Récupérer dynamiquement si nécessaire
        },
        requireAuth: true,
      );

      print('✅ Token FCM enregistré avec succès');
      return true;
    } catch (e) {
      print('❌ Erreur envoi token FCM: $e');
      return false;
    }
  }

  /// Supprimer le token FCM (lors de la déconnexion)
  Future<bool> removeFCMToken(String fcmToken) async {
    try {
      print('🗑️ Suppression du token FCM...');

      final userId = await getCurrentUserId();
      final data = {'user_id': userId, 'fcm_token': fcmToken};
      await _apiClient.delete(
        'fcm/remove-token',
        // data,
        requireAuth: true,
      );

      print('✅ Token FCM supprimé');
      return true;
    } catch (e) {
      print('❌ Erreur suppression token FCM: $e');
      return false;
    }
  }

  /// Mettre à jour les préférences de notification
  Future<bool> updateNotificationPreferences(Map<String, bool> preferences) async {
    try {
      print('⚙️ Mise à jour des préférences de notification...');
      
      final userId = await getCurrentUserId();
      await _apiClient.post(
        'notifications/preferences/',
        data: {
          'user_id': userId,
          'preferences': preferences,
        },
        requireAuth: true,
      );
      
      print('✅ Préférences de notification mises à jour');
      return true;
      
    } catch (e) {
      print('❌ Erreur mise à jour préférences: $e');
      return false;
    }
  }

  /// Marquer une notification comme lue
  // Future<bool> markNotificationAsRead(int notificationId) async {
  //   try {
  //     print('✅ Marquage notification comme lue...');
      
  //     await _apiClient.patch(
  //       'notifications/$notificationId/mark-read/',
  //       data: {'is_read': true},
  //       requireAuth: true,
  //     );
      
  //     print('✅ Notification marquée comme lue');
  //     return true;
      
  //   } catch (e) {
  //     print('❌ Erreur marquage notification: $e');
  //     return false;
  //   }
  // }

  /// Envoyer une notification de test
  Future<bool> sendTestNotification() async {
    try {
      print('🧪 Envoi notification de test...');
      
      final userId = await getCurrentUserId();
      await _apiClient.post(
        'notifications/test/',
        data: {'user_id': userId},
        requireAuth: true,
      );
      
      print('✅ Notification de test envoyée');
      return true;
      
    } catch (e) {
      print('❌ Erreur envoi notification test: $e');
      return false;
    }
  }
}
