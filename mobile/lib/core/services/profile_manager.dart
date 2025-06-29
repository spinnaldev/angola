// lib/core/services/profile_manager.dart - Synchronisé avec l'utilisateur authentifié
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';

class ProfileManager {
  static const String _currentProfileKey = 'current_profile';
  static const String _defaultProfile = 'client';

  // Profil actuel en mémoire (utilisé comme fallback seulement)
  static String? _fallbackProfile;
  static bool _isInitialized = false;
  
  // Référence au AuthProvider pour obtenir le rôle de l'utilisateur connecté
  static AuthProvider? _authProvider;

  /// Initialise le ProfileManager en chargeant le profil sauvegardé
  static Future<void> initialize([AuthProvider? authProvider]) async {
    try {
      _authProvider = authProvider;
      
      final prefs = await SharedPreferences.getInstance();
      _fallbackProfile = prefs.getString(_currentProfileKey) ?? _defaultProfile;
      _isInitialized = true;
      
      print("ProfileManager initialisé - Profil fallback: $_fallbackProfile");
      
      // Si un AuthProvider est fourni, synchroniser avec le rôle utilisateur
      if (authProvider != null) {
        await _syncWithUserRole();
      }
    } catch (e) {
      print("Erreur lors de l'initialisation du ProfileManager: $e");
      _fallbackProfile = _defaultProfile;
      _isInitialized = true;
    }
  }

  /// Met à jour la référence du AuthProvider
  static void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
    // Synchroniser immédiatement si possible
    _syncWithUserRole();
  }

  /// Synchronise le profil avec le rôle de l'utilisateur connecté
  static Future<void> _syncWithUserRole() async {
    if (_authProvider == null || !_authProvider!.isAuthenticated) {
      return;
    }

    final user = _authProvider!.currentUser;
    if (user != null && user.role != null) {
      final userRole = user.role;
      print("🔄 Synchronisation: Rôle utilisateur = $userRole");
      
      // Convertir le rôle utilisateur en profil ProfileManager
      String targetProfile;
      if (userRole == 'provider') {
        targetProfile = 'provider';
      } else {
        targetProfile = 'client'; // client, admin, ou tout autre rôle → mode client
      }
      
      // Mettre à jour le profil si différent
      if (_fallbackProfile != targetProfile) {
        print("🔄 Mise à jour profil: $_fallbackProfile → $targetProfile");
        await _setFallbackProfile(targetProfile);
      }
    }
  }

  /// Récupère le profil actuel (priorité: rôle utilisateur > fallback > défaut)
  static String getCurrentProfile() {
    // PRIORITÉ 1: Si utilisateur connecté, utiliser son rôle
    if (_authProvider != null && _authProvider!.isAuthenticated) {
      final user = _authProvider!.currentUser;
      if (user != null && user.role != null) {
        final userRole = user.role;
        
        // Convertir le rôle utilisateur
        if (userRole == 'provider') {
          print("Profil basé sur utilisateur connecté: provider");
          return 'provider';
        } else {
          print("Profil basé sur utilisateur connecté: client (rôle: $userRole)");
          return 'client';
        }
      }
    }
    
    // PRIORITÉ 2: Utiliser le profil fallback
    if (!_isInitialized || _fallbackProfile == null) {
      print("ProfileManager pas initialisé, utilisation du profil par défaut: $_defaultProfile");
      return _defaultProfile;
    }
    
    print("Profil fallback utilisé: $_fallbackProfile");
    return _fallbackProfile!;
  }

  /// Définit le profil fallback (pour les utilisateurs non connectés)
  static Future<void> _setFallbackProfile(String profile) async {
    try {
      _fallbackProfile = profile;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentProfileKey, profile);
      print("Profil fallback sauvegardé: $profile");
    } catch (e) {
      print("Erreur lors de la sauvegarde du profil fallback: $e");
      _fallbackProfile = profile;
    }
  }

  /// Définit le profil actuel (seulement pour les utilisateurs non connectés)
  static Future<void> setCurrentProfile(String profile) async {
    print("🔧 setCurrentProfile appelé avec: $profile");
    
    // Si utilisateur connecté, ne pas permettre le changement manuel
    if (_authProvider != null && _authProvider!.isAuthenticated) {
      final user = _authProvider!.currentUser;
      if (user != null) {
        print("⚠️ Utilisateur connecté détecté. Le profil est déterminé par le rôle utilisateur: ${user.role}");
        // Synchroniser au lieu de changer manuellement
        await _syncWithUserRole();
        return;
      }
    }
    
    // Pour les utilisateurs non connectés, permettre le changement
    await _setFallbackProfile(profile);
    print("Profil changé vers: $profile (utilisateur non connecté)");
  }

  /// Vérifie si on est en mode prestataire
  static bool isProviderMode() {
    bool result = getCurrentProfile() == 'provider';
    print("isProviderMode() = $result (profil: ${getCurrentProfile()})");
    return result;
  }

  /// Vérifie si on est en mode client
  static bool isClientMode() {
    bool result = getCurrentProfile() == 'client';
    print("isClientMode() = $result (profil: ${getCurrentProfile()})");
    return result;
  }

  /// Bascule entre les profils (seulement si utilisateur non connecté)
  static Future<void> toggleProfile() async {
    if (_authProvider != null && _authProvider!.isAuthenticated) {
      print("⚠️ Impossible de basculer le profil: utilisateur connecté");
      return;
    }
    
    final newProfile = isProviderMode() ? 'client' : 'provider';
    await setCurrentProfile(newProfile);
  }

  /// Force la synchronisation avec le rôle utilisateur
  static Future<void> forceSync() async {
    await _syncWithUserRole();
  }

  /// Force la réinitialisation
  static Future<void> forceReset() async {
    _fallbackProfile = null;
    _isInitialized = false;
    _authProvider = null;
    await initialize();
  }

  /// Récupère l'icône du profil actuel
  static String getProfileIcon() {
    return isProviderMode() ? 'work' : 'person';
  }

  /// Récupère le libellé du profil actuel
  static String getProfileLabel() {
    return isProviderMode() ? 'Prestataire' : 'Client';
  }

  /// Récupère la couleur du profil actuel
  static String getProfileColor() {
    return isProviderMode()
        ? '#2196F3'
        : '#4CAF50'; // Bleu pour prestataire, vert pour client
  }

  /// Getter pour vérifier si le ProfileManager est initialisé
  static bool get isInitialized => _isInitialized;
  
  /// Debug: affiche l'état actuel
  static void debugState() {
    print("=== PROFILE MANAGER DEBUG ===");
    print("Initialisé: $_isInitialized");
    print("AuthProvider: ${_authProvider != null ? 'SET' : 'NULL'}");
    print("Utilisateur connecté: ${_authProvider?.isAuthenticated ?? false}");
    if (_authProvider?.currentUser != null) {
      print("Rôle utilisateur: ${_authProvider!.currentUser!.role}");
    }
    print("Profil fallback: $_fallbackProfile");
    print("Profil actuel: ${getCurrentProfile()}");
    print("Mode prestataire: ${isProviderMode()}");
    print("============================");
  }
}