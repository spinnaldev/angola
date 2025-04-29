import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  AuthService(this._apiClient);

  Future<User?> login(String email, String password) async {
    try {
      final response = await _apiClient.login(email, password);
      
      if (response != null && response['user'] != null) {
        // Utiliser directement les données utilisateur de la réponse
        final user = User.fromJson(response['user']);
        
        // Sauvegarder le user dans les préférences
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('user_data', User.toJsonString(user));
        
        return user;
      }
      return null;
    } catch (e) {
      print('Erreur de login: $e');
      rethrow;
    }
  }

  // Méthodes pour le reset de mot de passe
  Future<bool> requestPasswordReset(String email) async {
    try {
      return await _apiClient.resetPasswordRequest(email);
    } catch (e) {
      print('Erreur de demande de réinitialisation de mot de passe: $e');
      rethrow;
    }
  }

  Future<bool> verifyResetCode(String email, String code) async {
    try {
      return await _apiClient.verifyResetCode(email, code);
    } catch (e) {
      print('Erreur de vérification du code: $e');
      rethrow;
    }
  }

  Future<bool> resetPasswordConfirm(String email, String code, String newPassword) async {
    try {
      return await _apiClient.resetPasswordConfirm(email, code, newPassword);
    } catch (e) {
      print('Erreur de réinitialisation du mot de passe: $e');
      rethrow;
    }
  }

  Future<User?> register(String username, String email, String password, String firstName, 
      String lastName, String phoneNumber, String role) async {
    try {
      final response = await _apiClient.post(
        'auth/register/',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'password2': password,
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phoneNumber,
          'role': role,
        },
        requireAuth: false,
      );
      
      // Après l'inscription, connecter l'utilisateur
      // return await login(username, password);
    } catch (e) {
      print('Erreur d\'inscription: $e');
      rethrow; // Propager l'erreur pour un meilleur traitement dans le Provider
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _apiClient.post(
        'auth/password-reset/',
        data: {'email': email},
        requireAuth: false
      );
      return true;
    } catch (e) {
      print('Erreur de réinitialisation de mot de passe: $e');
      rethrow; // Propager l'erreur pour un meilleur traitement dans le Provider
    }
  }

  Future<bool> logout() async {
    try {
      // Supprimer les tokens
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      
      // Supprimer les données utilisateur locales
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('user_data');
      
      return true;
    } catch (e) {
      print('Erreur de déconnexion: $e');
      return false;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      // Vérifier si un token existe
      final token = await _secureStorage.read(key: 'access_token');
      if (token == null) return null;
      
      // Récupérer les données utilisateur depuis les préférences
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      
      if (userData != null) {
        try {
          return User.fromJsonString(userData);
        } catch (e) {
          // En cas d'erreur de parsing, on continue pour rafraîchir depuis l'API
        }
      }
      
      // Si pas en cache ou erreur de parsing, récupérer depuis l'API
      try {
        final apiData = await _apiClient.get('users/me/');
        final user = User.fromJson(apiData);
        
        // Mettre en cache
        prefs.setString('user_data', User.toJsonString(user));
        
        return user;
      } catch (e) {
        // En cas d'erreur API (token expiré par exemple), déconnexion
        await logout();
        return null;
      }
    } catch (e) {
      print('Erreur de récupération d\'utilisateur: $e');
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.read(key: 'access_token');
    return token != null;
  }
}