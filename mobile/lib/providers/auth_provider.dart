import 'package:flutter/foundation.dart';
import '../core/services/auth_service.dart';
import '../core/models/user.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  
  AuthStatus _status = AuthStatus.uninitialized;
  User? _currentUser;
  String? _errorMessage;

  AuthProvider(this._authService) {
    // Vérifier l'état d'authentification au démarrage
    _checkCurrentUser();
  }

  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> _checkCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      _currentUser = user;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    try {
      _errorMessage = null;
      final user = await _authService.login(username, password);
      
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

  Future<bool> resetPassword(String email) async {
    try {
      _errorMessage = null;
      final result = await _authService.resetPassword(email);
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}