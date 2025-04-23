import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  AuthService(this._apiClient);

  Future<User?> login(String username, String password) async {
    try {
      final response = await _apiClient.login(username, password);
      
      if (response['access'] != null) {
        // Récupérer les infos utilisateur
        final userData = await _apiClient.get('users/me/');
        final user = User.fromJson(userData);
        
        // Sauvegarder le user dans les préférences
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('user_data', User.toJsonString(user));
        
        return user;
      }
      return null;
    } catch (e) {
      print('Erreur de login: $e');
      return null;
    }
  }

  Future<User?> register(String username, String email, String password, String firstName, 
      String lastName, String phoneNumber, String role) async {
    try {
      final response = await _apiClient.register({
        'username': username,
        'email': email,
        'password': password,
        'password2': password,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'role': role,
      });
      
      // Après l'inscription, connecter l'utilisateur
      return await login(username, password);
    } catch (e) {
      print('Erreur d\'inscription: $e');
      return null;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      return await _apiClient.resetPassword(email);
    } catch (e) {
      print('Erreur de réinitialisation de mot de passe: $e');
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      await _apiClient.logout();
      
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
        return User.fromJsonString(userData);
      }
      
      // Si pas en cache, récupérer depuis l'API
      final apiData = await _apiClient.get('users/me/');
      final user = User.fromJson(apiData);
      
      // Mettre en cache
      prefs.setString('user_data', User.toJsonString(user));
      
      return user;
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