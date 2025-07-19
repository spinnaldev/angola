import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../providers/localization_provider.dart';
import 'package:teyago/providers/language_provider.dart';

class ApiClient {
  final String baseUrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ApiClient({required this.baseUrl});

  // Future<Map<String, String>> getHeaders({bool requireAuth = true}) async {  // Enlever le _
  //   Map<String, String> headers = {
  //     'Content-Type': 'application/json; charset=utf-8',
  //     'Accept': 'application/json',
  //     'Accept-Charset': 'utf-8',
  //   };

  //   if (requireAuth) {
  //     final token = await _secureStorage.read(key: 'access_token');
  //     if (token != null) {
  //       headers['Authorization'] = 'Bearer $token';
  //     }
  //   }

  //   return headers;
  // }

  Future<Map<String, String>> getHeaders({bool requireAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      'Accept-Charset': 'utf-8',
    };

    // // Ajouter la langue actuelle dans les headers
    // if (navigatorKey.currentContext != null) {
    //   try {
    //     final languageProvider = Provider.of<LanguageProvider>(
    //       navigatorKey.currentContext!, 
    //       listen: false
    //     );
    //     headers['X-Language'] = languageProvider.currentLanguageCode;
    //     headers['Accept-Language'] = languageProvider.currentLanguageCode;
    //   } catch (e) {
    //     print('Erreur récupération langue: $e');
    //     // Fallback à la langue par défaut
    //     headers['X-Language'] = 'fr';
    //     headers['Accept-Language'] = 'fr';
    //   }
    // } else {
    //   // Fallback si pas de context
    //   headers['X-Language'] = 'fr';
    //   headers['Accept-Language'] = 'fr';
    // }

    if (requireAuth) {
      final token = await _secureStorage.read(key: 'access_token');
      print(
          '🔑 Token lu depuis storage: ${token != null ? "EXISTS (${token.length} chars)" : "NULL"}'); // Debug

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        print(
            '✅ Header Authorization ajouté: Bearer ${token.substring(0, 20)}...'); // Debug
      } else {
        print('❌ Aucun token trouvé dans le storage'); // Debug
      }
    }

