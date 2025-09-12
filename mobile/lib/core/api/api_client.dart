import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../providers/localization_provider.dart';
import 'package:teyago/providers/language_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  Future<dynamic> patch(String endpoint,
    {Map<String, dynamic>? data, bool requireAuth = true}) async {
    final headers = await getHeaders(requireAuth: requireAuth);

    final String body = data != null ? json.encode(data) : '';
    final response = await http.patch(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: utf8.encode(body),
    );

    return _handleResponse(response);
  }

  Future<Map<String, String>> getHeaders({bool requireAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      'Accept-Charset': 'utf-8',
      'Accept-Encoding': 'utf-8',
    };

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
    return _handleResponse(response);
  }   

  Future<dynamic> post(String endpoint,
      {Map<String, dynamic>? data, bool requireAuth = true}) async {
    final headers = await getHeaders(requireAuth: requireAuth);

    // Convertir les données en JSON avec encodage UTF-8
    // final encodedData = data != null ? utf8.encode(json.encode(data)) : null;
    final String body = data != null ? json.encode(data) : '';
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: utf8.encode(body),
    );

    // Force l'encodage en UTF-8 pour la réponse
    // final encodedResponse = utf8.decode(response.bodyBytes);
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint,
      {Map<String, dynamic>? data, bool requireAuth = true}) async {
    final headers = await getHeaders(requireAuth: requireAuth);

    // Convertir les données en JSON avec encodage UTF-8
    // final encodedData = data != null ? utf8.encode(json.encode(data)) : null;
    final String body = data != null ? json.encode(data) : '';

    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: utf8.encode(body),
    );

    // Force l'encodage en UTF-8 pour la réponse
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint, {bool requireAuth = true}) async {
    final headers = await getHeaders(requireAuth: requireAuth);
    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );

    // Force l'encodage en UTF-8 pour la réponse
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    try {
      // ✅ SOLUTION PRINCIPALE : Décoder correctement la réponse
      String responseBody;
      
      // Vérifier l'encodage dans les headers de réponse
      final contentType = response.headers['content-type'] ?? '';
      
      if (contentType.contains('charset=utf-8') || contentType.contains('application/json')) {
        // Décoder en UTF-8
        responseBody = utf8.decode(response.bodyBytes);
      } else {
        // Fallback : essayer UTF-8 par défaut
        try {
          responseBody = utf8.decode(response.bodyBytes);
        } catch (e) {
          // Si échec UTF-8, utiliser la méthode normale
          responseBody = response.body;
        }
      }

      // ✅ NETTOYAGE SUPPLÉMENTAIRE
      responseBody = _cleanEncodingIssues(responseBody);

      print('📥 Status: ${response.statusCode}');
      print('📥 Content-Type: $contentType');
      print('📥 Response (nettoyé): ${responseBody.length > 200 ? responseBody.substring(0, 200) + '...' : responseBody}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody.isNotEmpty) {
          try {
            // Supprimer le BOM si présent
            final cleanBody = responseBody.replaceAll('\uFEFF', '');
            return json.decode(cleanBody);
          } catch (e) {
            print('❌ Erreur parsing JSON: $e');
            print('📄 Body original: $responseBody');
            return null;
          }
        }
        return null;
      } else if (response.statusCode == 401) {
        _refreshToken();
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      } else {
        print('❌ Erreur HTTP ${response.statusCode}: $responseBody');
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur dans _handleResponse: $e');
      rethrow;
    }
  }

  // ✅ MÉTHODE POUR CORRIGER LES PROBLÈMES D'ENCODAGE COURANTS
  String _cleanEncodingIssues(String text) {
    if (text.isEmpty) return text;

    // ✅ Corrections spécifiques aux problèmes d'encodage UTF-8
    Map<String, String> fixes = {
      'Ã©': 'é',     // é mal encodé
      'Ã¨': 'è',     // è mal encodé
      'Ã¡': 'á',     // á mal encodé
      'Ã ': 'à',     // à mal encodé
      'Ã§': 'ç',     // ç mal encodé
      'Ãª': 'ê',     // ê mal encodé
      'Ã´': 'ô',     // ô mal encodé
      'Ã¢': 'â',     // â mal encodé
      'Ã¯': 'ï',     // ï mal encodé
      'Ã¼': 'ü',     // ü mal encodé
      'Ã±': 'ñ',     // ñ mal encodé
      'â€™': '\'',    // apostrophe mal encodée
      'â€œ': '"',    // guillemet mal encodé
      'â€': '"',     // guillemet mal encodé
      'â€¦': '...',  // ellipse mal encodée
      'â€"': '–',    // tiret mal encodé
      'â€"': '—',    // tiret long mal encodé
    };

    String cleaned = text;
    fixes.forEach((wrong, correct) {
      cleaned = cleaned.replaceAll(wrong, correct);
    });

    return cleaned;
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
