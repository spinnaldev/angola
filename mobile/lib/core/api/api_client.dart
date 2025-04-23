import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final String baseUrl;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

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
      throw Exception('Non autorisé. Veuillez vous reconnecter.');
    } else {
      try {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Une erreur est survenue');
      } catch (e) {
        throw Exception('Erreur ${response.statusCode}: ${response.reasonPhrase}');
      }
    }
  }

  // Méthodes spécifiques à l'authentification
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await post('auth/token/', 
      data: {
        'username': username,
        'password': password,
      },
      requireAuth: false,
    );
    
    if (response != null && response['access'] != null) {
      await _secureStorage.write(key: 'access_token', value: response['access']);
      await _secureStorage.write(key: 'refresh_token', value: response['refresh']);
    }
    
    return response;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    return await post('auth/register/', data: userData, requireAuth: false);
  }

  Future<bool> resetPassword(String email) async {
    try {
      await post('auth/password-reset/', data: {'email': email}, requireAuth: false);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> logout() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    return true;
  }
}