    print('📤 Headers finaux: ${headers.keys.toList()}'); // Debug
    return headers;
  }

  Future<void> debugToken() async {
    final token = await _secureStorage.read(key: 'access_token');
    final refresh = await _secureStorage.read(key: 'refresh_token');

    print('=== DEBUG TOKEN INFO ===');
    print(
        'Access Token: ${token != null ? "EXISTS (${token.length} chars)" : "NULL"}');
    print(
        'Refresh Token: ${refresh != null ? "EXISTS (${refresh.length} chars)" : "NULL"}');

    if (token != null) {
      print(
          'Token preview: ${token.substring(0, math.min(50, token.length))}...');
    }
    print('========================');
  }

  Future<void> testTokenAndAPI() async {
    final apiClient = ApiClient(baseUrl: 'https://teyago.com/api');

    // Debug du token
    await apiClient.debugToken();

    // Test d'appel API avec logs détaillés
    try {
      print('🧪 Test appel API /users/me/...');
      final response = await apiClient.get('users/me/', requireAuth: true);
      print('✅ Succès: $response');
    } catch (e) {
      print('❌ Erreur: $e');
    }
  }

  Future<dynamic> get(String endpoint, {bool requireAuth = true}) async {
    final headers = await getHeaders(requireAuth: requireAuth);
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );

    // Force l'encodage en UTF-8 pour la réponse
    final encodedResponse = utf8.decode(response.bodyBytes);
    return _handleResponse(response.statusCode, encodedResponse);
  }   

  Future<dynamic> post(String endpoint,
      {Map<String, dynamic>? data, bool requireAuth = true}) async {
    final headers = await getHeaders(requireAuth: requireAuth);

    // Convertir les données en JSON avec encodage UTF-8
    final encodedData = data != null ? utf8.encode(json.encode(data)) : null;

    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: encodedData,
    );

    // Force l'encodage en UTF-8 pour la réponse
    final encodedResponse = utf8.decode(response.bodyBytes);
    return _handleResponse(response.statusCode, encodedResponse);
  }

  Future<dynamic> put(String endpoint,
      {Map<String, dynamic>? data, bool requireAuth = true}) async {
    final headers = await getHeaders(requireAuth: requireAuth);

    // Convertir les données en JSON avec encodage UTF-8
    final encodedData = data != null ? utf8.encode(json.encode(data)) : null;

    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: encodedData,
    );

    // Force l'encodage en UTF-8 pour la réponse
    final encodedResponse = utf8.decode(response.bodyBytes);
    return _handleResponse(response.statusCode, encodedResponse);
  }

  Future<dynamic> delete(String endpoint, {bool requireAuth = true}) async {
    final headers = await getHeaders(requireAuth: requireAuth);
    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );

    // Force l'encodage en UTF-8 pour la réponse
    final encodedResponse = utf8.decode(response.bodyBytes);
    return _handleResponse(response.statusCode, encodedResponse);
  }

  dynamic _handleResponse(int statusCode, String responseBody) {
    if (statusCode >= 200 && statusCode < 300) {
      if (responseBody.isNotEmpty) {
        try {
          // Assurer l'encodage UTF-8 avant le parsing JSON
          final cleanBody = responseBody.replaceAll('\uFEFF', ''); // Remove BOM
          return json.decode(cleanBody);
        } catch (e) {
          print('Erreur parsing JSON: $e');
          print('Response body: $responseBody');
          return null;
        }
      }
      return null;
    } else if (statusCode == 401) {
      // Si token expiré ou invalide
      _refreshToken();
      throw Exception('Non autorisé. Veuillez vous reconnecter.');
    } else {
      try {
        final errorData = json.decode(responseBody);
        if (errorData is Map) {
          // Rechercher les erreurs dans la réponse
          if (errorData.containsKey('detail')) {
            throw Exception(errorData['detail']);
          } else if (errorData.containsKey('error')) {
            throw Exception(errorData['error']);
          } else if (errorData.containsKey('non_field_errors')) {
            if (errorData['non_field_errors'] is List) {
              throw Exception(errorData['non_field_errors'].join(', '));
            } else {
              throw Exception(errorData['non_field_errors'].toString());
            }
          } else {
            // Parcourir les erreurs de champs
            String errorMessages = '';
            errorData.forEach((key, value) {
              if (value is List) {
                errorMessages += '$key: ${value.join(', ')}\n';
              } else {
                errorMessages += '$key: $value\n';
              }
            });

            if (errorMessages.isNotEmpty) {
              throw Exception(errorMessages.trim());
            }
          }
        }

        throw Exception('Erreur $statusCode');
      } catch (e) {
        if (e is Exception) {
          rethrow;
        }
        throw Exception('Erreur $statusCode');
      }
    }
  }

  Future<void> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) return;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        await _secureStorage.write(key: 'access_token', value: data['access']);
      } else {
        // Si le refresh token est également invalide
        await _secureStorage.delete(key: 'access_token');
        await _secureStorage.delete(key: 'refresh_token');
      }
    } catch (e) {
      print('Erreur de rafraîchissement du token: $e');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await post(
        'auth/login/', // Nouvel endpoint
        data: {
          'email': email,
          'password': password,
        },
        requireAuth: false,
      );

      if (response != null && response['access'] != null) {
        // Sauvegarder les tokens
        await _secureStorage.write(
            key: 'access_token', value: response['access']);
        await _secureStorage.write(
            key: 'refresh_token', value: response['refresh']);

        // La réponse contient déjà les données utilisateur
        return response;
      }
      throw Exception('Échec de connexion');
    } catch (e) {
      print('Erreur de login: $e');
      rethrow;
    }
  }

  Future<bool> resetPasswordRequest(String email) async {
    try {
      print('Envoi de la demande de réinitialisation pour: $email'); // Debug

      final response = await post('auth/password-reset-request/',
          data: {'email': email}, requireAuth: false);

      print('Réponse reçue: $response'); // Debug

      // Si on arrive ici, c'est que la requête a réussi (pas d'exception)
      return true;
    } catch (e) {
      print('Erreur de demande de réinitialisation de mot de passe: $e');
      rethrow;
    }
  }

  Future<bool> verifyResetCode(String email, String code) async {
    try {
      print('Vérification du code: $code pour: $email'); // Debug

      final response = await post('auth/verify-reset-code/',
          data: {'email': email, 'code': code}, requireAuth: false);

      print('Réponse vérification: $response'); // Debug

      return true;
    } catch (e) {
      print('Erreur de vérification du code: $e');
      rethrow;
    }
  }

  Future<bool> resetPasswordConfirm(
      String email, String code, String newPassword) async {
    try {
      print('Confirmation reset pour: $email'); // Debug

      final response = await post('auth/password-reset-confirm/',
          data: {'email': email, 'code': code, 'new_password': newPassword},
          requireAuth: false);

      print('Réponse confirmation: $response'); // Debug

      return true;
    } catch (e) {
      print('Erreur de réinitialisation du mot de passe: $e');
      rethrow;
    }
  }
}
