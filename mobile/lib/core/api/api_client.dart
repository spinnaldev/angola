import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final String baseUrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ApiClient({required this.baseUrl});

  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
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

  Future<dynamic> get(String endpoint, {bool requireAuth = true}) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? data, bool requireAuth = true}) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: data != null ? json.encode(data) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? data, bool requireAuth = true}) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: data != null ? json.encode(data) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint, {bool requireAuth = true}) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return json.decode(response.body);
      }
      return null;
    } else if (response.statusCode == 401) {
      // Si token expiré ou invalide
      _refreshToken();
      throw Exception('Non autorisé. Veuillez vous reconnecter.');
    } else {
      try {
        final errorData = json.decode(response.body);
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
        
        throw Exception('Erreur ${response.statusCode}: ${response.reasonPhrase}');
      } catch (e) {
        if (e is Exception) {
          rethrow;
        }
        throw Exception('Erreur ${response.statusCode}: ${response.reasonPhrase}');
      }
    }
  }

  Future<void> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) return;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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
        'auth/login/',  // Nouvel endpoint
        data: {
          'email': email,
          'password': password,
        },
        requireAuth: false,
      );
      
      if (response != null && response['access'] != null) {
        // Sauvegarder les tokens
        await _secureStorage.write(key: 'access_token', value: response['access']);
        await _secureStorage.write(key: 'refresh_token', value: response['refresh']);
        
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
      final response = await post(
        'auth/password-reset-request/',
        data: {'email': email},
        requireAuth: false
      );
      return true;
    } catch (e) {
      print('Erreur de demande de réinitialisation de mot de passe: $e');
      rethrow;
    }
  }

  Future<bool> verifyResetCode(String email, String code) async {
    try {
      final response = await post(
        'auth/verify-reset-code/',
        data: {
          'email': email,
          'code': code
        },
        requireAuth: false
      );
      return true;
    } catch (e) {
      print('Erreur de vérification du code: $e');
      rethrow;
    }
  }

  Future<bool> resetPasswordConfirm(String email, String code, String newPassword) async {
    try {
      final response = await post(
        'auth/password-reset-confirm/',
        data: {
          'email': email,
          'code': code,
          'new_password': newPassword
        },
        requireAuth: false
      );
      return true;
    } catch (e) {
      print('Erreur de réinitialisation du mot de passe: $e');
      rethrow;
    }
  }
}