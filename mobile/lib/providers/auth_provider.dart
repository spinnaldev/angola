import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:teyago/core/models/verification_result.dart';
import 'package:teyago/core/services/api_service.dart';
import 'package:teyago/core/services/phone_verification_service.dart';
import 'package:teyago/core/services/provider_verification_service.dart';
import '../core/services/auth_service.dart';
import '../core/models/user.dart';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/services/profile_manager.dart';
import '../core/api/api_client.dart'; // ✅ Import ApiClient
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'provider_verification_provider.dart';
import 'phone_verification_provider.dart';
import 'verification_guard_provider.dart';

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
  late final ApiClient _apiClient; // ✅ Référence ApiClient
  
  AuthStatus _status = AuthStatus.uninitialized;
  User? _currentUser;
  String? _errorMessage;
  final apiService = ApiService(
      baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:8004/api',
      // baseUrl: 'http://10.0.2.2:8003/api',
      // baseUrl: "https://angola.onrender.com/api",
      apiKey: 'your_api_key_here',
    );
  // État pour le reset de mot de passe
  PasswordResetStatus _resetStatus = PasswordResetStatus.initial;
  String? _resetEmail;
  String? _resetCode;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  AuthProvider(this._authService) {
    // ✅ Initialiser ApiClient pour bénéficier des corrections d'encodage
    _apiClient = ApiClient(baseUrl: _getBaseUrl());
    // Vérifier l'état d'authentification au démarrage
    _checkCurrentUser();
  }

  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.uninitialized;
  // Getters pour le reset de mot de passe
  PasswordResetStatus get resetStatus => _resetStatus;
  String? get resetEmail => _resetEmail;
  String? get resetCode => _resetCode;

  ProviderVerificationProvider? _providerVerificationProvider;
  PhoneVerificationProvider? _phoneVerificationProvider;
  VerificationGuardProvider? _verificationGuardProvider;

  ProviderVerificationProvider? get providerVerificationProvider => _providerVerificationProvider;
  PhoneVerificationProvider? get phoneVerificationProvider => _phoneVerificationProvider;
  VerificationGuardProvider? get verificationGuardProvider => _verificationGuardProvider;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    // Mettre à jour la référence ProfileManager quand des listeners sont ajoutés
    ProfileManager.setAuthProvider(this);
  }

  // // ✅ NOUVELLE MÉTHODE 1: Invalider le cache
  // void invalidateCache() {
  //   print('🗑️ AuthProvider: Cache invalidé');
  //   // Si vous avez d'autres variables de cache, les réinitialiser ici
  // }

  // Initialiser les providers de vérification
  void _initializeVerificationProviders() {
    if (_authService != null) {
      final providerService = ProviderVerificationService(apiService);
      final phoneService = PhoneVerificationService(apiService);
      
      _providerVerificationProvider = ProviderVerificationProvider(providerService);
      _phoneVerificationProvider = PhoneVerificationProvider(phoneService);
      _verificationGuardProvider = VerificationGuardProvider();
      
      notifyListeners();
    }
  }
  
  

  // Charger les statuts de vérification après connexion
  Future<void> _loadVerificationStatuses() async {
    if (_currentUser == null) return;
    
    try {
      if (_currentUser!.role == 'provider' && _providerVerificationProvider != null) {
        await _providerVerificationProvider!.fetchVerificationStatus();
      } else if (_currentUser!.role == 'client' && _phoneVerificationProvider != null) {
        await _phoneVerificationProvider!.fetchVerificationStatus();
      }
    } catch (e) {
      print('❌ Erreur chargement statuts vérification: $e');
    }
  }

  
  // ✅ MÉTHODE CORRIGÉE: refreshToken
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) {
        print('❌ Aucun refresh token disponible');
        await logout();
        return false;
      }

      print('🔄 Tentative de rafraîchissement du token...');
      
      // ✅ Utiliser ApiClient au lieu de http.post
      final responseData = await _apiClient.post(
        'auth/token/refresh/',
        data: {'refresh': refreshToken},
        requireAuth: false
      );

      print('✅ Réponse refresh token reçue');

      if (responseData != null && responseData['access'] != null) {
        final newAccessToken = responseData['access'];
        
        // Sauvegarder le nouveau token d'accès
        await _secureStorage.write(key: 'access_token', value: newAccessToken);
        
        print('✅ Token rafraîchi avec succès');
        return true;
      } else {
        print('❌ Réponse invalide pour le refresh token');
        
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
      
      // Nettoyer en cas d'erreur
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      _status = AuthStatus.unauthenticated;
      _currentUser = null;
      notifyListeners();
      
      return false;
    }
  }

  // ✅ MÉTHODE CORRIGÉE: isTokenValid
  Future<bool> isTokenValid() async {
    try {
      final token = await _secureStorage.read(key: 'access_token');
      if (token == null) return false;

      // ✅ Utiliser ApiClient au lieu de http.get
      final responseData = await _apiClient.get('users/me/', requireAuth: true);
      
      // Si on reçoit des données, le token est valide
      return responseData != null;
    } catch (e) {
      print('❌ Erreur lors de la vérification du token: $e');
      return false;
    }
  }

  /// Méthode pour valider et éventuellement rafraîchir le token avant les requêtes
  Future<bool> ensureValidToken() async {
    if (!await isTokenValid()) {
      print('🔄 Token invalide, tentative de rafraîchissement...');
      return await refreshToken();
    }
    return true;
  }

  // Méthodes pour l'authentification et la vérification du statut
  // Future<void> _checkCurrentUser() async {
  //   try {
  //     final user = await _authService.getCurrentUser();
  //     if (user != null) {
  //       _currentUser = user;
  //       _status = AuthStatus.authenticated;
        
  //       // ✅ Debug encodage utilisateur
  //       print('✅ Utilisateur actuel: ${user.firstName} ${user.lastName}');
  //     } else {
  //       _status = AuthStatus.unauthenticated;
  //     }
  //   } catch (e) {
  //     print('❌ Erreur _checkCurrentUser: $e');
  //     _status = AuthStatus.unauthenticated;
  //   }
  //   notifyListeners();
  // }

  
  // Nouvelle méthode: Récupérer explicitement les informations utilisateur
  Future<void> getCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
        
        // ✅ Debug encodage utilisateur
        print('✅ Informations utilisateur récupérées: ${user.firstName} ${user.lastName}');
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Méthodes d'authentification existantes (utilisent déjà AuthService qui peut être migré séparément)
  Future<bool> login(String email, String password) async {
    try {
      // Réinitialiser le message d'erreur
      _errorMessage = null;
      notifyListeners();
      
      print('🔑 Tentative de connexion pour: $email');
      
      final user = await _authService.login(email, password);
      
      if (user != null) {
        print('✅ Connexion réussie pour: ${user.email} (rôle: ${user.role})');
        print('✅ Nom d\'utilisateur: ${user.firstName} ${user.lastName} (encodage correct)');
        
        _currentUser = user;
        _status = AuthStatus.authenticated;
        
        // AJOUT: Synchroniser le ProfileManager avec le rôle utilisateur
        ProfileManager.setAuthProvider(this);
        await ProfileManager.forceSync();
        // Initialiser les providers de vérification
        _initializeVerificationProviders();
        
        // Charger les statuts de vérification
        await _loadVerificationStatuses();

        
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
      
      // ✅ Gérer différents types d'erreurs avec messages UTF-8 corrects
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
        print('✅ Inscription réussie: ${user.firstName} ${user.lastName} (encodage correct)');
        
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
        print('✅ Inscription avec catégories réussie: ${user.firstName} ${user.lastName}');
        
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
  
  // Méthodes existantes pour le reset de mot de passe (utilisent AuthService)
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
  Future<bool> logout({BuildContext? context}) async {
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
      
      print('✅ Déconnexion réussie');
      
      notifyListeners();

      // AJOUT : Redirection automatique si contexte fourni
      if (context != null && context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home', 
          (route) => false,
        );
        
        // Optionnel : Afficher un message de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.loggedOutSuccessfully),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      return success;
    } catch (e) {
      print('❌ Erreur lors de la déconnexion: $e');
      
      // Forcer la déconnexion locale même en cas d'erreur
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      
      notifyListeners();

      // Redirection même en cas d'erreur
      if (context != null && context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home', 
          (route) => false,
        );
      }
      
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
        print('✅ Profil mis à jour: ${updatedUser.firstName} ${updatedUser.lastName}');
        
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
    print('User Name: ${_currentUser?.firstName} ${_currentUser?.lastName}');
    print('Access Token: ${token != null ? 'EXISTS (${token.length} chars)' : 'NULL'}');
    print('Refresh Token: ${refreshToken != null ? 'EXISTS' : 'NULL'}');
    print('Is Authenticated: $isAuthenticated');
    print('========================');
  }

  /// Méthode pour obtenir l'URL de base de votre API
  String _getBaseUrl() {
    try {
      // Si vous avez accès à dotenv
      return dotenv.env['API_BASE_URL'] ?? 'https://teyago.com/api';
      
    } catch (e) {
      return 'https://teyago.com/api';
    }
  }


  Future<void> checkAuthenticationStatus() async {
    try {
      print('🔍 Vérification du statut d\'authentification...');
      _status = AuthStatus.uninitialized;
      notifyListeners();

      // Vérifier si un token est stocké
      final token = await _secureStorage.read(key: 'auth_token');
      
      if (token == null || token.isEmpty) {
        print('❌ Aucun token trouvé');
        _status = AuthStatus.unauthenticated;
        _currentUser = null;
        notifyListeners();
        return;
      }

      print('✅ Token trouvé, vérification de la validité...');
      
      // Vérifier si le token est encore valide
      try {
        final user = await _authService.getCurrentUser();
        
        if (user != null) {
          print('✅ Utilisateur authentifié: ${user.firstName} ${user.lastName}');
          _currentUser = user;
          _status = AuthStatus.authenticated;
          
          // Synchroniser avec le ProfileManager
          ProfileManager.setAuthProvider(this);
          await ProfileManager.forceSync();
          
          notifyListeners();
        } else {
          print('❌ Token invalide, déconnexion');
          await _clearStoredCredentials();
          _status = AuthStatus.unauthenticated;
          _currentUser = null;
          notifyListeners();
        }
      } catch (e) {
        print('❌ Erreur lors de la vérification du token: $e');
        
        if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
          print('🔄 Token expiré, déconnexion automatique');
          await _clearStoredCredentials();
        }
        
        _status = AuthStatus.unauthenticated;
        _currentUser = null;
        notifyListeners();
      }
      
    } catch (e) {
      print('❌ Erreur lors de la vérification du statut d\'authentification: $e');
      _status = AuthStatus.unauthenticated;
      _currentUser = null;
      notifyListeners();
    }
  }

  /// Vérifier l'utilisateur actuel (méthode privée utilisée au démarrage)
  Future<void> _checkCurrentUser() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      
      if (token != null && token.isNotEmpty) {
        print('✅ Token trouvé au démarrage, vérification...');
        
        try {
          final user = await _authService.getCurrentUser();
          
          if (user != null) {
            _currentUser = user;
            _status = AuthStatus.authenticated;
            
            // Synchroniser avec le ProfileManager
            ProfileManager.setAuthProvider(this);
            await ProfileManager.forceSync();
            
            // Initialiser les providers de vérification
            _initializeVerificationProviders();
            
            // Charger les statuts de vérification
            await _loadVerificationStatuses();
            
            print('✅ Utilisateur restauré: ${user.firstName} ${user.lastName}');
          } else {
            await _clearStoredCredentials();
            _status = AuthStatus.unauthenticated;
          }
        } catch (e) {
          print('❌ Token invalide, nettoyage...');
          await _clearStoredCredentials();
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ Erreur lors de la vérification de l\'utilisateur: $e');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Nettoyer les identifiants stockés
  Future<void> _clearStoredCredentials() async {
    try {
      await _secureStorage.delete(key: 'auth_token');
      await _secureStorage.delete(key: 'refresh_token');
      await _secureStorage.delete(key: 'user_data');
      print('🧹 Identifiants supprimés du stockage sécurisé');
    } catch (e) {
      print('❌ Erreur lors du nettoyage des identifiants: $e');
    }
  }

  // Rafraîchir les statuts de vérification
  Future<void> refreshVerificationStatuses() async {
    await _loadVerificationStatuses();
    _verificationGuardProvider?.clearCache();
  }
  
  // Vérifier si l'utilisateur peut effectuer une action
  bool canPerformAction(BuildContext context, String actionDescription) {
    if (_verificationGuardProvider == null) return false;
    
    final result = _verificationGuardProvider!.checkAccess(context, _currentUser, actionDescription);
    return result.canAccess;
  }
  
  // Obtenir le résultat de vérification pour une action
  VerificationResult getVerificationResult(BuildContext context, String actionDescription) {
    if (_verificationGuardProvider == null) {
      return VerificationResult.blocked(
        title: 'Erreur',
        message: 'Service de vérification non initialisé',
      );
    }
    
    return _verificationGuardProvider!.checkAccess(context ,_currentUser, actionDescription);
  }
 
  // Future<void> refreshUserProfile() async {
  //   if (_currentUser == null) return;
    
  //   try {
  //     print('🔄 Rechargement du profil utilisateur...');
      
  //     final userData = await _authService.getCurrentUser();
  //     if (userData != null) {
  //       _currentUser = userData;
  //       print('✅ Profil utilisateur rechargé avec succès');
        
  //       // Recharger aussi les statuts de vérification
  //       await _loadVerificationStatuses();
        
  //       notifyListeners();
  //     }
  //   } catch (e) {
  //     print('❌ Erreur lors du rechargement du profil: $e');
  //     // Ne pas rethrow l'erreur pour éviter de casser l'UI
  //   }
  // }


  // ✅ AMÉLIORATION : Méthode pour vérifier si l'utilisateur est vérifié
  bool get isCurrentUserVerified {
    if (_currentUser == null) return false;
    return _currentUser!.verificationInfo.isVerified;
  }

  // ✅ AMÉLIORATION : Obtenir le statut de vérification actuel
  String get currentVerificationStatus {
    if (_currentUser == null) return 'not_verified';
    return _currentUser!.verificationInfo.status;
  }
  

  // ✅ NOUVELLE MÉTHODE : Force refresh complet
  Future<void> forceCompleteRefresh() async {
    try {
      

      print('🔄 Début force refresh complet...');

      // 1. Invalider le cache local
      invalidateCache();

      // 2. Appeler la nouvelle endpoint de force refresh
      final refreshedUser = await _authService.forceRefreshUserProfile();
      
      if (refreshedUser != null) {
        _currentUser = refreshedUser;
        print('✅ Utilisateur mis à jour via force refresh');
        
        // 3. Recharger les statuts de vérification
        await _loadVerificationStatuses();
        
        // 4. Notifier tous les listeners
        notifyListeners();
        
        print('✅ Force refresh complet terminé avec succès');
      } else {
        throw Exception('Aucune donnée utilisateur retournée');
      }

    } catch (e) {
      print('❌ Erreur force refresh complet: $e');
      
      // Fallback: essayer la méthode traditionnelle
      try {
        await refreshUserProfile();
      } catch (fallbackError) {
        print('❌ Erreur fallback: $fallbackError');
      }
    } finally {
      // setState(() {
      //   isLoading = false;
      // });
    }
  }

  // ✅ MÉTHODE AMÉLIORÉE : Refresh traditionnel
  Future<void> refreshUserProfile() async {
    if (_currentUser == null) return;
    
    try {
      print('🔄 Refresh traditionnel du profil...');
      
      // Essayer d'abord la nouvelle endpoint détaillée
      final userData = await _authService.getCurrentUserDetailed();
      
      if (userData != null) {
        _currentUser = userData;
        print('✅ Profil rechargé via endpoint détaillée');
      } else {
        // Fallback vers l'ancienne méthode
        final fallbackData = await _authService.getCurrentUser();
        if (fallbackData != null) {
          _currentUser = fallbackData;
          print('✅ Profil rechargé via fallback');
        }
      }
      
      // Recharger aussi les statuts de vérification
      await _loadVerificationStatuses();
      
      notifyListeners();
    } catch (e) {
      print('❌ Erreur refresh profil: $e');
      // Ne pas rethrow pour éviter de casser l'UI
    }
  }

  // ✅ NOUVELLE MÉTHODE : Vérifier si refresh nécessaire
  bool shouldRefresh() {
    if (_currentUser == null) return true;
    
    // Vérifier si les données semblent obsolètes
    final lastUpdate = _lastRefreshTime;
    if (lastUpdate == null) return true;
    
    final timeSinceUpdate = DateTime.now().difference(lastUpdate);
    return timeSinceUpdate.inMinutes > 2; // Refresh si plus de 2 minutes
  }

  DateTime? _lastRefreshTime;
  
  // ✅ NOUVELLE MÉTHODE : Invalider le cache
  void invalidateCache() {
    _lastRefreshTime = null;
    print('🧹 Cache local invalidé');
  }

  // ✅ MÉTHODE AMÉLIORÉE : Update current user
  void updateCurrentUser(User newUser) {
    _currentUser = newUser;
    _lastRefreshTime = DateTime.now();
    notifyListeners();
    print('✅ Utilisateur mis à jour et cache rafraîchi');
  }


}