// lib/core/services/profile_manager.dart
import 'package:shared_preferences/shared_preferences.dart';

class ProfileManager {
  static const String _currentProfileKey = 'current_profile';
  static const String _defaultProfile = 'client';
  
  // Profil actuel en mémoire
  static String? _currentProfile;
  
  /// Initialise le ProfileManager en chargeant le profil sauvegardé
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentProfile = prefs.getString(_currentProfileKey) ?? _defaultProfile;
  }
  
  /// Récupère le profil actuel
  static String getCurrentProfile() {
    return _currentProfile ?? _defaultProfile;
  }
  
  /// Définit le profil actuel et le sauvegarde
  static Future<void> setCurrentProfile(String profile) async {
    _currentProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentProfileKey, profile);
  }
  
  /// Vérifie si on est en mode prestataire
  static bool isProviderMode() {
    return getCurrentProfile() == 'provider';
  }
  
  /// Vérifie si on est en mode client
  static bool isClientMode() {
    return getCurrentProfile() == 'client';
  }
  
  /// Bascule entre les profils
  static Future<void> toggleProfile() async {
    final newProfile = isProviderMode() ? 'client' : 'provider';
    await setCurrentProfile(newProfile);
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
    return isProviderMode() ? '#2196F3' : '#4CAF50'; // Bleu pour prestataire, vert pour client
  }
}