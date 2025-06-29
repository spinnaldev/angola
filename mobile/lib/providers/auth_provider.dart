import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/services/auth_service.dart';
import '../core/models/user.dart';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/services/profile_manager.dart'; 

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated
}

enum PasswordResetStatus {
  initial,
  requestSent,
  codeVerified,
  completed,
  failed
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  
  AuthStatus _status = AuthStatus.uninitialized;
  User? _currentUser;
  String? _errorMessage;
  
  // État pour le reset de mot de passe
  PasswordResetStatus _resetStatus = PasswordResetStatus.initial;
  String? _resetEmail;
  String? _resetCode;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  AuthProvider(this._authService) {
    // Vérifier l'état d'authentification au démarrage
    _checkCurrentUser();
  }

  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  
  // Getters pour le reset de mot de passe
  PasswordResetStatus get resetStatus => _resetStatus;
  String? get resetEmail => _resetEmail;
  String? get resetCode => _resetCode;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    // Mettre à jour la référence ProfileManager quand des listeners sont ajoutés
    ProfileManager.setAuthProvider(this);
  }

  
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) {
        print('❌ Aucun refresh token disponible');
        await logout();
        return false;
      }

      print('🔄 Tentative de rafraîchissement du token...');
      
      // Récupérer l'URL de base depuis votre configuration
      final baseUrl = _getBaseUrl();
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/token/refresh/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'refresh': refreshToken}),
      );

      print('Réponse refresh token: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newAccessToken = data['access'];
        
        // Sauvegarder le nouveau token d'accès
        await _secureStorage.write(key: 'access_token', value: newAccessToken);
        
        print('✅ Token rafraîchi avec succès');
        return true;
      } else {
        print('❌ Échec du rafraîchissement: ${response.statusCode} - ${response.body}');
        
        // Supprimer les tokens invalides
        await _secureStorage.delete(key: 'access_token');
        await _secureStorage.delete(key: 'refresh_token');
        
        // Mettre à jour le statut d'authentification
        _status = AuthStatus.unauthenticated;
        _currentUser = null;
        notifyListeners();
        
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors du rafraîchissement du token: $e');
      return false;
    }
  }

  /// Méthode pour vérifier si le token est valide
  Future<bool> isTokenValid() async {
    try {
      final token = await _secureStorage.read(key: 'access_token');
      if (token == null) return false;

      final baseUrl = _getBaseUrl();
      
      // Faire un appel API simple pour vérifier la validité du token
      final response = await http.get(
        Uri.parse('$baseUrl/users/me/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur lors de la vérification du token: $e');
      return false;
    }
  }

  /// Méthode pour valider et éventuellement rafraîchir le token avant les requêtes
  Future<bool> ensureValidToken() async {
    if (!await isTokenValid()) {
      print('Token invalide, tentative de rafraîchissement...');
      return await refreshToken();
    }
    return true;
  }

  // Méthodes pour l'authentification et la vérification du statut
  Future<void> _checkCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  
  // Nouvelle méthode: Récupérer explicitement les informations utilisateur
  Future<void> getCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Méthodes d'authentification existantes
  Future<bool> login(String email, String password) async {
    try {
      // Réinitialiser le message d'erreur
      _errorMessage = null;
      notifyListeners();
      
      print('🔑 Tentative de connexion pour: $email');
      
      final user = await _authService.login(email, password);
      
      if (user != null) {
        print('✅ Connexion réussie pour: ${user.email} (rôle: ${user.role})');
        _currentUser = user;
        _status = AuthStatus.authenticated;
        
        // AJOUT: Synchroniser le ProfileManager avec le rôle utilisateur
        ProfileManager.setAuthProvider(this);
        await ProfileManager.forceSync();
        
        notifyListeners();
        return true;
      } else {
        print('❌ Connexion échouée: utilisateur null');
        _errorMessage = "Échec de la connexion. Vérifiez vos identifiants.";
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors de la connexion: $e');
      
      // Gérer différents types d'erreurs
      if (e.toString().contains('401') || 
          e.toString().contains('Unauthorized') ||
          e.toString().contains('Invalid credentials')) {
        _errorMessage = "Email ou mot de passe incorrect.";
      } else if (e.toString().contains('404')) {
        _errorMessage = "Compte non trouvé.";
      } else if (e.toString().contains('500')) {
        _errorMessage = "Erreur serveur. Veuillez réessayer plus tard.";
      } else if (e.toString().contains('Network') || 
                 e.toString().contains('SocketException')) {
        _errorMessage = "Erreur de réseau. Vérifiez votre connexion internet.";
      } else {
        _errorMessage = "Erreur de connexion: ${e.toString()}";
      }
      
      _status = AuthStatus.unauthenticated;
      _currentUser = null;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> register(String username, String email, String password, 
      String firstName, String lastName, String phoneNumber, String role) async {
    try {
      _errorMessage = null;
      final user = await _authService.register(
        username, email, password, firstName, lastName, phoneNumber, role);
      
      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;

        // AJOUT: Synchroniser le ProfileManager avec le rôle utilisateur
        ProfileManager.setAuthProvider(this);
        await ProfileManager.forceSync();

        notifyListeners();
        return true;
      } else {
        _errorMessage = "Échec de l'inscription. Veuillez réessayer.";
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

   // Méthode pour enregistrer un prestataire avec ses catégories
  Future<bool> registerWithCategories(
    String username,
    String email,
    String password,
    String firstName,
    String lastName,
    String phoneNumber,
    String role,
    List<int> selectedCategories
  ) async {
    try {
      _errorMessage = null;
      final user = await _authService.registerWithCategories(
        username,
        email,
        password,
        firstName,
        lastName,
        phoneNumber,
        role,
        selectedCategories
      );
      
      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;

        // AJOUT: Synchroniser le ProfileManager avec le rôle utilisateur
        ProfileManager.setAuthProvider(this);
        await ProfileManager.forceSync();
        
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Échec de l'inscription. Veuillez réessayer.";
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }
  // Méthodes existantes pour le reset de mot de passe
  Future<bool> requestPasswordReset(String email) async {
    try {
      _errorMessage = null;
      _resetStatus = PasswordResetStatus.initial;
      final result = await _authService.requestPasswordReset(email);
      
      if (result) {
        _resetEmail = email;
        _resetStatus = PasswordResetStatus.requestSent;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Échec de la demande de réinitialisation.";
        _resetStatus = PasswordResetStatus.failed;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _resetStatus = PasswordResetStatus.failed;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyResetCode(String code) async {
    try {
      _errorMessage = null;
      if (_resetEmail == null) {
        _errorMessage = "Email non défini. Veuillez réessayer depuis le début.";
        return false;
      }
      
      final result = await _authService.verifyResetCode(_resetEmail!, code);
      
      if (result) {
        _resetCode = code;
        _resetStatus = PasswordResetStatus.codeVerified;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Code de vérification invalide.";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPasswordConfirm(String newPassword) async {
    try {
      _errorMessage = null;
      if (_resetEmail == null || _resetCode == null) {
        _errorMessage = "Informations manquantes. Veuillez réessayer depuis le début.";
        return false;
      }
      
      final result = await _authService.resetPasswordConfirm(_resetEmail!, _resetCode!, newPassword);
      
      if (result) {
        _resetStatus = PasswordResetStatus.completed;
        // Réinitialiser les valeurs
        _resetEmail = null;
        _resetCode = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Échec de la réinitialisation du mot de passe.";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void resetPasswordProcess() {
    _resetStatus = PasswordResetStatus.initial;
    _resetEmail = null;
    _resetCode = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Méthode de déconnexion améliorée
  Future<bool> logout() async {
    try {
      // Appel à votre AuthService existant
      final success = await _authService.logout();
      
      // S'assurer que les tokens sont supprimés
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      
      // Mettre à jour l'état
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      
      notifyListeners();
      return success;
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
      
      // Forcer la déconnexion locale même en cas d'erreur
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? bio,
    String? location,
    String? companyName,
    File? profileImage,
  }) async {
    try {
      _errorMessage = null;
      
      if (_currentUser == null) {
        _errorMessage = "Aucun utilisateur connecté";
        notifyListeners();
        return false;
      }
      
      final updatedUser = await _authService.updateProfile(
        userId: _currentUser!.id,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        bio: bio,
        location: location,
        companyName: companyName,
        profileImage: profileImage,
      );
      
      if (updatedUser != null) {
        _currentUser = updatedUser;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Échec de la mise à jour du profil";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Méthode utilitaire pour débugger l'état d'authentification
  Future<void> debugAuthState() async {
    final token = await _secureStorage.read(key: 'access_token');
    final refreshToken = await _secureStorage.read(key: 'refresh_token');
    
    print('=== DEBUG AUTH STATE ===');
    print('Status: $_status');
    print('Current User: ${_currentUser?.email ?? 'null'}');
    print('Access Token: ${token != null ? 'EXISTS (${token.length} chars)' : 'NULL'}');
    print('Refresh Token: ${refreshToken != null ? 'EXISTS' : 'NULL'}');
    print('Is Authenticated: $isAuthenticated');
    print('========================');
  }

  /// Méthode pour obtenir l'URL de base de votre API
  String _getBaseUrl() {
    try {
      // Si vous avez accès à dotenv
      return dotenv.env['API_BASE_URL'] ?? 'http://localhost:8003/api';
      
    } catch (e) {
      return 'http://localhost:8003/api';
    }
  }
}