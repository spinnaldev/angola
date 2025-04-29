import 'package:flutter/foundation.dart';
import '../core/services/auth_service.dart';
import '../core/models/user.dart';

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
      _errorMessage = null;
      final user = await _authService.login(email, password);
      
      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Échec de la connexion. Vérifiez vos identifiants.";
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
  
  Future<bool> register(String username, String email, String password, 
      String firstName, String lastName, String phoneNumber, String role) async {
    try {
      _errorMessage = null;
      final user = await _authService.register(
        username, email, password, firstName, lastName, phoneNumber, role);
      
      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
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
      final success = await _authService.logout();
      if (success) {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
      return success;
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
}